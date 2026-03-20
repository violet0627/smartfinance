# ==============================================================================
# app/__init__.py - Application Factory (Creates and Configures the Flask App)
# ==============================================================================
# This file is the heart of the backend. It:
# 1. Creates the Flask application instance
# 2. Initializes extensions (database, CORS, email)
# 3. Registers all API route blueprints (auth, transactions, budgets, etc.)
#
# The "factory pattern" means we use a function (create_app) to build the app,
# rather than creating it at the top level. This makes testing easier.
# ==============================================================================

from flask import Flask                  # Flask is the web framework that handles HTTP requests/responses
from flask_sqlalchemy import SQLAlchemy  # SQLAlchemy is the ORM (Object-Relational Mapper) for database access
from flask_cors import CORS              # CORS allows the Flutter app (different origin) to call our API
from flask_mail import Mail              # Flask-Mail handles sending emails (verification, password reset)
from config import config               # Import our configuration dictionary from config.py

# --- Create Extension Instances ---
# These are created here (outside the function) so other files can import them.
# For example, model files import 'db' to define database tables.
db = SQLAlchemy()  # Database ORM - lets us use Python classes instead of raw SQL queries
mail = Mail()      # Email handler - used to send verification and password reset emails


def create_app(config_name='development'):
    """
    Application Factory Function.
    Creates and configures a new Flask application instance.

    Parameters:
        config_name (str): Which configuration to use ('development' or 'production').
                          Defaults to 'development'.

    Returns:
        app: A fully configured Flask application ready to handle requests.
    """

    # Create a new Flask app instance.
    # __name__ tells Flask where to find templates and static files.
    app = Flask(__name__)

    # Load configuration settings from our config class (defined in config.py).
    # This sets up database URI, secret key, email settings, etc.
    app.config.from_object(config[config_name])

    # --- Initialize Extensions with the App ---
    # These extensions were created above but need to be "attached" to our specific app.

    db.init_app(app)    # Connect SQLAlchemy to this app (enables database operations)
    CORS(app)           # Enable CORS - allows requests from different origins (Flutter app)
                        # Without this, the browser/app would block API calls due to security policy.
    mail.init_app(app)  # Connect Flask-Mail to this app (enables sending emails)

    # --- Register Blueprints (API Route Groups) ---
    # Blueprints organize routes into logical groups. Each blueprint handles one feature.
    # We import them inside this function to avoid "circular import" errors
    # (because route files import 'db' from this file).

    from app.routes.auth import auth_bp                           # Authentication routes (login, register, etc.)
    from app.routes.transactions import transactions_bp           # Transaction routes (add, list, delete)
    from app.routes.budgets import budgets_bp                     # Budget routes (create, track spending)
    from app.routes.investments import investments_bp             # Investment routes (portfolio management)
    from app.routes.gamification import gamification_bp           # Gamification routes (XP, achievements)
    from app.routes.reports import reports_bp                     # Report routes (analytics, summaries)
    from app.routes.settings import settings_bp                   # Settings routes (user preferences)
    from app.routes.goals import goals_bp                         # Financial goals routes
    from app.routes.two_factor_auth import two_factor_bp          # Two-factor authentication routes
    from app.routes.security import security_bp                   # Security routes (sessions, activity logs)
    from app.routes.recurring_transactions import recurring_bp    # Recurring transactions routes

    # Register each blueprint with a URL prefix.
    # The url_prefix means all routes in that blueprint start with that path.
    # Example: auth_bp has a '/login' route -> full URL becomes '/api/auth/login'
    app.register_blueprint(auth_bp, url_prefix='/api/auth')                  # /api/auth/login, /api/auth/register, etc.
    app.register_blueprint(transactions_bp, url_prefix='/api/transactions')  # /api/transactions/add, /api/transactions/list, etc.
    app.register_blueprint(budgets_bp, url_prefix='/api/budgets')            # /api/budgets/create, /api/budgets/list, etc.
    app.register_blueprint(investments_bp, url_prefix='/api/investments')    # /api/investments/add, /api/investments/portfolio, etc.
    app.register_blueprint(gamification_bp, url_prefix='/api/gamification')  # /api/gamification/xp, /api/gamification/achievements, etc.
    app.register_blueprint(reports_bp, url_prefix='/api/reports')            # /api/reports/summary, /api/reports/monthly, etc.
    app.register_blueprint(settings_bp, url_prefix='/api/settings')          # /api/settings/update, /api/settings/get, etc.
    app.register_blueprint(goals_bp, url_prefix='/api/goals')                # /api/goals/create, /api/goals/list, etc.
    app.register_blueprint(two_factor_bp, url_prefix='/api/auth')            # /api/auth/2fa/setup, /api/auth/2fa/verify, etc.
    app.register_blueprint(security_bp, url_prefix='/api/security')          # /api/security/sessions, /api/security/logs, etc.
    app.register_blueprint(recurring_bp, url_prefix='/api/recurring')        # /api/recurring/create, /api/recurring/list, etc.

    # --- Create database tables if they don't exist yet ---
    # db.create_all() looks at all imported models and creates any tables that are
    # missing from the database. It is safe to call on every startup — it skips
    # tables that already exist, so it never destroys existing data.
    # This fixes the "Table 'smartfinance.usersettings' doesn't exist" crash.
    with app.app_context():
        # Import models here so SQLAlchemy knows about every table before create_all()
        from app.models import user, user_settings  # noqa: F401 — imported for side effects
        db.create_all()

    # Return the fully configured app, ready to handle incoming HTTP requests.
    return app
