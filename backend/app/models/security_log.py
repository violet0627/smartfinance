# ==============================================================================
# security_log.py - Security Log Model (Database Table Definition)
# ==============================================================================
# This file defines the 'securitylogs' table in the MySQL database.
# It records security-related events that happen on a user's account.
#
# This is like an "audit trail" - it keeps a history of important security events
# so users can review their account activity for suspicious behavior.
#
# Examples of logged events:
# - "login" - User logged in successfully
# - "login_failed" - Someone tried to login with wrong password
# - "password_change" - User changed their password
# - "2fa_enabled" - User turned on two-factor authentication
# - "session_terminated" - User logged out another device
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps


class SecurityLog(db.Model):
    """
    Security Activity Log Model - Records security events for audit purposes.

    Maps to the 'securitylogs' table in MySQL.
    Each row = one security event (e.g., "User 1 logged in from 192.168.1.100").
    """

    __tablename__ = 'securitylogs'  # The exact table name in MySQL (lowercase)

    # --- Column Definitions ---
    LogId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique log entry ID
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
        # Which user's account this event is about.
    EventType = db.Column(db.String(100), nullable=False)    # Type of event (e.g., "login", "password_change", "2fa_enabled")
    EventDescription = db.Column(db.Text)                    # Human-readable description of what happened
                                                              # (e.g., "Successful login from Chrome on Windows")
    IpAddress = db.Column(db.String(45))                     # IP address where the event originated
    DeviceInfo = db.Column(db.String(255))                   # Device/browser info (e.g., "Chrome 120 on Windows 11")
    Success = db.Column(db.Boolean, default=True)            # Did the action succeed? (False for failed login attempts)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)  # When the event occurred

    def to_dict(self):
        """
        Convert SecurityLog to dictionary for JSON API responses.

        The Flutter app uses this to display the "Activity Log" in
        the Security settings, showing recent security events.
        """
        return {
            'logId': self.LogId,                                                          # Log entry ID
            'userId': self.UserId,                                                        # User's ID
            'eventType': self.EventType,                                                  # Event type (e.g., "login")
            'eventDescription': self.EventDescription,                                    # Description of what happened
            'ipAddress': self.IpAddress,                                                  # Source IP address
            'deviceInfo': self.DeviceInfo,                                                # Device information
            'success': self.Success,                                                      # Was it successful?
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,         # Event timestamp
        }

    def __repr__(self):
        """String representation for debugging."""
        return f'<SecurityLog {self.LogId} - {self.EventType}>'
