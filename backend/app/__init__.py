from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_mail import Mail
from config import config

# Created outside create_app so other modules (models, routes) can import them directly
db = SQLAlchemy()
mail = Mail()


def create_app(config_name='development'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    db.init_app(app)
    CORS(app)
    mail.init_app(app)

    # Blueprints imported here to avoid circular imports (route files import db from this module)
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
    from app.routes.financial_insights import insights_bp

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
    app.register_blueprint(insights_bp, url_prefix='/api/insights')

    with app.app_context():
        # All models must be imported before create_all() so SQLAlchemy registers their tables.
        # noqa: F401 — imported for the SQLAlchemy model registry side-effect only.
        from app.models import (  # noqa: F401
            user, user_settings, transaction, budget, investment, goal,
            achievement, password_reset, two_factor_auth, email_verification,
            session, security_log, recurring_transaction,
        )
        db.create_all()

    return app
