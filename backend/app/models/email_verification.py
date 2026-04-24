from app import db
from datetime import datetime, timedelta


class EmailVerification(db.Model):
    __tablename__ = 'emailverificationtokens'

    TokenId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
    Token = db.Column(db.String(500), nullable=False)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    ExpiresAt = db.Column(db.DateTime, nullable=False)
    Used = db.Column(db.Boolean, default=False)

    def is_expired(self):
        return datetime.utcnow() > self.ExpiresAt

    def is_valid(self):
        return not self.Used and not self.is_expired()

    def to_dict(self):
        return {
            'tokenId': self.TokenId,
            'userId': self.UserId,
            'expiresAt': self.ExpiresAt.isoformat() if self.ExpiresAt else None,
            'used': self.Used,
            'isExpired': self.is_expired(),
            'isValid': self.is_valid(),
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None
        }

    def __repr__(self):
        return f'<EmailVerification UserId={self.UserId} Used={self.Used}>'
