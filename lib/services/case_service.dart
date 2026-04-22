import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

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

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📩 Save Case Response Status: ${response.statusCode}');
      print('📩 Save Case Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Case saved successfully',
          'caseId': jsonResponse['case']?['id'],
        };
      } else {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': false,
          'error': jsonResponse['message'] ?? 'Failed to save case',
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
