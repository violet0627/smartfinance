from app import db
from datetime import datetime


class TwoFactorAuth(db.Model):
    __tablename__ = 'TwoFactorAuths'

    TwoFactorId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
    Secret = db.Column(db.String(500), nullable=False)   # Shared TOTP secret — never returned to the client after setup
    BackupCodes = db.Column(db.Text)                     # JSON-encoded list of one-time backup codes
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    LastUsedAt = db.Column(db.DateTime)

    def to_dict(self):
        # Secret excluded intentionally — never returned to the client after setup
        return {
            'twoFactorId': self.TwoFactorId,
            'userId': self.UserId,
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,
            'lastUsedAt': self.LastUsedAt.isoformat() if self.LastUsedAt else None
        }
