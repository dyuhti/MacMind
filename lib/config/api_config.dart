import 'package:flutter/foundation.dart';

/// Platform-aware API configuration
/// Handles different base URLs for development (localhost/Wi-Fi IP) and production (Render)
class ApiConfig {
  // Production backend on Render
  static const String productionBaseUrl = "https://med-calci-backend.onrender.com";
  // Local backend (optional, opt-in)
  // Enable with: `--dart-define=USE_LOCAL_API=true`
  // Override URL with: `--dart-define=LOCAL_API_URL=http://10.0.2.2:5000`
  static const bool useLocalApi = bool.fromEnvironment(
    'USE_LOCAL_API',
    defaultValue: false,
  );
  static const String localApiUrl = String.fromEnvironment(
    'LOCAL_API_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  /// Get the appropriate base URL based on platform and build type
  static String get baseUrl {
    // Default to production to avoid accidental breakage.
    if (kReleaseMode || !useLocalApi || kIsWeb) {
      return productionBaseUrl;
    }
    return localApiUrl;
  }

  /// Get server host for configuration purposes
  static String get serverHost {
    return baseUrl.contains("localhost") || baseUrl.contains("127.0.0.1")
        ? "localhost"
        : baseUrl.replaceAll("http://", "").replaceAll("https://", "").split(":")[0];
  }

  /// Get server port
  static int get serverPort {
    final urlPort = baseUrl.split(":").last;
    return int.tryParse(urlPort.split("/").first) ?? 5000;
  }

  /// Update this method to configure for your environment
  static void configure({String? customBaseUrl}) {
    if (customBaseUrl != null) {
      assert(
        customBaseUrl.startsWith("http://") || customBaseUrl.startsWith("https://"),
        "Base URL must start with http:// or https://",
      );
    }
  }
}
