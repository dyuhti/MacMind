import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AgentConstantsService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getAllAgents() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/agent-constants"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((agent) => agent as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception("Failed to fetch agents: $e");
    }
  }

  static Future<Map<String, dynamic>?> getAgentByName(String agentName) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/agent-constants/$agentName"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception("Failed to fetch agent");
      }
    } catch (e) {
      throw Exception("Failed to fetch agent: $e");
    }
  }
}
