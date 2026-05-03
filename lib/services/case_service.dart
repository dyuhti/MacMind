import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'auth_service.dart';

class CaseService {
  /// Save a patient case to backend
  /// 
  /// Parameters:
  ///   - patientName: Name of the patient
  ///   - patientId: Patient ID
  ///   - date: Date of case (YYYY-MM-DD)
  ///   - surgeryType: Type of surgery
  ///   - anestheticAgent: Anesthetic agent used
  ///   - molecularMass: Molecular mass value
  ///   - vaporConstant: Vapor constant value
  ///   - density: Density value
  ///   - Optional calculation and phase fields for detailed history storage
  /// 
  /// Returns: {success: true/false, error?: string}
  static Future<Map<String, dynamic>> saveCase({
    required String patientName,
    required String patientId,
    required String date,
    required String surgeryType,
    required String anestheticAgent,
    required String molecularMass,
    required String vaporConstant,
    required String density,
    double? freshGasFlow,
    double? dialConcentration,
    double? timeMinutes,
    double? initialWeight,
    double? finalWeight,
    double? biroFormula,
    double? dionFormula,
    double? weightBased,
    String? notes,
    double? inductionFGF,
    double? inductionConcentration,
    double? inductionTime,
    double? inductionBiro,
    double? inductionDion,
    double? finalBiro,
    double? finalDion,
    List<Map<String, dynamic>>? maintenanceRows,
    List<Map<String, dynamic>>? maintenanceCalculations,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/calculator/cases');

      print('📝 Save Case Request: $url');
      print('👤 Patient Name: $patientName');
      print('🆔 Patient ID: $patientId');
      print('📅 Date: $date');

      final requestBody = {
        'patient_name': patientName,
        'patient_id': patientId,
        'date': date,
        'surgery_type': surgeryType,
        'anesthetic_agent': anestheticAgent,
        'molecular_mass': molecularMass,
        'vapor_constant': vaporConstant,
        'density': density,
        // Add all optional calculation fields
        if (freshGasFlow != null) 'fresh_gas_flow': freshGasFlow,
        if (dialConcentration != null) 'dial_concentration': dialConcentration,
        if (timeMinutes != null) 'time_minutes': timeMinutes,
        if (initialWeight != null) 'initial_weight': initialWeight,
        if (finalWeight != null) 'final_weight': finalWeight,
        // Also include nested weight object for compatibility
        if (initialWeight != null || finalWeight != null)
          'weight': {
            if (initialWeight != null) 'initialWeight': initialWeight,
            if (finalWeight != null) 'finalWeight': finalWeight,
          },
        if (biroFormula != null) 'biro_formula': biroFormula,
        if (dionFormula != null) 'dion_formula': dionFormula,
        if (weightBased != null) 'weight_based': weightBased,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (inductionFGF != null) 'induction_fgf': inductionFGF,
        if (inductionConcentration != null) 'induction_concentration': inductionConcentration,
        if (inductionTime != null) 'induction_time': inductionTime,
        if (inductionBiro != null) 'induction_biro': inductionBiro,
        if (inductionDion != null) 'induction_dion': inductionDion,
        if (finalBiro != null) 'final_biro': finalBiro,
        if (finalDion != null) 'final_dion': finalDion,
        if (maintenanceRows != null) 'maintenance_rows': maintenanceRows,
        if (maintenanceCalculations != null) 'maintenance_calculations': maintenanceCalculations,
      };

      print('📤 Request Body: ${jsonEncode(requestBody)}');

      // Attach auth token if available (prevents backend sending HTML login pages)
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📩 Save Case Response Status: ${response.statusCode}');
      print('📩 Save Case Response Body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Case saved successfully',
            'caseId': jsonResponse['case']?['id'],
          };
        } catch (e) {
          // Backend returned 201 but non-JSON body (rare) — return success with raw body
          print('⚠️ Save case: 201 but invalid JSON response: $e');
          return {
            'success': true,
            'message': 'Case saved (non-JSON response)',
            'caseId': null,
            'rawBody': response.body,
          };
        }
      } else {
        // Avoid jsonDecode on error pages that may be HTML — include raw body in error
        print('❌ Save failed with status ${response.statusCode}. Body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        String errMsg = 'Failed to save case (status ${response.statusCode})';
        try {
          final jsonResponse = jsonDecode(response.body);
          errMsg = jsonResponse['message']?.toString() ?? errMsg;
        } catch (_) {
          // If response is HTML, include first chars for debugging
          errMsg = 'Server error: ${response.body}';
        }
        return {
          'success': false,
          'error': errMsg,
        };
      }
    } catch (e) {
      print('❌ Error saving case: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Fetch all saved patient cases from backend
  /// 
  /// Returns: {success: true/false, cases: [...], error?: string}
  static Future<Map<String, dynamic>> getAllCases() async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/calculator/cases');

      print('📋 Fetch Cases Request: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📩 Fetch Cases Response Status: ${response.statusCode}');
      print('📩 Fetch Cases Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final cases = jsonResponse['cases'] ?? [];
        return {
          'success': true,
          'cases': cases,
          'count': cases.length,
          'message': jsonResponse['message'] ?? 'Cases retrieved successfully',
        };
      } else {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': false,
          'cases': [],
          'error': jsonResponse['message'] ?? 'Failed to fetch cases',
        };
      }
    } catch (e) {
      print('❌ Error fetching cases: $e');
      return {
        'success': false,
        'cases': [],
        'error': 'Network error: $e',
      };
    }
  }

  /// Fetch a specific case by ID
  /// 
  /// Parameters:
  ///   - caseId: The case ID to fetch
  /// 
  /// Returns: {success: true/false, case?: {...}, error?: string}
  static Future<Map<String, dynamic>> getCaseById(int caseId) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/calculator/cases/$caseId');

      print('🔍 Fetch Case Request: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📩 Fetch Case Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'case': jsonResponse['case'],
        };
      } else {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': false,
          'error': jsonResponse['message'] ?? 'Case not found',
        };
      }
    } catch (e) {
      print('❌ Error fetching case: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Update an existing case by ID
  /// 
  /// Parameters:
  ///   - caseId: The case ID to update
  ///   - patientName, patientId, date, surgeryType, anestheticAgent, etc.
  /// 
  /// Returns: {success: true/false, error?: string}
  static Future<Map<String, dynamic>> updateCase({
    required String caseId,
    required String patientName,
    required String patientId,
    required String date,
    required String surgeryType,
    required String anestheticAgent,
    required String molecularMass,
    required String vaporConstant,
    required String density,
    double? freshGasFlow,
    double? dialConcentration,
    double? timeMinutes,
    double? initialWeight,
    double? finalWeight,
    double? biroFormula,
    double? dionFormula,
    double? weightBased,
    String? notes,
    double? inductionFGF,
    double? inductionConcentration,
    double? inductionTime,
    double? inductionBiro,
    double? inductionDion,
    double? finalBiro,
    double? finalDion,
    List<Map<String, dynamic>>? maintenanceRows,
    List<Map<String, dynamic>>? maintenanceCalculations,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/calculator/cases/$caseId');

      print('✏️ Update Case Request: $url');
      print('🆔 Case ID: $caseId');

      final requestBody = {
        'patient_name': patientName,
        'patient_id': patientId,
        'date': date,
        'surgery_type': surgeryType,
        'anesthetic_agent': anestheticAgent,
        'molecular_mass': molecularMass,
        'vapor_constant': vaporConstant,
        'density': density,
        if (freshGasFlow != null) 'fresh_gas_flow': freshGasFlow,
        if (dialConcentration != null) 'dial_concentration': dialConcentration,
        if (timeMinutes != null) 'time_minutes': timeMinutes,
        if (initialWeight != null) 'initial_weight': initialWeight,
        if (finalWeight != null) 'final_weight': finalWeight,
        // Also include nested weight object for compatibility
        if (initialWeight != null || finalWeight != null)
          'weight': {
            if (initialWeight != null) 'initialWeight': initialWeight,
            if (finalWeight != null) 'finalWeight': finalWeight,
          },
        if (biroFormula != null) 'biro_formula': biroFormula,
        if (dionFormula != null) 'dion_formula': dionFormula,
        if (weightBased != null) 'weight_based': weightBased,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (inductionFGF != null) 'induction_fgf': inductionFGF,
        if (inductionConcentration != null) 'induction_concentration': inductionConcentration,
        if (inductionTime != null) 'induction_time': inductionTime,
        if (inductionBiro != null) 'induction_biro': inductionBiro,
        if (inductionDion != null) 'induction_dion': inductionDion,
        if (finalBiro != null) 'final_biro': finalBiro,
        if (finalDion != null) 'final_dion': finalDion,
        if (maintenanceRows != null) 'maintenance_rows': maintenanceRows,
        if (maintenanceCalculations != null) 'maintenance_calculations': maintenanceCalculations,
      };

      print('📤 Update Request Body: ${jsonEncode(requestBody)}');

      // Attach auth token if available
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📩 Update Case Response Status: ${response.statusCode}');
      print('📩 Update Case Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Case updated successfully',
            'caseId': jsonResponse['case']?['id'],
          };
        } catch (e) {
          // 200 but body not JSON — backend may be misconfigured; return success with raw body
          print('⚠️ Update case: 200 but invalid JSON response: $e');
          return {
            'success': true,
            'message': 'Case updated (non-JSON response)',
            'caseId': null,
            'rawBody': response.body,
          };
        }
      } else {
        // Log and return raw body for debugging (may be HTML login page)
        print('❌ Update failed with status ${response.statusCode}. Body begins: ${response.body.length > 200 ? response.body.substring(0,200) : response.body}');
        String errMsg = 'Failed to update case (status ${response.statusCode})';
        try {
          final jsonResponse = jsonDecode(response.body);
          errMsg = jsonResponse['message']?.toString() ?? errMsg;
        } catch (_) {
          // Non-JSON body (HTML) — include raw body for debugging
          errMsg = 'Server error: ${response.body}';
        }
        return {
          'success': false,
          'error': errMsg,
        };
      }
    } catch (e) {
      print('❌ Error updating case: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Delete a case by ID
  /// 
  /// Parameters:
  ///   - caseId: The case ID to delete
  /// 
  /// Returns: {success: true/false, error?: string}
  static Future<Map<String, dynamic>> deleteCase(int caseId) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/calculator/cases/$caseId');

      print('🗑️ Delete Case Request: $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📩 Delete Case Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Case deleted successfully',
        };
      } else {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': false,
          'error': jsonResponse['message'] ?? 'Failed to delete case',
        };
      }
    } catch (e) {
      print('❌ Error deleting case: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
