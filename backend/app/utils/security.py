"""
Security utilities for password hashing and JWT token management
Ensures secure password storage and user authentication
"""
import bcrypt
import jwt
from datetime import datetime, timedelta
import os


def hash_password(password):
    """
    Hash a password using bcrypt
    
    Args:
        password: Plain text password
    
    Returns:
        Hashed password as string
    """
    salt = bcrypt.gensalt(rounds=12)
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')


def verify_password(password, hashed):
    """
    Verify a password against its hash
    
    Args:
        password: Plain text password to verify
        hashed: Hashed password to verify against
    
    Returns:
        True if password matches, False otherwise
    """
    try:
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    except:
        return False


def create_token(user_id, email, expires_in_days=30):
    """
    Create JWT token for user authentication
    
    Args:
        user_id: User's MongoDB ID
        email: User's email
        expires_in_days: Token expiration in days
    
    Returns:
        JWT token as string
    """
    secret_key = os.getenv('JWT_SECRET_KEY', 'your-jwt-secret-key-change-this')
    
    payload = {
        'user_id': str(user_id),
        'email': email,
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(days=expires_in_days)
    }
    
    token = jwt.encode(payload, secret_key, algorithm='HS256')
    return token


def verify_token(token):
    """
    Verify and decode JWT token
    
    Args:
        token: JWT token to verify
    
    Returns:
        Dictionary with token payload or error info
    """
    secret_key = os.getenv('JWT_SECRET_KEY', 'your-jwt-secret-key-change-this')
    
    try:
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        return {'success': True, 'payload': payload}
    except jwt.ExpiredSignatureError:
        return {'success': False, 'error': 'Token has expired'}
    except jwt.InvalidTokenError:
        return {'success': False, 'error': 'Invalid token'}
