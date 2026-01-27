import jwt
from datetime import datetime, timedelta
from functools import wraps
from flask import request, jsonify
import os

# JWT Configuration
SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'smartfinance-secret-key-change-in-production')
ALGORITHM = 'HS256'
ACCESS_TOKEN_EXPIRE_MINUTES = 60  # 1 hour
REFRESH_TOKEN_EXPIRE_DAYS = 30  # 30 days


def generate_access_token(user_id, email):
    """Generate JWT access token"""
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'access',
        'exp': datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


def generate_refresh_token(user_id, email):
    """Generate JWT refresh token"""
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'refresh',
        'exp': datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS),
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


def decode_token(token):
    """Decode and verify JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None  # Token has expired
    except jwt.InvalidTokenError:
        return None  # Invalid token


def token_required(f):
    """Decorator to protect routes with JWT authentication"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None

        # Get token from Authorization header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                # Expected format: "Bearer <token>"
                token = auth_header.split(' ')[1]
            except IndexError:
                return jsonify({'error': 'Invalid token format'}), 401

        if not token:
            return jsonify({'error': 'Token is missing'}), 401

        # Decode and verify token
        payload = decode_token(token)

        if not payload:
            return jsonify({'error': 'Token is invalid or expired'}), 401

        if payload.get('type') != 'access':
            return jsonify({'error': 'Invalid token type'}), 401

        # Add user info to request context
        request.user_id = payload['user_id']
        request.user_email = payload['email']

        return f(*args, **kwargs)

    return decorated


def generate_password_reset_token(user_id, email):
    """Generate password reset token (short-lived)"""
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'password_reset',
        'exp': datetime.utcnow() + timedelta(hours=1),  # 1 hour expiry
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


def verify_password_reset_token(token):
    """Verify password reset token"""
    payload = decode_token(token)

    if not payload:
        return None

    if payload.get('type') != 'password_reset':
        return None

    return {
        'user_id': payload['user_id'],
        'email': payload['email']
    }


def generate_email_verification_token(user_id, email):
    """Generate email verification token (24-hour expiry)"""
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'email_verification',
        'exp': datetime.utcnow() + timedelta(hours=24),  # 24 hour expiry
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


def verify_email_verification_token(token):
    """Verify email verification token"""
    payload = decode_token(token)

    if not payload:
        return None

    if payload.get('type') != 'email_verification':
        return None

    return {
        'user_id': payload['user_id'],
        'email': payload['email']
    }
