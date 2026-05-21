"""
Oxygen routes blueprint.
Handles persistence of oxygen cylinder calculations.
"""
import logging

from flask import Blueprint, jsonify, request

from app import db
from app.models.oxygen_calculation import OxygenCalculation
from app.services.oxygen_timer_service import OxygenTimerService


oxygen_bp = Blueprint('oxygen_bp', __name__)
logger = logging.getLogger(__name__)


@oxygen_bp.route('/save', methods=['POST'])
def save_oxygen_calculation():
    """Save an oxygen calculation to PostgreSQL."""
    try:
        data = request.get_json(silent=True) or {}
        logger.info('Received oxygen calculation save request: %s', data)

        cylinder_type = str(data.get('cylinder_type', '')).strip()
        pressure_psi = data.get('pressure_psi')
        total_oxygen_content = data.get('total_oxygen_content')

        if not cylinder_type:
            return jsonify({"success": False, "message": "cylinder_type is required"}), 400

        try:
            pressure_value = float(pressure_psi)
        except (TypeError, ValueError):
            return jsonify({"success": False, "message": "pressure_psi must be a number"}), 400

        try:
            oxygen_value = float(total_oxygen_content)
        except (TypeError, ValueError):
            return jsonify({"success": False, "message": "total_oxygen_content must be a number"}), 400

        if pressure_value <= 0:
            return jsonify({"success": False, "message": "pressure_psi must be greater than 0"}), 400

        if oxygen_value < 0:
            return jsonify({"success": False, "message": "total_oxygen_content must be at least 0"}), 400

        record = OxygenCalculation(
            cylinder_type=cylinder_type,
            pressure_psi=pressure_value,
            total_oxygen_content=oxygen_value,
        )

        db.session.add(record)
        db.session.commit()

        logger.info(
            'Saved oxygen calculation id=%s type=%s pressure=%s oxygen=%s',
            record.id,
            cylinder_type,
            pressure_value,
            oxygen_value,
        )

        return jsonify({
            "success": True,
            "message": "Calculation saved successfully",
            "calculation": record.to_dict(),
        }), 201

    except Exception as error:
        db.session.rollback()
        logger.exception('Error saving oxygen calculation: %s', error)
        return jsonify({
            "success": False,
            "message": "Error saving calculation",
            "error": str(error),
        }), 500


@oxygen_bp.route('/timer/start', methods=['POST'])
def start_oxygen_timer():
    """Create a timer history row when the countdown starts."""
    data = request.get_json(silent=True) or {}
    logger.info('Received oxygen timer start request: %s', data)

    response_body, status_code = OxygenTimerService.start_timer(data)
    return jsonify(response_body), status_code


@oxygen_bp.route('/timer/pause', methods=['POST'])
def pause_oxygen_timer():
    """Mark an oxygen timer as paused."""
    data = request.get_json(silent=True) or {}
    logger.info('Received oxygen timer pause request: %s', data)

    history_id = data.get('history_id')
    try:
        history_id = int(history_id)
    except (TypeError, ValueError):
        return jsonify({'success': False, 'message': 'history_id must be an integer'}), 400

    if history_id <= 0:
        return jsonify({'success': False, 'message': 'history_id must be greater than 0'}), 400

    response_body, status_code = OxygenTimerService.update_timer_status(
        history_id,
        'paused',
        'paused_at',
    )
    return jsonify(response_body), status_code


@oxygen_bp.route('/timer/resume', methods=['POST'])
def resume_oxygen_timer():
    """Mark an oxygen timer as resumed."""
    data = request.get_json(silent=True) or {}
    logger.info('Received oxygen timer resume request: %s', data)

    history_id = data.get('history_id')
    try:
        history_id = int(history_id)
    except (TypeError, ValueError):
        return jsonify({'success': False, 'message': 'history_id must be an integer'}), 400

    if history_id <= 0:
        return jsonify({'success': False, 'message': 'history_id must be greater than 0'}), 400

    response_body, status_code = OxygenTimerService.update_timer_status(
        history_id,
        'resumed',
        'resumed_at',
    )
    return jsonify(response_body), status_code


@oxygen_bp.route('/timer/stop', methods=['POST'])
def stop_oxygen_timer():
    """Mark an oxygen timer as stopped."""
    data = request.get_json(silent=True) or {}
    logger.info('Received oxygen timer stop request: %s', data)

    history_id = data.get('history_id')
    try:
        history_id = int(history_id)
    except (TypeError, ValueError):
        return jsonify({'success': False, 'message': 'history_id must be an integer'}), 400

    if history_id <= 0:
        return jsonify({'success': False, 'message': 'history_id must be greater than 0'}), 400

    response_body, status_code = OxygenTimerService.update_timer_status(
        history_id,
        'stopped',
        'stopped_at',
    )
    return jsonify(response_body), status_code


@oxygen_bp.route('/timer/complete', methods=['POST'])
def complete_oxygen_timer():
    """Mark an oxygen timer as completed."""
    data = request.get_json(silent=True) or {}
    logger.info('Received oxygen timer complete request: %s', data)

    history_id = data.get('history_id')
    try:
        history_id = int(history_id)
    except (TypeError, ValueError):
        return jsonify({'success': False, 'message': 'history_id must be an integer'}), 400

    if history_id <= 0:
        return jsonify({'success': False, 'message': 'history_id must be greater than 0'}), 400

    response_body, status_code = OxygenTimerService.update_timer_status(
        history_id,
        'completed',
        'completed_at',
    )
    return jsonify(response_body), status_code


@oxygen_bp.route('/timer/history', methods=['GET'])
def get_oxygen_timer_history():
    """Return all timer history rows ordered newest first."""
    logger.info('Received oxygen timer history request')
    response_body, status_code = OxygenTimerService.get_history()
    return jsonify(response_body), status_code