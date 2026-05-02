# QUICK FIX - Profile Not Loading Data

Follow these exact steps:

## Step 1: Start/Restart Backend

```bash
cd C:\Users\Dyuthi\med_calci_app\backend
python run.py
```

**You should see:**
```
╔════════════════════════════════════════════╗
║     MacMind Medical Calculator Backend     ║
╚════════════════════════════════════════════╝

🚀 Server starting on http://0.0.0.0:5000
✅ Server is ready!
```

⚠️ **IMPORTANT:** If you see errors, the backend won't work. Share the error in console.

---

## Step 2: Verify User Account Exists

In Flutter, you MUST:
1. Open Login screen
2. Tap "Create Account"
3. Register with:
   - Full Name: `Dr. John Doe`
   - Email: `john@example.com`
   - Password: `Test123`
   - Confirm: `Test123`
4. Tap "Register" button

⚠️ **DO NOT skip registration.** Profile only works after creating an account.

---

## Step 3: Navigate to Profile Screen

1. After registration succeeds, you should be auto-logged in
2. Navigate to Profile screen
3. Watch the console for logs

---

## Step 4: Check Console Logs

Open VS Code terminal / Android Studio logcat and look for:

**GOOD LOGS (means it's working):**
```
🔄 Loading profile...
🔑 Token retrieved: eyJ0eXAi...
📡 Fetching profile from: http://10.0.2.2:5000/api/profile
🔍 Fetch profile status: 200
📦 Fetch profile body: {"name":"Dr. John Doe","email":"john@example.com"}
✅ Profile data received
📝 Setting name: Dr. John Doe
```

**BAD LOGS (means something is wrong):**
```
❌ No authentication token found
🔍 Fetch profile status: 401
🔍 Fetch profile status: 500
```

---

## Step 5: If Still Showing "Not set"

Run this command in backend to test the API directly:

```bash
python -c "
from app import create_app, db
from app.models.user import User
from app.utils.security import create_token

app = create_app('development')
with app.app_context():
    # Find first user
    user = User.query.first()
    if user:
        print(f'User found: {user.full_name} ({user.email})')
        token = create_token(user.id, user.email)
        print(f'Token: {token[:50]}...')
    else:
        print('No users in database!')
"
```

This will show if users exist in the database.

---

## Common Issues & Fixes

### Issue 1: "Failed to load profile" appears

**Cause:** Profile API failed or token missing

**Fix:**
1. ✅ Make sure user registered
2. ✅ Restart Flutter app
3. ✅ Check backend is running on port 5000

### Issue 2: Shows "Not set" for all fields

**Cause:** API returned empty data OR backend not returning correct format

**Fix:**
1. ✅ Verify user was registered (full_name and email saved)
2. ✅ Check database: `SELECT * FROM users;`
3. ✅ Restart backend (changes not applied)

### Issue 3: 401 Unauthorized error

**Cause:** Token not valid or not sent

**Fix:**
1. ✅ Logout completely
2. ✅ Register again (fresh token)
3. ✅ Check SharedPreferences has token (see logs)

---

## What's Expected to Happen

1. **Register:**
   ```
   ✅ Token stored: eyJ0eXAi...
   ```

2. **Open Profile:**
   ```
   🔍 Fetch profile status: 200
   📦 {"name":"Dr. John Doe","email":"john@example.com"}
   ```

3. **UI Shows:**
   ```
   Name:     Dr. John Doe
   Role:     Not set
   Email:    john@example.com
   Hospital: Not set
   ```

---

## Next Steps

1. **Do the registration flow** (if not done)
2. **Check the console logs** and share them
3. **Tell me what you see** so I can help debug

If you share:
- The console logs when error occurs
- What API status code you get (200, 401, 404, 500?)
- What the backend returns

I can fix it immediately!
