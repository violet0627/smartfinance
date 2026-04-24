from app import db
from datetime import datetime


class Budget(db.Model):
    __tablename__ = 'Budgets'

    BudgetId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    MonthYear = db.Column(db.String(7), nullable=False)   # Format: "YYYY-MM"
    BudgetPeriod = db.Column(db.String(50), nullable=False)
    TotalBudget = db.Column(db.Numeric(10, 2), nullable=False)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    UpdatedAt = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)

    categories = db.relationship('BudgetCategory', backref='budget', lazy=True, cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'budgetId': self.BudgetId,
            'monthYear': self.MonthYear,
            'budgetPeriod': self.BudgetPeriod,
            'totalBudget': float(self.TotalBudget),
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,
            'updatedAt': self.UpdatedAt.isoformat() if self.UpdatedAt else None,
            'userId': self.UserId,
            'categories': [cat.to_dict() for cat in self.categories]
        }


class BudgetCategory(db.Model):
    __tablename__ = 'BudgetCategories'

    BudgetCategoryId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    CategoryName = db.Column(db.String(100), nullable=False)
    AllocatedAmount = db.Column(db.Numeric(10, 2), nullable=False)
    # SpentAmount is a denormalised cache updated on each transaction write to avoid
    # aggregation queries every time the Budget Overview screen loads
    SpentAmount = db.Column(db.Numeric(10, 2), default=0.00)
    BudgetId = db.Column(db.Integer, db.ForeignKey('Budgets.BudgetId'), nullable=False)

    def to_dict(self):
        return {
            'budgetCategoryId': self.BudgetCategoryId,
            'categoryName': self.CategoryName,
            'allocatedAmount': float(self.AllocatedAmount),
            'spentAmount': float(self.SpentAmount),
            'budgetId': self.BudgetId
        }
