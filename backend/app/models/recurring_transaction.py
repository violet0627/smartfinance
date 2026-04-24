from app import db
from datetime import datetime, timedelta


class RecurringTransaction(db.Model):
    __tablename__ = 'recurringtransactions'

    RecurringId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId', ondelete='CASCADE'), nullable=False)
    Name = db.Column(db.String(255), nullable=False)
    TransactionType = db.Column(db.String(20), nullable=False)
    Category = db.Column(db.String(50), nullable=False)
    Amount = db.Column(db.Numeric(15, 2), nullable=False)
    Description = db.Column(db.Text)
    Frequency = db.Column(db.String(20), nullable=False)   # "daily", "weekly", "monthly", "yearly"
    StartDate = db.Column(db.Date, nullable=False)
    EndDate = db.Column(db.Date)
    LastExecuted = db.Column(db.Date)
    NextExecution = db.Column(db.Date, nullable=False)
    IsActive = db.Column(db.Boolean, default=True)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    UpdatedAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def calculate_next_execution(self):
        base_date = self.LastExecuted or self.StartDate

        if self.Frequency == 'daily':
            return base_date + timedelta(days=1)
        elif self.Frequency == 'weekly':
            return base_date + timedelta(weeks=1)
        elif self.Frequency == 'monthly':
            # timedelta does not support months, so advance manually
            month = base_date.month
            year = base_date.year
            if month == 12:
                month, year = 1, year + 1
            else:
                month += 1
            return base_date.replace(year=year, month=month)
        elif self.Frequency == 'yearly':
            return base_date.replace(year=base_date.year + 1)
        else:
            return base_date

    def should_execute(self):
        if not self.IsActive:
            return False
        today = datetime.now().date()
        if today < self.NextExecution:
            return False
        if self.EndDate and today > self.EndDate:
            return False
        return True

    def to_dict(self):
        return {
            'recurringId': self.RecurringId,
            'userId': self.UserId,
            'name': self.Name,
            'transactionType': self.TransactionType,
            'category': self.Category,
            'amount': float(self.Amount),
            'description': self.Description,
            'frequency': self.Frequency,
            'startDate': self.StartDate.isoformat() if self.StartDate else None,
            'endDate': self.EndDate.isoformat() if self.EndDate else None,
            'lastExecuted': self.LastExecuted.isoformat() if self.LastExecuted else None,
            'nextExecution': self.NextExecution.isoformat() if self.NextExecution else None,
            'isActive': self.IsActive,
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,
            'updatedAt': self.UpdatedAt.isoformat() if self.UpdatedAt else None
        }

    def __repr__(self):
        return f'<RecurringTransaction {self.Name} - {self.Frequency}>'
