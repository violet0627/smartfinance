# ==============================================================================
# two_factor_auth.py - Two-Factor Authentication Routes (2FA API Endpoints)
# ==============================================================================
# This file defines API endpoints for Two-Factor Authentication (2FA).
# 2FA adds an extra layer of security: after entering their password, users
# must also enter a 6-digit code from an authenticator app (like Google Authenticator).
#
# How 2FA works:
# 1. SETUP: User scans a QR code with their authenticator app
# 2. VERIFY SETUP: User enters a code from the app to confirm it's working
# 3. LOGIN: After password, user must enter a 2FA code
# 4. BACKUP: If user loses their phone, they can use one-time backup codes
#
# URL prefix: /api/auth (shared with auth.py, set in app/__init__.py)
# ==============================================================================

from flask import Blueprint, request, jsonify              # Blueprint for grouping, request for input, jsonify for output
from app import db                                          # Database instance
from app.models.user import User                            # User model
from app.models.two_factor_auth import TwoFactorAuth        # TwoFactorAuth model (stores secrets/backup codes)
from app.utils.two_factor_utils import TwoFactorUtils       # Utility class for 2FA operations
from datetime import datetime                                # For timestamps

# --- Create the Blueprint ---
two_factor_bp = Blueprint('two_factor', __name__)


# ==============================================================================
# ROUTE: POST /api/auth/2fa/setup
# ==============================================================================
# Called when the user clicks "Enable 2FA" in the Security settings.
# Generates a TOTP secret, creates a QR code for the authenticator app,
# and generates backup codes for recovery.
#
# IMPORTANT: This does NOT enable 2FA yet - the user must verify a code first
# (using the verify-setup endpoint below).
# ==============================================================================
@two_factor_bp.route('/2fa/setup', methods=['POST'])
def setup_2fa():
    """Initialize 2FA setup for a user - returns QR code and secret"""
    try:
        data = request.get_json()
        user_id = data.get('userId')

        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400

        # --- Step 1: Get the user ---
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # --- Step 2: Check if 2FA is already enabled ---
        if user.TwoFactorEnabled:
            return jsonify({'error': '2FA is already enabled for this account'}), 400

        # --- Step 3: Generate a new TOTP secret ---
        # This is a random base32-encoded string that both the server and the
        # authenticator app will use to generate matching 6-digit codes.
        secret = TwoFactorUtils.generate_secret()

        # --- Step 4: Generate QR code image ---
        # The QR code encodes a special URI that authenticator apps can read.
        # When scanned, the app automatically adds the account with the secret.
        # Returns a base64-encoded PNG image string.
        qr_code = TwoFactorUtils.generate_qr_code(secret, user.Email)

        # --- Step 5: Generate backup codes ---
        # These are one-time-use codes for when the user can't access their
        # authenticator app (e.g., lost phone). Usually 8 codes like "A1B2-C3D4".
        backup_codes = TwoFactorUtils.generate_backup_codes()

        # --- Step 6: Hash backup codes before storing ---
        # Like passwords, we never store backup codes in plain text.
        hashed_backup_codes = TwoFactorUtils.hash_backup_codes(backup_codes)

        # --- Step 7: Save or update the 2FA record ---
        existing_2fa = TwoFactorAuth.query.filter_by(UserId=user_id).first()

        if existing_2fa:
            # Update existing record (from a previous incomplete setup attempt)
            existing_2fa.Secret = secret
            existing_2fa.BackupCodes = hashed_backup_codes
            existing_2fa.CreatedAt = datetime.utcnow()
        else:
            # Create new 2FA record (don't enable yet - wait for verification)
            two_factor = TwoFactorAuth(
                UserId=user_id,
                Secret=secret,
                BackupCodes=hashed_backup_codes
            )
            db.session.add(two_factor)

        db.session.commit()

        # --- Step 8: Return setup data ---
        # The user sees the QR code and backup codes on screen.
        # They should save the backup codes somewhere safe!
        return jsonify({
            'message': '2FA setup initialized',
            'qrCode': qr_code,               # Base64 QR code image for authenticator app
            'secret': secret,                  # Plain text secret for manual entry
            'backupCodes': backup_codes        # Show ONCE - user must save these!
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error setting up 2FA: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/2fa/verify-setup
# ==============================================================================
# Called after the user scans the QR code and enters their first 2FA code.
# This ENABLES 2FA on the account (proves the authenticator app is set up correctly).
# ==============================================================================
@two_factor_bp.route('/2fa/verify-setup', methods=['POST'])
def verify_2fa_setup():
    """Verify the 2FA setup by validating the first TOTP code - this enables 2FA"""
    try:
        data = request.get_json()
        user_id = data.get('userId')
        code = data.get('code')              # The 6-digit code from the authenticator app

        if not user_id or not code:
            return jsonify({'error': 'User ID and code are required'}), 400

        # --- Get user ---
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # --- Get the 2FA record with the secret ---
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA not initialized. Please setup 2FA first'}), 400

        # --- Verify the code against the stored secret ---
        # TwoFactorUtils.verify_totp() checks if the code matches what the
        # secret would generate at the current time (with a small window for clock drift).
        is_valid = TwoFactorUtils.verify_totp(two_factor.Secret, code)

        if not is_valid:
            return jsonify({'error': 'Invalid verification code'}), 400

        # --- Code is correct! Enable 2FA ---
        user.TwoFactorEnabled = True                  # Turn on 2FA for this user
        two_factor.LastUsedAt = datetime.utcnow()     # Record when 2FA was last used
        db.session.commit()

        return jsonify({
            'message': '2FA enabled successfully',
            'user': user.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error verifying 2FA: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/2fa/verify
# ==============================================================================
# Called during login (after password is correct) to verify the 2FA code.
# Also used for sensitive operations that require extra verification.
# ==============================================================================
@two_factor_bp.route('/2fa/verify', methods=['POST'])
def verify_2fa_code():
    """Verify a 2FA code during login or sensitive operations"""
    try:
        data = request.get_json()
        user_id = data.get('userId')
        code = data.get('code')

        if not user_id or not code:
            return jsonify({'error': 'User ID and code are required'}), 400

        # --- Get user and check 2FA is enabled ---
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        # --- Get the 2FA secret ---
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        # --- Verify the TOTP code ---
        is_valid = TwoFactorUtils.verify_totp(two_factor.Secret, code)

        if is_valid:
            two_factor.LastUsedAt = datetime.utcnow()   # Update last used time
            db.session.commit()

            return jsonify({
                'message': 'Code verified successfully',
                'verified': True
            }), 200
        else:
            return jsonify({
                'message': 'Invalid code',
                'verified': False
            }), 200

    except Exception as e:
        return jsonify({'error': f'Error verifying code: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/2fa/verify-backup
# ==============================================================================
# Called when the user can't access their authenticator app and uses a backup code.
# Backup codes are ONE-TIME USE - once used, it's removed from the list.
# ==============================================================================
@two_factor_bp.route('/2fa/verify-backup', methods=['POST'])
def verify_backup_code():
    """Verify a backup code (one-time use)"""
    try:
        data = request.get_json()
        user_id = data.get('userId')
        backup_code = data.get('backupCode')     # e.g., "A1B2-C3D4"

        if not user_id or not backup_code:
            return jsonify({'error': 'User ID and backup code are required'}), 400

        # --- Get user and check 2FA is enabled ---
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        # --- Get 2FA record with backup codes ---
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        # --- Verify the backup code ---
        # This hashes the input code and checks against stored hashed codes.
        # If valid, it returns the updated list with the used code removed.
        is_valid, updated_codes = TwoFactorUtils.verify_backup_code(
            backup_code,
            two_factor.BackupCodes
        )

        if is_valid:
            # Remove the used backup code from storage
            two_factor.BackupCodes = updated_codes
            two_factor.LastUsedAt = datetime.utcnow()
            db.session.commit()

            return jsonify({
                'message': 'Backup code verified successfully',
                'verified': True
            }), 200
        else:
            return jsonify({
                'message': 'Invalid backup code',
                'verified': False
            }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error verifying backup code: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/2fa/disable
# ==============================================================================
# Called when the user wants to turn off 2FA.
# Requires password confirmation for security (prevents unauthorized disabling).
# ==============================================================================
@two_factor_bp.route('/2fa/disable', methods=['POST'])
def disable_2fa():
    """Disable 2FA for a user (requires password confirmation)"""
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')      # Must confirm password to disable 2FA

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        # --- Get user ---
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # --- Verify password ---
        if not user.check_password(password):
            return jsonify({'error': 'Invalid password'}), 401

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        # --- Disable 2FA ---
        user.TwoFactorEnabled = False    # Turn off 2FA on the user

        # Delete the 2FA record (secret and backup codes)
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if two_factor:
            db.session.delete(two_factor)

        db.session.commit()

        return jsonify({
            'message': '2FA disabled successfully',
            'user': user.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error disabling 2FA: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/auth/2fa/status/<user_id>
# ==============================================================================
# Called to check the current 2FA status for a user.
# Returns whether 2FA is enabled, if they have backup codes, and when last used.
# ==============================================================================
@two_factor_bp.route('/2fa/status/<int:user_id>', methods=['GET'])
def get_2fa_status(user_id):
    """Get 2FA status for a user"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Get 2FA record if it exists
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()

        return jsonify({
            'twoFactorEnabled': user.TwoFactorEnabled,     # Is 2FA turned on?
            'hasBackupCodes': two_factor is not None and two_factor.BackupCodes is not None,  # Has backup codes?
            'lastUsedAt': two_factor.LastUsedAt.isoformat() if two_factor and two_factor.LastUsedAt else None  # When last used
        }), 200

    except Exception as e:
        return jsonify({'error': f'Error getting 2FA status: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/2fa/regenerate-backup-codes
# ==============================================================================
# Called when the user wants new backup codes (e.g., they used most of them).
# Requires password confirmation for security.
# Old backup codes are replaced with new ones.
# ==============================================================================
@two_factor_bp.route('/2fa/regenerate-backup-codes', methods=['POST'])
def regenerate_backup_codes():
    """Regenerate backup codes for a user"""
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        # --- Get user and verify password ---
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.check_password(password):
            return jsonify({'error': 'Invalid password'}), 401

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        # --- Get 2FA record ---
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        # --- Generate new backup codes ---
        backup_codes = TwoFactorUtils.generate_backup_codes()                    # Generate 8 new codes
        hashed_backup_codes = TwoFactorUtils.hash_backup_codes(backup_codes)     # Hash for secure storage

        # Replace old backup codes with new ones
        two_factor.BackupCodes = hashed_backup_codes
        db.session.commit()

        return jsonify({
            'message': 'Backup codes regenerated successfully',
            'backupCodes': backup_codes     # Show ONCE - user must save these!
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error regenerating backup codes: {str(e)}'}), 500
