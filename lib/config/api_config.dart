/// Platform-aware API configuration
/// Handles different base URLs for development (localhost/Wi-Fi IP) and production (Render)
class ApiConfig {
  // Production backend on Render
  static const String productionBaseUrl = "https://med-calci-backend-new.onrender.com";
  // Local backend (optional, opt-in)
  // Enable with: `--dart-define=USE_LOCAL_API=true`
  // Override URL with: `--dart-define=LOCAL_API_URL=http://180.235.121.253:8150`
  // static const bool useLocalApi = bool.fromEnvironment(
  //   'USE_LOCAL_API',
  //   defaultValue: true,
  // );
  // static const String localApiUrl = String.fromEnvironment(
  //   'LOCAL_API_URL',
  //   defaultValue: 'http://180.235.121.253:8150',
  // );

  /// Base URL (hardcoded to production for APKs)
  static const String baseUrl = productionBaseUrl;
}
