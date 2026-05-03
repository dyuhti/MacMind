"""
Calculator routes blueprint
Handles case saving and retrieval
"""
from flask import Blueprint, request, jsonify
import json as json_lib
from app import db
from app.models.case import Case

# Create blueprint for calculator routes
calculator_bp = Blueprint('calculator', __name__)


@calculator_bp.route('/cases', methods=['POST'])
def save_case():
    """
    Save a patient case to database
    
    Request body:
        {
            "patient_name": "John Doe",
            "patient_id": "P12345",
            "date": "2026-04-22",
            "surgery_type": "General Anesthesia",
            "anesthetic_agent": "Sevoflurane",
            "molecular_mass": "200.05",
            "vapor_constant": "184",
            "density": "1.52"
        }
    
    Returns:
        201: Case saved successfully
        400: Invalid parameters or missing fields
        500: Database error
    """
    try:
        data = request.get_json() or {}

        # Validate required fields
        required_fields = [
            'patient_name', 'patient_id', 'date', 'surgery_type',
            'anesthetic_agent', 'molecular_mass', 'vapor_constant', 'density'
        ]
        
        for field in required_fields:
            if field not in data:
                return jsonify({"message": f"Missing field: {field}"}), 400

        print(f"💾 Saving case: {data['patient_name']} ({data['patient_id']})")
        new_case = Case(
            patient_name=data['patient_name'],
            patient_id=data['patient_id'],
            date=data['date'],
            surgery_type=data['surgery_type'],
            anesthetic_agent=data['anesthetic_agent'],
            molecular_mass=data['molecular_mass'],
            vapor_constant=data['vapor_constant'],
            density=data['density'],
            fresh_gas_flow=data.get('fresh_gas_flow'),
            dial_concentration=data.get('dial_concentration'),
            time_minutes=data.get('time_minutes'),
            initial_weight=data.get('initial_weight'),
            final_weight=data.get('final_weight'),
            notes=data.get('notes'),
            biro_formula=data.get('biro_formula'),
            dion_formula=data.get('dion_formula'),
            weight_based=data.get('weight_based'),
            induction_fgf=data.get('induction_fgf'),
            induction_concentration=data.get('induction_concentration'),
            induction_time=data.get('induction_time'),
            induction_biro=data.get('induction_biro'),
            induction_dion=data.get('induction_dion'),
            final_biro=data.get('final_biro'),
            final_dion=data.get('final_dion'),
            maintenance_rows=json_lib.dumps(data.get('maintenance_rows', [])),
            maintenance_calculations=json_lib.dumps(data.get('maintenance_calculations', [])),
        )

        db.session.add(new_case)
        db.session.commit()

        case_id = new_case.id
        print(f"✅ Case saved with ID: {case_id}")

        return jsonify({
            "success": True,
            "message": "Case saved successfully",
            "case": {
                "id": case_id,
                "patient_name": data['patient_name'],
                "patient_id": data['patient_id'],
                "date": data['date']
            }
        }), 201

    except Exception as e:
        db.session.rollback()
        print(f"❌ Error saving case: {str(e)}")
        return jsonify({"message": f"Error: {str(e)}"}), 500


@calculator_bp.route('/cases', methods=['GET'])
def get_cases():
    """
    Fetch all saved patient cases from database
    
    Returns:
        200: List of all cases ordered by latest first
        500: Database error
    """
    try:
        print("📋 Fetching all cases...")
        cases = Case.query.order_by(Case.created_at.desc()).all()
        cases_data = [c.to_dict() for c in cases]

        print(f"✅ Retrieved {len(cases_data)} cases")

        return jsonify({
            "success": True,
            "message": "Cases retrieved successfully",
            "cases": cases_data,
            "count": len(cases_data)
        }), 200

    except Exception as e:
        print(f"❌ Error fetching cases: {str(e)}")
        return jsonify({
            "success": False,
            "message": f"Error: {str(e)}",
            "cases": []
        }), 500


@calculator_bp.route('/cases/<int:case_id>', methods=['GET'])
def get_case(case_id):
    """
    Fetch a specific case by ID
    
    Args:
        case_id: Case ID (path parameter)
    
    Returns:
        200: Case details
        404: Case not found
        500: Database error
    """
    try:
        print(f"🔍 Fetching case {case_id}...")
        case = Case.query.filter_by(id=case_id).first()

        if case:
            print(f"✅ Case {case_id} found")
            return jsonify({
                "success": True,
                "message": "Case retrieved successfully",
                "case": case.to_dict()
            }), 200
        else:
            print(f"❌ Case {case_id} not found")
            return jsonify({
                "success": False,
                "message": "Case not found"
            }), 404

    except Exception as e:
        print(f"❌ Error fetching case: {str(e)}")
        return jsonify({
            "success": False,
            "message": f"Error: {str(e)}"
        }), 500


@calculator_bp.route('/cases/<int:case_id>', methods=['PUT', 'PATCH'])
def update_case(case_id):
    """
    Update an existing case by ID

    Expects JSON body with fields to update. Fields not provided will keep previous values.
    Returns:
        200: Case updated successfully
        404: Case not found
        500: Database error
    """
    try:
        print(f"✏️ Update request received for case {case_id} - method={request.method}")
        data = request.get_json() or {}

        existing = Case.query.filter_by(id=case_id).first()
        if not existing:
            print(f"❌ Case {case_id} not found for update")
            return jsonify({"success": False, "message": "Case not found"}), 404

        # Update only provided fields
        field_map = {
            'patient_name': 'patient_name',
            'patient_id': 'patient_id',
            'date': 'date',
            'surgery_type': 'surgery_type',
            'anesthetic_agent': 'anesthetic_agent',
            'molecular_mass': 'molecular_mass',
            'vapor_constant': 'vapor_constant',
            'density': 'density',
            'fresh_gas_flow': 'fresh_gas_flow',
            'dial_concentration': 'dial_concentration',
            'time_minutes': 'time_minutes',
            'initial_weight': 'initial_weight',
            'final_weight': 'final_weight',
            'notes': 'notes',
            'biro_formula': 'biro_formula',
            'dion_formula': 'dion_formula',
            'weight_based': 'weight_based',
            'induction_fgf': 'induction_fgf',
            'induction_concentration': 'induction_concentration',
            'induction_time': 'induction_time',
            'induction_biro': 'induction_biro',
            'induction_dion': 'induction_dion',
            'final_biro': 'final_biro',
            'final_dion': 'final_dion',
        }

        for payload_key, model_attr in field_map.items():
            if payload_key in data:
                setattr(existing, model_attr, data[payload_key])

        if 'maintenance_rows' in data:
            existing.maintenance_rows = json_lib.dumps(data.get('maintenance_rows') or [])

        if 'maintenance_calculations' in data:
            existing.maintenance_calculations = json_lib.dumps(data.get('maintenance_calculations') or [])

        print(f"📤 Executing update for case {case_id}")
        db.session.commit()

        print(f"✅ Case {case_id} updated successfully")
        return jsonify({"success": True, "message": "Case updated successfully", "case": {"id": case_id}}), 200

    except Exception as e:
        db.session.rollback()
        print(f"❌ Error updating case: {str(e)}")
        return jsonify({"success": False, "message": f"Error: {str(e)}"}), 500


@calculator_bp.route('/cases/<int:case_id>', methods=['DELETE'])
def delete_case(case_id):
    """
    Delete a patient case
    
    Args:
        case_id: Case ID (path parameter)
    
    Returns:
        200: Case deleted successfully
        404: Case not found
        500: Database error
    """
    try:
        print(f"🗑️  Deleting case {case_id}...")
        case = Case.query.filter_by(id=case_id).first()

        if case:
            db.session.delete(case)
            db.session.commit()
            print(f"✅ Case {case_id} deleted")
            return jsonify({
                "success": True,
                "message": "Case deleted successfully"
            }), 200
        else:
            print(f"❌ Case {case_id} not found")
            return jsonify({
                "success": False,
                "message": "Case not found"
            }), 404

    except Exception as e:
        db.session.rollback()
        print(f"❌ Error deleting case: {str(e)}")
        return jsonify({
            "success": False,
            "message": f"Error: {str(e)}"
        }), 500
