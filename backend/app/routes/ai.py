"""
AI routes blueprint - clinical insights via Groq
"""
from flask import Blueprint, request, jsonify
from app.utils.decorators import require_json, require_token
from app.utils.groq_service import generate_clinical_insight

ai_bp = Blueprint('ai', __name__)


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

        # Build prompt templates per type
        if calc_type == 'economy':
            prompt = (
                f"An economy anesthetic calculation was performed. "
                f"Agent: {data.get('agent') or data.get('anesthetic_agent')}. "
                f"Molecular weight: {data.get('molecular_mass')}. "
                f"Fresh gas flow (L/min): {data.get('fresh_gas_flow')}. "
                f"Concentration (%): {data.get('concentration') or data.get('dial_concentration')}. "
                f"Duration (minutes): {data.get('duration') or data.get('time_minutes')}. "
                f"Total consumption (ml): {data.get('consumption') or data.get('total_consumption')}."
            )
        elif calc_type == 'volatile':
            prompt = (
                f"Volatile anesthetic result page data: Agent={data.get('agent') or data.get('anesthetic_agent')}, "
                f"molecular_weight={data.get('molecular_mass')}, fgf={data.get('fresh_gas_flow')}, "
                f"concentration={data.get('concentration') or data.get('dial_concentration')}, "
                f"duration={data.get('duration') or data.get('time_minutes')}, "
                f"biro={data.get('biro_formula')}, dion={data.get('dion_formula')}, "
                f"weight_based={data.get('weight_based')}, total={data.get('total_consumption')}"
            )
        elif calc_type == 'oxygen':
            prompt = (
                f"Oxygen cylinder calculation: type={data.get('cylinder_type')}, "
                f"pressure={data.get('pressure')}, oxygen_content={data.get('oxygen_content')}, "
                f"factor={data.get('factor')}"
            )
        elif calc_type == 'case_summary':
            prompt = (
                f"Case summary: surgery_type={data.get('surgery_type')}, "
                f"anesthetic_agent={data.get('anesthetic_agent')}, fgf={data.get('fresh_gas_flow')}, "
                f"duration={data.get('time_minutes')}, weight_diff={data.get('weight_difference')}, "
                f"formulas={data.get('formulas')}"
            )
        else:
            # Generic prompt
            prompt = f"Clinical calculation data: {data}"

        # Call Groq service
        result = generate_clinical_insight(prompt)

        if result.get('success'):
            insights = result.get('insights') or []
            if not insights:
                return jsonify({"success": False, "message": "No insights generated", "insights": []}), 200
            return jsonify({"success": True, "insights": insights}), 200

        # Failure - return fallback
        return jsonify({"success": False, "message": result.get('error', 'AI unavailable'), "insights": []}), 200

    except Exception as e:
        return jsonify({"success": False, "message": f"Error: {str(e)}", "insights": []}), 500