#!/usr/bin/env python3
"""
COMPLETE TESTING GUIDE - MongoDB Removal + Auth Integration

This guide walks you through testing the complete flow:
1. Backend: User registration with auto-profile creation
2. Backend: Authentication with JWT tokens
3. Flutter: Token storage and usage in profile operations
"""

import json

BACKEND_TESTS = """
═══════════════════════════════════════════════════════════════
🧪 BACKEND TESTING CHECKLIST
═══════════════════════════════════════════════════════════════

✅ BACKEND TEST 1: Registration + Auto-Profile Creation
   
   Endpoint: POST /api/auth/register
   
   Request body:
   {
     "full_name": "Dr. John Smith",
     "email": "john.smith@example.com",
     "password": "SecurePass123",
     "confirm_password": "SecurePass123"
   }
   
   Expected response (201):
   {
     "success": true,
     "message": "Registration successful",
     "user": {
       "id": 1,
       "email": "john.smith@example.com",
       "full_name": "Dr. John Smith"
     },
     "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
   }
   
   ✅ Verify in MySQL:
   
   SELECT * FROM users WHERE email = 'john.smith@example.com';
   → Should show: id, full_name, email, password (hashed)
   
   SELECT * FROM profiles WHERE user_id = <user_id>;
   → Should show: user_id, name, email, role, hospital (auto-created)
   
───────────────────────────────────────────────────────────────

✅ BACKEND TEST 2: Login + Token Generation
   
   Endpoint: POST /api/auth/login
   
   Request body:
   {
     "email": "john.smith@example.com",
     "password": "SecurePass123"
   }
   
   Expected response (200):
   {
     "success": true,
     "message": "Login successful",
     "user": {
       "id": 1,
       "email": "john.smith@example.com",
       "full_name": "Dr. John Smith"
     },
     "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
   }
   
   ✅ Copy the token for profile API tests

───────────────────────────────────────────────────────────────

✅ BACKEND TEST 3: Fetch User Profile (Protected)
   
   Endpoint: GET /api/profile
   
   Headers:
   {
     "Authorization": "Bearer <token_from_login>",
     "Content-Type": "application/json"
   }
   
   Expected response (200):
   {
     "name": "Dr. John Smith",
     "email": "john.smith@example.com",
     "role": "Doctor",
     "hospital": ""
   }
   
   ⚠️  If no Authorization header:
   → Response (401): Unauthorized
   
───────────────────────────────────────────────────────────────

✅ BACKEND TEST 4: Update User Profile (Protected)
   
   Endpoint: PUT /api/profile
   
   Headers:
   {
     "Authorization": "Bearer <token_from_login>",
     "Content-Type": "application/json"
   }
   
   Request body:
   {
     "name": "Dr. John Smith",
     "email": "john.smith@hospital.com",
     "role": "Cardiologist",
     "hospital": "Central Medical Hospital"
   }
   
   Expected response (200):
   {
     "message": "Profile updated successfully",
     "profile": {
       "name": "Dr. John Smith",
       "email": "john.smith@hospital.com",
       "role": "Cardiologist",
       "hospital": "Central Medical Hospital"
     }
   }
   
   ✅ Verify in MySQL:
   
   SELECT * FROM profiles WHERE user_id = <user_id>;
   → Should show updated values

═══════════════════════════════════════════════════════════════
"""

FLUTTER_CHANGES = """
═══════════════════════════════════════════════════════════════
📱 FLUTTER CHANGES APPLIED
═══════════════════════════════════════════════════════════════

FILE 1: lib/services/auth_service.dart
───────────────────────────────────────────────────────────────

✅ ADDED: Token storage constant
   static const String _tokenKey = "authToken";

✅ UPDATED: login() method
   - Extracts token from login response
   - Stores token in SharedPreferences
   - Token is now used for all authenticated API calls

✅ UPDATED: register() method
   - Extracts token from registration response
   - Auto-logs in user after registration
   - Stores token in SharedPreferences

✅ ADDED: getToken() method
   - Retrieves stored JWT token
   - Returns null if not logged in
   
   Usage:
   String? token = await AuthService.getToken();

✅ UPDATED: logout() method
   - Clears all authentication data
   - Removes token from storage
   
   Usage:
   await AuthService.logout();

───────────────────────────────────────────────────────────────

FILE 2: lib/services/profile_service.dart
───────────────────────────────────────────────────────────────

✅ UPDATED: Imports
   - Now uses ApiConfig.baseUrl (dynamic)
   - Imports AuthService for token management
   - Imports SharedPreferences for direct access if needed

✅ UPDATED: fetchProfile() method
   - Gets JWT token from AuthService.getToken()
   - Includes Authorization header: "Bearer {token}"
   - Handles 401 (Unauthorized) by clearing token and logging out
   
   Request headers:
   {
     "Authorization": "Bearer {jwt_token}",
     "Content-Type": "application/json"
   }

✅ UPDATED: updateProfile() method
   - Gets JWT token from AuthService.getToken()
   - Includes Authorization header: "Bearer {token}"
   - Handles 401 (Unauthorized) by clearing token and logging out
   
   Request headers:
   {
     "Authorization": "Bearer {jwt_token}",
     "Content-Type": "application/json"
   }

═══════════════════════════════════════════════════════════════
"""

FLUTTER_TESTING = """
═══════════════════════════════════════════════════════════════
📱 FLUTTER TESTING CHECKLIST
═══════════════════════════════════════════════════════════════

✅ FLUTTER TEST 1: Registration Flow
   
   1. Open Flutter app
   2. Navigate to Registration screen
   3. Enter:
      - Full Name: Dr. Test User
      - Email: test.user@example.com
      - Password: TestPass123
      - Confirm Password: TestPass123
   4. Tap "Register" button
   
   Expected:
   ✅ Registration successful
   ✅ Auto-login (token stored in SharedPreferences)
   ✅ Navigates to next screen
   ✅ "🚀 Token stored: eyJ0eXAi..." appears in console
   
   Backend result:
   ✅ User created in database
   ✅ Profile auto-created with user_id linkage

───────────────────────────────────────────────────────────────

✅ FLUTTER TEST 2: Profile Screen Load
   
   1. After registration, navigate to Profile screen
   2. Wait for profile data to load
   
   Expected:
   ✅ "🔍 Fetch profile status: 200" in console
   ✅ Profile data displays:
      - Name: Dr. Test User
      - Role: Doctor
      - Email: test.user@example.com
      - Hospital: (empty)
   ✅ No errors or "Failed to load profile"
   
   If you see "❌ No authentication token found":
   → Token was not stored properly after registration
   → Check: AuthService.login() is called after registration
   → Check: Token is present in login response

───────────────────────────────────────────────────────────────

✅ FLUTTER TEST 3: Edit Profile
   
   1. On Profile screen, tap "Edit Profile" button
   2. Change values:
      - Name: Dr. Updated Name
      - Role: Cardiologist
      - Email: updated@hospital.com
      - Hospital: City Medical Center
   3. Tap "Save" button
   
   Expected:
   ✅ "✏️  Update profile status: 200" in console
   ✅ Snackbar shows "Profile updated"
   ✅ Screen switches to view mode
   ✅ Values are persisted
   
   Database result:
   ✅ Profile row updated in MySQL with new values

───────────────────────────────────────────────────────────────

✅ FLUTTER TEST 4: Token Persistence
   
   1. Register a user and see token stored
   2. Kill the app (or restart)
   3. Reopen the app
   4. Navigate to Profile screen
   
   Expected:
   ✅ Profile loads automatically
   ✅ No need to login again
   ✅ Data from previous session displays
   
   This means: Token is persisted in SharedPreferences ✅

───────────────────────────────────────────────────────────────

✅ FLUTTER TEST 5: Logout Functionality
   
   1. On Profile screen or after login
   2. Tap logout button (you'll need to add this)
   
   Expected:
   ✅ "✅ Logged out successfully" in console
   ✅ Redirected to login screen
   ✅ Token removed from storage
   
   Code to add (in a button):
   ```dart
   await AuthService.logout();
   Navigator.of(context).pushReplacementNamed('/login');
   ```

═══════════════════════════════════════════════════════════════
"""

EXPECTED_DATA_FLOW = """
═══════════════════════════════════════════════════════════════
📊 EXPECTED DATA FLOW
═══════════════════════════════════════════════════════════════

1️⃣  REGISTRATION FLOW
   
   Flutter Register Screen
            ↓
   POST /api/auth/register
            ↓
   Backend: User.create()
            ├─ Create user in users table
            ├─ Get user.id
            ├─ Auto-create profile with user_id
            └─ Commit transaction
            ↓
   Response: {token: "jwt...", user: {...}}
            ↓
   Flutter: Store token in SharedPreferences
            ↓
   Auto-login successful ✅

───────────────────────────────────────────────────────────────

2️⃣  PROFILE FETCH FLOW
   
   Flutter Profile Screen
            ↓
   GET /api/profile
   Headers: Authorization: Bearer {token}
            ↓
   Backend: @require_token decorator
            ├─ Verify JWT token
            ├─ Extract user_id from token
            ├─ Query: Profile.query.filter_by(user_id=user_id)
            └─ Return user's profile
            ↓
   Response: {name: "...", email: "...", ...}
            ↓
   Flutter: Display in UI ✅

───────────────────────────────────────────────────────────────

3️⃣  PROFILE UPDATE FLOW
   
   Flutter Edit Profile Screen
            ↓
   PUT /api/profile
   Headers: Authorization: Bearer {token}
   Body: {name: "...", email: "...", ...}
            ↓
   Backend: @require_token decorator
            ├─ Verify JWT token
            ├─ Extract user_id from token
            ├─ Query: Profile.query.filter_by(user_id=user_id)
            ├─ Update fields
            └─ Commit to profiles table
            ↓
   Response: {message: "updated", profile: {...}}
            ↓
   Flutter: Show success ✅

═══════════════════════════════════════════════════════════════
"""

TROUBLESHOOTING = """
═══════════════════════════════════════════════════════════════
🔧 TROUBLESHOOTING
═══════════════════════════════════════════════════════════════

❌ PROBLEM: "Failed to load profile" on Flutter
   
   ✅ SOLUTIONS:
   1. Check token is stored:
      → SharedPreferences should have "authToken" key
      → Run backend test first to verify token is issued
   
   2. Check if user is logged in:
      → Profile screen should only work after login/register
      → Clear SharedPreferences if corrupted
   
   3. Check backend is running:
      → Backend must be started: python run.py
      → Port 5000 should be accessible

───────────────────────────────────────────────────────────────

❌ PROBLEM: "401 Unauthorized" in logs
   
   ✅ SOLUTIONS:
   1. Token might have expired (unlikely in dev)
   2. Token format incorrect:
      → Should be: "Bearer eyJ0eXAi..."
      → NOT: "Bearer <token>"
   
   3. Token not being retrieved:
      → Ensure login() stores token
      → Ensure register() calls login()

───────────────────────────────────────────────────────────────

❌ PROBLEM: Profile loads but shows old data
   
   ✅ SOLUTIONS:
   1. Profile auto-created with empty values
      → Call PUT /api/profile to update
      → Values will persist in profiles table
   
   2. Cached response:
      → Clear app data
      → Restart app
      → Re-login

───────────────────────────────────────────────────────────────

❌ PROBLEM: "No authentication token found" in logs
   
   ✅ SOLUTIONS:
   1. User not logged in:
      → Must register or login first
      → Token is only available after successful auth
   
   2. Token was cleared:
      → Call logout() removes token
      → Must login again to get new token

═══════════════════════════════════════════════════════════════
"""

SUMMARY = """
═══════════════════════════════════════════════════════════════
✅ MIGRATION COMPLETE: MongoDB → MySQL + Token Auth
═══════════════════════════════════════════════════════════════

WHAT'S CHANGED:

Backend:
  ✅ MongoDB completely removed
  ✅ All data in MySQL (SQLAlchemy)
  ✅ Profile auto-created on user registration
  ✅ All profile routes protected with @require_token
  ✅ Profiles linked to users via user_id

Flutter:
  ✅ AuthService stores JWT tokens
  ✅ ProfileService uses Authorization headers
  ✅ Token persisted in SharedPreferences
  ✅ Token cleared on logout
  ✅ Handles 401 Unauthorized by logging out

NEXT STEPS:

1. ✅ Test backend: python test_registration_flow.py
2. ✅ Test Flutter: Register → Open Profile → Edit → Save
3. ✅ Verify database: SELECT * FROM users; SELECT * FROM profiles;
4. ✅ Test token persistence: Kill app, reopen, profile still loads
5. ✅ Add logout button with: await AuthService.logout();

PRODUCTION READY:

✅ Single database (MySQL)
✅ JWT authentication
✅ User-based profiles (no global profile)
✅ Token persistence across sessions
✅ Automatic logout on token expiry
✅ Error handling for 401 responses

═══════════════════════════════════════════════════════════════
"""

if __name__ == '__main__':
    print(BACKEND_TESTS)
    print(FLUTTER_CHANGES)
    print(FLUTTER_TESTING)
    print(EXPECTED_DATA_FLOW)
    print(TROUBLESHOOTING)
    print(SUMMARY)
