"""
Calculator routes blueprint
Handles case saving and retrieval
"""
from flask import Blueprint, request, jsonify
import mysql.connector
from config.config import Config

# Create blueprint for calculator routes
calculator_bp = Blueprint('calculator', __name__)


def get_db_connection():
    """
    Get a connection to the MySQL database
    
    Returns:
        MySQL connection object
    """
    try:
        conn = mysql.connector.connect(
            host=Config.MYSQL_HOST,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DB
        )
        return conn
    except mysql.connector.Error as err:
        print(f"❌ Database connection error: {err}")
        raise


@calculator_bp.route('/cases', methods=['POST'])
def save_case():
    """
    Save a patient case to MySQL database
    
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
        data = request.json

        # Validate required fields
        required_fields = [
            'patient_name', 'patient_id', 'date', 'surgery_type',
            'anesthetic_agent', 'molecular_mass', 'vapor_constant', 'density'
        ]
        
        for field in required_fields:
            if field not in data:
                return jsonify({"message": f"Missing field: {field}"}), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        # Build query with all columns
        query = """
        INSERT INTO cases (
            patient_name, patient_id, date, surgery_type, anesthetic_agent,
            molecular_mass, vapor_constant, density,
            fresh_gas_flow, dial_concentration, time,
            initial_weight, final_weight, notes,
            biro_formula, dion_formula, weight_based,
            induction_fgf, induction_concentration, induction_time,
            induction_biro, induction_dion, final_biro, final_dion,
            maintenance_rows, maintenance_calculations
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        import json as json_lib
        values = (
            data['patient_name'],
            data['patient_id'],
            data['date'],
            data['surgery_type'],
            data['anesthetic_agent'],
            data['molecular_mass'],
            data['vapor_constant'],
            data['density'],
            data.get('fresh_gas_flow'),
            data.get('dial_concentration'),
            data.get('time_minutes'),  # Map to time column
            data.get('initial_weight'),
            data.get('final_weight'),
            data.get('notes'),
            data.get('biro_formula'),
            data.get('dion_formula'),
            data.get('weight_based'),
            data.get('induction_fgf'),
            data.get('induction_concentration'),
            data.get('induction_time'),
            data.get('induction_biro'),
            data.get('induction_dion'),
            data.get('final_biro'),
            data.get('final_dion'),
            json_lib.dumps(data.get('maintenance_rows', [])) if data.get('maintenance_rows') else None,
            json_lib.dumps(data.get('maintenance_calculations', [])) if data.get('maintenance_calculations') else None,
        )

        print(f"💾 Saving case: {data['patient_name']} ({data['patient_id']})")
        cursor.execute(query, values)
        conn.commit()

        case_id = cursor.lastrowid
        print(f"✅ Case saved with ID: {case_id}")

        cursor.close()
        conn.close()

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

    except mysql.connector.Error as err:
        print(f"❌ Database error: {err}")
        return jsonify({"message": f"Database error: {err}"}), 500
    except Exception as e:
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
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        query = "SELECT * FROM cases ORDER BY created_at DESC"
        
        print("📋 Fetching all cases...")
        cursor.execute(query)
        cases = cursor.fetchall()

        cursor.close()
        conn.close()

        print(f"✅ Retrieved {len(cases)} cases")

        return jsonify({
            "success": True,
            "message": "Cases retrieved successfully",
            "cases": cases,
            "count": len(cases)
        }), 200

    except mysql.connector.Error as err:
        print(f"❌ Database error: {err}")
        return jsonify({
            "success": False,
            "message": f"Database error: {err}",
            "cases": []
        }), 500
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
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        query = "SELECT * FROM cases WHERE id = %s"
        
        print(f"🔍 Fetching case {case_id}...")
        cursor.execute(query, (case_id,))
        case = cursor.fetchone()

        cursor.close()
        conn.close()

        if case:
            print(f"✅ Case {case_id} found")
            return jsonify({
                "success": True,
                "message": "Case retrieved successfully",
                "case": case
            }), 200
        else:
            print(f"❌ Case {case_id} not found")
            return jsonify({
                "success": False,
                "message": "Case not found"
            }), 404

    except mysql.connector.Error as err:
        print(f"❌ Database error: {err}")
        return jsonify({
            "success": False,
            "message": f"Database error: {err}"
        }), 500
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
        data = request.json or {}

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # Ensure the case exists
        cursor.execute("SELECT * FROM cases WHERE id = %s", (case_id,))
        existing = cursor.fetchone()
        if not existing:
            cursor.close()
            conn.close()
            print(f"❌ Case {case_id} not found for update")
            return jsonify({"success": False, "message": "Case not found"}), 404

        import json as json_lib

        # Build values using provided data or fall back to existing
        updated_values = (
            data.get('patient_name', existing.get('patient_name')),
            data.get('patient_id', existing.get('patient_id')),
            data.get('date', existing.get('date')),
            data.get('surgery_type', existing.get('surgery_type')),
            data.get('anesthetic_agent', existing.get('anesthetic_agent')),
            data.get('molecular_mass', existing.get('molecular_mass')),
            data.get('vapor_constant', existing.get('vapor_constant')),
            data.get('density', existing.get('density')),
            data.get('fresh_gas_flow', existing.get('fresh_gas_flow')),
            data.get('dial_concentration', existing.get('dial_concentration')),
            data.get('time_minutes', existing.get('time')),
            data.get('initial_weight', existing.get('initial_weight')),
            data.get('final_weight', existing.get('final_weight')),
            data.get('notes', existing.get('notes')),
            data.get('biro_formula', existing.get('biro_formula')),
            data.get('dion_formula', existing.get('dion_formula')),
            data.get('weight_based', existing.get('weight_based')),
            data.get('induction_fgf', existing.get('induction_fgf')),
            data.get('induction_concentration', existing.get('induction_concentration')),
            data.get('induction_time', existing.get('induction_time')),
            data.get('induction_biro', existing.get('induction_biro')),
            data.get('induction_dion', existing.get('induction_dion')),
            data.get('final_biro', existing.get('final_biro')),
            data.get('final_dion', existing.get('final_dion')),
            # maintenance rows/calculations stored as JSON strings in DB
            json_lib.dumps(data.get('maintenance_rows')) if data.get('maintenance_rows') is not None else existing.get('maintenance_rows'),
            json_lib.dumps(data.get('maintenance_calculations')) if data.get('maintenance_calculations') is not None else existing.get('maintenance_calculations'),
        )

        update_query = """
        UPDATE cases SET
            patient_name = %s,
            patient_id = %s,
            date = %s,
            surgery_type = %s,
            anesthetic_agent = %s,
            molecular_mass = %s,
            vapor_constant = %s,
            density = %s,
            fresh_gas_flow = %s,
            dial_concentration = %s,
            `time` = %s,
            initial_weight = %s,
            final_weight = %s,
            notes = %s,
            biro_formula = %s,
            dion_formula = %s,
            weight_based = %s,
            induction_fgf = %s,
            induction_concentration = %s,
            induction_time = %s,
            induction_biro = %s,
            induction_dion = %s,
            final_biro = %s,
            final_dion = %s,
            maintenance_rows = %s,
            maintenance_calculations = %s
        WHERE id = %s
        """

        # Append case_id to values
        exec_values = updated_values + (case_id,)

        print(f"📤 Executing update for case {case_id}")
        cursor.execute(update_query, exec_values)
        conn.commit()

        cursor.close()
        conn.close()

        print(f"✅ Case {case_id} updated successfully")
        return jsonify({"success": True, "message": "Case updated successfully", "case": {"id": case_id}}), 200

    except mysql.connector.Error as err:
        print(f"❌ Database error updating case: {err}")
        return jsonify({"success": False, "message": f"Database error: {err}"}), 500
    except Exception as e:
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
        conn = get_db_connection()
        cursor = conn.cursor()

        query = "DELETE FROM cases WHERE id = %s"
        
        print(f"🗑️  Deleting case {case_id}...")
        cursor.execute(query, (case_id,))
        conn.commit()

        if cursor.rowcount > 0:
            print(f"✅ Case {case_id} deleted")
            cursor.close()
            conn.close()
            return jsonify({
                "success": True,
                "message": "Case deleted successfully"
            }), 200
        else:
            print(f"❌ Case {case_id} not found")
            cursor.close()
            conn.close()
            return jsonify({
                "success": False,
                "message": "Case not found"
            }), 404

    except mysql.connector.Error as err:
        print(f"❌ Database error: {err}")
        return jsonify({
            "success": False,
            "message": f"Database error: {err}"
        }), 500
    except Exception as e:
        print(f"❌ Error deleting case: {str(e)}")
        return jsonify({
            "success": False,
            "message": f"Error: {str(e)}"
        }), 500
