"""
Feedback routes blueprint.
Provides endpoints for submitting and retrieving feedback.
"""
from flask import Blueprint, jsonify, request

from app import db
from app.models.feedback import Feedback
from app.models.user import User
from app.utils.decorators import require_token


feedback_bp = Blueprint('feedback', __name__)


@feedback_bp.route('/submit_feedback', methods=['POST'])
@require_token
def submit_feedback(current_user):
    """
    Submit feedback from the authenticated user.
    
    Headers:
        Authorization: Bearer <token>
    
    Request body:
        {
            "rating": 5,
            "category": "Bug Report",
            "feedback_message": "The app crashes when..."
        }
    
    Returns:
        200: Feedback submitted successfully
        400: Invalid input
        401: Unauthorized
        500: Server error
    """
    try:
        user_id = int(current_user['user_id'])
        user = User.find_by_id(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        data = request.json or {}
        
        # Validate required fields
        rating = data.get('rating')
        category = data.get('category')
        feedback_message = data.get('feedback_message')

        if rating is None:
            return jsonify({'error': 'Rating is required'}), 400
        
        if not category:
            return jsonify({'error': 'Category is required'}), 400
        
        if not feedback_message:
            return jsonify({'error': 'Feedback message is required'}), 400

        # Create feedback
        result = Feedback.create(
            user_id=user_id,
            user_name=user.full_name,
            user_email=user.email,
            rating=rating,
            category=category,
            feedback_message=feedback_message
        )

        if not result['success']:
            return jsonify({'error': result['error']}), 400

        return jsonify({
            'message': 'Thank you for your feedback!',
            'feedback': result['feedback']
        }), 200

    except ValueError:
        return jsonify({'error': 'Invalid rating value'}), 400
    except Exception as e:
        db.session.rollback()
        print('ERROR:', str(e))
        return jsonify({'error': str(e)}), 500


@feedback_bp.route('/feedback/<int:feedback_id>', methods=['GET'])
@require_token
def get_feedback(current_user, feedback_id):
    """
    Get a specific feedback entry.
    
    Headers:
        Authorization: Bearer <token>
    
    Args:
        feedback_id: Feedback ID
    
    Returns:
        200: Feedback data
        404: Feedback not found
        401: Unauthorized
        500: Server error
    """
    try:
        feedback = Feedback.find_by_id(feedback_id)

        if not feedback:
            return jsonify({'error': 'Feedback not found'}), 404

        return jsonify(feedback.to_dict()), 200

    except Exception as e:
        print('ERROR:', str(e))
        return jsonify({'error': str(e)}), 500


@feedback_bp.route('/feedback', methods=['GET'])
@require_token
def get_user_feedback(current_user):
    """
    Get all feedback submitted by the authenticated user.
    
    Headers:
        Authorization: Bearer <token>
    
    Returns:
        200: List of feedback entries
        401: Unauthorized
        500: Server error
    """
    try:
        user_id = int(current_user['user_id'])
        feedbacks = Feedback.find_by_user_id(user_id)

        return jsonify({
            'feedbacks': [f.to_dict() for f in feedbacks],
            'count': len(feedbacks)
        }), 200

    except Exception as e:
        print('ERROR:', str(e))
        return jsonify({'error': str(e)}), 500


@feedback_bp.route('/admin/feedback', methods=['GET'])
@require_token
def get_all_feedback(current_user):
    """
    Get all feedback entries (admin endpoint).
    
    Headers:
        Authorization: Bearer <token>
    
    Returns:
        200: List of all feedback entries
        401: Unauthorized
        500: Server error
    """
    try:
        feedbacks = Feedback.get_all()

        return jsonify({
            'feedbacks': [f.to_dict() for f in feedbacks],
            'count': len(feedbacks)
        }), 200

    except Exception as e:
        print('ERROR:', str(e))
        return jsonify({'error': str(e)}), 500
