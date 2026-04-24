from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.models.password_reset import PasswordReset
from app.models.email_verification import EmailVerification
from app.utils.jwt_utils import (
    generate_access_token, generate_refresh_token,
    generate_password_reset_token, verify_password_reset_token,
    generate_email_verification_token, verify_email_verification_token,
    decode_token
)
from app.utils.email_service import send_verification_email, send_password_reset_email
from datetime import datetime, timedelta
import re

auth_bp = Blueprint('auth', __name__)


def validate_email(email):
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def validate_password(password):
    if len(password) < 8:
        return False, "Password must be at least 8 characters"
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False, "Password must contain at least one symbol"
    return True, "Password is valid"


@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()

        required_fields = ['email', 'password', 'fullName']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({'error': f'{field} is required'}), 400

        email = data['email'].strip().lower()
        password = data['password']
        full_name = data['fullName'].strip()
        phone_number = data.get('phoneNumber', '').strip()

        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        is_valid, message = validate_password(password)
        if not is_valid:
            return jsonify({'error': message}), 400

        if User.query.filter_by(Email=email).first():
            return jsonify({'error': 'Email already registered'}), 409

        new_user = User(
            Email=email,
            FullName=full_name,
            PhoneNumber=phone_number if phone_number else None
        )
        new_user.set_password(password)
        db.session.add(new_user)
        db.session.commit()

        verification_token = generate_email_verification_token(new_user.UserId, new_user.Email)
        email_verification = EmailVerification(
            UserId=new_user.UserId,
            Token=verification_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=24)
        )
        db.session.add(email_verification)
        db.session.commit()

        send_verification_email(new_user.Email, new_user.FullName, verification_token)

        access_token = generate_access_token(new_user.UserId, new_user.Email)
        refresh_token = generate_refresh_token(new_user.UserId, new_user.Email)

        return jsonify({
            'message': 'User registered successfully. Please verify your email.',
            'user': new_user.to_dict(),
            'accessToken': access_token,
            'refreshToken': refresh_token,
            'verificationToken': verification_token
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Registration failed'}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()

        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400

        email = data['email'].strip().lower()
        user = User.query.filter_by(Email=email).first()

        # Intentionally vague error to prevent email enumeration
        if not user or not user.check_password(data['password']):
            return jsonify({'error': 'Invalid email or password'}), 401

        user.LastLogin = datetime.utcnow()
        db.session.commit()

        access_token = generate_access_token(user.UserId, user.Email)
        refresh_token = generate_refresh_token(user.UserId, user.Email)

        return jsonify({
            'message': 'Login successful',
            'user': user.to_dict(),
            'accessToken': access_token,
            'refreshToken': refresh_token
        }), 200

    except Exception as e:
        return jsonify({'error': 'Login failed'}), 500


@auth_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        return jsonify({'user': user.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch user'}), 500


@auth_bp.route('/refresh', methods=['POST'])
def refresh_token():
    try:
        data = request.get_json()
        refresh_token = data.get('refreshToken')

        if not refresh_token:
            return jsonify({'error': 'Refresh token is required'}), 400

        payload = decode_token(refresh_token)
        if not payload or payload.get('type') != 'refresh':
            return jsonify({'error': 'Invalid or expired refresh token'}), 401

        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        new_access_token = generate_access_token(user.UserId, user.Email)
        return jsonify({'accessToken': new_access_token, 'message': 'Token refreshed successfully'}), 200

    except Exception as e:
        return jsonify({'error': 'Token refresh failed'}), 500


@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()

        if not email:
            return jsonify({'error': 'Email is required'}), 400
        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        user = User.query.filter_by(Email=email).first()
        # Same response whether email exists or not — prevents email enumeration
        if not user:
            return jsonify({'message': 'If the email exists, a password reset link has been sent'}), 200

        reset_token = generate_password_reset_token(user.UserId, user.Email)
        password_reset = PasswordReset(
            UserId=user.UserId,
            Token=reset_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=1)
        )
        db.session.add(password_reset)
        db.session.commit()

        send_password_reset_email(user.Email, user.FullName, reset_token)
        return jsonify({'message': 'If the email exists, a password reset link has been sent'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Password reset request failed'}), 500


@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    try:
        data = request.get_json()
        reset_token = data.get('token')
        new_password = data.get('newPassword')

        if not reset_token or not new_password:
            return jsonify({'error': 'Token and new password are required'}), 400

        is_valid, message = validate_password(new_password)
        if not is_valid:
            return jsonify({'error': message}), 400

        payload = verify_password_reset_token(reset_token)
        if not payload:
            return jsonify({'error': 'Invalid or expired reset token'}), 401

        password_reset = PasswordReset.query.filter_by(Token=reset_token, Used=False).first()
        if not password_reset or not password_reset.is_valid():
            return jsonify({'error': 'Invalid or expired reset token'}), 401

        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        user.set_password(new_password)
        password_reset.Used = True
        db.session.commit()
        return jsonify({'message': 'Password reset successfully'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Password reset failed'}), 500


@auth_bp.route('/verify-reset-token', methods=['POST'])
def verify_reset_token():
    try:
        data = request.get_json()
        reset_token = data.get('token')

        if not reset_token:
            return jsonify({'error': 'Token is required'}), 400

        payload = verify_password_reset_token(reset_token)
        if not payload:
            return jsonify({'valid': False, 'error': 'Invalid or expired token'}), 200

        password_reset = PasswordReset.query.filter_by(Token=reset_token, Used=False).first()
        if not password_reset or not password_reset.is_valid():
            return jsonify({'valid': False, 'error': 'Invalid or expired token'}), 200

        return jsonify({'valid': True, 'email': payload['email']}), 200

    except Exception as e:
        return jsonify({'error': 'Token verification failed'}), 500


@auth_bp.route('/verify-email', methods=['POST'])
def verify_email():
    try:
        data = request.get_json()
        verification_token = data.get('token')

        if not verification_token:
            return jsonify({'error': 'Verification token is required'}), 400

        payload = verify_email_verification_token(verification_token)
        if not payload:
            return jsonify({'error': 'Invalid or expired verification token'}), 401

        email_verification = EmailVerification.query.filter_by(
            Token=verification_token, Used=False
        ).first()
        if not email_verification or not email_verification.is_valid():
            return jsonify({'error': 'Invalid or expired verification token'}), 401

        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        user.EmailVerified = True
        email_verification.Used = True
        db.session.commit()
        return jsonify({'message': 'Email verified successfully', 'user': user.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Email verification failed'}), 500


@auth_bp.route('/resend-verification', methods=['POST'])
def resend_verification():
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()

        if not email:
            return jsonify({'error': 'Email is required'}), 400
        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        user = User.query.filter_by(Email=email).first()
        # Same response whether email exists or not — prevents email enumeration
        if not user:
            return jsonify({'message': 'If the email exists and is not verified, a new verification link has been sent'}), 200

        if user.EmailVerified:
            return jsonify({'message': 'Email is already verified'}), 200

        verification_token = generate_email_verification_token(user.UserId, user.Email)
        email_verification = EmailVerification(
            UserId=user.UserId,
            Token=verification_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=24)
        )
        db.session.add(email_verification)
        db.session.commit()

        send_verification_email(user.Email, user.FullName, verification_token)
        return jsonify({
            'message': 'Verification email sent successfully',
            'verificationToken': verification_token
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to resend verification email'}), 500


@auth_bp.route('/check-verification/<int:user_id>', methods=['GET'])
def check_verification_status(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        return jsonify({'emailVerified': user.EmailVerified, 'email': user.Email}), 200
    except Exception as e:
        return jsonify({'error': 'Failed to check verification status'}), 500
