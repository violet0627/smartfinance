# ==============================================================================
# user.py - User Model (Database Table Definition)
# ==============================================================================
# This file defines the 'Users' table in the MySQL database.
# It represents a registered user of the SmartFinance app.
#
# In SQLAlchemy (our ORM), each Python class = one database table.
# Each class attribute with db.Column = one column in that table.
#
# Key concepts:
# - ORM (Object-Relational Mapper): Lets us use Python objects instead of SQL
# - Model: A Python class that maps to a database table
# - Relationship: Links between tables (e.g., a User has many Transactions)
# ==============================================================================

from app import db              # Import the SQLAlchemy database instance from app/__init__.py
from datetime import datetime   # For timestamps (when user was created, last login, etc.)
import bcrypt                   # Library for securely hashing passwords (one-way encryption)


class User(db.Model):
    """
    User Model - Represents a registered user in the SmartFinance app.

    This maps to the 'Users' table in MySQL.
    Each row in the table = one User object in Python.
    """

    # Tell SQLAlchemy the exact table name in MySQL (case-sensitive).
    __tablename__ = 'Users'

    # --- Column Definitions ---
    # Each db.Column() defines a column in the 'Users' table.
    # Parameters:
    #   - db.Integer, db.String(255), etc. = the data type
    #   - primary_key=True = this column uniquely identifies each row
    #   - autoincrement=True = MySQL auto-generates the next number (1, 2, 3...)
    #   - unique=True = no two rows can have the same value
    #   - nullable=False = this column MUST have a value (cannot be NULL/empty)
    #   - default=... = value to use if none is provided

    UserId = db.Column(db.Integer, primary_key=True, autoincrement=True)     # Unique ID for each user (auto-generated: 1, 2, 3...)
    Email = db.Column(db.String(255), unique=True, nullable=False)           # User's email (must be unique, used for login)
    PasswordHash = db.Column(db.String(255), nullable=False)                 # Hashed password (NEVER store plain text passwords!)
    FullName = db.Column(db.String(255), nullable=False)                     # User's full name
    PhoneNumber = db.Column(db.String(20))                                   # Optional phone number
    EmailVerified = db.Column(db.Boolean, default=False)                     # Has user verified their email? (True/False)
    TwoFactorEnabled = db.Column(db.Boolean, default=False)                  # Is 2FA (two-factor authentication) enabled?
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)              # When the account was created (auto-set)
    LastLogin = db.Column(db.DateTime)                                       # When the user last logged in
    ExperiencePts = db.Column(db.Integer, default=0)                         # Gamification: XP points earned by the user
    CurrentLevel = db.Column(db.Integer, default=1)                          # Gamification: User's current level (starts at 1)

    # --- Relationships ---
    # These define how the User table connects to other tables.
    # 'db.relationship' creates a virtual link (not a real column) that lets us
    # access related data easily.
    #
    # Parameters:
    #   - 'Transaction' = the related model class name
    #   - backref='user' = creates a reverse link (transaction.user returns the User)
    #   - lazy=True = related data is loaded only when accessed (not immediately)
    #   - cascade='all, delete-orphan' = if a user is deleted, their transactions are also deleted

    transactions = db.relationship('Transaction', backref='user', lazy=True, cascade='all, delete-orphan')  # User's transactions
    budgets = db.relationship('Budget', backref='user', lazy=True, cascade='all, delete-orphan')            # User's budgets
    investments = db.relationship('Investment', backref='user', lazy=True, cascade='all, delete-orphan')    # User's investments

    def set_password(self, password):
        """
        Hash and store the user's password securely.

        How it works:
        1. password.encode('utf-8') converts the string to bytes (bcrypt needs bytes)
        2. bcrypt.gensalt() generates a random "salt" (random data added to prevent rainbow table attacks)
        3. bcrypt.hashpw() combines the password + salt and hashes it (one-way, cannot be reversed)
        4. .decode('utf-8') converts the result back to a string for storage in the database

        Example: "mypassword123" -> "$2b$12$LJ3m4ks..." (unreadable hash)
        """
        self.PasswordHash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    def check_password(self, password):
        """
        Check if the provided password matches the stored hash.

        How it works:
        1. Takes the plain text password the user typed
        2. Hashes it using the same salt that was used originally
        3. Compares it with the stored hash
        4. Returns True if they match, False otherwise

        This is used during login to verify the user's password.
        """
        return bcrypt.checkpw(password.encode('utf-8'), self.PasswordHash.encode('utf-8'))

    def to_dict(self):
        """
        Convert the User object to a Python dictionary (for JSON API responses).

        When the Flutter app requests user data, we can't send a Python object directly.
        We need to convert it to a dictionary, which Flask then converts to JSON.

        Note: PasswordHash is intentionally EXCLUDED for security!
        We never send the password hash to the client.

        The .isoformat() method converts datetime to a string like "2025-01-15T10:30:00"
        which is a standard format (ISO 8601) that Flutter can easily parse.
        """
        return {
            'userId': self.UserId,                                                         # User's unique ID
            'email': self.Email,                                                           # User's email
            'fullName': self.FullName,                                                     # User's name
            'phoneNumber': self.PhoneNumber,                                               # User's phone (may be None)
            'emailVerified': self.EmailVerified,                                           # Is email verified?
            'twoFactorEnabled': self.TwoFactorEnabled,                                     # Is 2FA enabled?
            'createdAt': self.CreatedAt.isoformat() if self.CreatedAt else None,           # Account creation date
            'lastLogin': self.LastLogin.isoformat() if self.LastLogin else None,           # Last login date
            'experiencePts': self.ExperiencePts,                                           # XP points
            'currentLevel': self.CurrentLevel                                              # Current level
        }
