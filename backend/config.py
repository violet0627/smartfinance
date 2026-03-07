# ==============================================================================
# config.py - Configuration Settings for the SmartFinance Backend
# ==============================================================================
# This file defines all the settings the app needs to run, such as:
# - Database connection details (MySQL host, port, username, password)
# - Email server settings (for sending verification emails)
# - Secret keys (for encrypting JWT tokens)
#
# It reads sensitive values from a '.env' file so they aren't hardcoded in code.
# ==============================================================================

import os                          # 'os' module lets us read environment variables
from dotenv import load_dotenv     # 'load_dotenv' reads the .env file and loads values into environment
from urllib.parse import quote_plus  # 'quote_plus' URL-encodes special characters (e.g., @ becomes %40)

# Load the .env file from the current directory.
# The .env file contains sensitive data like passwords that shouldn't be in code.
# Example .env file:
#   DB_PASSWORD=siow@@2468
#   SECRET_KEY=my-secret-key
load_dotenv()


class Config:
    """Base configuration - shared settings used by all environments (dev, production)."""

    # SECRET_KEY is used by Flask to sign session cookies and JWT tokens.
    # It should be a long random string in production for security.
    # os.getenv() reads from environment variables; the second argument is the default/fallback value.
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-this')

    # When set to False, this disables a Flask-SQLAlchemy feature that tracks
    # every change to database objects. We don't need it and it uses extra memory.
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # --- Database Configuration ---
    # These read from the .env file. If not found, they use the default values.
    DB_HOST = os.getenv('DB_HOST', 'localhost')      # Where MySQL is running (usually 'localhost')
    DB_PORT = os.getenv('DB_PORT', '3306')            # MySQL default port is 3306
    DB_USER = os.getenv('DB_USER', 'root')            # MySQL username (default is 'root')
    DB_PASSWORD = os.getenv('DB_PASSWORD', '')         # MySQL password (from .env file)
    DB_NAME = os.getenv('DB_NAME', 'smartfinance')     # Name of the database to use

    # Build the full database connection URL that SQLAlchemy needs.
    # Format: mysql+pymysql://username:password@host:port/database_name
    # - 'mysql+pymysql' tells SQLAlchemy to use MySQL with the PyMySQL driver
    # - quote_plus(DB_PASSWORD) URL-encodes the password so special characters
    #   like '@@' don't break the URL (e.g., 'siow@@2468' becomes 'siow%40%402468')
    SQLALCHEMY_DATABASE_URI = f"mysql+pymysql://{DB_USER}:{quote_plus(DB_PASSWORD)}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

    # --- Flask-Mail Configuration (for sending emails) ---
    # These settings configure how the app sends emails (e.g., verification emails).
    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com')   # Gmail's SMTP server address
    MAIL_PORT = int(os.getenv('MAIL_PORT', 587))                # Port 587 is for TLS-encrypted email
    MAIL_USE_TLS = os.getenv('MAIL_USE_TLS', 'True') == 'True'  # TLS = encryption for email in transit
    MAIL_USE_SSL = os.getenv('MAIL_USE_SSL', 'False') == 'True'  # SSL = alternative encryption (not used here)
    MAIL_USERNAME = os.getenv('MAIL_USERNAME', '')               # Gmail address to send from
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD', '')               # Gmail app password (not regular password)
    MAIL_DEFAULT_SENDER = os.getenv('MAIL_DEFAULT_SENDER', 'noreply@smartfinance.com')  # "From" address


class DevelopmentConfig(Config):
    """Development configuration - used when coding and testing locally."""
    DEBUG = True               # Enables detailed error pages and auto-reload on code changes
    FLASK_ENV = 'development'  # Tells Flask we're in development mode


class ProductionConfig(Config):
    """Production configuration - used when the app is deployed for real users."""
    DEBUG = False              # Disables debug mode for security (don't show error details to users)
    FLASK_ENV = 'production'   # Tells Flask we're in production mode


# --- Configuration Dictionary ---
# This maps string names to config classes, so we can easily switch between them.
# In run.py, we call create_app('development') which looks up DevelopmentConfig here.
config = {
    'development': DevelopmentConfig,   # Used during local development
    'production': ProductionConfig,     # Used when deployed to a real server
    'default': DevelopmentConfig        # Fallback if no environment is specified
}
