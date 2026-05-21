"""
Service layer for oxygen timer persistence and updates.
"""
from datetime import datetime
import logging

from app import db
from app.models.oxygen_timer_history import OxygenTimerHistory


logger = logging.getLogger(__name__)


class OxygenTimerService:
    """Encapsulates oxygen timer validation and database writes."""

    @staticmethod
    def _parse_start_payload(data):
        cylinder_type = str(data.get('cylinder_type', '')).strip()
        duration_text = str(data.get('duration_text', '')).strip()

        if not cylinder_type:
            return None, {'success': False, 'message': 'cylinder_type is required'}, 400

        try:
            pressure_psi = float(data.get('pressure_psi'))
        except (TypeError, ValueError):
            return None, {'success': False, 'message': 'pressure_psi must be a number'}, 400

        try:
            total_oxygen_content = float(data.get('total_oxygen_content'))
        except (TypeError, ValueError):
            return None, {'success': False, 'message': 'total_oxygen_content must be a number'}, 400

        try:
            selected_flow_rate = float(data.get('selected_flow_rate'))
        except (TypeError, ValueError):
            return None, {'success': False, 'message': 'selected_flow_rate must be a number'}, 400

        try:
            duration_seconds = int(data.get('duration_seconds'))
        except (TypeError, ValueError):
            return None, {'success': False, 'message': 'duration_seconds must be an integer'}, 400

        if pressure_psi <= 0:
            return None, {'success': False, 'message': 'pressure_psi must be greater than 0'}, 400

        if total_oxygen_content < 0:
            return None, {'success': False, 'message': 'total_oxygen_content must be at least 0'}, 400

        if selected_flow_rate <= 0:
            return None, {'success': False, 'message': 'selected_flow_rate must be greater than 0'}, 400

        if duration_seconds <= 0:
            return None, {'success': False, 'message': 'duration_seconds must be greater than 0'}, 400

        if not duration_text:
            return None, {'success': False, 'message': 'duration_text is required'}, 400

        return {
            'cylinder_type': cylinder_type,
            'pressure_psi': pressure_psi,
            'total_oxygen_content': total_oxygen_content,
            'selected_flow_rate': selected_flow_rate,
            'duration_seconds': duration_seconds,
            'duration_text': duration_text,
        }, None, None

    @staticmethod
    def start_timer(data, user_id):
        """Insert a new oxygen timer history row."""
        parsed, error_response, status_code = OxygenTimerService._parse_start_payload(data)
        if error_response is not None:
            return error_response, status_code

        try:
            now = datetime.utcnow()
            history = OxygenTimerHistory(
                user_id=user_id,
                cylinder_type=parsed['cylinder_type'],
                pressure_psi=parsed['pressure_psi'],
                total_oxygen_content=parsed['total_oxygen_content'],
                selected_flow_rate=parsed['selected_flow_rate'],
                duration_seconds=parsed['duration_seconds'],
                duration_text=parsed['duration_text'],
                timer_status='running',
                started_at=now,
            )

            db.session.add(history)
            db.session.commit()

            logger.info(
                'Started oxygen timer history_id=%s flow_rate=%s duration_seconds=%s duration_text=%s',
                history.id,
                history.selected_flow_rate,
                history.duration_seconds,
                history.duration_text,
            )

            return {
                'success': True,
                'history_id': history.id,
                'history': history.to_dict(),
            }, 201
        except Exception as error:
            db.session.rollback()
            logger.exception('Failed to start oxygen timer: %s', error)
            return {
                'success': False,
                'message': 'Failed to start oxygen timer',
                'error': str(error),
            }, 500

    @staticmethod
    def update_timer_status(history_id, user_id, status, timestamp_field):
        """Update an existing oxygen timer history row with a new status."""
        try:
            timer_history = OxygenTimerHistory.query.filter_by(id=history_id, user_id=user_id).first()
            if timer_history is None:
                return {
                    'success': False,
                    'message': f'Oxygen timer history {history_id} not found',
                }, 404

            now = datetime.utcnow()
            timer_history.timer_status = status
            setattr(timer_history, timestamp_field, now)

            db.session.commit()

            logger.info(
                'Updated oxygen timer history_id=%s status=%s timestamp_field=%s',
                history_id,
                status,
                timestamp_field,
            )

            return {
                'success': True,
                'message': f'Oxygen timer marked as {status}',
                'history': timer_history.to_dict(),
            }, 200
        except Exception as error:
            db.session.rollback()
            logger.exception(
                'Failed to update oxygen timer history_id=%s status=%s: %s',
                history_id,
                status,
                error,
            )
            return {
                'success': False,
                'message': f'Failed to update oxygen timer status to {status}',
                'error': str(error),
            }, 500

    @staticmethod
    def get_history(user_id):
        """Return all timer history rows ordered newest first."""
        try:
            history_rows = (
                OxygenTimerHistory.query
                .filter_by(user_id=user_id)
                .order_by(OxygenTimerHistory.created_at.desc(), OxygenTimerHistory.id.desc())
                .all()
            )

            return {
                'success': True,
                'history': [row.to_dict() for row in history_rows],
                'count': len(history_rows),
            }, 200
        except Exception as error:
            logger.exception('Failed to fetch oxygen timer history: %s', error)
            return {
                'success': False,
                'message': 'Failed to fetch oxygen timer history',
                'error': str(error),
                'history': [],
            }, 500