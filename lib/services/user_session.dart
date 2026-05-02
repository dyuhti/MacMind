/// Global user session class to maintain user data across the app
/// Stores user information from successful login/register
class UserSession {
  static String? name;
  static String? email;

  /// Reset session (used during logout)
  static void clear() {
    name = null;
    email = null;
  }

  /// Check if user session is active
  static bool isActive() {
    return name != null && name!.isNotEmpty;
  }
}
