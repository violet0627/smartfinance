# ==============================================================================
# jwt_utils.py - JWT (JSON Web Token) Utility Functions
# ==============================================================================
# This file provides all JWT-related functionality for SmartFinance.
#
# What is JWT?
# JWT (JSON Web Token) is a secure way to transmit information between the
# Flutter app and the backend server. It's like a digital "passport" that
# proves who the user is.
#
# How it works:
# 1. User logs in with email + password
# 2. Backend creates a JWT token containing the user's ID and email
# 3. Backend signs the token with a secret key (like stamping a passport)
# 4. Flutter app stores the token and sends it with every API request
# 5. Backend verifies the token's signature to confirm the user's identity
#
# Token types:
# - ACCESS TOKEN: Short-lived (1 hour), used for API requests
# - REFRESH TOKEN: Long-lived (30 days), used to get new access tokens
# - PASSWORD RESET TOKEN: Short-lived (1 hour), used for password reset links
# - EMAIL VERIFICATION TOKEN: Medium-lived (24 hours), used for email verification
# ==============================================================================

import jwt                                          # PyJWT library for creating/verifying tokens
from datetime import datetime, timedelta            # For timestamps and expiry calculations
from functools import wraps                         # For creating decorators (used in token_required)
from flask import request, jsonify                  # For accessing HTTP request data and creating responses
import os                                           # For reading environment variables

# ==============================================================================
# JWT Configuration
# ==============================================================================
# SECRET_KEY: The secret key used to sign (encrypt) JWT tokens.
# This key must be kept secret - anyone with this key can create valid tokens!
# os.getenv() tries to read from environment variable first, falls back to default.
# In production, ALWAYS set the JWT_SECRET_KEY environment variable!
SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'smartfinance-secret-key-change-in-production')

# ALGORITHM: The hashing algorithm used to sign the token.
# HS256 = HMAC with SHA-256 (a common, secure algorithm for JWT)
ALGORITHM = 'HS256'

# Token expiry times
ACCESS_TOKEN_EXPIRE_MINUTES = 60     # Access token expires after 1 hour
REFRESH_TOKEN_EXPIRE_DAYS = 30       # Refresh token expires after 30 days


# ==============================================================================
# FUNCTION: generate_access_token
# ==============================================================================
# Creates a short-lived JWT access token for API authentication.
# This token is sent in the "Authorization" header of every API request.
#
# The token contains (payload):
# - user_id: The user's unique ID
# - email: The user's email address
# - type: "access" (to distinguish from other token types)
# - exp: When the token expires (UTC timestamp)
# - iat: When the token was issued (UTC timestamp)
#
# Args:
#     user_id (int): The user's ID
#     email (str): The user's email
#
# Returns:
#     str: The encoded JWT token string
# ==============================================================================
def generate_access_token(user_id, email):
    """Generate JWT access token"""
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'access',                                                      # Token type identifier
        'exp': datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),  # Expiry time
        'iat': datetime.utcnow()                                               # Issued at time
    }
    # jwt.encode() creates the token string by:
    # 1. Converting the payload to JSON
    # 2. Encoding it as Base64
    # 3. Signing it with the SECRET_KEY using the ALGORITHM
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


# ==============================================================================
# FUNCTION: generate_refresh_token
# ==============================================================================
# Creates a long-lived JWT refresh token.
# Used to get a new access token when the current one expires.
# The user doesn't need to log in again as long as the refresh token is valid.
# ==============================================================================
def generate_refresh_token(user_id, email):
    """Generate JWT refresh token"""
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'refresh',                                                    # Token type identifier
        'exp': datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS), # 30 days expiry
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


# ==============================================================================
# FUNCTION: decode_token
# ==============================================================================
# Decodes and verifies a JWT token.
# This is the opposite of encode - it reads the data inside a token.
#
# Steps:
# 1. Verify the token's signature (proves it wasn't tampered with)
# 2. Check if the token has expired
# 3. Return the payload (data inside the token)
#
# Returns None if the token is invalid or expired (instead of crashing).
# ==============================================================================
def decode_token(token):
    """Decode and verify JWT token"""
    try:
        # jwt.decode() does the reverse of jwt.encode():
        # 1. Verifies the signature using SECRET_KEY
        # 2. Checks if the 'exp' claim has passed (token expired?)
        # 3. Returns the payload dictionary
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None      # Token has expired (past the 'exp' time)
    except jwt.InvalidTokenError:
        return None      # Token is invalid (tampered with, wrong format, etc.)


# ==============================================================================
# FUNCTION: token_required (DECORATOR)
# ==============================================================================
# A decorator that protects API routes with JWT authentication.
# When you put @token_required before a route function, it will:
# 1. Check for a token in the "Authorization" header
# 2. Decode and verify the token
# 3. Attach user info to the request (request.user_id, request.user_email)
# 4. Call the actual route function only if the token is valid
#
# Usage:
#     @some_bp.route('/protected', methods=['GET'])
#     @token_required
#     def protected_route():
#         user_id = request.user_id  # Available because of the decorator
#         ...
#
# A "decorator" is a function that wraps another function to add behavior.
# Think of it as a security guard that checks your ID before letting you in.
# ==============================================================================
def token_required(f):
    """Decorator to protect routes with JWT authentication"""
    @wraps(f)       # @wraps preserves the original function's name and docstring
    def decorated(*args, **kwargs):
        token = None

        # --- Step 1: Extract token from the Authorization header ---
        # The Flutter app sends: "Authorization: Bearer eyJhbG..."
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                # Split "Bearer eyJhbG..." into ["Bearer", "eyJhbG..."]
                # and take the second part (index [1]) - the actual token
                token = auth_header.split(' ')[1]
            except IndexError:
                return jsonify({'error': 'Invalid token format'}), 401

        if not token:
            return jsonify({'error': 'Token is missing'}), 401

        # --- Step 2: Decode and verify the token ---
        payload = decode_token(token)

        if not payload:
            return jsonify({'error': 'Token is invalid or expired'}), 401

        # --- Step 3: Verify it's an access token ---
        if payload.get('type') != 'access':
            return jsonify({'error': 'Invalid token type'}), 401

        # --- Step 4: Attach user info to the request ---
        # This makes user_id and email available in the route function
        request.user_id = payload['user_id']
        request.user_email = payload['email']

        # --- Step 5: Call the original route function ---
        return f(*args, **kwargs)

    return decorated    # Return the wrapped function


# ==============================================================================
# FUNCTION: generate_password_reset_token
# ==============================================================================
# Creates a short-lived token for password reset links.
# Expires in 1 hour for security (limits the window for misuse).
# ==============================================================================
def generate_password_reset_token(user_id, email):
    """Generate password reset token (short-lived)"""
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'password_reset',                                  # Token type identifier
        'exp': datetime.utcnow() + timedelta(hours=1),            # 1 hour expiry
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


# ==============================================================================
# FUNCTION: verify_password_reset_token
# ==============================================================================
# Verifies a password reset token and extracts user info.
# Returns None if the token is invalid, expired, or not a reset token.
# ==============================================================================
def verify_password_reset_token(token):
    """Verify password reset token"""
    payload = decode_token(token)

    if not payload:
        return None      # Token is invalid or expired

    # Make sure it's actually a password reset token (not an access/refresh token)
    if payload.get('type') != 'password_reset':
        return None

    # Return the user info from the token
    return {
        'user_id': payload['user_id'],
        'email': payload['email']
    }


# ==============================================================================
# FUNCTION: generate_email_verification_token
# ==============================================================================
# Creates a token for email verification links.
# Expires in 24 hours (gives the user time to check their email).
# ==============================================================================
def generate_email_verification_token(user_id, email):
    """Generate email verification token (24-hour expiry)"""
    payload = {
        'user_id': user_id,
        'email': email,
        'type': 'email_verification',                              # Token type identifier
        'exp': datetime.utcnow() + timedelta(hours=24),           # 24 hour expiry
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


# ==============================================================================
# FUNCTION: verify_email_verification_token
# ==============================================================================
# Verifies an email verification token and extracts user info.
# Returns None if the token is invalid, expired, or wrong type.
# ==============================================================================
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
