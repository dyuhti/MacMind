"""
Authentication routes blueprint
Handles user registration, login, and token management
"""
from flask import Blueprint, request, jsonify
from app.models.user import User
from app.models.login_history import LoginHistory
from app.utils.security import create_token
from app.utils.decorators import require_json, validate_fields, require_token
from app.utils.email import send_otp_email
from app import db
from datetime import datetime
import re

# Create blueprint for auth routes
auth_bp = Blueprint('auth', __name__)


def _detect_platform(ua):
    ua_lower = ua.lower()
    if 'android' in ua_lower:
        return 'Android'
    if 'iphone' in ua_lower or 'ipad' in ua_lower:
        return 'iOS'
    if 'windows' in ua_lower:
        return 'Windows'
    if 'macintosh' in ua_lower or 'mac os' in ua_lower:
        return 'macOS'
    if 'linux' in ua_lower:
        return 'Linux'
    return None


def _detect_device(ua):
    ua_lower = ua.lower()
    if 'samsung' in ua_lower:
        return 'Samsung'
    if 'pixel' in ua_lower:
        return 'Pixel'
    if 'iphone' in ua_lower:
        return 'iPhone'
    if 'ipad' in ua_lower:
        return 'iPad'
    if 'macintosh' in ua_lower or 'mac os' in ua_lower:
        return 'Mac'
    if 'windows' in ua_lower:
        return 'Windows PC'
    if 'linux' in ua_lower:
        return 'Linux PC'
    return None


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

        requested_role = str(data.get('role', User.ROLE_USER)).strip().lower()
        if requested_role != User.ROLE_USER:
            return {
                'success': False,
                'message': 'Admin registration is not allowed from this endpoint'
            }, 403
        
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
            password=data['password'],
            role=User.ROLE_USER,
        )
        
        if not result['success']:
            return {'success': False, 'message': result['error']}, 400
        
        # Create JWT token for auto-login
        token = create_token(result['id'], result['email'], result.get('role', User.ROLE_USER))
        
        return {
            'success': True,
            'message': 'Registration successful',
            'user': {
                'id': result['id'],
                'email': result['email'],
                'full_name': result['full_name'],
                'role': result.get('role', User.ROLE_USER),
            },
            'token': token,
            'access_token': token,
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
            # Record failed login attempt
            try:
                login_data = request.get_json(silent=True) or {}
                ua = request.headers.get('User-Agent', '')
                failed_record = LoginHistory(
                    user_id=0,
                    status='failed',
                    platform=login_data.get('platform') or _detect_platform(ua),
                    device=login_data.get('device') or _detect_device(ua),
                    browser=login_data.get('browser') or ua[:100] if ua else None,
                )
                user = User.find_by_email(data['email'])
                if user:
                    failed_record.user_id = user.id
                db.session.add(failed_record)
                db.session.commit()
            except Exception:
                db.session.rollback()
            return {'success': False, 'message': result['error']}, 401
        
        # Create JWT token
        token = create_token(result['id'], result['email'], result.get('role', User.ROLE_USER))

        name = result['full_name']
        role = result.get('role', User.ROLE_USER)

        # Record login history
        try:
            login_data = request.get_json(silent=True) or {}
            ua = request.headers.get('User-Agent', '')
            login_record = LoginHistory(
                user_id=result['id'],
                status='success',
                platform=login_data.get('platform') or _detect_platform(ua),
                device=login_data.get('device') or _detect_device(ua),
                browser=login_data.get('browser') or ua[:100] if ua else None,
            )
            db.session.add(login_record)
            db.session.commit()
        except Exception:
            db.session.rollback()
        
        return {
            'success': True,
            'message': 'Login successful',
            'id': result['id'],
            'name': name,
            'email': result['email'],
            'role': role,
            'access_token': token,
            'user': {
                'id': result['id'],
                'email': result['email'],
                'full_name': name,
                'role': role,
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
            return {'success': False, 'message': 'User not found'}, 401
        
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
        email_result = send_otp_email(email, user.full_name, otp)
        
        if not email_result.get('success'):
            return {
                'success': False,
                'message': email_result.get('error', 'Failed to send OTP email. Please try again.')
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


@auth_bp.route('/delete-account', methods=['OPTIONS'])
def delete_account_options():
    """Handle CORS preflight for account deletion requests."""
    response = jsonify({'success': True, 'message': 'Preflight ok'})
    response.status_code = 200
    response.headers['Allow'] = 'DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Origin'] = request.headers.get('Origin', '*')
    response.headers['Access-Control-Allow-Methods'] = 'DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response


@auth_bp.route('/delete-account', methods=['DELETE'])
@require_json
def delete_account():
    """Delete a user account after confirming the email and password."""
    try:
        data = request.get_json(silent=True) or {}
        email = str(data.get('email', '')).strip().lower()
        password = data.get('password', '')
        confirm_password = data.get('confirm_password', '')

        if not email:
            return {'success': False, 'message': 'Email is required'}, 400

        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, email):
            return {'success': False, 'message': 'Invalid email format'}, 400

        if not password:
            return {'success': False, 'message': 'Password is required'}, 400

        if not confirm_password:
            return {'success': False, 'message': 'Confirm password is required'}, 400

        if password != confirm_password:
            return {'success': False, 'message': 'Passwords do not match'}, 400

        result = User.delete_account(email, password)
        if not result['success']:
            return {'success': False, 'message': result['error']}, 400

        return {
            'success': True,
            'message': 'Account deleted successfully'
        }, 200
    except Exception as e:
        return {
            'success': False,
            'message': f'Error deleting account: {str(e)}'
        }, 500


@auth_bp.route('/logout', methods=['POST'])
@require_token
def logout(current_user):
    try:
        user_id = current_user.get('id') or current_user.get('user_id')
        if user_id:
            active_session = LoginHistory.query.filter_by(
                user_id=user_id, logout_time=None, status='success'
            ).order_by(LoginHistory.login_time.desc()).first()
            if active_session:
                active_session.logout_time = datetime.utcnow()
                diff = active_session.logout_time - active_session.login_time
                active_session.session_duration = int(diff.total_seconds())
                db.session.commit()
        return {'success': True, 'message': 'Logged out successfully'}, 200
    except Exception as e:
        db.session.rollback()
        return {'success': False, 'message': str(e)}, 500


@auth_bp.route('/change_password', methods=['POST'])
@auth_bp.route('/change-password', methods=['POST'])
@require_json
@validate_fields(['current_password', 'new_password'])
@require_token
def change_password(current_user):
    """
    Change user's password when already logged in
    
    Request body:
        {
            "current_password": "oldpassword123",
            "new_password": "newpassword123"
        }
    
    Returns:
        200: Password changed successfully
        400: Invalid current password or weak new password
        401: Unauthorized
    """
    try:
        data = request.get_json()
        current_password = data['current_password']
        new_password = data['new_password']
        
        # Get user ID from JWT token payload.
        # Tokens are created with "user_id", while some flows may provide "id".
        user_id = current_user.get('id') or current_user.get('user_id')

        if not user_id:
            return {
                'success': False,
                'message': 'Unable to identify user'
            }, 401

        try:
            user_id = int(user_id)
        except (TypeError, ValueError):
            return {
                'success': False,
                'message': 'Invalid user identity in token'
            }, 401
        
        # Validate new password length
        if len(new_password) < 8:
            return {
                'success': False,
                'message': 'Password must be at least 8 characters'
            }, 400
        
        # Validate new password has uppercase
        if not re.search(r'[A-Z]', new_password):
            return {
                'success': False,
                'message': 'Password must contain at least one uppercase letter'
            }, 400
        
        # Validate new password has number
        if not re.search(r'[0-9]', new_password):
            return {
                'success': False,
                'message': 'Password must contain at least one number'
            }, 400
        
        # Change password
        result = User.change_password(user_id, current_password, new_password)
        
        if not result['success']:
            return {'success': False, 'message': result['error']}, 400
        
        return {
            'success': True,
            'message': 'Password updated successfully'
        }, 200
    
    except Exception as e:
        return {
            'success': False,
            'message': f'Error changing password: {str(e)}'
        }, 500

