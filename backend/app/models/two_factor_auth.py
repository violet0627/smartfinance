# ==============================================================================
# two_factor_auth.py - Two-Factor Authentication Model (Database Table Definition)
# ==============================================================================
# This file defines the 'TwoFactorAuths' table in the MySQL database.
# It stores the 2FA secret key and backup codes for users who enable 2FA.
#
# Two-Factor Authentication (2FA) adds an extra layer of security:
# - Normal login: email + password (something you KNOW)
# - With 2FA: email + password + 6-digit code from authenticator app (something you HAVE)
#
# The secret key is used to generate time-based one-time passwords (TOTP)
# that change every 30 seconds. Both the app (Google Authenticator) and our
# backend share this same secret, so they can verify the codes match.
#
# Backup codes are one-time-use codes in case the user loses their phone.
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps


class TwoFactorAuth(db.Model):
    """
    Two-Factor Authentication Model - Stores 2FA secrets and backup codes.

    Maps to the 'TwoFactorAuths' table in MySQL.
    Each row = one user's 2FA configuration.
    Only users who have enabled 2FA will have a record here.
    """

    __tablename__ = 'TwoFactorAuths'  # The exact table name in MySQL

    # --- Column Definitions ---
    TwoFactorId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
        # Which user this 2FA setup belongs to.
        # ondelete='CASCADE' = if user is deleted, their 2FA record is also deleted.
    Secret = db.Column(db.String(500), nullable=False)   # The shared secret key used to generate TOTP codes
                                                          # This is shown as a QR code when setting up 2FA
                                                          # NEVER expose this to anyone!
    BackupCodes = db.Column(db.Text)                     # JSON string containing one-time-use backup codes
                                                          # Example: '["ABC123", "DEF456", "GHI789"]'
                                                          # Used when user can't access their authenticator app
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)   # When 2FA was set up
    LastUsedAt = db.Column(db.DateTime)                            # When 2FA was last used for login

    def to_dict(self):
        """
        Convert to dictionary for JSON API responses.

        IMPORTANT: The 'Secret' field is intentionally EXCLUDED from the response
        for security. We never send the 2FA secret to the client after initial setup.
        """
        return {
            'twoFactorId': self.TwoFactorId,                                              # 2FA record ID
            'userId': self.UserId,                                                        # User's ID
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,          # Setup date
            'lastUsedAt': self.LastUsedAt.isoformat() if self.LastUsedAt else None        # Last usage date
        }
