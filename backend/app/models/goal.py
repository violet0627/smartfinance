from app import db
from datetime import datetime


class Goal(db.Model):
    __tablename__ = 'Goals'

    GoalId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    # ondelete='CASCADE' enforces deletion at the database level in addition to SQLAlchemy's cascade
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
    GoalName = db.Column(db.String(100), nullable=False)
    Description = db.Column(db.Text, nullable=True)
    TargetAmount = db.Column(db.Numeric(15, 2), nullable=False)
    CurrentAmount = db.Column(db.Numeric(15, 2), default=0.00)
    StartDate = db.Column(db.Date, nullable=False, default=datetime.utcnow)
    Deadline = db.Column(db.Date, nullable=False)
    Status = db.Column(db.Enum('active', 'completed', 'abandoned'), default='active')
    Category = db.Column(db.String(50), nullable=True)
    Priority = db.Column(db.Enum('low', 'medium', 'high'), default='medium')
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    UpdatedAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship('User', backref=db.backref('goals', lazy=True, cascade='all, delete-orphan'))

    def to_dict(self):
        # Includes computed fields (progressPercentage, daysRemaining, isOverdue) not stored in the DB
        days_remaining = (self.Deadline - datetime.now().date()).days if self.Deadline else 0
        progress_percentage = min((float(self.CurrentAmount) / float(self.TargetAmount) * 100), 100) if self.TargetAmount > 0 else 0

        return {
            'goalId': self.GoalId,
            'userId': self.UserId,
            'goalName': self.GoalName,
            'description': self.Description,
            'targetAmount': float(self.TargetAmount),
            'currentAmount': float(self.CurrentAmount),
            'startDate': self.StartDate.isoformat() if self.StartDate else None,
            'deadline': self.Deadline.isoformat() if self.Deadline else None,
            'status': self.Status,
            'category': self.Category,
            'priority': self.Priority,
            'progressPercentage': round(progress_percentage, 2),
            'remainingAmount': float(self.TargetAmount - self.CurrentAmount),
            'daysRemaining': days_remaining,
            'isOverdue': days_remaining < 0 if self.Status == 'active' else False,
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,
            'updatedAt': self.UpdatedAt.isoformat() if self.UpdatedAt else None
        }

    def __repr__(self):
        return f'<Goal {self.GoalName} - {self.Status}>'
