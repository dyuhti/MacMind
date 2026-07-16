import logging
from datetime import datetime, timedelta

from flask import Blueprint, jsonify, request
from sqlalchemy import func

from app import db
from app.models.case import Case
from app.models.feedback import Feedback
from app.models.oxygen_calculation import OxygenCalculation
from app.models.user import User
from app.models.login_history import LoginHistory
from app.models.admin_note import AdminNote
from app.models.audit_log import AuditLog
from app.models.favorite import Favorite
from app.models.oxygen_timer_history import OxygenTimerHistory
from app.utils.decorators import admin_required

admin_user_bp = Blueprint('admin_user', __name__)
_log = logging.getLogger('admin_user_actions')


def _paginate_query(query, page, per_page):
    per_page = max(1, min(per_page, 100))
    page = max(1, page)
    total = query.count()
    items = query.offset((page - 1) * per_page).limit(per_page).all()
    pages = max(1, (total + per_page - 1) // per_page)
    return items, total, pages


def _admin_id(current_user):
    return int(current_user.get('user_id', 0))


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
# User Dashboard (aggregated stats)
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/dashboard', methods=['GET'])
@admin_required
def get_user_dashboard(current_user, user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        case_count = Case.query.filter_by(user_id=user_id).count()
        oxygen_count = OxygenCalculation.query.filter_by(user_id=user_id).count()
        favorite_count = Favorite.query.filter_by(user_id=user_id).count()
        feedback_count = Feedback.query.filter_by(user_id=user_id).count()
        login_count = LoginHistory.query.filter_by(user_id=user_id, status='success').count()
        feedback_submitted = Feedback.query.filter_by(user_id=user_id).count()

        last_login = LoginHistory.query.filter_by(
            user_id=user_id, status='success'
        ).order_by(LoginHistory.login_time.desc()).first()

        last_activity = _get_latest_activity(user_id)
        account_age = (datetime.utcnow() - user.created_at).days if user.created_at else 0

        total_sessions = LoginHistory.query.filter_by(user_id=user_id).count()
        avg_daily = _calc_avg_daily_usage(user_id, user.created_at)

        most_used = _get_most_used_calculator(user_id)

        last_login_data = None
        if last_login:
            last_login_data = {
                'time': last_login.login_time.isoformat(),
                'platform': last_login.platform,
                'device': last_login.device,
            }

        return jsonify({
            'success': True,
            'user': {
                'id': user.id,
                'full_name': user.full_name,
                'email': user.email,
                'role': user.role,
                'is_active': user.is_active if user.is_active is not None else True,
                'created_at': user.created_at.isoformat() if user.created_at else None,
                'case_count': case_count,
                'oxygen_count': oxygen_count,
                'favorite_count': favorite_count,
                'feedback_count': feedback_count,
                'login_count': login_count,
                'total_sessions': total_sessions,
                'feedback_submitted': feedback_submitted,
                'last_login': last_login_data,
                'last_activity': last_activity,
                'account_age_days': account_age,
                'average_daily_usage_mins': avg_daily,
                'most_used_calculator': most_used,
                'storage_used': '—',
                'app_version': '—',
                'country': '—',
                'platform': last_login.platform if last_login else '—',
                'device': last_login.device if last_login else '—',
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


def _get_latest_activity(user_id):
    candidates = []

    latest_case = Case.query.filter_by(user_id=user_id).order_by(Case.created_at.desc()).first()
    if latest_case:
        candidates.append(('case', latest_case.created_at))

    latest_oxygen = OxygenCalculation.query.filter_by(user_id=user_id).order_by(
        OxygenCalculation.created_at.desc()
    ).first()
    if latest_oxygen:
        candidates.append(('oxygen', latest_oxygen.created_at))

    latest_feedback = Feedback.query.filter_by(user_id=user_id).order_by(
        Feedback.created_at.desc()
    ).first()
    if latest_feedback:
        candidates.append(('feedback', latest_feedback.created_at))

    latest_login = LoginHistory.query.filter_by(user_id=user_id).order_by(
        LoginHistory.login_time.desc()
    ).first()
    if latest_login:
        candidates.append(('login', latest_login.login_time))

    if not candidates:
        return None

    latest = max(candidates, key=lambda x: x[1])
    return latest[1].isoformat()


def _calc_avg_daily_usage(user_id, created_at):
    if not created_at:
        return 0
    days = max(1, (datetime.utcnow() - created_at).days)
    total = Case.query.filter_by(user_id=user_id).count() + OxygenCalculation.query.filter_by(user_id=user_id).count()
    return round(total / days, 2)


def _get_most_used_calculator(user_id):
    case_count = Case.query.filter_by(user_id=user_id).count()
    oxygen_count = OxygenCalculation.query.filter_by(user_id=user_id).count()
    if case_count >= oxygen_count and case_count > 0:
        return 'Volatile Anesthetic'
    elif oxygen_count > 0:
        return 'Oxygen Cylinder'
    return None


# ---------------------------------------------------------------------------
# Activities
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/activities', methods=['GET'])
@admin_required
def get_user_activities(current_user, user_id):
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
        search = request.args.get('search', '').strip().lower()
        filter_type = request.args.get('filter', '').strip().lower()

        activities = []
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        if not filter_type or filter_type == 'case':
            cases = Case.query.filter_by(user_id=user_id).order_by(Case.created_at.desc()).all()
            for c in cases:
                activities.append({
                    'type': 'case_created',
                    'description': f'Created case for {c.patient_name} ({c.surgery_type})',
                    'timestamp': c.created_at.isoformat(),
                    'platform': '—',
                    'device': '—',
                })

        if not filter_type or filter_type == 'oxygen':
            oxygens = OxygenCalculation.query.filter_by(user_id=user_id).order_by(
                OxygenCalculation.created_at.desc()
            ).all()
            for o in oxygens:
                activities.append({
                    'type': 'oxygen_created',
                    'description': f'Created oxygen calculation ({o.cylinder_type}, {o.pressure_psi} PSI)',
                    'timestamp': o.created_at.isoformat(),
                    'platform': '—',
                    'device': '—',
                })

        if not filter_type or filter_type == 'feedback':
            feedbacks = Feedback.query.filter_by(user_id=user_id).order_by(
                Feedback.created_at.desc()
            ).all()
            for f in feedbacks:
                activities.append({
                    'type': 'feedback_submitted',
                    'description': f'Submitted feedback ({f.category}, rating: {f.rating})',
                    'timestamp': f.created_at.isoformat(),
                    'platform': '—',
                    'device': '—',
                })

        if not filter_type or filter_type == 'login':
            logins = LoginHistory.query.filter_by(user_id=user_id).order_by(
                LoginHistory.login_time.desc()
            ).all()
            for l in logins:
                desc = f'Logged {"in" if l.status == "success" else "in (failed)"}'
                if l.logout_time:
                    desc += f' | session: {l.session_duration or "—"}s'
                activities.append({
                    'type': 'login' if l.status == 'success' else 'login_failed',
                    'description': desc,
                    'timestamp': l.login_time.isoformat(),
                    'platform': l.platform or '—',
                    'device': l.device or '—',
                })

        if not filter_type or filter_type == 'favorite':
            favorites = Favorite.query.filter_by(user_id=user_id).order_by(
                Favorite.created_at.desc()
            ).all()
            for f in favorites:
                activities.append({
                    'type': 'favorite_added',
                    'description': f'Added favorite: {f.calculator_name}',
                    'timestamp': f.created_at.isoformat(),
                    'platform': '—',
                    'device': '—',
                })

        if search:
            activities = [
                a for a in activities
                if search in a['description'].lower()
            ]

        activities.sort(key=lambda a: a['timestamp'], reverse=True)
        total = len(activities)
        start = (page - 1) * per_page
        sliced = activities[start:start + per_page]
        pages = max(1, (total + per_page - 1) // per_page)

        return jsonify({
            'success': True,
            'activities': sliced,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': total,
                'pages': pages,
            },
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Cases CRUD
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/cases', methods=['GET'])
@admin_required
def get_user_cases(current_user, user_id):
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
        search = request.args.get('search', '').strip()

        query = Case.query.filter_by(user_id=user_id).order_by(Case.created_at.desc())
        if search:
            query = query.filter(Case.patient_name.ilike(f'%{search}%'))

        items, total, pages = _paginate_query(query, page, per_page)
        return jsonify({
            'success': True,
            'cases': [c.to_dict() for c in items],
            'pagination': {'page': page, 'per_page': per_page, 'total': total, 'pages': pages},
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/cases', methods=['POST'])
@admin_required
def create_user_case(current_user, user_id):
    try:
        data = request.get_json(silent=True) or {}
        result = Case.create(user_id=user_id, **data)
        if result.get('success'):
            _log_audit(current_user, user_id, 'case_created', new_value=f'Case ID {result["id"]}')
            return jsonify(result), 201
        return jsonify({'success': False, 'message': result.get('error', 'Failed to create case')}), 400
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/cases/<int:case_id>', methods=['PUT'])
@admin_required
def update_user_case(current_user, user_id, case_id):
    try:
        case = Case.query.filter_by(id=case_id, user_id=user_id).first()
        if not case:
            return jsonify({'success': False, 'message': 'Case not found'}), 404

        data = request.get_json(silent=True) or {}
        for field in ('patient_name', 'patient_id', 'date', 'surgery_type', 'anesthetic_agent',
                       'molecular_mass', 'vapor_constant', 'density', 'fresh_gas_flow',
                       'dial_concentration', 'time_minutes', 'initial_weight', 'final_weight',
                       'biro_formula', 'dion_formula', 'weight_based', 'notes',
                       'induction_fgf', 'induction_concentration', 'induction_time',
                       'induction_biro', 'induction_dion', 'final_biro', 'final_dion',
                       'maintenance_rows', 'maintenance_calculations'):
            if field in data:
                setattr(case, field, data[field])
        db.session.commit()
        _log_audit(current_user, user_id, 'case_updated', old_value=f'Case ID {case_id}')
        return jsonify({'success': True, 'case': case.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/cases/<int:case_id>', methods=['DELETE'])
@admin_required
def delete_user_case(current_user, user_id, case_id):
    try:
        case = Case.query.filter_by(id=case_id, user_id=user_id).first()
        if not case:
            return jsonify({'success': False, 'message': 'Case not found'}), 404
        db.session.delete(case)
        db.session.commit()
        _log_audit(current_user, user_id, 'case_deleted', old_value=f'Case ID {case_id}')
        return jsonify({'success': True, 'message': 'Case deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Oxygen CRUD
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/oxygen', methods=['GET'])
@admin_required
def get_user_oxygen(current_user, user_id):
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
        query = OxygenCalculation.query.filter_by(user_id=user_id).order_by(
            OxygenCalculation.created_at.desc()
        )
        items, total, pages = _paginate_query(query, page, per_page)
        return jsonify({
            'success': True,
            'oxygen': [o.to_dict() for o in items],
            'pagination': {'page': page, 'per_page': per_page, 'total': total, 'pages': pages},
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/oxygen', methods=['POST'])
@admin_required
def create_user_oxygen(current_user, user_id):
    try:
        data = request.get_json(silent=True) or {}
        calc = OxygenCalculation(
            user_id=user_id,
            cylinder_type=data.get('cylinder_type', 'Unknown'),
            pressure_psi=data.get('pressure_psi', 0),
            total_oxygen_content=data.get('total_oxygen_content', 0),
        )
        db.session.add(calc)
        db.session.commit()
        _log_audit(current_user, user_id, 'oxygen_created', new_value=f'Oxygen ID {calc.id}')
        return jsonify({'success': True, 'oxygen': calc.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/oxygen/<int:oxygen_id>', methods=['PUT'])
@admin_required
def update_user_oxygen(current_user, user_id, oxygen_id):
    try:
        calc = OxygenCalculation.query.filter_by(id=oxygen_id, user_id=user_id).first()
        if not calc:
            return jsonify({'success': False, 'message': 'Oxygen calculation not found'}), 404
        data = request.get_json(silent=True) or {}
        if 'cylinder_type' in data:
            calc.cylinder_type = data['cylinder_type']
        if 'pressure_psi' in data:
            calc.pressure_psi = data['pressure_psi']
        if 'total_oxygen_content' in data:
            calc.total_oxygen_content = data['total_oxygen_content']
        db.session.commit()
        return jsonify({'success': True, 'oxygen': calc.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/oxygen/<int:oxygen_id>', methods=['DELETE'])
@admin_required
def delete_user_oxygen(current_user, user_id, oxygen_id):
    try:
        calc = OxygenCalculation.query.filter_by(id=oxygen_id, user_id=user_id).first()
        if not calc:
            return jsonify({'success': False, 'message': 'Oxygen calculation not found'}), 404
        db.session.delete(calc)
        db.session.commit()
        _log_audit(current_user, user_id, 'oxygen_deleted', old_value=f'Oxygen ID {oxygen_id}')
        return jsonify({'success': True, 'message': 'Oxygen calculation deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Favorites
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/favorites', methods=['GET'])
@admin_required
def get_user_favorites(current_user, user_id):
    try:
        favorites = Favorite.query.filter_by(user_id=user_id).order_by(Favorite.order).all()
        return jsonify({
            'success': True,
            'favorites': [f.to_dict() for f in favorites],
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/favorites', methods=['POST'])
@admin_required
def add_user_favorite(current_user, user_id):
    try:
        data = request.get_json(silent=True) or {}
        max_order = db.session.query(func.max(Favorite.order)).filter_by(user_id=user_id).scalar() or 0
        fav = Favorite(
            user_id=user_id,
            calculator_name=data.get('calculator_name', ''),
            order=data.get('order', max_order + 1),
        )
        db.session.add(fav)
        db.session.commit()
        return jsonify({'success': True, 'favorite': fav.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/favorites/<int:fav_id>', methods=['DELETE'])
@admin_required
def remove_user_favorite(current_user, user_id, fav_id):
    try:
        fav = Favorite.query.filter_by(id=fav_id, user_id=user_id).first()
        if not fav:
            return jsonify({'success': False, 'message': 'Favorite not found'}), 404
        db.session.delete(fav)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Favorite removed'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/favorites/reorder', methods=['PUT'])
@admin_required
def reorder_user_favorites(current_user, user_id):
    try:
        data = request.get_json(silent=True) or {}
        items = data.get('items', [])
        for item in items:
            fav = Favorite.query.filter_by(id=item.get('id'), user_id=user_id).first()
            if fav:
                fav.order = item.get('order', 0)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Favorites reordered'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Feedback
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/feedback', methods=['GET'])
@admin_required
def get_user_feedback(current_user, user_id):
    try:
        feedbacks = Feedback.find_by_user_id(user_id)
        return jsonify({
            'success': True,
            'feedback': [f.to_dict() for f in feedbacks],
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/feedback/<int:feedback_id>', methods=['PATCH'])
@admin_required
def update_user_feedback(current_user, user_id, feedback_id):
    try:
        fb = Feedback.find_by_id(feedback_id)
        if not fb or fb.user_id != user_id:
            return jsonify({'success': False, 'message': 'Feedback not found'}), 404
        data = request.get_json(silent=True) or {}
        if 'status' in data:
            fb.status = data['status']
        if 'admin_reply' in data:
            fb.admin_reply = data['admin_reply']
        db.session.commit()
        return jsonify({'success': True, 'feedback': fb.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/feedback/<int:feedback_id>', methods=['DELETE'])
@admin_required
def delete_user_feedback(current_user, user_id, feedback_id):
    try:
        fb = Feedback.find_by_id(feedback_id)
        if not fb or fb.user_id != user_id:
            return jsonify({'success': False, 'message': 'Feedback not found'}), 404
        db.session.delete(fb)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Feedback deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Login History
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/login-history', methods=['GET'])
@admin_required
def get_user_login_history(current_user, user_id):
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
        query = LoginHistory.query.filter_by(user_id=user_id).order_by(
            LoginHistory.login_time.desc()
        )
        items, total, pages = _paginate_query(query, page, per_page)
        return jsonify({
            'success': True,
            'login_history': [l.to_dict() for l in items],
            'pagination': {'page': page, 'per_page': per_page, 'total': total, 'pages': pages},
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/security', methods=['GET'])
@admin_required
def get_user_security(current_user, user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        failed_logins = LoginHistory.query.filter_by(user_id=user_id, status='failed').count()
        known_devices = (
            db.session.query(LoginHistory.device, LoginHistory.platform)
            .filter_by(user_id=user_id)
            .distinct()
            .all()
        )
        recent_sessions = LoginHistory.query.filter_by(
            user_id=user_id, status='success', logout_time=None
        ).count()

        return jsonify({
            'success': True,
            'security': {
                'password_last_changed': user.created_at.isoformat() if user.created_at else None,
                'failed_logins': failed_logins,
                'known_devices': [
                    {'device': d, 'platform': p} for d, p in known_devices if d
                ],
                'current_sessions': recent_sessions,
                'is_blocked': user.is_active is False,
                'two_factor_enabled': False,
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/terminate-sessions', methods=['POST'])
@admin_required
def terminate_user_sessions(current_user, user_id):
    try:
        LoginHistory.query.filter_by(user_id=user_id, logout_time=None).update(
            {'logout_time': datetime.utcnow()}
        )
        db.session.commit()
        _log_audit(current_user, user_id, 'sessions_terminated')
        return jsonify({'success': True, 'message': 'Sessions terminated'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/reset-password', methods=['POST'])
@admin_required
def admin_reset_user_password(current_user, user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404
        import secrets
        from app.utils.security import hash_password
        new_password = secrets.token_urlsafe(12)
        user.password = hash_password(new_password)
        db.session.commit()
        _log_audit(current_user, user_id, 'password_reset_by_admin')
        return jsonify({
            'success': True,
            'message': 'Password reset successfully',
            'new_password': new_password,
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/unlock', methods=['POST'])
@admin_required
def unlock_user_account(current_user, user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404
        user.is_active = True
        db.session.commit()
        _log_audit(current_user, user_id, 'account_unlocked')
        return jsonify({'success': True, 'message': 'Account unlocked'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Admin Notes
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/admin-notes', methods=['GET'])
@admin_required
def get_admin_notes(current_user, user_id):
    try:
        notes = AdminNote.query.filter_by(user_id=user_id).order_by(AdminNote.created_at.desc()).all()
        return jsonify({
            'success': True,
            'admin_notes': [n.to_dict() for n in notes],
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/admin-notes', methods=['POST'])
@admin_required
def create_admin_note(current_user, user_id):
    try:
        data = request.get_json(silent=True) or {}
        note = AdminNote(
            user_id=user_id,
            admin_id=_admin_id(current_user),
            note=data.get('note', ''),
        )
        db.session.add(note)
        db.session.commit()
        return jsonify({'success': True, 'admin_note': note.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/admin-notes/<int:note_id>', methods=['PUT'])
@admin_required
def update_admin_note(current_user, user_id, note_id):
    try:
        note = AdminNote.query.filter_by(id=note_id, user_id=user_id).first()
        if not note:
            return jsonify({'success': False, 'message': 'Note not found'}), 404
        data = request.get_json(silent=True) or {}
        if 'note' in data:
            note.note = data['note']
        note.updated_at = datetime.utcnow()
        db.session.commit()
        return jsonify({'success': True, 'admin_note': note.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/admin-notes/<int:note_id>', methods=['DELETE'])
@admin_required
def delete_admin_note(current_user, user_id, note_id):
    try:
        note = AdminNote.query.filter_by(id=note_id, user_id=user_id).first()
        if not note:
            return jsonify({'success': False, 'message': 'Note not found'}), 404
        db.session.delete(note)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Note deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# Audit Log
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/audit-log', methods=['GET'])
@admin_required
def get_user_audit_log(current_user, user_id):
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
        query = AuditLog.query.filter_by(target_user_id=user_id).order_by(
            AuditLog.timestamp.desc()
        )
        items, total, pages = _paginate_query(query, page, per_page)
        return jsonify({
            'success': True,
            'audit_logs': [l.to_dict() for l in items],
            'pagination': {'page': page, 'per_page': per_page, 'total': total, 'pages': pages},
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


# ---------------------------------------------------------------------------
# User Analytics
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/analytics', methods=['GET'])
@admin_required
def get_user_analytics(current_user, user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        case_count = Case.query.filter_by(user_id=user_id).count()
        oxygen_count = OxygenCalculation.query.filter_by(user_id=user_id).count()
        most_used = _get_most_used_calculator(user_id)

        days_since_creation = max(1, (datetime.utcnow() - user.created_at).days) if user.created_at else 1
        avg_per_week = round((case_count + oxygen_count) / days_since_creation * 7, 1)

        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        cases_30 = Case.query.filter(
            Case.user_id == user_id, Case.created_at >= thirty_days_ago
        ).count()
        oxygen_30 = OxygenCalculation.query.filter(
            OxygenCalculation.user_id == user_id, OxygenCalculation.created_at >= thirty_days_ago
        ).count()

        last_activity = _get_latest_activity(user_id)
        days_since_last = 0
        if last_activity:
            try:
                last_dt = datetime.fromisoformat(last_activity)
                days_since_last = (datetime.utcnow() - last_dt).days
            except Exception:
                pass

        weekly = _build_time_series(user_id, 7)
        monthly = _build_time_series(user_id, 30)

        feature_usage = [
            {'name': 'Volatile Anesthetic', 'count': case_count, 'percentage': round(case_count / max(1, case_count + oxygen_count) * 100, 1)},
            {'name': 'Oxygen Cylinder', 'count': oxygen_count, 'percentage': round(oxygen_count / max(1, case_count + oxygen_count) * 100, 1)},
        ]

        return jsonify({
            'success': True,
            'analytics': {
                'total_cases': case_count,
                'total_oxygen': oxygen_count,
                'most_used_calculator': most_used,
                'avg_calculations_per_week': avg_per_week,
                'registration_date': user.created_at.isoformat() if user.created_at else None,
                'last_active_date': last_activity,
                'cases_last_30_days': cases_30,
                'oxygen_last_30_days': oxygen_30,
                'days_since_last_activity': days_since_last,
                'weekly_activity': weekly,
                'monthly_activity': monthly,
                'calculator_usage': feature_usage,
                'feature_usage_breakdown': feature_usage,
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


def _build_time_series(user_id, days):
    since = datetime.utcnow() - timedelta(days=days)
    case_daily = (
        db.session.query(
            func.date(Case.created_at).label('day'),
            func.count(Case.id).label('cnt'),
        )
        .filter(Case.user_id == user_id, Case.created_at >= since)
        .group_by(func.date(Case.created_at))
        .all()
    )
    oxygen_daily = (
        db.session.query(
            func.date(OxygenCalculation.created_at).label('day'),
            func.count(OxygenCalculation.id).label('cnt'),
        )
        .filter(OxygenCalculation.user_id == user_id, OxygenCalculation.created_at >= since)
        .group_by(func.date(OxygenCalculation.created_at))
        .all()
    )
    daily_map = {}
    for row in case_daily:
        d = str(row.day)
        daily_map.setdefault(d, {'date': d, 'cases': 0, 'oxygen': 0})
        daily_map[d]['cases'] = row.cnt
    for row in oxygen_daily:
        d = str(row.day)
        daily_map.setdefault(d, {'date': d, 'cases': 0, 'oxygen': 0})
        daily_map[d]['oxygen'] = row.cnt
    return sorted(daily_map.values(), key=lambda x: x['date'])


# ---------------------------------------------------------------------------
# Quick Actions — Promote / Demote / Notify / Export
# ---------------------------------------------------------------------------

@admin_user_bp.route('/admin/users/<int:user_id>/role', methods=['PATCH'])
@admin_required
def update_user_role(current_user, user_id):
    try:
        auth_id = _admin_id(current_user)
        if auth_id == user_id:
            return jsonify({'success': False, 'message': 'Cannot change your own role'}), 400

        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        data = request.get_json(silent=True) or {}
        new_role = data.get('role', '').strip().lower()
        if new_role not in ('admin', 'user'):
            return jsonify({'success': False, 'message': 'Role must be admin or user'}), 400

        old_role = user.role
        user.role = new_role
        db.session.commit()
        _log_audit(current_user, user_id, 'role_changed', old_value=old_role, new_value=new_role)
        return jsonify({'success': True, 'message': f'Role changed to {new_role}'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/send-notification', methods=['POST'])
@admin_required
def send_user_notification(current_user, user_id):
    try:
        data = request.get_json(silent=True) or {}
        title = data.get('title', '')
        message = data.get('message', '')
        if not title or not message:
            return jsonify({'success': False, 'message': 'Title and message required'}), 400
        _log_audit(current_user, user_id, 'notification_sent', new_value=f'{title}: {message}')
        return jsonify({'success': True, 'message': 'Notification queued'}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@admin_user_bp.route('/admin/users/<int:user_id>/export', methods=['GET'])
@admin_required
def export_user_data(current_user, user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        cases = [c.to_dict() for c in Case.query.filter_by(user_id=user_id).all()]
        oxygens = [o.to_dict() for o in OxygenCalculation.query.filter_by(user_id=user_id).all()]
        feedbacks = [f.to_dict() for f in Feedback.query.filter_by(user_id=user_id).all()]
        favorites = [f.to_dict() for f in Favorite.query.filter_by(user_id=user_id).all()]
        login_history = [l.to_dict() for l in LoginHistory.query.filter_by(user_id=user_id).all()]

        return jsonify({
            'success': True,
            'export': {
                'user': user.to_dict(),
                'cases': cases,
                'oxygen_calculations': oxygens,
                'feedback': feedbacks,
                'favorites': favorites,
                'login_history': login_history,
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
