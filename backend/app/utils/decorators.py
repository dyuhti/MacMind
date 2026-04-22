"""
Custom decorators for route protection and request validation
Provides authentication middleware and input validation
"""
from functools import wraps
from flask import request, jsonify
from app.utils.security import verify_token


def require_token(f):
    """
    Decorator to require JWT token for protected routes
    Extracts and validates token from Authorization header
    
    Usage:
        @app.route('/protected')
        @require_token
        def protected_route(current_user):
            return {'user': current_user}
    
    Returns:
        401 if token is missing or invalid
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = None
        
        # Check for token in Authorization header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(' ')[1]
            except IndexError:
                return {'success': False, 'message': 'Invalid Authorization header format'}, 401
        
        if not token:
            return {'success': False, 'message': 'Token is missing'}, 401
        
        # Verify token
        result = verify_token(token)
        if not result['success']:
            return {'success': False, 'message': result['error']}, 401
        
        # Pass user data to route handler
        kwargs['current_user'] = result['payload']
        return f(*args, **kwargs)
    
    return decorated_function


def require_json(f):
    """
    Decorator to require JSON content type
    Validates that request is JSON format
    
    Usage:
        @app.route('/api/data', methods=['POST'])
        @require_json
        def create_data():
            data = request.get_json()
            return {'success': True}
    
    Returns:
        400 if content is not JSON
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not request.is_json:
            return {'success': False, 'message': 'Request must be JSON'}, 400
        return f(*args, **kwargs)
    
    return decorated_function


def validate_fields(required_fields):
    """
    Decorator to validate required fields in request
    
    Usage:
        @app.route('/api/user', methods=['POST'])
        @validate_fields(['email', 'password'])
        def create_user():
            data = request.get_json()
            return {'success': True}
    
    Args:
        required_fields: List of required field names
    
    Returns:
        400 if any required field is missing
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            data = request.get_json()
            
            if not data:
                return {'success': False, 'message': 'Request body is empty'}, 400
            
            missing_fields = [field for field in required_fields if field not in data]
            
            if missing_fields:
                return {
                    'success': False,
                    'message': f'Missing required fields: {", ".join(missing_fields)}'
                }, 400
            
            return f(*args, **kwargs)
        
        return decorated_function
    return decorator
