"""
Flask application factory
Initializes Flask app with blueprints and extensions
"""
from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text

# Global database object
db = SQLAlchemy()


def _ensure_user_role_column():
    """Add users.role column for existing databases that predate admin roles."""
    inspector = db.inspect(db.engine)
    tables = inspector.get_table_names()
    if 'users' not in tables:
        return

    columns = {col['name'] for col in inspector.get_columns('users')}
    if 'role' in columns:
        return

    db.session.execute(text("ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'user'"))
    db.session.commit()
    print("[MIGRATION] Added missing users.role column with default 'user'")


def _ensure_password_changed_at_column():
    """Add users.password_changed_at column for existing databases."""
    inspector = db.inspect(db.engine)
    tables = inspector.get_table_names()
    if 'users' not in tables:
        return
    columns = {col['name'] for col in inspector.get_columns('users')}
    if 'password_changed_at' in columns:
        return
    db.session.execute(text("ALTER TABLE users ADD COLUMN password_changed_at TIMESTAMP"))
    db.session.commit()
    print("[MIGRATION] Added missing users.password_changed_at column")


def _ensure_is_active_column():
    """Add users.is_active column for existing databases that predate account deactivation."""
    inspector = db.inspect(db.engine)
    tables = inspector.get_table_names()
    if 'users' not in tables:
        return

    columns = {col['name'] for col in inspector.get_columns('users')}
    if 'is_active' in columns:
        return

    db.session.execute(text("ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE"))
    db.session.commit()
    print("[MIGRATION] Added missing users.is_active column with default TRUE")


def _ensure_feedback_columns():
    """Add status and admin_reply columns to feedback table if missing."""
    inspector = db.inspect(db.engine)
    tables = inspector.get_table_names()
    if 'feedback' not in tables:
        return

    columns = {col['name'] for col in inspector.get_columns('feedback')}
    if 'status' not in columns:
        db.session.execute(text("ALTER TABLE feedback ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending'"))
    if 'admin_reply' not in columns:
        db.session.execute(text("ALTER TABLE feedback ADD COLUMN admin_reply TEXT"))
    db.session.commit()
    print("[MIGRATION] Ensured feedback.status and feedback.admin_reply columns")


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
            _ensure_user_role_column()
            _ensure_is_active_column()
            _ensure_password_changed_at_column()
            print("[INIT] Database tables initialized")
        except Exception as e:
            db.session.rollback()
            print(f"[WARN] Database initialization warning: {str(e)}")
    
    # Run additional migrations
    with app.app_context():
        try:
            _ensure_feedback_columns()
        except Exception as e:
            print(f"[WARN] Feedback migration warning: {str(e)}")

    # Register blueprints (route modules)
    from app.routes.health import health_bp
    from app.routes.auth import auth_bp
    from app.routes.calculator import calculator_bp
    from app.routes.cases import cases_bp
    from app.routes.ai import ai_bp
    from app.routes.profile import profile_bp
    from app.routes.feedback import feedback_bp
    from app.routes.oxygen import oxygen_bp
    from app.routes.admin import admin_bp
    from app.routes.admin_user_dashboard import admin_user_bp
    
    app.register_blueprint(health_bp, url_prefix='/api')
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(calculator_bp, url_prefix='/api/calculator')
    app.register_blueprint(cases_bp, url_prefix='/api/cases')
    app.register_blueprint(ai_bp, url_prefix='/api/ai')
    app.register_blueprint(profile_bp, url_prefix='/api')
    app.register_blueprint(feedback_bp, url_prefix='/api')
    app.register_blueprint(oxygen_bp, url_prefix='/api/oxygen')
    app.register_blueprint(admin_bp, url_prefix='/api')
    app.register_blueprint(admin_user_bp, url_prefix='/api')
    
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
