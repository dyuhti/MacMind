"""
Profile routes blueprint.
Provides endpoints for fetching and updating user profile data from the users table only.
No separate profiles table is used - all data comes from the users table (full_name, email).
"""
from flask import Blueprint, jsonify, request

from app import db
from app.models.user import User
from app.utils.decorators import require_token


profile_bp = Blueprint('profile', __name__)


@profile_bp.route('/profile', methods=['GET'])
@require_token
def get_profile(current_user):
    """
    Get the profile for the authenticated user.
    Returns data from the users table only (full_name and email).
    
    Headers:
        Authorization: Bearer <token>
    
    Returns:
        200: User profile data {name, email}
        401: Unauthorized
        500: Server error
    """
    try:
        user_id = int(current_user['user_id'])  # Token uses 'user_id', not 'id'
        user = User.find_by_id(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Return only data from users table
        return jsonify({
            'name': user.full_name,
            'email': user.email
        }), 200
    except Exception as e:
        print('ERROR:', str(e))
        return jsonify({'error': str(e)}), 500


@profile_bp.route('/profile', methods=['PUT'])
@require_token
def update_profile(current_user):
    """
    Update the profile for the authenticated user.
    Only updates users table fields (full_name and email).
    Other fields (role, hospital) are accepted but ignored.
    
    Headers:
        Authorization: Bearer <token>
    
    Request body:
        {
            "name": "Dr. John Doe",
            "email": "john@example.com",
            "role": "Cardiologist",           (ignored)
            "hospital": "City Hospital"       (ignored)
        }
    
    Returns:
        200: Profile updated successfully
        401: Unauthorized
        400: Invalid input
        500: Server error
    """
    try:
        user_id = int(current_user['user_id'])  # Token uses 'user_id', not 'id'
        user = User.find_by_id(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        data = request.json or {}
        
        # Update only users table fields
        # role and hospital are accepted but ignored (stored in UI only, not persisted)
        if data.get('name'):
            user.full_name = data.get('name')
        if data.get('email'):
            user.email = data.get('email')
        
        db.session.commit()

        return jsonify({
            'message': 'Profile updated successfully',
            'profile': {
                'name': user.full_name,
                'email': user.email
            }
        }), 200
    except Exception as e:
        db.session.rollback()
        print('ERROR:', str(e))
        return jsonify({'error': str(e)}), 500

