# ==============================================================================
# investment.py - Investment Model (Database Table Definition)
# ==============================================================================
# This file defines the 'Investments' table in the MySQL database.
# An investment represents an asset the user has purchased (stocks, crypto, etc.).
#
# Each investment tracks:
# - What was bought (asset name, type, symbol)
# - How much was bought (quantity, purchase price)
# - Current value (current price, for calculating profit/loss)
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance
from datetime import datetime   # For timestamps


class Investment(db.Model):
    """
    Investment Model - Represents a single investment/asset in the user's portfolio.

    Maps to the 'Investments' table in MySQL.
    Each row = one investment (e.g., "100 shares of AAPL bought at RM150 each").
    """

    __tablename__ = 'Investments'  # The exact table name in MySQL

    # --- Column Definitions ---
    InvestmentId = db.Column(db.Integer, primary_key=True, autoincrement=True)  # Unique ID (auto-generated)
    AssetName = db.Column(db.String(255), nullable=False)                        # Name of the asset (e.g., "Apple Inc.", "Bitcoin")
    AssetsType = db.Column(db.String(100), nullable=False)                       # Type of asset (e.g., "Stocks", "Crypto", "Bonds")
    StockSymbol = db.Column(db.String(20))                                       # Optional ticker symbol (e.g., "AAPL", "BTC")
    Quantity = db.Column(db.Numeric(15, 4), nullable=False)                      # How many units owned (e.g., 100 shares, 0.5 BTC)
                                                                                  # Numeric(15,4) allows up to 4 decimal places for crypto
    PurchasePrice = db.Column(db.Numeric(10, 2), nullable=False)                 # Price per unit when bought (e.g., RM150.00)
    PurchaseDate = db.Column(db.Date, nullable=False)                            # When the investment was purchased
    CurrentPrice = db.Column(db.Numeric(10, 2))                                  # Current price per unit (updated manually or via API)
    LastUpdated = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)  # When current price was last updated
    Notes = db.Column(db.Text)                                                   # Optional notes about this investment
    UserId = db.Column(db.Integer, db.ForeignKey('Users.UserId'), nullable=False)  # Which user owns this investment

    def to_dict(self):
        """
        Convert Investment to dictionary for JSON API responses.

        The Flutter app uses this data to display the portfolio overview
        and calculate total value, profit/loss, etc.
        """
        return {
            'investmentId': self.InvestmentId,                                                  # Investment's unique ID
            'assetName': self.AssetName,                                                        # Asset name (e.g., "Apple Inc.")
            'assetsType': self.AssetsType,                                                      # Asset type (e.g., "Stocks")
            'stockSymbol': self.StockSymbol,                                                    # Ticker symbol (e.g., "AAPL")
            'quantity': float(self.Quantity),                                                    # Number of units as float
            'purchasePrice': float(self.PurchasePrice),                                         # Buy price as float
            'purchaseDate': self.PurchaseDate.isoformat() if self.PurchaseDate else None,       # Purchase date string
            'currentPrice': float(self.CurrentPrice) if self.CurrentPrice else None,            # Current price (may be None if not updated)
            'lastUpdated': self.LastUpdated.isoformat() if self.LastUpdated else None,          # Last price update timestamp
            'notes': self.Notes,                                                                # Optional notes
            'userId': self.UserId                                                               # Owner's user ID
        }
