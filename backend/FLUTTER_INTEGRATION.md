# 📱 Flutter Integration Guide

Complete guide to connect your Flutter app to the MacMind backend.

---

## 🔗 Backend Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/health` | GET | Check server status |
| `/api/auth/register` | POST | Create new account |
| `/api/auth/login` | POST | Login with credentials |
| `/api/auth/profile` | GET | Get user profile (requires token) |
| `/api/auth/verify-token` | POST | Verify JWT token |
| `/api/calculator/calculate` | POST | Calculate dosage |

---

## 🚀 Quick Start

### Step 1: Update `auth_service.dart`

Replace your existing auth service with this:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  // Base URL from config
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Storage keys
  static const String _tokenKey = "auth_token";
  static const String _userKey = "user_data";

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    String? hospitalId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "username": username,
          if (hospitalId != null) "hospital_id": hospitalId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Save token
        await _saveToken(data['token']);
        
        // Save user data
        await _saveUser(data['user']);
        
        return {
          "success": true,
          "message": "Registration successful",
          "user": data['user'],
          "token": data['token']
        };
      }

      // Handle errors
      final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
      return {"success": false, "error": error};
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save token
        await _saveToken(data['token']);
        
        // Save user data
        await _saveUser(data['user']);
        
        return {
          "success": true,
          "message": "Login successful",
          "user": data['user'],
          "token": data['token']
        };
      }

      // Handle authentication errors
      if (response.statusCode == 401) {
        return {
          "success": false,
          "error": "Invalid email or password"
        };
      }

      // Handle other errors
      final error = jsonDecode(response.body)['error'] ?? 'Login failed';
      return {"success": false, "error": error};
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  /// Verify token validity
  static Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/verify-token"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        return {"success": true, "valid": true};
      }

      return {"success": false, "valid": false};
    } catch (e) {
      return {"success": false, "error": "$e"};
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/auth/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "user": data['user']};
      }

      return {"success": false, "error": "Failed to fetch profile"};
    } catch (e) {
      return {"success": false, "error": "$e"};
    }
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Get saved token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get saved user data
  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Private helper: Save token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Private helper: Save user data
  static Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }
}
```

---

### Step 2: Update `api_config.dart`

```dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Production backend
  static const String productionBaseUrl = "https://med-calci-backend.onrender.com";
  
  // Local backend URLs (for development)
  static const bool useLocalApi = bool.fromEnvironment(
    'USE_LOCAL_API',
    defaultValue: false,
  );
  
  static const String localApiUrl = String.fromEnvironment(
    'LOCAL_API_URL',
    defaultValue: 'http://10.0.2.2:5000', // Android emulator
  );

  /// Get appropriate base URL
  static String get baseUrl {
    // Use local for development, production for release
    if (kReleaseMode || !useLocalApi || kIsWeb) {
      return productionBaseUrl;
    }
    return localApiUrl;
  }
}
```

---

### Step 3: Update Your Login Screen

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input_field.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    // Validate inputs
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() => errorMessage = "Please enter email and password");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Call backend login
      final result = await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (result['success']) {
        // Login successful - navigate to home
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful!')),
          );
          
          // Navigate to dashboard
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } else {
        // Login failed - show error
        setState(() => errorMessage = result['error'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Handle register button press
  Future<void> _handleRegister() async {
    // Validate inputs
    if (emailController.text.isEmpty || 
        passwordController.text.isEmpty) {
      setState(() => errorMessage = "Please enter email and password");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Call backend register
      final result = await AuthService.register(
        email: emailController.text.trim(),
        password: passwordController.text,
        username: emailController.text.split('@')[0], // Use email prefix as username
      );

      if (result['success']) {
        // Register successful - auto login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account created successfully!')),
          );
          
          // Navigate to dashboard
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } else {
        // Register failed - show error
        setState(() => errorMessage = result['error'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SizedBox(height: 50),
                
                // Title
                Text(
                  'MacMind',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                SizedBox(height: 8),
                
                Text(
                  'Medical Calculator',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 40),

                // Email Input
                CustomInputField(
                  label: 'Email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'doctor@hospital.com',
                ),
                SizedBox(height: 16),

                // Password Input
                CustomInputField(
                  label: 'Password',
                  controller: passwordController,
                  obscureText: true,
                  hintText: 'Enter password',
                ),
                SizedBox(height: 8),

                // Error Message
                if (errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                
                SizedBox(height: 24),

                // Login Button
                CustomButton(
                  label: isLoading ? 'Logging in...' : 'Login',
                  onPressed: isLoading ? null : _handleLogin,
                  isFullWidth: true,
                ),
                SizedBox(height: 12),

                // Register Button
                CustomButton(
                  label: isLoading ? 'Creating account...' : 'Create Account',
                  onPressed: isLoading ? null : _handleRegister,
                  isFullWidth: true,
                  isPrimary: false,
                ),

                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 🔌 Backend URL Configuration

### For Android Emulator

```dart
// Use this in api_config.dart
'http://10.0.2.2:5000'  // Android emulator localhost bridge
```

### For Real Device (Same Network)

```dart
// Find your PC IP:
// Windows: ipconfig (look for IPv4 Address)
// Mac/Linux: ifconfig (look for inet address)

// Example: 192.168.1.100:5000
'http://192.168.1.100:5000'
```

### For Production (Render, AWS, etc.)

```dart
'https://your-backend-domain.com'
```

---

## 🧪 Testing Login Flow

### Test Sequence

1. **Start backend:**
   ```bash
   python run.py
   ```

2. **Run Flutter app:**
   ```bash
   flutter run
   ```

3. **Test register:**
   - Enter email: `test@example.com`
   - Enter password: `TestPass123`
   - Click "Create Account"
   - Should navigate to dashboard

4. **Test login:**
   - Enter same email/password
   - Click "Login"
   - Should navigate to dashboard

---

## 🐛 Troubleshooting

### "Connection refused" or timeout

**Problem:** Flutter can't reach backend

**Solutions:**
1. Check backend is running: `python run.py`
2. Check IP address in `api_config.dart`
3. For emulator, use `10.0.2.2` instead of `localhost`
4. For real device, use your PC's local IP (e.g., `192.168.1.100`)

### "Invalid credentials" on login

**Problem:** User doesn't exist or wrong password

**Solutions:**
1. Register first before login
2. Check email/password spelling
3. Ensure backend is using same database

### "Network error"

**Problem:** JSON parsing or request format issue

**Solutions:**
1. Check backend response format matches code
2. Verify `Content-Type: application/json` header
3. Check email format validation

### Token not saved

**Problem:** App crashes after login

**Solutions:**
1. Ensure `shared_preferences` is added to `pubspec.yaml`
2. Check permissions in `AndroidManifest.xml`
3. Test `getToken()` method separately

---

## 📊 Response Handling

### Success Response (Login)

```json
{
  "message": "Login successful",
  "user": {
    "user_id": 1,
    "email": "doctor@hospital.com",
    "username": "dr_smith"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Error Response (Invalid Credentials)

```json
{
  "error": "Invalid password"
}
```

---

## 🔐 Security Best Practices

1. **Never hardcode credentials** in app
2. **Store token securely** using `secure_storage` package
3. **Validate email** before sending to backend
4. **Use HTTPS** in production
5. **Refresh token** periodically
6. **Clear token on logout** (handled by `AuthService.logout()`)

---

## 📚 Next Steps

1. ✅ Test login/register flow
2. ⬜ Add password hashing (backend: already done with bcrypt)
3. ⬜ Add remember me functionality
4. ⬜ Add session persistence
5. ⬜ Add automatic token refresh
6. ⬜ Add biometric authentication

---

## 🆘 Need Help?

1. Run Python test: `python test_auth.py`
2. Check API docs: `API_TESTING.md`
3. Check backend logs for errors
4. Verify database connection

---

**Ready to test? Start the backend and run your Flutter app!** 🚀

