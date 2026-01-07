from app import db
from datetime import datetime

class Transaction(db.Model):
    __tablename__ = 'Transactions'

    TransactionId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    Amount = db.Column(db.Numeric(10, 2), nullable=False)
    Category = db.Column(db.String(100), nullable=False)
    Description = db.Column(db.Text)
    TransactionDate = db.Column(db.Date, nullable=False)
    TransactionType = db.Column(db.Enum('income', 'expense'), nullable=False)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)

    def to_dict(self):
        """Convert transaction object to dictionary"""
        return {
            'transactionId': self.TransactionId,
            'amount': float(self.Amount),
            'category': self.Category,
            'description': self.Description,
            'transactionDate': self.TransactionDate.isoformat() if self.TransactionDate else None,
            'transactionType': self.TransactionType,
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,
            'userId': self.UserId
        }
