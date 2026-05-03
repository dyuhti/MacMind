"""
Configuration module for Flask application
Handles database connection, environment variables, and app settings
"""
import os
from datetime import timedelta

class Config:
    """Base configuration class with common settings"""
    
    # Flask settings
    DEBUG = False
    TESTING = False
    
    # Database (supports DATABASE_URL environment variable)
    # Prefer DATABASE_URL (e.g., from Render). Accept both postgres:// and postgresql://
    db_url = os.getenv(
        'DATABASE_URL',
        'mysql+pymysql://root:root123@localhost:3306/med_calci_app'
    )
    # Some providers (Heroku) use the scheme 'postgres://', which SQLAlchemy
    # does not accept in recent versions; normalize to 'postgresql://'
    if isinstance(db_url, str) and db_url.startswith('postgres://'):
        db_url = db_url.replace('postgres://', 'postgresql://', 1)
    SQLALCHEMY_DATABASE_URI = db_url
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = False
    
    # MySQL direct connection (for calculator.py)
    MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
    MYSQL_USER = os.getenv('MYSQL_USER', 'root')
    MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', 'root123')
    MYSQL_DB = os.getenv('MYSQL_DB', 'med_calci_app')
    
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
        'mysql+pymysql://root:password@localhost:3306/macmind_test'
    )
    if isinstance(db_url_test, str) and db_url_test.startswith('postgres://'):
        db_url_test = db_url_test.replace('postgres://', 'postgresql://', 1)
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
