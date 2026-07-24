import 'package:flutter/foundation.dart';

/// Platform-aware API configuration
/// Handles different base URLs for development (localhost/Wi-Fi IP) and production (Render)
class ApiConfig {
  // Production backend on Render
  //static const String productionBaseUrl = "https://med-calci-backend.onrender.com";
  // Local backend (optional, opt-in)
  // Enable with: `--dart-define=USE_LOCAL_API=true`
  // Override URL with: `--dart-define=LOCAL_API_URL=http://180.235.121.253:8190`
  // static const bool useLocalApi = bool.fromEnvironment(
  //   'USE_LOCAL_API',
  //   defaultValue: true,
  // );
  // static const String localApiUrl = String.fromEnvironment(
  //   'LOCAL_API_URL',
  //   defaultValue: 'http://180.235.121.253:8190',
  // );

  /// Base URL (hardcoded to production for APKs)
  static const String baseUrl = "http://180.235.121.253:8190";

  /// Groq Whisper API Configuration
  static const String groqApiUrl = "https://api.groq.com/openai/v1/audio/transcriptions";
  static const String groqModel = "whisper-large-v3";
  
  /// Get Groq API Key from environment
  /// Store this securely - for production, fetch from secure backend endpoint
  /// For development, use a .env file and load with flutter_dotenv
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// Get server host for configuration purposes
  // static String get serverHost {
  //   return baseUrl.contains("localhost") || baseUrl.contains("127.0.0.1")
  //       ? "localhost"
  //       : baseUrl.replaceAll("http://", "").replaceAll("https://", "").split(":")[0];
  // }

  /// Get server port
  // static int get serverPort {
  //   final urlPort = baseUrl.split(":").last;
  //   return int.tryParse(urlPort.split("/").first) ?? 5000;
  // }

  /// Update this method to configure for your environment
//   static void configure({String? customBaseUrl}) {
//     if (customBaseUrl != null) {
//       assert(
//         customBaseUrl.startsWith("http://") || customBaseUrl.startsWith("https://"),
//         "Base URL must start with http:// or https://",
//       );
//     }
//   }
// }
}
