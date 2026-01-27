from app import db
from datetime import datetime

class UserSession(db.Model):
    """User Session Model - Track active login sessions"""
    __tablename__ = 'usersessions'

    SessionId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
    DeviceName = db.Column(db.String(255))
    DeviceType = db.Column(db.String(50))  # mobile, web, desktop
    IpAddress = db.Column(db.String(45))
    UserAgent = db.Column(db.Text)
    LoginAt = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    LastActiveAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    IsActive = db.Column(db.Boolean, default=True)
    RefreshToken = db.Column(db.String(500))
    ExpiresAt = db.Column(db.DateTime)

    def to_dict(self):
        """Convert session to dictionary"""
        return {
            'sessionId': self.SessionId,
            'userId': self.UserId,
            'deviceName': self.DeviceName or 'Unknown Device',
            'deviceType': self.DeviceType or 'unknown',
            'ipAddress': self.IpAddress,
            'loginAt': self.LoginAt.isoformat() if self.LoginAt else None,
            'lastActiveAt': self.LastActiveAt.isoformat() if self.LastActiveAt else None,
            'isActive': self.IsActive,
            'expiresAt': self.ExpiresAt.isoformat() if self.ExpiresAt else None,
        }

    def __repr__(self):
        return f'<UserSession {self.SessionId} - User {self.UserId}>'
