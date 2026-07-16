"""
Custom decorators for route protection and request validation
Provides authentication middleware and input validation
"""
from functools import wraps
from flask import request, jsonify
from app.utils.security import verify_token


def _extract_bearer_token():
    """Extract Bearer token from Authorization header."""
    if 'Authorization' not in request.headers:
        return None, ({'success': False, 'message': 'Token is missing'}, 401)

    auth_header = request.headers['Authorization']
    parts = auth_header.split(' ')
    if len(parts) != 2 or parts[0].lower() != 'bearer' or not parts[1].strip():
        return None, ({'success': False, 'message': 'Invalid Authorization header format'}, 401)

    return parts[1].strip(), None


def _resolve_authenticated_user(payload):
    """Resolve user from token payload and merge trusted role from database."""
    from app.models.user import User

    user = None
    user_id = payload.get('user_id')
    email = payload.get('email')

    try:
        if user_id is not None:
            user = User.find_by_id(int(user_id))
    except (TypeError, ValueError):
        user = None

    if not user and email:
        user = User.find_by_email(email)

    if not user:
        return None, ({'success': False, 'message': 'User not found'}, 401)

    trusted_payload = dict(payload)
    trusted_payload['user_id'] = str(user.id)
    trusted_payload['email'] = user.email
    trusted_payload['role'] = user.role

    return trusted_payload, None


def login_required(f):
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
        token, token_error = _extract_bearer_token()
        if token_error:
            return token_error
        
        # Verify token
        result = verify_token(token)
        if not result['success']:
            return {'success': False, 'message': result['error']}, 401

        current_user, user_error = _resolve_authenticated_user(result['payload'])
        if user_error:
            return user_error
        
        # Pass user data to route handler
        kwargs['current_user'] = current_user
        return f(*args, **kwargs)

    return decorated_function


def admin_required(f):
    """Decorator requiring authenticated admin user."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token, token_error = _extract_bearer_token()
        if token_error:
            return token_error

        result = verify_token(token)
        if not result['success']:
            return {'success': False, 'message': result['error']}, 401

        current_user, user_error = _resolve_authenticated_user(result['payload'])
        if user_error:
            return user_error

        if current_user.get('role') != 'admin':
            return {'success': False, 'message': 'Admin access required'}, 403

        kwargs['current_user'] = current_user
        return f(*args, **kwargs)

    return decorated_function


def require_token(f):
    """Backward-compatible alias for login_required."""
    return login_required(f)


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
