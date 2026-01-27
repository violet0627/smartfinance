from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.models.two_factor_auth import TwoFactorAuth
from app.utils.two_factor_utils import TwoFactorUtils
from datetime import datetime

two_factor_bp = Blueprint('two_factor', __name__)

@two_factor_bp.route('/2fa/setup', methods=['POST'])
def setup_2fa():
    """
    Initialize 2FA setup for a user
    Returns QR code and secret for authenticator app
    """
    try:
        data = request.get_json()
        user_id = data.get('userId')

        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400

        # Get user
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Check if 2FA is already enabled
        if user.TwoFactorEnabled:
            return jsonify({'error': '2FA is already enabled for this account'}), 400

        # Generate new secret
        secret = TwoFactorUtils.generate_secret()

        # Generate QR code
        qr_code = TwoFactorUtils.generate_qr_code(secret, user.Email)

        # Generate backup codes
        backup_codes = TwoFactorUtils.generate_backup_codes()

        # Hash backup codes for storage
        hashed_backup_codes = TwoFactorUtils.hash_backup_codes(backup_codes)

        # Check if 2FA record exists (from previous incomplete setup)
        existing_2fa = TwoFactorAuth.query.filter_by(UserId=user_id).first()

        if existing_2fa:
            # Update existing record
            existing_2fa.Secret = secret
            existing_2fa.BackupCodes = hashed_backup_codes
            existing_2fa.CreatedAt = datetime.utcnow()
        else:
            # Create new 2FA record (but don't enable yet - wait for verification)
            two_factor = TwoFactorAuth(
                UserId=user_id,
                Secret=secret,
                BackupCodes=hashed_backup_codes
            )
            db.session.add(two_factor)

        db.session.commit()

        return jsonify({
            'message': '2FA setup initialized',
            'qrCode': qr_code,
            'secret': secret,  # For manual entry
            'backupCodes': backup_codes  # Show once, user must save them
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error setting up 2FA: {str(e)}'}), 500


@two_factor_bp.route('/2fa/verify-setup', methods=['POST'])
def verify_2fa_setup():
    """
    Verify the 2FA setup by validating the first TOTP code
    This enables 2FA for the user
    """
    try:
        data = request.get_json()
        user_id = data.get('userId')
        code = data.get('code')

        if not user_id or not code:
            return jsonify({'error': 'User ID and code are required'}), 400

        # Get user
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Get 2FA record
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA not initialized. Please setup 2FA first'}), 400

        # Verify the code
        is_valid = TwoFactorUtils.verify_totp(two_factor.Secret, code)

        if not is_valid:
            return jsonify({'error': 'Invalid verification code'}), 400

        # Enable 2FA for the user
        user.TwoFactorEnabled = True
        two_factor.LastUsedAt = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': '2FA enabled successfully',
            'user': user.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error verifying 2FA: {str(e)}'}), 500


@two_factor_bp.route('/2fa/verify', methods=['POST'])
def verify_2fa_code():
    """
    Verify a 2FA code during login or sensitive operations
    """
    try:
        data = request.get_json()
        user_id = data.get('userId')
        code = data.get('code')

        if not user_id or not code:
            return jsonify({'error': 'User ID and code are required'}), 400

        # Get user
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        # Get 2FA record
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        # Verify TOTP code
        is_valid = TwoFactorUtils.verify_totp(two_factor.Secret, code)

        if is_valid:
            # Update last used time
            two_factor.LastUsedAt = datetime.utcnow()
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


@two_factor_bp.route('/2fa/verify-backup', methods=['POST'])
def verify_backup_code():
    """
    Verify a backup code (one-time use)
    """
    try:
        data = request.get_json()
        user_id = data.get('userId')
        backup_code = data.get('backupCode')

        if not user_id or not backup_code:
            return jsonify({'error': 'User ID and backup code are required'}), 400

        # Get user
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        # Get 2FA record
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        # Verify backup code
        is_valid, updated_codes = TwoFactorUtils.verify_backup_code(
            backup_code,
            two_factor.BackupCodes
        )

        if is_valid:
            # Update backup codes (removing the used one)
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


@two_factor_bp.route('/2fa/disable', methods=['POST'])
def disable_2fa():
    """
    Disable 2FA for a user (requires password confirmation)
    """
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        # Get user
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Verify password
        if not user.check_password(password):
            return jsonify({'error': 'Invalid password'}), 401

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        # Disable 2FA
        user.TwoFactorEnabled = False

        # Delete 2FA record
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


@two_factor_bp.route('/2fa/status/<int:user_id>', methods=['GET'])
def get_2fa_status(user_id):
    """
    Get 2FA status for a user
    """
    try:
        # Get user
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Get 2FA record if exists
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()

        return jsonify({
            'twoFactorEnabled': user.TwoFactorEnabled,
            'hasBackupCodes': two_factor is not None and two_factor.BackupCodes is not None,
            'lastUsedAt': two_factor.LastUsedAt.isoformat() if two_factor and two_factor.LastUsedAt else None
        }), 200

    except Exception as e:
        return jsonify({'error': f'Error getting 2FA status: {str(e)}'}), 500


@two_factor_bp.route('/2fa/regenerate-backup-codes', methods=['POST'])
def regenerate_backup_codes():
    """
    Regenerate backup codes for a user
    """
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        # Get user
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Verify password
        if not user.check_password(password):
            return jsonify({'error': 'Invalid password'}), 401

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        # Get 2FA record
        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        # Generate new backup codes
        backup_codes = TwoFactorUtils.generate_backup_codes()
        hashed_backup_codes = TwoFactorUtils.hash_backup_codes(backup_codes)

        # Update backup codes
        two_factor.BackupCodes = hashed_backup_codes
        db.session.commit()

        return jsonify({
            'message': 'Backup codes regenerated successfully',
            'backupCodes': backup_codes
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error regenerating backup codes: {str(e)}'}), 500
