from app import db
from datetime import datetime

class Investment(db.Model):
    __tablename__ = 'Investments'

    InvestmentId = db.Column(db.Integer, primary_key=True, autoincrement=True)
    AssetName = db.Column(db.String(255), nullable=False)
    AssetsType = db.Column(db.String(100), nullable=False)
    StockSymbol = db.Column(db.String(20))
    Quantity = db.Column(db.Numeric(15, 4), nullable=False)
    PurchasePrice = db.Column(db.Numeric(10, 2), nullable=False)
    PurchaseDate = db.Column(db.Date, nullable=False)
    CurrentPrice = db.Column(db.Numeric(10, 2))
    LastUpdated = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    Notes = db.Column(db.Text)
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)

    def to_dict(self):
        """Convert investment object to dictionary"""
        return {
            'investmentId': self.InvestmentId,
            'assetName': self.AssetName,
            'assetsType': self.AssetsType,
            'stockSymbol': self.StockSymbol,
            'quantity': float(self.Quantity),
            'purchasePrice': float(self.PurchasePrice),
            'purchaseDate': self.PurchaseDate.isoformat() if self.PurchaseDate else None,
            'currentPrice': float(self.CurrentPrice) if self.CurrentPrice else None,
            'lastUpdated': self.LastUpdated.isoformat() if self.LastUpdated else None,
            'notes': self.Notes,
            'userId': self.UserId
        }
