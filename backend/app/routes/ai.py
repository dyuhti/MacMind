"""
AI routes blueprint - clinical insights via Groq
"""
import logging

from flask import Blueprint, request, jsonify
from app.utils.decorators import require_json, require_token
from app.utils.groq_service import generate_clinical_insight

ai_bp = Blueprint('ai', __name__)
logger = logging.getLogger(__name__)


@ai_bp.route('/clinical-insight', methods=['POST'])
@require_json
@require_token
def clinical_insight(current_user):
    """
    POST /api/ai/clinical-insight

    Body: { "type": "economy", "data": {...} }
    Returns: { success: true/false, insights: [str,...] }
    """
    try:
        payload = request.get_json() or {}
        calc_type = (payload.get('type') or '').lower()
        data = payload.get('data') or {}
        logger.info("AI route request type=%s user_id=%s", calc_type, current_user.get('user_id'))

        # Build prompt templates per type - focus on clinical interpretation and inference
        if calc_type == 'economy':
            agent = data.get('agent') or data.get('anesthetic_agent')
            fgf = data.get('fresh_gas_flow')
            duration = data.get('duration') or data.get('time_minutes')
            prompt = (
                f"Analyze the consumption behavior of {agent} volatile anesthetic across a range of fresh gas flow rates. "
                f"The calculation considers a duration of {duration} minutes and shows consumption patterns. "
                f"Provide clinical insights about: consumption efficiency trends, flow impact on agent utilization, "
                f"cost-effectiveness observations, and any efficiency or wastage implications. "
                f"Do not repeat the entered values or formulas."
            )
        elif calc_type == 'volatile':
            agent = data.get('agent') or data.get('anesthetic_agent')
            duration = data.get('duration') or data.get('time_minutes')
            biro = data.get('biro_formula')
            dion = data.get('dion_formula')
            prompt = (
                f"A volatile anesthetic procedure using {agent} over {duration} minutes resulted in calculated consumptions of approximately {biro}ml (Biro) and {dion}ml (Dion). "
                f"Provide clinical observations about: anesthetic utilization patterns, resource efficiency, "
                f"consistency with low-flow anesthesia principles, consumption stability, and any notable characteristics of this profile. "
                f"Focus on clinical meaning and efficiency implications. Do not repeat patient data or formulas."
            )
        elif calc_type == 'oxygen':
            cylinder_type = data.get('cylinder_type')
            total_content = data.get('oxygen_content')
            prompt = (
                f"An {cylinder_type} oxygen cylinder contains approximately {total_content} liters of available oxygen. "
                f"Provide clinical insights about: adequacy of oxygen reserve for typical surgical scenarios, "
                f"emergency preparedness implications, suitability for short vs extended procedures, "
                f"utilization profile recommendations, and practical considerations for this reserve capacity. "
                f"Do not repeat the cylinder type, pressure, or formula."
            )
        elif calc_type == 'case_summary':
            agent = data.get('anesthetic_agent')
            surgery = data.get('surgery_type')
            duration = data.get('time_minutes')
            prompt = (
                f"A {surgery} case was anesthetized with {agent} over {duration} minutes. "
                f"Provide clinical insights about: the consumption profile observed, anesthetic efficacy indicators, "
                f"resource utilization efficiency, stability of anesthetic delivery, and any notable clinical characteristics. "
                f"Focus on clinical interpretation and efficiency analysis. Do not repeat case details or values."
            )
        else:
            # Generic prompt
            prompt = (
                "Analyze the clinical significance of these anesthetic calculation results. "
                "Provide insights about utilization patterns, efficiency, clinical implications, and professional observations. "
                "Do not repeat raw data or formulas."
            )

        # Call Groq service
        result = generate_clinical_insight(prompt)

        if result.get('success'):
            insights = result.get('insights') or []
            if not insights:
                return jsonify({"success": False, "message": "No insights generated", "insights": []}), 200
            return jsonify({"success": True, "insights": insights}), 200

        # Failure - forward service message (do not mask with generic fallback)
        failure_message = result.get('message') or result.get('error') or 'AI unavailable'
        logger.error("AI route upstream failure type=%s message=%s", calc_type, failure_message)
        return jsonify({"success": False, "message": failure_message, "insights": []}), 200

    except Exception as e:
        logger.exception("AI route unexpected error: %s", str(e))
        return jsonify({"success": False, "message": f"Error: {str(e)}", "insights": []}), 500