"""
Admin routes blueprint.
Provides admin-only management endpoints for dashboard, users, entries,
analytics, and feedback. Every route is protected by @admin_required which
re-checks is_admin from the database — the Flutter UI check is purely cosmetic.

Admin actions (deactivate, delete, patch) are logged via Python's stdlib
logging module. No passwords or tokens are ever logged.
"""
import logging
from datetime import datetime, timedelta

from flask import Blueprint, jsonify, request
from sqlalchemy import func

from app import db
from app.models.case import Case
from app.models.feedback import Feedback
from app.models.oxygen_calculation import OxygenCalculation
from app.models.user import User
from app.models.audit_log import AuditLog
from app.utils.decorators import admin_required

admin_bp = Blueprint('admin', __name__)

# Module-level logger — emits to the app's existing logging config.
# Sensitive data (passwords, tokens) must never be passed to these calls.
_log = logging.getLogger('admin_actions')


# ---------------------------------------------------------------------------
# Helper utilities
# ---------------------------------------------------------------------------

def _paginate_query(query, page: int, per_page: int):
    """Return (items, total, pages) for a SQLAlchemy query."""
    per_page = max(1, min(per_page, 100))  # cap at 100 rows per page
    page = max(1, page)
    total = query.count()
    items = query.offset((page - 1) * per_page).limit(per_page).all()
    pages = max(1, (total + per_page - 1) // per_page)
    return items, total, pages


def _admin_id(current_user):
    """Extract admin user ID from the current_user dict."""
    return int(current_user.get('user_id') or current_user.get('id', 0))


def _log_action(current_user, action: str, detail: str = ''):
    """Log an admin action without sensitive data."""
    admin_email = current_user.get('email', 'unknown')
    _log.info('[ADMIN] %s performed %s. %s', admin_email, action, detail)


def _log_audit(current_user, target_user_id, action, old_value=None, new_value=None):
    log = AuditLog(
        target_user_id=target_user_id,
        admin_id=_admin_id(current_user),
        action=action,
        old_value=str(old_value) if old_value else None,
        new_value=str(new_value) if new_value else None,
    )
    db.session.add(log)
    db.session.commit()


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

@admin_bp.route('/admin/dashboard', methods=['GET'])
@admin_required
def get_admin_dashboard(current_user):
    """Return aggregate metrics for admin dashboard."""
    try:
        users_count = User.query.count()
        admins_count = User.query.filter_by(role=User.ROLE_ADMIN).count()
        regular_users_count = User.query.filter_by(role=User.ROLE_USER).count()
        active_users_count = User.query.filter(
            User.is_active.isnot(False)
        ).count()
        cases_count = Case.query.count()
        oxygen_calculations_count = OxygenCalculation.query.count()
        feedback_count = Feedback.query.count()

        return jsonify({
            'success': True,
            'dashboard': {
                'users_count': users_count,
                'admins_count': admins_count,
                'regular_users_count': regular_users_count,
                'active_users_count': active_users_count,
                'cases_count': cases_count,
                'oxygen_calculations_count': oxygen_calculations_count,
                'feedback_count': feedback_count,
                'total_calculations_count': cases_count + oxygen_calculations_count,
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Analytics
# ---------------------------------------------------------------------------

@admin_bp.route('/admin/analytics/summary', methods=['GET'])
@admin_required
def get_analytics_summary(current_user):
    """
    Return analytics summary:
      - total_users, active_users, total_cases, total_oxygen
      - entries_per_day: list of {date, cases, oxygen} for last `days` days
      - top_calculators: [{'name': ..., 'count': ...}]

    Query params:
      days (int, default 30) — how many days of history to include
    """
    try:
        days = int(request.args.get('days', 30))
        days = max(7, min(days, 90))

        since = datetime.utcnow() - timedelta(days=days)

        total_users = User.query.count()
        active_users = User.query.filter(User.is_active.isnot(False)).count()
        total_cases = Case.query.count()
        total_oxygen = OxygenCalculation.query.count()

        # --- entries per day ---
        case_daily = (
            db.session.query(
                func.date(Case.created_at).label('day'),
                func.count(Case.id).label('cnt'),
            )
            .filter(Case.created_at >= since)
            .group_by(func.date(Case.created_at))
            .all()
        )
        oxygen_daily = (
            db.session.query(
                func.date(OxygenCalculation.created_at).label('day'),
                func.count(OxygenCalculation.id).label('cnt'),
            )
            .filter(OxygenCalculation.created_at >= since)
            .group_by(func.date(OxygenCalculation.created_at))
            .all()
        )

        # Build a merged date → counts dict
        daily_map: dict = {}
        for row in case_daily:
            d = str(row.day)
            daily_map.setdefault(d, {'date': d, 'cases': 0, 'oxygen': 0})
            daily_map[d]['cases'] = row.cnt
        for row in oxygen_daily:
            d = str(row.day)
            daily_map.setdefault(d, {'date': d, 'cases': 0, 'oxygen': 0})
            daily_map[d]['oxygen'] = row.cnt

        entries_per_day = sorted(daily_map.values(), key=lambda x: x['date'])

        # --- top calculators ---
        # Treat volatile cases and oxygen separately as two "calculators"
        top_calculators = [
            {'name': 'Volatile Anesthetic', 'count': total_cases},
            {'name': 'Oxygen Cylinder', 'count': total_oxygen},
        ]
        top_calculators.sort(key=lambda x: x['count'], reverse=True)

        return jsonify({
            'success': True,
            'analytics': {
                'total_users': total_users,
                'active_users': active_users,
                'total_cases': total_cases,
                'total_oxygen': total_oxygen,
                'total_entries': total_cases + total_oxygen,
                'days': days,
                'entries_per_day': entries_per_day,
                'top_calculators': top_calculators,
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Users — list, detail, patch, delete
# ---------------------------------------------------------------------------

@admin_bp.route('/admin/users', methods=['GET'])
@admin_required
def get_admin_users(current_user):
    """
    Paginated, searchable list of users.

    Query params:
      page (int, default 1)
      per_page (int, default 20, max 100)
      search (str) — fuzzy match on full_name or email
    """
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
        search = request.args.get('search', '').strip()

        query = User.query.order_by(User.created_at.desc())
        if search:
            pattern = f'%{search}%'
            query = query.filter(
                db.or_(
                    User.full_name.ilike(pattern),
                    User.email.ilike(pattern),
                )
            )

        users, total, pages = _paginate_query(query, page, per_page)

        return jsonify({
            'success': True,
            'users': [
                {
                    'id': u.id,
                    'name': u.full_name,
                    'email': u.email,
                    'role': u.role,
                    'is_active': u.is_active if u.is_active is not None else True,
                    'created_at': u.created_at.isoformat() if u.created_at else None,
                }
                for u in users
            ],
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': total,
                'pages': pages,
            },
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/users/<int:user_id>', methods=['GET'])
@admin_required
def get_admin_user_detail(user_id, current_user):
    """Return single user detail including case and oxygen counts."""
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        case_count = Case.query.filter_by(user_id=user_id).count()
        oxygen_count = OxygenCalculation.query.filter_by(user_id=user_id).count()

        return jsonify({
            'success': True,
            'user': {
                **user.to_dict(),
                'case_count': case_count,
                'oxygen_count': oxygen_count,
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/users/<int:user_id>', methods=['PATCH'])
@admin_required
def patch_admin_user(user_id, current_user):
    """
    Update a user's is_active status (deactivate / reactivate).
    Admins cannot deactivate their own account.

    Request body:
        { "is_active": false }
    """
    try:
        auth_id = _admin_id(current_user)
        if auth_id == user_id:
            return jsonify({
                'success': False,
                'message': 'You cannot deactivate your own admin account',
            }), 400

        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        data = request.get_json(silent=True) or {}
        if 'is_active' not in data:
            return jsonify({
                'success': False,
                'message': "Missing required field: 'is_active'",
            }), 400

        is_active = bool(data['is_active'])
        user.is_active = is_active
        db.session.commit()

        action = 'activated' if is_active else 'deactivated'
        _log_action(current_user, f'user_{action}', f'target_user_id={user_id}')
        _log_audit(current_user, user_id, f'user_{action}')

        return jsonify({
            'success': True,
            'message': f'User {action} successfully',
            'user': {
                'id': user.id,
                'email': user.email,
                'is_active': user.is_active,
            },
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/users/<int:user_id>', methods=['DELETE'])
@admin_required
def delete_admin_user(user_id, current_user):
    """Delete a user account. Prevent deleting own admin account."""
    try:
        auth_id = _admin_id(current_user)
        if auth_id == user_id:
            return jsonify({
                'success': False,
                'message': 'You cannot delete your own admin account',
            }), 400

        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        _log_action(current_user, 'user_deleted', f'target_user_id={user_id}')
        _log_audit(current_user, user_id, 'user_deleted')
        db.session.delete(user)
        db.session.commit()
        return jsonify({'success': True, 'message': 'User deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Entries — paginated list, patch, delete (cases + oxygen)
# ---------------------------------------------------------------------------

@admin_bp.route('/admin/entries', methods=['GET'])
@admin_required
def get_admin_entries(current_user):
    """
    Paginated list of calculator entries.

    Query params:
      type ('case' | 'oxygen' | 'all', default 'all')
      page (int, default 1)
      per_page (int, default 20)
      search (str) — matches patient_name for cases, cylinder_type for oxygen
    """
    try:
        entry_type = request.args.get('type', 'all').lower()
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
        search = request.args.get('search', '').strip()

        cases_data = []
        oxygen_data = []

        if entry_type in ('case', 'all'):
            q = Case.query.outerjoin(Case.user).order_by(Case.created_at.desc())
            if search:
                like = f'%{search}%'
                q = q.filter(
                    Case.patient_name.ilike(like) |
                    User.full_name.ilike(like) |
                    User.email.ilike(like)
                )
            if entry_type == 'case':
                items, total, pages = _paginate_query(q, page, per_page)
                cases_data = [{'_entry_type': 'case', **c.to_dict()} for c in items]
                return jsonify({
                    'success': True,
                    'type': 'case',
                    'entries': cases_data,
                    'pagination': {'page': page, 'per_page': per_page,
                                   'total': total, 'pages': pages},
                }), 200
            else:
                cases_data = [c.to_dict() for c in q.all()]

        if entry_type in ('oxygen', 'all'):
            q = OxygenCalculation.query.outerjoin(OxygenCalculation.user).order_by(OxygenCalculation.created_at.desc())
            if search:
                like = f'%{search}%'
                q = q.filter(
                    OxygenCalculation.cylinder_type.ilike(like) |
                    User.full_name.ilike(like) |
                    User.email.ilike(like)
                )
            if entry_type == 'oxygen':
                items, total, pages = _paginate_query(q, page, per_page)
                oxygen_data = [{'_entry_type': 'oxygen', **o.to_dict()} for o in items]
                return jsonify({
                    'success': True,
                    'type': 'oxygen',
                    'entries': oxygen_data,
                    'pagination': {'page': page, 'per_page': per_page,
                                   'total': total, 'pages': pages},
                }), 200
            else:
                oxygen_data = [o.to_dict() for o in q.all()]

        # type == 'all': merge, slice manually
        all_entries = (
            [{'_entry_type': 'case', **c} for c in cases_data]
            + [{'_entry_type': 'oxygen', **o} for o in oxygen_data]
        )
        all_entries.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        total = len(all_entries)
        per_page = max(1, min(per_page, 100))
        start = (page - 1) * per_page
        sliced = all_entries[start: start + per_page]
        pages = max(1, (total + per_page - 1) // per_page)

        return jsonify({
            'success': True,
            'type': 'all',
            'entries': sliced,
            'pagination': {'page': page, 'per_page': per_page,
                           'total': total, 'pages': pages},
        }), 200

    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/entries/<int:entry_id>', methods=['PATCH'])
@admin_required
def patch_admin_entry(entry_id, current_user):
    """
    Edit an entry. Only Case entries are editable (patient_name, notes).

    Query param:
      type ('case', required)

    Request body (any subset):
        { "patient_name": "...", "notes": "..." }
    """
    try:
        entry_type = request.args.get('type', 'case').lower()
        data = request.get_json(silent=True) or {}

        if entry_type != 'case':
            return jsonify({
                'success': False,
                'message': 'Only case entries support editing',
            }), 400

        case = Case.query.get(entry_id)
        if not case:
            return jsonify({'success': False, 'message': 'Case not found'}), 404

        if 'patient_name' in data:
            name = str(data['patient_name']).strip()
            if not name:
                return jsonify({'success': False, 'message': 'patient_name cannot be empty'}), 400
            case.patient_name = name

        if 'notes' in data:
            case.notes = str(data['notes']).strip() or None

        db.session.commit()
        _log_action(current_user, 'entry_patched', f'type=case id={entry_id}')

        return jsonify({
            'success': True,
            'message': 'Entry updated successfully',
            'entry': case.to_dict(),
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_bp.route('/admin/entries/<int:entry_id>', methods=['DELETE'])
@admin_required
def delete_admin_entry(entry_id, current_user):
    """
    Delete an entry.

    Query param:
      type ('case' | 'oxygen', required)
    """
    try:
        entry_type = request.args.get('type', 'case').lower()

        if entry_type == 'case':
            entry = Case.query.get(entry_id)
            label = 'Case'
        elif entry_type == 'oxygen':
            entry = OxygenCalculation.query.get(entry_id)
            label = 'Oxygen calculation'
        else:
            return jsonify({'success': False, 'message': "type must be 'case' or 'oxygen'"}), 400

        if not entry:
            return jsonify({'success': False, 'message': f'{label} not found'}), 404

        _log_action(current_user, 'entry_deleted', f'type={entry_type} id={entry_id}')
        db.session.delete(entry)
        db.session.commit()

        return jsonify({'success': True, 'message': f'{label} deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Calculators (kept for backward-compat with existing Flutter screen)
# ---------------------------------------------------------------------------

@admin_bp.route('/admin/calculators', methods=['GET'])
@admin_required
def get_admin_calculators(current_user):
    """Return all calculator usage data for admin visibility."""
    try:
        cases = Case.query.order_by(Case.created_at.desc()).all()
        oxygen_calculations = OxygenCalculation.query.order_by(
            OxygenCalculation.created_at.desc()
        ).all()

        return jsonify({
            'success': True,
            'cases': [case.to_dict() for case in cases],
            'oxygen_calculations': [calc.to_dict() for calc in oxygen_calculations],
            'case_count': len(cases),
            'oxygen_count': len(oxygen_calculations),
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Feedback
# ---------------------------------------------------------------------------

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
