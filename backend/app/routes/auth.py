# ==============================================================================
# auth.py - Authentication Routes (API Endpoints for Login, Register, etc.)
# ==============================================================================
# This file defines ALL the authentication-related API endpoints.
# These are the URLs that the Flutter app calls when users:
# - Register a new account
# - Login to their account
# - Reset their password
# - Verify their email
# - Refresh their JWT token
#
# Each function is a "route handler" - it runs when the Flutter app sends
# an HTTP request to a specific URL with a specific method (GET, POST, etc.)
#
# URL prefix: /api/auth (set in app/__init__.py when registering this blueprint)
# So the full URLs are like: /api/auth/register, /api/auth/login, etc.
# ==============================================================================

from flask import Blueprint, request, jsonify     # Blueprint = group of routes, request = incoming data, jsonify = convert dict to JSON response
from app import db                                 # Database instance for saving/querying data
from app.models.user import User                   # User model (database table)
from app.models.password_reset import PasswordReset         # Password reset token model
from app.models.email_verification import EmailVerification # Email verification token model
from app.utils.jwt_utils import (                  # JWT (JSON Web Token) utility functions
    generate_access_token,                         # Creates a short-lived token for API access
    generate_refresh_token,                        # Creates a long-lived token to get new access tokens
    generate_password_reset_token,                 # Creates a token for password reset links
    verify_password_reset_token,                   # Validates a password reset token
    generate_email_verification_token,             # Creates a token for email verification links
    verify_email_verification_token,               # Validates an email verification token
    decode_token                                   # Decodes any JWT token to read its data
)
from app.utils.email_service import send_verification_email, send_password_reset_email  # Email sending functions
from datetime import datetime, timedelta           # For timestamps and calculating expiry times
import re                                          # Regular expressions for email/password validation

# --- Create the Blueprint ---
# Blueprint('auth', __name__) creates a group of routes named 'auth'.
# All routes in this file will be grouped under this blueprint.
# The URL prefix '/api/auth' is added in app/__init__.py.
auth_bp = Blueprint('auth', __name__)


# ==============================================================================
# HELPER FUNCTIONS (used by multiple routes below)
# ==============================================================================

def validate_email(email):
    """
    Validate email format using a regular expression (regex).

    The regex pattern checks for:
    - [a-zA-Z0-9._%+-]+  = one or more letters, numbers, dots, underscores, etc. (before @)
    - @                   = the @ symbol
    - [a-zA-Z0-9.-]+     = one or more letters, numbers, dots, hyphens (domain name)
    - \\.[a-zA-Z]{2,}     = a dot followed by 2+ letters (like .com, .my, .edu)

    Examples:
    - "user@gmail.com" -> True (valid)
    - "not-an-email"   -> False (no @)
    - "@gmail.com"     -> False (nothing before @)

    Returns:
        bool: True if email format is valid, False otherwise.
    """
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None  # re.match returns None if no match


def validate_password(password):
    """
    Validate password strength against security requirements.

    Rules:
    1. At least 8 characters long
    2. At least one uppercase letter (A-Z)
    3. At least one lowercase letter (a-z)
    4. At least one special symbol (!@#$%^&*... etc.)

    Args:
        password (str): The password to validate.

    Returns:
        tuple: (is_valid: bool, message: str)
        - (True, "Password is valid") if all rules pass
        - (False, "error message") if any rule fails
    """
    if len(password) < 8:
        return False, "Password must be at least 8 characters"
    if not re.search(r'[A-Z]', password):           # re.search looks for pattern anywhere in string
        return False, "Password must contain at least one uppercase letter"
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False, "Password must contain at least one symbol"
    return True, "Password is valid"


# ==============================================================================
# ROUTE: POST /api/auth/register
# ==============================================================================
# Called when a user submits the registration form in the Flutter app.
# Creates a new user account, sends verification email, and returns JWT tokens.
# ==============================================================================
@auth_bp.route('/register', methods=['POST'])      # Only accepts POST requests (sending data)
def register():
    """Register a new user"""
    try:
        # --- Step 1: Get the JSON data sent from the Flutter app ---
        # request.get_json() reads the body of the HTTP request as a dictionary.
        # The Flutter app sends something like:
        # {"email": "user@gmail.com", "password": "MyPass123!", "fullName": "John Doe"}
        data = request.get_json()

        # --- Step 2: Check that all required fields are present ---
        # If any field is missing or empty, return error with HTTP 400 (Bad Request)
        required_fields = ['email', 'password', 'fullName']
        for field in required_fields:
            if field not in data or not data[field]:     # Check if key exists AND has a value
                return jsonify({'error': f'{field} is required'}), 400

        # --- Step 3: Clean up the input data ---
        email = data['email'].strip().lower()      # strip() removes spaces, lower() makes lowercase
        password = data['password']
        full_name = data['fullName'].strip()
        phone_number = data.get('phoneNumber', '').strip()  # .get() returns '' if key doesn't exist

        # --- Step 4: Validate email format ---
        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        # --- Step 5: Validate password strength ---
        is_valid, message = validate_password(password)  # Returns (True/False, message)
        if not is_valid:
            return jsonify({'error': message}), 400

        # --- Step 6: Check if email is already registered ---
        # User.query.filter_by(Email=email) searches the Users table for this email.
        # .first() returns the first match or None if no match found.
        existing_user = User.query.filter_by(Email=email).first()
        if existing_user:
            return jsonify({'error': 'Email already registered'}), 409  # 409 = Conflict

        # --- Step 7: Create the new user object ---
        new_user = User(
            Email=email,
            FullName=full_name,
            PhoneNumber=phone_number if phone_number else None  # Save None if no phone number
        )
        new_user.set_password(password)  # Hash the password before saving (never store plain text!)

        # --- Step 8: Save the user to the database ---
        db.session.add(new_user)    # Stage the new user for saving
        db.session.commit()          # Actually save to the database (like pressing "Save")

        # --- Step 9: Generate email verification token ---
        # This creates a JWT token specifically for verifying the user's email address.
        verification_token = generate_email_verification_token(new_user.UserId, new_user.Email)

        # --- Step 10: Save the verification token to the database ---
        email_verification = EmailVerification(
            UserId=new_user.UserId,
            Token=verification_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=24)  # Token expires in 24 hours
        )
        db.session.add(email_verification)
        db.session.commit()

        # --- Step 11: Send verification email ---
        # Sends an email with a link containing the verification token.
        send_verification_email(new_user.Email, new_user.FullName, verification_token)

        # --- Step 12: Generate JWT tokens for the new user ---
        # These tokens allow the user to access the app immediately after registration.
        access_token = generate_access_token(new_user.UserId, new_user.Email)   # Short-lived (1 hour)
        refresh_token = generate_refresh_token(new_user.UserId, new_user.Email) # Long-lived (30 days)

        # --- Step 13: Return success response ---
        # HTTP 201 = "Created" (a new resource was successfully created)
        return jsonify({
            'message': 'User registered successfully. Please verify your email.',
            'user': new_user.to_dict(),              # User data as a dictionary
            'accessToken': access_token,              # For API access
            'refreshToken': refresh_token,            # For getting new access tokens
            'verificationToken': verification_token   # For development only (remove in production!)
        }), 201

    except Exception as e:
        # If ANYTHING goes wrong, undo all database changes (rollback)
        db.session.rollback()
        return jsonify({'error': f'Registration failed: {str(e)}'}), 500  # 500 = Server Error


# ==============================================================================
# ROUTE: POST /api/auth/login
# ==============================================================================
# Called when a user submits the login form. Validates credentials and returns
# JWT tokens if the email/password combination is correct.
# ==============================================================================
@auth_bp.route('/login', methods=['POST'])
def login():
    """Login user"""
    try:
        data = request.get_json()

        # --- Step 1: Check required fields ---
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400

        email = data['email'].strip().lower()
        password = data['password']

        # --- Step 2: Find user by email ---
        user = User.query.filter_by(Email=email).first()

        # --- Step 3: Verify password ---
        # We check both conditions together to avoid revealing whether the email exists.
        # "Invalid email or password" is intentionally vague for security.
        if not user or not user.check_password(password):
            return jsonify({'error': 'Invalid email or password'}), 401  # 401 = Unauthorized

        # --- Step 4: Update last login timestamp ---
        user.LastLogin = datetime.utcnow()
        db.session.commit()

        # --- Step 5: Generate new JWT tokens ---
        access_token = generate_access_token(user.UserId, user.Email)
        refresh_token = generate_refresh_token(user.UserId, user.Email)

        # --- Step 6: Return success with user data and tokens ---
        return jsonify({
            'message': 'Login successful',
            'user': user.to_dict(),
            'accessToken': access_token,
            'refreshToken': refresh_token
        }), 200  # 200 = OK

    except Exception as e:
        return jsonify({'error': f'Login failed: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/auth/user/<user_id>
# ==============================================================================
# Called to fetch a user's profile data. The <int:user_id> part is a URL
# parameter - Flask automatically extracts the number from the URL.
# Example: GET /api/auth/user/5 -> user_id = 5
# ==============================================================================
@auth_bp.route('/user/<int:user_id>', methods=['GET'])   # <int:user_id> captures an integer from the URL
def get_user(user_id):
    """Get user by ID"""
    try:
        # User.query.get() looks up a user by their primary key (UserId)
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404  # 404 = Not Found

        return jsonify({'user': user.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': f'Failed to fetch user: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/refresh
# ==============================================================================
# Called when the access token expires. The Flutter app sends its refresh token
# to get a new access token without requiring the user to login again.
#
# Flow:
# 1. Access token expires after 1 hour
# 2. Flutter app sends refresh token to this endpoint
# 3. Backend generates a new access token
# 4. Flutter app uses the new access token for future requests
# ==============================================================================
@auth_bp.route('/refresh', methods=['POST'])
def refresh_token():
    """Refresh access token using refresh token"""
    try:
        data = request.get_json()
        refresh_token = data.get('refreshToken')

        if not refresh_token:
            return jsonify({'error': 'Refresh token is required'}), 400

        # --- Step 1: Decode the refresh token ---
        # This reads the data inside the token and verifies it hasn't been tampered with.
        payload = decode_token(refresh_token)

        if not payload:
            return jsonify({'error': 'Invalid or expired refresh token'}), 401

        # --- Step 2: Verify it's actually a refresh token (not an access token) ---
        if payload.get('type') != 'refresh':
            return jsonify({'error': 'Invalid token type'}), 401

        # --- Step 3: Verify the user still exists ---
        # The user might have been deleted since the token was issued.
        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # --- Step 4: Generate a new access token ---
        new_access_token = generate_access_token(user.UserId, user.Email)

        return jsonify({
            'accessToken': new_access_token,
            'message': 'Token refreshed successfully'
        }), 200

    except Exception as e:
        return jsonify({'error': f'Token refresh failed: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/forgot-password
# ==============================================================================
# Called when a user clicks "Forgot Password" in the app.
# Generates a reset token and sends it via email.
# ==============================================================================
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

        # --- Find user by email ---
        user = User.query.filter_by(Email=email).first()

        # SECURITY: Always return the same message whether the email exists or not.
        # This prevents attackers from discovering which emails are registered
        # (called "email enumeration" attack).
        if not user:
            return jsonify({
                'message': 'If the email exists, a password reset link has been sent'
            }), 200

        # --- Generate a password reset token ---
        reset_token = generate_password_reset_token(user.UserId, user.Email)

        # --- Save the token to the database ---
        password_reset = PasswordReset(
            UserId=user.UserId,
            Token=reset_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=1)  # Expires in 1 hour
        )
        db.session.add(password_reset)
        db.session.commit()

        # TODO: In production, send email with reset link
        # For now, return the token in the response (ONLY FOR DEVELOPMENT)
        return jsonify({
            'message': 'If the email exists, a password reset link has been sent',
            'resetToken': reset_token  # Remove this in production!
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Password reset request failed: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/reset-password
# ==============================================================================
# Called when the user clicks the reset link and submits a new password.
# Validates the reset token and updates the user's password.
# ==============================================================================
@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    """Reset password using token"""
    try:
        data = request.get_json()
        reset_token = data.get('token')
        new_password = data.get('newPassword')

        if not reset_token or not new_password:
            return jsonify({'error': 'Token and new password are required'}), 400

        # --- Validate the new password's strength ---
        is_valid, message = validate_password(new_password)
        if not is_valid:
            return jsonify({'error': message}), 400

        # --- Step 1: Verify the JWT token itself ---
        payload = verify_password_reset_token(reset_token)
        if not payload:
            return jsonify({'error': 'Invalid or expired reset token'}), 401

        # --- Step 2: Check the token in the database (hasn't been used) ---
        # Token=reset_token: find this exact token
        # Used=False: only find tokens that haven't been used yet
        password_reset = PasswordReset.query.filter_by(Token=reset_token, Used=False).first()
        if not password_reset or not password_reset.is_valid():
            return jsonify({'error': 'Invalid or expired reset token'}), 401

        # --- Step 3: Get the user and update their password ---
        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        user.set_password(new_password)   # Hash and save the new password
        password_reset.Used = True         # Mark the token as used (can't be reused)
        db.session.commit()

        return jsonify({'message': 'Password reset successfully'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Password reset failed: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/verify-reset-token
# ==============================================================================
# Called to check if a password reset token is still valid before showing
# the "enter new password" form.
# ==============================================================================
@auth_bp.route('/verify-reset-token', methods=['POST'])
def verify_reset_token():
    """Verify if reset token is valid"""
    try:
        data = request.get_json()
        reset_token = data.get('token')

        if not reset_token:
            return jsonify({'error': 'Token is required'}), 400

        # --- Check the JWT token ---
        payload = verify_password_reset_token(reset_token)
        if not payload:
            return jsonify({'valid': False, 'error': 'Invalid or expired token'}), 200

        # --- Check the database record ---
        password_reset = PasswordReset.query.filter_by(Token=reset_token, Used=False).first()
        if not password_reset or not password_reset.is_valid():
            return jsonify({'valid': False, 'error': 'Invalid or expired token'}), 200

        # Token is valid - return success with the user's email
        return jsonify({
            'valid': True,
            'email': payload['email']
        }), 200

    except Exception as e:
        return jsonify({'error': f'Token verification failed: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/verify-email
# ==============================================================================
# Called when the user clicks the email verification link.
# Marks the user's email as verified in the database.
# ==============================================================================
@auth_bp.route('/verify-email', methods=['POST'])
def verify_email():
    """Verify email address using token"""
    try:
        data = request.get_json()
        verification_token = data.get('token')

        if not verification_token:
            return jsonify({'error': 'Verification token is required'}), 400

        # --- Step 1: Verify the JWT token ---
        payload = verify_email_verification_token(verification_token)
        if not payload:
            return jsonify({'error': 'Invalid or expired verification token'}), 401

        # --- Step 2: Check the database record ---
        email_verification = EmailVerification.query.filter_by(
            Token=verification_token,
            Verified=False              # Only find unused tokens
        ).first()

        if not email_verification or not email_verification.is_valid():
            return jsonify({'error': 'Invalid or expired verification token'}), 401

        # --- Step 3: Mark email as verified ---
        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404

        user.EmailVerified = True             # Mark user's email as verified
        email_verification.Verified = True     # Mark the token as used
        db.session.commit()

        return jsonify({
            'message': 'Email verified successfully',
            'user': user.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Email verification failed: {str(e)}'}), 500


# ==============================================================================
# ROUTE: POST /api/auth/resend-verification
# ==============================================================================
# Called when the user requests a new verification email (e.g., if the
# original one expired or got lost).
# ==============================================================================
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

        # --- Find user ---
        user = User.query.filter_by(Email=email).first()

        # SECURITY: Same anti-enumeration technique as forgot-password
        if not user:
            return jsonify({
                'message': 'If the email exists and is not verified, a new verification link has been sent'
            }), 200

        # --- Check if already verified ---
        if user.EmailVerified:
            return jsonify({
                'message': 'Email is already verified'
            }), 200

        # --- Generate new verification token ---
        verification_token = generate_email_verification_token(user.UserId, user.Email)

        # --- Save to database ---
        email_verification = EmailVerification(
            UserId=user.UserId,
            Token=verification_token,
            ExpiresAt=datetime.utcnow() + timedelta(hours=24)
        )
        db.session.add(email_verification)
        db.session.commit()

        # --- Send the email ---
        send_verification_email(user.Email, user.FullName, verification_token)

        return jsonify({
            'message': 'Verification email sent successfully',
            'verificationToken': verification_token  # For development only
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to resend verification email: {str(e)}'}), 500


# ==============================================================================
# ROUTE: GET /api/auth/check-verification/<user_id>
# ==============================================================================
# Called to check whether a user's email has been verified.
# The Flutter app can use this to decide whether to show a
# "please verify your email" banner.
# ==============================================================================
@auth_bp.route('/check-verification/<int:user_id>', methods=['GET'])
def check_verification_status(user_id):
    """Check if user's email is verified"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({
            'emailVerified': user.EmailVerified,   # True or False
            'email': user.Email                     # The user's email address
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to check verification status: {str(e)}'}), 500
