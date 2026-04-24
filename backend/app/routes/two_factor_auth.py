from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.models.two_factor_auth import TwoFactorAuth
from app.utils.two_factor_utils import TwoFactorUtils
from datetime import datetime

two_factor_bp = Blueprint('two_factor', __name__)


@two_factor_bp.route('/2fa/setup', methods=['POST'])
def setup_2fa():
    # Does not enable 2FA — caller must still complete /verify-setup to confirm the app is working
    try:
        data = request.get_json()
        user_id = data.get('userId')

        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if user.TwoFactorEnabled:
            return jsonify({'error': '2FA is already enabled for this account'}), 400

        secret = TwoFactorUtils.generate_secret()
        qr_code = TwoFactorUtils.generate_qr_code(secret, user.Email)
        backup_codes = TwoFactorUtils.generate_backup_codes()
        hashed_backup_codes = TwoFactorUtils.hash_backup_codes(backup_codes)

        existing_2fa = TwoFactorAuth.query.filter_by(UserId=user_id).first()

        if existing_2fa:
            existing_2fa.Secret = secret
            existing_2fa.BackupCodes = hashed_backup_codes
            existing_2fa.CreatedAt = datetime.utcnow()
        else:
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
            'secret': secret,
            'backupCodes': backup_codes  # shown once; user must save these
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to set up 2FA'}), 500


@two_factor_bp.route('/2fa/verify-setup', methods=['POST'])
def verify_2fa_setup():
    try:
        data = request.get_json()
        user_id = data.get('userId')
        code = data.get('code')

        if not user_id or not code:
            return jsonify({'error': 'User ID and code are required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA not initialized. Please setup 2FA first'}), 400

        is_valid = TwoFactorUtils.verify_totp(two_factor.Secret, code)

        if not is_valid:
            return jsonify({'error': 'Invalid verification code'}), 400

        user.TwoFactorEnabled = True
        two_factor.LastUsedAt = datetime.utcnow()
        db.session.commit()

        return jsonify({
            'message': '2FA enabled successfully',
            'user': user.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to verify 2FA setup'}), 500


@two_factor_bp.route('/2fa/verify', methods=['POST'])
def verify_2fa_code():
    try:
        data = request.get_json()
        user_id = data.get('userId')
        code = data.get('code')

        if not user_id or not code:
            return jsonify({'error': 'User ID and code are required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        is_valid = TwoFactorUtils.verify_totp(two_factor.Secret, code)

        if is_valid:
            two_factor.LastUsedAt = datetime.utcnow()
            db.session.commit()
            return jsonify({'message': 'Code verified successfully', 'verified': True}), 200
        else:
            return jsonify({'message': 'Invalid code', 'verified': False}), 200

    except Exception as e:
        return jsonify({'error': 'Failed to verify 2FA code'}), 500


@two_factor_bp.route('/2fa/verify-backup', methods=['POST'])
def verify_backup_code():
    try:
        data = request.get_json()
        user_id = data.get('userId')
        backup_code = data.get('backupCode')

        if not user_id or not backup_code:
            return jsonify({'error': 'User ID and backup code are required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        is_valid, updated_codes = TwoFactorUtils.verify_backup_code(
            backup_code,
            two_factor.BackupCodes
        )

        if is_valid:
            two_factor.BackupCodes = updated_codes
            two_factor.LastUsedAt = datetime.utcnow()
            db.session.commit()
            return jsonify({'message': 'Backup code verified successfully', 'verified': True}), 200
        else:
            return jsonify({'message': 'Invalid backup code', 'verified': False}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to verify backup code'}), 500


@two_factor_bp.route('/2fa/disable', methods=['POST'])
def disable_2fa():
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.check_password(password):
            return jsonify({'error': 'Invalid password'}), 401

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        user.TwoFactorEnabled = False
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
        return jsonify({'error': 'Failed to disable 2FA'}), 500


@two_factor_bp.route('/2fa/status/<int:user_id>', methods=['GET'])
def get_2fa_status(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()

        return jsonify({
            'twoFactorEnabled': user.TwoFactorEnabled,
            'hasBackupCodes': two_factor is not None and two_factor.BackupCodes is not None,
            'lastUsedAt': two_factor.LastUsedAt.isoformat() if two_factor and two_factor.LastUsedAt else None
        }), 200

    except Exception as e:
        return jsonify({'error': 'Failed to get 2FA status'}), 500


@two_factor_bp.route('/2fa/regenerate-backup-codes', methods=['POST'])
def regenerate_backup_codes():
    try:
        data = request.get_json()
        user_id = data.get('userId')
        password = data.get('password')

        if not user_id or not password:
            return jsonify({'error': 'User ID and password are required'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.check_password(password):
            return jsonify({'error': 'Invalid password'}), 401

        if not user.TwoFactorEnabled:
            return jsonify({'error': '2FA is not enabled for this account'}), 400

        two_factor = TwoFactorAuth.query.filter_by(UserId=user_id).first()
        if not two_factor:
            return jsonify({'error': '2FA configuration not found'}), 404

        backup_codes = TwoFactorUtils.generate_backup_codes()
        hashed_backup_codes = TwoFactorUtils.hash_backup_codes(backup_codes)

        two_factor.BackupCodes = hashed_backup_codes
        db.session.commit()

        return jsonify({
            'message': 'Backup codes regenerated successfully',
            'backupCodes': backup_codes  # shown once; user must save these
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to regenerate backup codes'}), 500
