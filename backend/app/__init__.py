from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_mail import Mail
from config import config

db = SQLAlchemy()
mail = Mail()

def create_app(config_name='development'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    # Initialize extensions
    db.init_app(app)
    CORS(app)
    mail.init_app(app)

    # Register blueprints
    from app.routes.auth import auth_bp
    from app.routes.transactions import transactions_bp
    from app.routes.budgets import budgets_bp
    from app.routes.investments import investments_bp
    from app.routes.gamification import gamification_bp
    from app.routes.reports import reports_bp
    from app.routes.settings import settings_bp
    from app.routes.goals import goals_bp
    from app.routes.two_factor_auth import two_factor_bp
    from app.routes.security import security_bp
    from app.routes.recurring_transactions import recurring_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(transactions_bp, url_prefix='/api/transactions')
    app.register_blueprint(budgets_bp, url_prefix='/api/budgets')
    app.register_blueprint(investments_bp, url_prefix='/api/investments')
    app.register_blueprint(gamification_bp, url_prefix='/api/gamification')
    app.register_blueprint(reports_bp, url_prefix='/api/reports')
    app.register_blueprint(settings_bp, url_prefix='/api/settings')
    app.register_blueprint(goals_bp, url_prefix='/api/goals')
    app.register_blueprint(two_factor_bp, url_prefix='/api/auth')
    app.register_blueprint(security_bp, url_prefix='/api/security')
    app.register_blueprint(recurring_bp, url_prefix='/api/recurring')

    return app
