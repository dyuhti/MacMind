"""
Cases routes blueprint
Handles patient case data management
"""
from flask import Blueprint, request, jsonify
from app.utils.decorators import require_json, validate_fields
from app.models.case import Case

# Create blueprint for cases routes
cases_bp = Blueprint('cases', __name__)


@cases_bp.route('', methods=['POST'])
@require_json
@validate_fields(['patient_name', 'patient_id', 'date', 'surgery_type', 
                  'anesthetic_agent', 'molecular_mass', 'vapor_constant', 'density'])
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
            "molecular_mass": "200.5",
            "vapor_constant": "45.8",
            "density": "1.52"
        }
    
    Returns:
        201: Case saved successfully
        400: Invalid parameters or missing fields
        500: Database error
    """
    try:
        data = request.get_json()
        
        # Create new case
        result = Case.create(
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
            biro_formula=data.get('biro_formula'),
            dion_formula=data.get('dion_formula'),
            weight_based=data.get('weight_based'),
            notes=data.get('notes'),
            induction_fgf=data.get('induction_fgf'),
            induction_concentration=data.get('induction_concentration'),
            induction_time=data.get('induction_time'),
            induction_biro=data.get('induction_biro'),
            induction_dion=data.get('induction_dion'),
            final_biro=data.get('final_biro'),
            final_dion=data.get('final_dion'),
            maintenance_rows=data.get('maintenance_rows'),
            maintenance_calculations=data.get('maintenance_calculations')
        )
        
        if result['success']:
            return {
                'success': True,
                'message': 'Case saved successfully',
                'case': result
            }, 201
        else:
            return {
                'success': False,
                'message': result['error']
            }, 400
    
    except Exception as e:
        return {
            'success': False,
            'message': f'Error saving case: {str(e)}'
        }, 500


@cases_bp.route('', methods=['GET'])
def get_cases():
    """
    Fetch all saved patient cases
    
    Returns:
        200: List of all cases ordered by latest first
        500: Database error
    """
    try:
        result = Case.get_all()
        
        if result['success']:
            return {
                'success': True,
                'message': 'Cases retrieved successfully',
                'cases': result['cases'],
                'count': result['count']
            }, 200
        else:
            return {
                'success': False,
                'message': result['error'],
                'cases': []
            }, 400
    
    except Exception as e:
        return {
            'success': False,
            'message': f'Error fetching cases: {str(e)}',
            'cases': []
        }, 500


@cases_bp.route('/<int:case_id>', methods=['GET'])
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
        result = Case.get_by_id(case_id)
        
        if result['success']:
            return {
                'success': True,
                'message': 'Case retrieved successfully',
                'case': result['case']
            }, 200
        else:
            return {
                'success': False,
                'message': result['error']
            }, 404
    
    except Exception as e:
        return {
            'success': False,
            'message': f'Error fetching case: {str(e)}'
        }, 500


@cases_bp.route('/<int:case_id>', methods=['DELETE'])
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
        result = Case.delete(case_id)
        
        if result['success']:
            return {
                'success': True,
                'message': result['message']
            }, 200
        else:
            return {
                'success': False,
                'message': result['error']
            }, 404
    
    except Exception as e:
        return {
            'success': False,
            'message': f'Error deleting case: {str(e)}'
        }, 500
