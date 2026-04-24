# ==============================================================================
# session.py - User Session Model (Database Table Definition)
# ==============================================================================
# This file defines the 'usersessions' table in the MySQL database.
# It tracks active login sessions - every time a user logs in, a session is created.
#
# This is used for the "Security" section in the app where users can see:
# - What devices are logged into their account
# - When and from where each login happened
# - Ability to log out other devices remotely
#
# Example session data:
# - Device: "Samsung Galaxy S24" (mobile)
# - IP: 192.168.1.100
# - Login time: 2025-01-15 10:30:00
# - Status: Active
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps


class UserSession(db.Model):
    """
    User Session Model - Tracks active login sessions across devices.

    Maps to the 'usersessions' table in MySQL.
    Each row = one active (or expired) login session.
    """

    __tablename__ = 'usersessions'  # The exact table name in MySQL (lowercase)

    # --- Column Definitions ---
    SessionId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique session ID
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
        # Which user this session belongs to.
    DeviceName = db.Column(db.String(255))         # Name of the device (e.g., "Samsung Galaxy S24", "Chrome on Windows")
    DeviceType = db.Column(db.String(50))          # Type of device: "mobile", "web", or "desktop"
    IpAddress = db.Column(db.String(45))           # IP address of the device (IPv4 or IPv6)
                                                    # String(45) because IPv6 addresses can be up to 45 characters
    UserAgent = db.Column(db.Text)                 # Browser/app user agent string (detailed info about the device/browser)
    LoginAt = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)  # When the user logged in
    LastActiveAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
        # Last time this session was active (auto-updates on any database update)
    IsActive = db.Column(db.Boolean, default=True)  # Is this session still active? (False = logged out)
    RefreshToken = db.Column(db.String(500))        # JWT refresh token for this session (used to get new access tokens)
    ExpiresAt = db.Column(db.DateTime)              # When this session expires automatically

    def to_dict(self):
        """
        Convert UserSession to dictionary for JSON API responses.

        The Flutter app uses this to display the "Active Sessions" list
        in the Security settings screen.

        'Unknown Device' and 'unknown' are fallback values if the device
        info wasn't captured during login.
        """
        return {
            'sessionId': self.SessionId,                                                    # Session ID
            'userId': self.UserId,                                                          # User's ID
            'deviceName': self.DeviceName or 'Unknown Device',                              # Device name (with fallback)
            'deviceType': self.DeviceType or 'unknown',                                     # Device type (with fallback)
            'ipAddress': self.IpAddress,                                                    # IP address
            'loginAt': self.LoginAt.isoformat() if self.LoginAt else None,                  # Login timestamp
            'lastActiveAt': self.LastActiveAt.isoformat() if self.LastActiveAt else None,   # Last active timestamp
            'isActive': self.IsActive,                                                      # Is session still active?
            'expiresAt': self.ExpiresAt.isoformat() if self.ExpiresAt else None,           # Expiry timestamp
        }

    def __repr__(self):
        """String representation for debugging."""
        return f'<UserSession {self.SessionId} - User {self.UserId}>'
