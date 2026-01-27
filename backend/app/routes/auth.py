from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User
from app.models.password_reset import PasswordReset
from app.models.email_verification import EmailVerification
from app.utils.jwt_utils import (
    generate_access_token,
    generate_refresh_token,
    generate_password_reset_token,
    verify_password_reset_token,
    generate_email_verification_token,
    verify_email_verification_token,
    decode_token
)
from app.utils.email_service import send_verification_email, send_password_reset_email
from datetime import datetime, timedelta
import re

auth_bp = Blueprint('auth', __name__)

def validate_email(email):
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def validate_password(password):
    """Validate password strength"""
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
    """Register a new user"""
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = ['email', 'password', 'fullName']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({'error': f'{field} is required'}), 400

        email = data['email'].strip().lower()
        password = data['password']
        full_name = data['fullName'].strip()
        phone_number = data.get('phoneNumber', '').strip()

        # Validate email format
        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        # Validate password strength
        is_valid, message = validate_password(password)
        if not is_valid:
            return jsonify({'error': message}), 400

        # Check if user already exists
        existing_user = User.query.filter_by(Email=email).first()
        if existing_user:
            return jsonify({'error': 'Email already registered'}), 409

        # Create new user
        new_user = User(
            Email=email,
            FullName=full_name,
            PhoneNumber=phone_number if phone_number else None
        )
        new_user.set_password(password)

        db.session.add(new_user)
        db.session.commit()

        # Generate email verification token
        verification_token = generate_email_verification_token(new_user.UserId, new_user.Email)

        # Save verification token to database
        email_verification = EmailVerification(
            UserId=new_user.UserId,
            Token=verification_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=24)
        )
        db.session.add(email_verification)
        db.session.commit()

        # Send verification email (in background in production)
        send_verification_email(new_user.Email, new_user.FullName, verification_token)

        # Generate JWT tokens
        access_token = generate_access_token(new_user.UserId, new_user.Email)
        refresh_token = generate_refresh_token(new_user.UserId, new_user.Email)

        return jsonify({
            'message': 'User registered successfully. Please verify your email.',
            'user': new_user.to_dict(),
            'accessToken': access_token,
            'refreshToken': refresh_token,
            'verificationToken': verification_token  # For development only
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Registration failed: {str(e)}'}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    """Login user"""
    try:
        data = request.get_json()

        # Validate required fields
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400

        email = data['email'].strip().lower()
        password = data['password']

        # Find user by email
        user = User.query.filter_by(Email=email).first()

        if not user or not user.check_password(password):
            return jsonify({'error': 'Invalid email or password'}), 401

        # Update last login
        user.LastLogin = datetime.utcnow()
        db.session.commit()

        # Generate JWT tokens
        access_token = generate_access_token(user.UserId, user.Email)
        refresh_token = generate_refresh_token(user.UserId, user.Email)

        return jsonify({
            'message': 'Login successful',
            'user': user.to_dict(),
            'accessToken': access_token,
            'refreshToken': refresh_token
        }), 200

    except Exception as e:
        return jsonify({'error': f'Login failed: {str(e)}'}), 500

@auth_bp.route('/user/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Get user by ID"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({'user': user.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': f'Failed to fetch user: {str(e)}'}), 500


@auth_bp.route('/refresh', methods=['POST'])
def refresh_token():
    """Refresh access token using refresh token"""
    try:
        data = request.get_json()
        refresh_token = data.get('refreshToken')

        if not refresh_token:
            return jsonify({'error': 'Refresh token is required'}), 400

        # Decode refresh token
        payload = decode_token(refresh_token)

        if not payload:
            return jsonify({'error': 'Invalid or expired refresh token'}), 401

        if payload.get('type') != 'refresh':
            return jsonify({'error': 'Invalid token type'}), 401

        # Verify user still exists
        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Generate new access token
        new_access_token = generate_access_token(user.UserId, user.Email)

        return jsonify({
            'accessToken': new_access_token,
            'message': 'Token refreshed successfully'
        }), 200

    except Exception as e:
        return jsonify({'error': f'Token refresh failed: {str(e)}'}), 500


@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    """Request password reset"""
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()

        if not email:
            return jsonify({'error': 'Email is required'}), 400

        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        # Find user by email
        user = User.query.filter_by(Email=email).first()

        # Always return success to prevent email enumeration
        # Even if user doesn't exist, return success message
        if not user:
            return jsonify({
                'message': 'If the email exists, a password reset link has been sent'
            }), 200

        # Generate reset token
        reset_token = generate_password_reset_token(user.UserId, user.Email)

        # Save token to database
        password_reset = PasswordReset(
            UserId=user.UserId,
            Token=reset_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=1)
        )
        db.session.add(password_reset)
        db.session.commit()

        # TODO: In production, send email with reset link
        # For now, return the token in response (ONLY FOR DEVELOPMENT)
        return jsonify({
            'message': 'If the email exists, a password reset link has been sent',
            'resetToken': reset_token  # Remove this in production!
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Password reset request failed: {str(e)}'}), 500


@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    """Reset password using token"""
    try:
        data = request.get_json()
        reset_token = data.get('token')
        new_password = data.get('newPassword')

        if not reset_token or not new_password:
            return jsonify({'error': 'Token and new password are required'}), 400

        # Validate password strength
        is_valid, message = validate_password(new_password)
        if not is_valid:
            return jsonify({'error': message}), 400

        # Verify token
        payload = verify_password_reset_token(reset_token)
        if not payload:
            return jsonify({'error': 'Invalid or expired reset token'}), 401

        # Check if token has been used
        password_reset = PasswordReset.query.filter_by(Token=reset_token, Used=False).first()
        if not password_reset or not password_reset.is_valid():
            return jsonify({'error': 'Invalid or expired reset token'}), 401

        # Get user
        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Update password
        user.set_password(new_password)
        password_reset.Used = True
        db.session.commit()

        return jsonify({'message': 'Password reset successfully'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Password reset failed: {str(e)}'}), 500


@auth_bp.route('/verify-reset-token', methods=['POST'])
def verify_reset_token():
    """Verify if reset token is valid"""
    try:
        data = request.get_json()
        reset_token = data.get('token')

        if not reset_token:
            return jsonify({'error': 'Token is required'}), 400

        # Verify token
        payload = verify_password_reset_token(reset_token)
        if not payload:
            return jsonify({'valid': False, 'error': 'Invalid or expired token'}), 200

        # Check in database
        password_reset = PasswordReset.query.filter_by(Token=reset_token, Used=False).first()
        if not password_reset or not password_reset.is_valid():
            return jsonify({'valid': False, 'error': 'Invalid or expired token'}), 200

        return jsonify({
            'valid': True,
            'email': payload['email']
        }), 200

    except Exception as e:
        return jsonify({'error': f'Token verification failed: {str(e)}'}), 500


@auth_bp.route('/verify-email', methods=['POST'])
def verify_email():
    """Verify email address using token"""
    try:
        data = request.get_json()
        verification_token = data.get('token')

        if not verification_token:
            return jsonify({'error': 'Verification token is required'}), 400

        # Verify token
        payload = verify_email_verification_token(verification_token)
        if not payload:
            return jsonify({'error': 'Invalid or expired verification token'}), 401

        # Check if token has been used
        email_verification = EmailVerification.query.filter_by(
            Token=verification_token,
            Verified=False
        ).first()

        if not email_verification or not email_verification.is_valid():
            return jsonify({'error': 'Invalid or expired verification token'}), 401

        # Get user
        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Mark email as verified
        user.EmailVerified = True
        email_verification.Verified = True
        db.session.commit()

        return jsonify({
            'message': 'Email verified successfully',
            'user': user.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Email verification failed: {str(e)}'}), 500


@auth_bp.route('/resend-verification', methods=['POST'])
def resend_verification():
    """Resend verification email"""
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()

        if not email:
            return jsonify({'error': 'Email is required'}), 400

        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        # Find user by email
        user = User.query.filter_by(Email=email).first()

        # Always return success to prevent email enumeration
        if not user:
            return jsonify({
                'message': 'If the email exists and is not verified, a new verification link has been sent'
            }), 200

        # Check if already verified
        if user.EmailVerified:
            return jsonify({
                'message': 'Email is already verified'
            }), 200

        # Generate new verification token
        verification_token = generate_email_verification_token(user.UserId, user.Email)

        # Save token to database
        email_verification = EmailVerification(
            UserId=user.UserId,
            Token=verification_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=24)
        )
        db.session.add(email_verification)
        db.session.commit()

        # Send verification email
        send_verification_email(user.Email, user.FullName, verification_token)

        return jsonify({
            'message': 'Verification email sent successfully',
            'verificationToken': verification_token  # For development only
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to resend verification email: {str(e)}'}), 500


@auth_bp.route('/check-verification/<int:user_id>', methods=['GET'])
def check_verification_status(user_id):
    """Check if user's email is verified"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({
            'emailVerified': user.EmailVerified,
            'email': user.Email
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to check verification status: {str(e)}'}), 500
