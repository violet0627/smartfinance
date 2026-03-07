# ==============================================================================
# password_reset.py - Password Reset Token Model (Database Table Definition)
# ==============================================================================
# This file defines the 'PasswordResets' table in the MySQL database.
# When a user clicks "Forgot Password", a reset token is generated and stored here.
#
# Flow:
# 1. User clicks "Forgot Password" and enters their email
# 2. Backend generates a unique token and saves it in this table
# 3. Token is sent to user's email as a link/code
# 4. User enters the token + new password
# 5. Backend verifies the token (not expired, not already used)
# 6. Password is updated, token is marked as "Used"
#
# Security: Tokens expire after a set time and can only be used once.
# ==============================================================================

from app import db                        # Import the SQLAlchemy database instance
from datetime import datetime, timedelta  # For timestamps and expiry calculations


class PasswordReset(db.Model):
    """
    Password Reset Token Model - Stores temporary tokens for password reset requests.

    Maps to the 'PasswordResets' table in MySQL.
    Each row = one password reset request with its token and expiry time.
    """

    __tablename__ = 'PasswordResets'  # The exact table name in MySQL

    # --- Column Definitions ---
    ResetId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
        # Which user requested the reset.
        # ondelete='CASCADE' = if user is deleted, their reset tokens are also deleted.
    Token = db.Column(db.String(500), nullable=False, unique=True)   # The unique reset token (a long random string)
                                                                      # unique=True ensures no two tokens are the same
    ExpiresAt = db.Column(db.DateTime, nullable=False)               # When this token expires (usually 1 hour after creation)
    Used = db.Column(db.Boolean, default=False)                      # Has this token been used already? (prevents reuse)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)      # When the reset was requested

    # --- Relationships ---
    # password_reset.user -> returns the User who requested this reset
    # user.password_resets -> returns all PasswordReset tokens for that user
    user = db.relationship('User', backref=db.backref('password_resets', lazy=True))

    def is_expired(self):
        """
        Check if the reset token has expired.

        Compares the current time with ExpiresAt.
        Returns True if the current time is PAST the expiry time.
        """
        return datetime.utcnow() > self.ExpiresAt

    def is_valid(self):
        """
        Check if the token is still valid (can be used to reset password).

        A token is valid ONLY if:
        1. It hasn't been used yet (Used == False)
        2. It hasn't expired yet (is_expired() == False)

        Both conditions must be true.
        """
        return not self.Used and not self.is_expired()

    def to_dict(self):
        """Convert PasswordReset to dictionary for JSON API responses."""
        return {
            'resetId': self.ResetId,                                                    # Reset record ID
            'userId': self.UserId,                                                      # User who requested reset
            'expiresAt': self.ExpiresAt.isoformat() if self.ExpiresAt else None,        # Expiry timestamp
            'used': self.Used,                                                          # Has it been used?
            'isExpired': self.is_expired(),                                              # Is it expired? (computed)
            'isValid': self.is_valid(),                                                 # Is it still valid? (computed)
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None         # Creation timestamp
        }

    def __repr__(self):
        """String representation for debugging."""
        return f'<PasswordReset UserId={self.UserId} Used={self.Used}>'
