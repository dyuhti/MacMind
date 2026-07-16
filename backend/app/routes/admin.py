"""
Admin routes blueprint.
Provides admin-only management endpoints for dashboard, users, calculators, and feedback.
"""
from flask import Blueprint, jsonify

from app import db
from app.models.case import Case
from app.models.feedback import Feedback
from app.models.oxygen_calculation import OxygenCalculation
from app.models.user import User
from app.utils.decorators import admin_required


admin_bp = Blueprint('admin', __name__)


@admin_bp.route('/admin/dashboard', methods=['GET'])
@admin_required
def get_admin_dashboard(current_user):
    """Return aggregate metrics for admin dashboard."""
    try:
        users_count = User.query.count()
        admins_count = User.query.filter_by(role=User.ROLE_ADMIN).count()
        regular_users_count = User.query.filter_by(role=User.ROLE_USER).count()
        cases_count = Case.query.count()
        oxygen_calculations_count = OxygenCalculation.query.count()
        feedback_count = Feedback.query.count()

        return jsonify({
            'success': True,
            'dashboard': {
                'users_count': users_count,
                'admins_count': admins_count,
                'regular_users_count': regular_users_count,
                'cases_count': cases_count,
                'oxygen_calculations_count': oxygen_calculations_count,
                'feedback_count': feedback_count,
                'total_calculations_count': cases_count + oxygen_calculations_count,
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/users', methods=['GET'])
@admin_required
def get_admin_users(current_user):
    """List users for admin management."""
    try:
        users = User.query.order_by(User.created_at.desc()).all()
        return jsonify({
            'success': True,
            'users': [
                {
                    'id': user.id,
                    'name': user.full_name,
                    'email': user.email,
                    'role': user.role,
                    'created_at': user.created_at.isoformat() if user.created_at else None,
                }
                for user in users
            ],
            'count': len(users),
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/calculators', methods=['GET'])
@admin_required
def get_admin_calculators(current_user):
    """Return all calculator usage data for admin visibility."""
    try:
        cases = Case.query.order_by(Case.created_at.desc()).all()
        oxygen_calculations = OxygenCalculation.query.order_by(OxygenCalculation.created_at.desc()).all()

        return jsonify({
            'success': True,
            'cases': [case.to_dict() for case in cases],
            'oxygen_calculations': [calc.to_dict() for calc in oxygen_calculations],
            'case_count': len(cases),
            'oxygen_count': len(oxygen_calculations),
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/feedback', methods=['GET'])
@admin_required
def get_admin_feedback(current_user):
    """Return all feedback records for admin review."""
    try:
        feedbacks = Feedback.get_all()
        return jsonify({
            'success': True,
            'feedback': [item.to_dict() for item in feedbacks],
            'count': len(feedbacks),
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/users/<int:user_id>', methods=['DELETE'])
@admin_required
def delete_admin_user(user_id, current_user):
    """Delete a user account. Prevent deleting own admin account."""
    try:
        auth_user_id = int(current_user.get('user_id'))
        if auth_user_id == user_id:
            return jsonify({'success': False, 'message': 'You cannot delete your own admin account'}), 400

        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        db.session.delete(user)
        db.session.commit()
        return jsonify({'success': True, 'message': 'User deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
