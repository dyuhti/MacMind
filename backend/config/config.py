"""
Configuration module for Flask application
Handles database connection, environment variables, and app settings
"""
import os
from datetime import timedelta


def _normalize_database_url(url: str) -> str:
    """Normalize DB URL for SQLAlchemy across providers and drivers."""
    if not isinstance(url, str):
        return url

    # Legacy scheme used by some providers
    if url.startswith('postgres://'):
        url = url.replace('postgres://', 'postgresql://', 1)

    # Use psycopg v3 explicitly when no driver is specified
    if url.startswith('postgresql://') and not url.startswith('postgresql+'): 
        url = url.replace('postgresql://', 'postgresql+psycopg://', 1)

    return url

class Config:
    """Base configuration class with common settings"""
    
    # Flask settings
    DEBUG = False
    TESTING = False
    
    # Database (supports DATABASE_URL environment variable)
    # Prefer DATABASE_URL (e.g., from Render). Accept both postgres:// and postgresql://
    db_url = os.getenv(
        'DATABASE_URL',
        'sqlite:///med_calci_app.db'
    )
    db_url = _normalize_database_url(db_url)
    SQLALCHEMY_DATABASE_URI = db_url
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = False
    
    # JWT/Session settings
    SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key-change-this-in-production')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your-jwt-secret-key-change-this')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=30)
    
    # CORS settings
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')
    
    # Email settings
    EMAIL_USER = os.getenv('EMAIL_USER', '')
    EMAIL_PASS = os.getenv('EMAIL_PASS', '')
    
    # API settings
    JSON_SORT_KEYS = False
    JSONIFY_PRETTYPRINT_REGULAR = True


class DevelopmentConfig(Config):
    """Development environment configuration"""
    DEBUG = True
    TESTING = False
    SQLALCHEMY_ECHO = True


class TestingConfig(Config):
    """Testing environment configuration"""
    DEBUG = True
    TESTING = True
    # Allow testing DB override and normalize postgres scheme if needed
    db_url_test = os.getenv(
        'DATABASE_URL_TEST',
        'sqlite:///med_calci_app_test.db'
    )
    db_url_test = _normalize_database_url(db_url_test)
    SQLALCHEMY_DATABASE_URI = db_url_test


class ProductionConfig(Config):
    """Production environment configuration"""
    DEBUG = False
    TESTING = False


# Dictionary to select config based on environment
config_by_name = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}
