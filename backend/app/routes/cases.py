"""
Cases routes blueprint
Handles patient case data management
"""
from flask import Blueprint, request, jsonify
from app.utils.decorators import require_json, validate_fields, require_token
from app.models.case import Case

# Create blueprint for cases routes
cases_bp = Blueprint('cases', __name__)


@cases_bp.route('', methods=['POST'])
@require_json
@require_token
@validate_fields(['patient_name', 'patient_id', 'date', 'surgery_type', 
                  'anesthetic_agent', 'molecular_mass', 'vapor_constant', 'density'])
def save_case(current_user):
    """
    Save a patient case to database
    
    Requires JWT authentication. Case is automatically associated with logged-in user.
    
    Request headers:
        Authorization: Bearer <jwt_token>
    
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
        401: Unauthorized (missing/invalid token)
        500: Database error
    """
    try:
        data = request.get_json()
        
        # Extract user_id from authenticated user
        user_id = int(current_user.get('user_id'))
        
        # Create new case with user association
        result = Case.create(
            user_id=user_id,
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
@require_token
def get_cases(current_user):
    """
    Fetch all saved patient cases for the authenticated user
    
    Requires JWT authentication. Returns only cases belonging to the logged-in user.
    
    Request headers:
        Authorization: Bearer <jwt_token>
    
    Returns:
        200: List of user's cases ordered by latest first
        401: Unauthorized (missing/invalid token)
        500: Database error
    """
    try:
        # Extract user_id from authenticated user
        user_id = int(current_user.get('user_id'))
        
        # Fetch only cases for this user
        result = Case.get_all(user_id=user_id)
        
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
@require_token
def get_case(case_id, current_user):
    """
    Fetch a specific case by ID
    
    Requires JWT authentication. User can only access their own cases.
    
    Args:
        case_id: Case ID (path parameter)
    
    Request headers:
        Authorization: Bearer <jwt_token>
    
    Returns:
        200: Case details
        401: Unauthorized (missing/invalid token)
        403: Forbidden (case belongs to different user)
        404: Case not found
        500: Database error
    """
    try:
        # Extract user_id from authenticated user
        user_id = int(current_user.get('user_id'))
        
        # Fetch case with ownership check
        result = Case.get_by_id(case_id, user_id=user_id)
        
        if result['success']:
            return {
                'success': True,
                'message': 'Case retrieved successfully',
                'case': result['case']
            }, 200
        else:
            # Check if error is due to unauthorized access
            if 'Unauthorized' in result['error']:
                return {
                    'success': False,
                    'message': result['error']
                }, 403
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


@cases_bp.route('/<int:case_id>', methods=['PUT'])
@require_token
@require_json
def update_case(case_id, current_user):
    """
    Update a specific case by ID
    
    Requires JWT authentication. User can only update their own cases.
    
    Args:
        case_id: Case ID (path parameter)
    
    Request headers:
        Authorization: Bearer <jwt_token>
        Content-Type: application/json
    
    Request body:
        {
            "patient_name": "Updated Name",
            "biro_formula": 45.5,
            ... (any other fields to update)
        }
    
    Returns:
        200: Case updated successfully
        400: Invalid parameters
        401: Unauthorized (missing/invalid token)
        403: Forbidden (case belongs to different user)
        404: Case not found
        500: Database error
    """
    try:
        data = request.get_json()
        
        # Extract user_id from authenticated user
        user_id = int(current_user.get('user_id'))
        
        # Update case with ownership check
        result = Case.update(case_id, user_id, **data)
        
        if result['success']:
            return {
                'success': True,
                'message': result['message'],
                'case': result['case']
            }, 200
        else:
            # Check if error is due to unauthorized access
            if 'Unauthorized' in result['error']:
                return {
                    'success': False,
                    'message': result['error']
                }, 403
            else:
                return {
                    'success': False,
                    'message': result['error']
                }, 404
    
    except Exception as e:
        return {
            'success': False,
            'message': f'Error updating case: {str(e)}'
        }, 500


@cases_bp.route('/<int:case_id>', methods=['DELETE'])
@require_token
def delete_case(case_id, current_user):
    """
    Delete a patient case
    
    Requires JWT authentication. User can only delete their own cases.
    
    Args:
        case_id: Case ID (path parameter)
    
    Request headers:
        Authorization: Bearer <jwt_token>
    
    Returns:
        200: Case deleted successfully
        401: Unauthorized (missing/invalid token)
        403: Forbidden (case belongs to different user)
        404: Case not found
        500: Database error
    """
    try:
        # Extract user_id from authenticated user
        user_id = int(current_user.get('user_id'))
        
        # Delete case with ownership check
        result = Case.delete(case_id, user_id=user_id)
        
        if result['success']:
            return {
                'success': True,
                'message': result['message']
            }, 200
        else:
            # Check if error is due to unauthorized access
            if 'Unauthorized' in result['error']:
                return {
                    'success': False,
                    'message': result['error']
                }, 403
            else:
                return {
                    'success': False,
                    'message': result['error']
                }, 404
        }, 500
