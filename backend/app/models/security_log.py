from app import db
from datetime import datetime

class SecurityLog(db.Model):
    """Security Activity Log Model - Track security events"""
    __tablename__ = 'securitylogs'

    LogId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
    EventType = db.Column(db.String(100), nullable=False)  # login, logout, password_change, 2fa_enabled, etc.
    EventDescription = db.Column(db.Text)
    IpAddress = db.Column(db.String(45))
    DeviceInfo = db.Column(db.String(255))
    Success = db.Column(db.Boolean, default=True)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        """Convert security log to dictionary"""
        return {
            'logId': self.LogId,
            'userId': self.UserId,
            'eventType': self.EventType,
            'eventDescription': self.EventDescription,
            'ipAddress': self.IpAddress,
            'deviceInfo': self.DeviceInfo,
            'success': self.Success,
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,
        }

    def __repr__(self):
        return f'<SecurityLog {self.LogId} - {self.EventType}>'
