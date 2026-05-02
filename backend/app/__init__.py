"""
Flask application factory
Initializes Flask app with blueprints and extensions
"""
from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy

# Global database object
db = SQLAlchemy()


def create_app(config_name='development'):
    """
    Application factory function
    Creates and configures Flask app with blueprints and SQLAlchemy
    
    Args:
        config_name: Configuration environment (development/testing/production)
    
    Returns:
        Flask application instance
    """
    from config.config import config_by_name
    
    app = Flask(__name__)
    app.config.from_object(config_by_name.get(config_name, 'development'))
    
    # Initialize SQLAlchemy database
    db.init_app(app)

    # Import models before creating tables so SQLAlchemy registers every table.
    from app import models  # noqa: F401
    
    # Initialize CORS
    CORS(app, origins=app.config['CORS_ORIGINS'])
    
    # Create database tables within app context
    with app.app_context():
        try:
            db.create_all()
            print("✅ Database tables initialized")
        except Exception as e:
            print(f"⚠️  Database initialization warning: {str(e)}")
    
    # Register blueprints (route modules)
    from app.routes.health import health_bp
    from app.routes.auth import auth_bp
    from app.routes.calculator import calculator_bp
    from app.routes.cases import cases_bp
    from app.routes.profile import profile_bp
    
    app.register_blueprint(health_bp, url_prefix='/api')
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(calculator_bp, url_prefix='/api/calculator')
    app.register_blueprint(cases_bp, url_prefix='/api/cases')
    app.register_blueprint(profile_bp, url_prefix='/api')
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return {'error': 'Resource not found'}, 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return {'error': 'Internal server error'}, 500
    
    return app


def get_db():
    """
    Get database instance
    
    Returns:
        SQLAlchemy database object
    """
    return db
