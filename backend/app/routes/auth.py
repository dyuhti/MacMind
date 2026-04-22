"""
Authentication routes blueprint
Handles user registration, login, and token management
"""
from flask import Blueprint, request, jsonify
from app.models.user import User
from app.utils.security import create_token
from app.utils.decorators import require_json, validate_fields, require_token
from app.utils.email import send_otp_email
import re

# Create blueprint for auth routes
auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['POST'])
@require_json
@validate_fields(['full_name', 'email', 'password', 'confirm_password'])
def register():
    """
    User registration endpoint
    
    Request body:
        {
            "full_name": "John Doe",
            "email": "user@example.com",
            "password": "securepassword",
            "confirm_password": "securepassword"
        }
    
    Returns:
        201: User created successfully
        400: Invalid input or user already exists
    """
    try:
        data = request.get_json()
        
        # Validate email format
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, data['email']):
            return {'success': False, 'message': 'Invalid email format'}, 400
        
        # Validate full_name
        if len(data['full_name'].strip()) < 2:
            return {'success': False, 'message': 'Full name must be at least 2 characters'}, 400
        
        # Validate password length
        if len(data['password']) < 6:
            return {'success': False, 'message': 'Password must be at least 6 characters'}, 400
        
        # Validate passwords match
        if data['password'] != data['confirm_password']:
            return {'success': False, 'message': 'Passwords do not match'}, 400
        
        # Create user
        result = User.create(
            full_name=data['full_name'],
            email=data['email'],
            password=data['password']
        )
        
        if not result['success']:
            return {'success': False, 'message': result['error']}, 400
        
        # Create JWT token for auto-login
        token = create_token(result['id'], result['email'])
        
        return {
            'success': True,
            'message': 'Registration successful',
            'user': {
                'id': result['id'],
                'email': result['email'],
                'full_name': result['full_name']
            },
            'token': token
        }, 201
    
    except Exception as e:
        return {'success': False, 'message': f'Registration error: {str(e)}'}, 500


@auth_bp.route('/login', methods=['POST'])
@require_json
@validate_fields(['email', 'password'])
def login():
    """
    User login endpoint
    
    Request body:
        {
            "email": "user@example.com",
            "password": "securepassword"
        }
    
    Returns:
        200: Login successful with JWT token
        401: Invalid credentials
    """
    try:
        data = request.get_json()
        
        # Verify password
        result = User.verify_password(data['email'], data['password'])
        
        if not result['success']:
            return {'success': False, 'message': result['error']}, 401
        
        # Create JWT token
        token = create_token(result['id'], result['email'])
        
        return {
            'success': True,
            'message': 'Login successful',
            'user': {
                'id': result['id'],
                'email': result['email'],
                'full_name': result['full_name']
            },
            'token': token
        }, 200
    
    except Exception as e:
        return {'success': False, 'message': f'Login error: {str(e)}'}, 500


@auth_bp.route('/verify-token', methods=['POST'])
@require_token
def verify_token(current_user):
    """
    Verify JWT token validity
    
    Headers:
        Authorization: Bearer <token>
    
    Returns:
        200: Token is valid
        401: Token is invalid
    """
    return {
        'success': True,
        'message': 'Token is valid',
        'user': current_user
    }, 200


@auth_bp.route('/profile', methods=['GET'])
@require_token
def get_profile(current_user):
    """
    Get current user profile
    
    Headers:
        Authorization: Bearer <token>
    
    Returns:
        200: User profile data
    """
    try:
        user = User.find_by_email(current_user['email'])
        
        if not user:
            return {'success': False, 'message': 'User not found'}, 404
        
        return {
            'success': True,
            'message': 'Profile retrieved successfully',
            'user': user.to_dict()
        }, 200
    
    except Exception as e:
        return {'success': False, 'message': f'Error retrieving profile: {str(e)}'}, 500


@auth_bp.route('/send-otp', methods=['POST'])
@require_json
@validate_fields(['email'])
def send_otp():
    """
    Send OTP via email for password reset
    
    Request body:
        {
            "email": "user@example.com"
        }
    
    Returns:
        200: OTP sent successfully
        400: Invalid email or user not found
    """
    try:
        data = request.get_json()
        email = data['email'].strip().lower()
        
        # Verify email format
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, email):
            return {'success': False, 'message': 'Invalid email format'}, 400
        
        # Check if user exists
        user = User.find_by_email(email)
        if not user:
            return {'success': False, 'message': 'User not found'}, 404
        
        # Generate and store OTP
        otp_result = User.store_otp(email)
        if not otp_result['success']:
            return {'success': False, 'message': otp_result['error']}, 500
        
        otp = otp_result['otp']
        
        # Send OTP via email
        email_sent = send_otp_email(email, user.full_name, otp)
        
        if not email_sent:
            return {
                'success': False,
                'message': 'Failed to send OTP email. Please try again.'
            }, 500
        
        return {
            'success': True,
            'message': 'OTP sent successfully to your email',
            'email': email
        }, 200
    
    except Exception as e:
        return {
            'success': False,
            'message': f'Error sending OTP: {str(e)}'
        }, 500


@auth_bp.route('/reset-password', methods=['POST'])
@require_json
@validate_fields(['email', 'otp', 'new_password'])
def reset_password():
    """
    Reset user password after OTP verification
    
    Request body:
        {
            "email": "user@example.com",
            "otp": "123456",
            "new_password": "newpassword123"
        }
    
    Returns:
        200: Password reset successfully
        400: Invalid OTP or validation error
    """
    try:
        data = request.get_json()
        email = data['email'].strip().lower()
        otp = data['otp'].strip()
        new_password = data['new_password']
        
        # Validate email format
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, email):
            return {'success': False, 'message': 'Invalid email format'}, 400
        
        # Validate password length
        if len(new_password) < 6:
            return {
                'success': False,
                'message': 'Password must be at least 6 characters'
            }, 400
        
        # Verify OTP
        otp_verify = User.verify_otp(email, otp)
        if not otp_verify['success']:
            return {'success': False, 'message': otp_verify['error']}, 400
        
        # Reset password
        reset_result = User.reset_password(email, new_password)
        if not reset_result['success']:
            return {'success': False, 'message': reset_result['error']}, 500
        
        return {
            'success': True,
            'message': 'Password reset successfully. Please login with your new password.'
        }, 200
    
    except Exception as e:
        return {
            'success': False,
            'message': f'Error resetting password: {str(e)}'
        }, 500

