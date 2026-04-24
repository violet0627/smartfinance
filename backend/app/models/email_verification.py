# ==============================================================================
# email_verification.py - Email Verification Token Model (Database Table Definition)
# ==============================================================================
# This file defines the 'emailverificationtokens' table in the MySQL database.
# When a user registers, a verification token is generated and emailed to them.
#
# Flow:
# 1. User registers with their email
# 2. Backend generates a unique token and saves it in this table
# 3. Token is sent to user's email (as a link or code)
# 4. User clicks the link / enters the code
# 5. Backend verifies the token is valid (not expired, not used)
# 6. User's EmailVerified flag is set to True
#
# This proves the user actually owns the email address they registered with.
# ==============================================================================

from app import db                        # Import the SQLAlchemy database instance
from datetime import datetime, timedelta  # For timestamps and expiry calculations


class EmailVerification(db.Model):
    """
    Email Verification Token Model - Stores tokens sent to verify user emails.

    Maps to the 'emailverificationtokens' table in MySQL.
    Each row = one email verification request with its token and expiry.
    """

    __tablename__ = 'emailverificationtokens'  # The exact table name in MySQL (lowercase)

    # --- Column Definitions ---
    TokenId = db.Column(db.Integer, primary_key=True, autoincrement=True)   # Unique ID
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
        # Which user needs to verify their email.
        # ondelete='CASCADE' = if user is deleted, their verification tokens are also deleted.
    Token = db.Column(db.String(500), nullable=False)                       # The unique verification token (a long random string)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)             # When the token was created
    ExpiresAt = db.Column(db.DateTime, nullable=False)                      # When the token expires
    Used = db.Column(db.Boolean, default=False)                             # Has this token been used? (prevents reuse)

    def is_expired(self):
        """
        Check if the verification token has expired.

        Returns True if the current time is past the expiry time.
        Expired tokens cannot be used to verify email.
        """
        return datetime.utcnow() > self.ExpiresAt

    def is_valid(self):
        """
        Check if the token is valid (can be used to verify email).

        A token is valid ONLY if both conditions are true:
        1. Not already used (Used == False)
        2. Not expired (current time < ExpiresAt)
        """
        return not self.Used and not self.is_expired()

    def to_dict(self):
        """Convert EmailVerification to dictionary for JSON API responses."""
        return {
            'tokenId': self.TokenId,                                                    # Token record ID
            'userId': self.UserId,                                                      # User to verify
            'expiresAt': self.ExpiresAt.isoformat() if self.ExpiresAt else None,        # Expiry timestamp
            'used': self.Used,                                                          # Has been used?
            'isExpired': self.is_expired(),                                              # Is it expired? (computed)
            'isValid': self.is_valid(),                                                 # Is it still valid? (computed)
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None         # Creation timestamp
        }

    def __repr__(self):
        """String representation for debugging."""
        return f'<EmailVerification UserId={self.UserId} Used={self.Used}>'
