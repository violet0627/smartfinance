import jwt
from datetime import datetime, timedelta
from functools import wraps
from flask import request, jsonify
import os

SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'smartfinance-secret-key-change-in-production')
ALGORITHM = 'HS256'
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 30


def generate_access_token(user_id, email):
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'access',
        'exp': datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def generate_refresh_token(user_id, email):
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'refresh',
        'exp': datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token):
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


def token_required(f):
    # Attaches request.user_id and request.user_email on success
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None

        if 'Authorization' in request.headers:
            try:
                token = request.headers['Authorization'].split(' ')[1]
            except IndexError:
                return jsonify({'error': 'Invalid token format'}), 401

        if not token:
            return jsonify({'error': 'Token is missing'}), 401

        payload = decode_token(token)
        if not payload:
            return jsonify({'error': 'Token is invalid or expired'}), 401

        if payload.get('type') != 'access':
            return jsonify({'error': 'Invalid token type'}), 401

        request.user_id = payload['user_id']
        request.user_email = payload['email']
        return f(*args, **kwargs)

    return decorated


def generate_password_reset_token(user_id, email):
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'password_reset',
        'exp': datetime.utcnow() + timedelta(hours=1),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def verify_password_reset_token(token):
    payload = decode_token(token)
    if not payload or payload.get('type') != 'password_reset':
        return None
    return {'user_id': payload['user_id'], 'email': payload['email']}


def generate_email_verification_token(user_id, email):
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'email_verification',
        'exp': datetime.utcnow() + timedelta(hours=24),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def verify_email_verification_token(token):
    payload = decode_token(token)
    if not payload or payload.get('type') != 'email_verification':
        return None
    return {'user_id': payload['user_id'], 'email': payload['email']}
