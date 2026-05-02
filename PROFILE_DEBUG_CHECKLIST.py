#!/usr/bin/env python3
"""
DIAGNOSTIC CHECKLIST - Profile Not Loading

Follow these steps to identify why the profile isn't showing data.
"""

CHECKLIST = """
═══════════════════════════════════════════════════════════════
📋 DIAGNOSTIC CHECKLIST - Profile Data Not Loading
═══════════════════════════════════════════════════════════════

STEP 1: Verify Backend is Running
───────────────────────────────────────────────────────────────
❓ Is the backend server running?

✅ DO THIS:
1. Open terminal
2. Run: cd C:\\Users\\Dyuthi\\med_calci_app\\backend
3. Run: python run.py
4. You should see:
   
   ╔════════════════════════════════════════════╗
   ║     MacMind Medical Calculator Backend     ║
   ╚════════════════════════════════════════════╝
   
   🚀 Server starting on http://0.0.0.0:5000
   ✅ Server is ready!

⚠️  IF YOU DON'T SEE THIS:
   → Backend is not running
   → Profile can't load without backend

───────────────────────────────────────────────────────────────

STEP 2: Verify User is Logged In
───────────────────────────────────────────────────────────────
❓ Is the user registered and logged in?

✅ DO THIS:
1. Open Flutter app
2. Go to Login/Registration
3. IF not logged in:
   → Create account first: Register screen
   → Enter: Full Name, Email, Password
   → Tap "Register"
4. IF logged in:
   → You should already have a token in SharedPreferences

⚠️  IF NOT LOGGED IN:
   → Can't access profile (requires authentication)
   → Token is required to fetch profile data

───────────────────────────────────────────────────────────────

STEP 3: Check Console Logs
───────────────────────────────────────────────────────────────
❓ What do the console logs show?

✅ DO THIS:
1. Open Android Studio or VS Code terminal
2. Run: flutter run (or restart app)
3. Navigate to Profile screen
4. Look for these log messages:

EXPECTED LOGS (SUCCESS):
   🔄 Loading profile...
   🔑 Token retrieved: eyJ0eXAi...
   📡 Fetching profile from: http://10.0.2.2:5000/api/profile
   🔍 Fetch profile status: 200
   📦 Fetch profile body: {"name":"Dr. John","email":"john@example.com"}
   ✅ Profile data received: {name: Dr. John, email: john@example.com, ...}
   📝 Setting name: Dr. John
   📝 Setting email: john@example.com
   ✅ All controllers set

ERROR LOGS (PROBLEMS):
   ❌ No authentication token found → User not logged in
   📡 Fetching profile from: http://10.0.2.2:5000/api/profile
   🔍 Fetch profile status: 401 → Token invalid/expired
   🔍 Fetch profile status: 404 → Backend error
   🔍 Fetch profile status: 500 → Server error

MISSING LOG:
   If you don't see logs at all:
   → Check that you're on the Profile screen
   → Check Flutter output panel (View → Output)

───────────────────────────────────────────────────────────────

STEP 4: Test Backend API Directly
───────────────────────────────────────────────────────────────
❓ Is the backend API working?

✅ DO THIS (using Postman or curl):

1. First, register a user:
   
   POST http://localhost:5000/api/auth/register
   Headers: Content-Type: application/json
   Body:
   {
     "full_name": "Dr. Test User",
     "email": "test@example.com",
     "password": "TestPass123",
     "confirm_password": "TestPass123"
   }
   
   Expected response (201):
   {
     "success": true,
     "token": "eyJ0eXAi..."
   }
   
   👉 COPY THE TOKEN

2. Then, fetch profile:
   
   GET http://localhost:5000/api/profile
   Headers:
   - Content-Type: application/json
   - Authorization: Bearer <PASTE_TOKEN_HERE>
   
   Expected response (200):
   {
     "name": "Dr. Test User",
     "email": "test@example.com"
   }

⚠️  IF YOU GET:
   - 401: Token is invalid/expired
   - 404: User not found
   - 500: Server error (check backend console)

───────────────────────────────────────────────────────────────

STEP 5: Check Database
───────────────────────────────────────────────────────────────
❓ Is user data in the database?

✅ DO THIS:

1. Open MySQL client (or MySQL Workbench)
2. Run:
   
   USE med_calci_app;
   SELECT * FROM users;
   
   You should see:
   | id | full_name | email | password | created_at |
   |----|-----------|-------|----------|------------|
   | 1  | Dr. Test  | t@ex  | $2b$...  | 2026-05-02 |

⚠️  IF NO USERS:
   → No one has registered yet
   → Need to register first

───────────────────────────────────────────────────────────────

TROUBLESHOOTING GUIDE
───────────────────────────────────────────────────────────────

PROBLEM: "Failed to load profile" SnackBar appears
   
SOLUTION:
   1. ✅ Backend is running?
   2. ✅ User is logged in (has token)?
   3. ✅ Check console logs for 401/404/500 errors
   4. ✅ Test API with Postman directly
   5. ✅ Check database for user record

───────────────────────────────────────────────────────────────

PROBLEM: Profile page shows "Not set" for all fields
   
SOLUTION:
   1. ✅ API returned successfully (200)?
   2. ✅ Backend returned name and email in response?
   3. ✅ Flutter is parsing JSON correctly?
   4. ✅ Controllers are being populated?
   
   Debug:
   → Print response body to see what backend returned
   → Check if 'name' and 'email' keys exist in response
   → Verify ProfileService is parsing correctly

───────────────────────────────────────────────────────────────

PROBLEM: Backend shows 404 error
   
SOLUTION:
   1. ✅ Is User.find_by_id() finding the user?
   2. ✅ Does user exist in database?
   3. ✅ Check backend logs for SQL errors
   4. ✅ Verify token contains correct user_id

───────────────────────────────────────────────────────────────

FINAL CHECKLIST (Before running)
───────────────────────────────────────────────────────────────

BACKEND:
 ☐ Backend is running (python run.py)
 ☐ Flask app is on port 5000
 ☐ Database is connected (MySQL running)
 ☐ users table exists and has data

FLUTTER:
 ☐ App is running (flutter run)
 ☐ User is registered and logged in
 ☐ Token is stored in SharedPreferences
 ☐ ApiConfig.baseUrl points to correct backend

NETWORK:
 ☐ Backend URL is reachable (http://10.0.2.2:5000 for emulator)
 ☐ Android app can reach localhost (use 10.0.2.2)
 ☐ No firewall blocking port 5000

═══════════════════════════════════════════════════════════════

If you've checked all these and still have issues:

1. Share the console logs when you see the error
2. Share the response from Postman test
3. Share the database query result

I can then help debug further!

═══════════════════════════════════════════════════════════════
"""

if __name__ == '__main__':
    print(CHECKLIST)
