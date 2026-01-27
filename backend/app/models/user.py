from app import db
from datetime import datetime
import bcrypt

class User(db.Model):
    __tablename__ = 'Users'

    UserId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    Email = db.Column(db.String(255), unique=True, nullable=False)
    PasswordHash = db.Column(db.String(255), nullable=False)
    FullName = db.Column(db.String(255), nullable=False)
    PhoneNumber = db.Column(db.String(20))
    EmailVerified = db.Column(db.Boolean, default=False)
    TwoFactorEnabled = db.Column(db.Boolean, default=False)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    LastLogin = db.Column(db.DateTime)
    ExperiencePts = db.Column(db.Integer, default=0)
    CurrentLevel = db.Column(db.Integer, default=1)

    # Relationships
    transactions = db.relationship('Transaction', backref='user', lazy=True, cascade='all, delete-orphan')
    budgets = db.relationship('Budget', backref='user', lazy=True, cascade='all, delete-orphan')
    investments = db.relationship('Investment', backref='user', lazy=True, cascade='all, delete-orphan')

    def set_password(self, password):
        """Hash and set the password"""
        self.PasswordHash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    def check_password(self, password):
        """Check if provided password matches the hash"""
        return bcrypt.checkpw(password.encode('utf-8'), self.PasswordHash.encode('utf-8'))

    def to_dict(self):
        """Convert user object to dictionary (excluding password)"""
        return {
            'userId': self.UserId,
            'email': self.Email,
            'fullName': self.FullName,
            'phoneNumber': self.PhoneNumber,
            'emailVerified': self.EmailVerified,
            'twoFactorEnabled': self.TwoFactorEnabled,
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,
            'lastLogin': self.LastLogin.isoformat() if self.LastLogin else None,
            'experiencePts': self.ExperiencePts,
            'currentLevel': self.CurrentLevel
        }
