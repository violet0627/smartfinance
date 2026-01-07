from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from config import config

db = SQLAlchemy()

def create_app(config_name='development'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    # Initialize extensions
    db.init_app(app)
    CORS(app)

    # Register blueprints
    from app.routes.auth import auth_bp
    from app.routes.transactions import transactions_bp
    from app.routes.budgets import budgets_bp
    from app.routes.investments import investments_bp
    from app.routes.gamification import gamification_bp
    from app.routes.reports import reports_bp
    from app.routes.settings import settings_bp
    from app.routes.goals import goals_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(transactions_bp, url_prefix='/api/transactions')
    app.register_blueprint(budgets_bp, url_prefix='/api/budgets')
    app.register_blueprint(investments_bp, url_prefix='/api/investments')
    app.register_blueprint(gamification_bp, url_prefix='/api/gamification')
    app.register_blueprint(reports_bp, url_prefix='/api/reports')
    app.register_blueprint(settings_bp, url_prefix='/api/settings')
    app.register_blueprint(goals_bp, url_prefix='/api/goals')

    return app
