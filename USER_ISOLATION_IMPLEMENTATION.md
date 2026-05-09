# User-Based Data Isolation - Implementation & Testing Guide

## Overview
This guide covers the implementation of strict user-based data isolation for the Flask + PostgreSQL backend and Flutter frontend. All saved cases, history, and calculations are now isolated per user and only accessible after authentication.

## Implementation Summary

### Backend Changes

#### 1. Database Schema (PostgreSQL)
- **Migration File**: `backend/db/003_add_user_id_to_cases.sql`
- **Changes**:
  - Added `user_id` INTEGER column to `cases` table
  - Added foreign key constraint `fk_cases_user_id` linking to `users.id` with ON DELETE CASCADE
  - Created index `idx_cases_user_id` for performance optimization
  - Existing cases without user_id are assigned to user_id = 1

#### 2. Flask Models
- **File**: `backend/app/models/case.py`
- **Changes**:
  - Added `user_id` column with foreign key to User model
  - Added SQLAlchemy relationship: `user = db.relationship('User', backref='cases')`
  - Updated `Case.create()` to accept and require `user_id` parameter
  - Updated `Case.get_all()` to filter by optional `user_id` parameter
  - Updated `Case.get_by_id()` to verify ownership before returning case
  - Added new `Case.update()` method with ownership verification
  - Updated `Case.delete()` to verify ownership before deletion

#### 3. Flask Routes
- **File**: `backend/app/routes/cases.py`
- **Changes**:
  - Added `@require_token` decorator to ALL case endpoints (POST, GET, PUT, DELETE)
  - `POST /api/calculator/cases` - Creates case with `current_user.id` automatically set
  - `GET /api/calculator/cases` - Returns only cases for authenticated user
  - `GET /api/calculator/cases/<id>` - Returns case only if user owns it (403 if not)
  - `PUT /api/calculator/cases/<id>` - Updates case only if user owns it (new endpoint)
  - `DELETE /api/calculator/cases/<id>` - Deletes case only if user owns it

#### 4. JWT Authentication
- **File**: `backend/app/utils/decorators.py`
- **Current Implementation**:
  - `@require_token` decorator extracts Bearer token from Authorization header
  - Verifies JWT signature and expiration
  - Injects `current_user` dict containing `user_id` and `email` into route handlers
  - Returns 401 with error message if token missing or invalid

### Frontend Changes

#### 1. AuthService Enhancements
- **File**: `lib/services/auth_service.dart`
- **Current Features**:
  - `getToken()` - Retrieves JWT from SharedPreferences
  - `login()` - Stores token on successful login
  - `register()` - Stores token on successful registration
  - `logout()` - Clears token and user session
  - `shouldAutoLogin()` - Checks if auto-login should be attempted
  - Token automatically sent in all protected API requests

#### 2. CaseService Updates
- **File**: `lib/services/case_service.dart`
- **Changes**:
  - `saveCase()` - Sends Authorization header with Bearer token
  - `getAllCases()` - Requires token; returns 401 if token missing/invalid
  - `getCaseById()` - Requires token; returns 403 if user doesn't own case
  - `updateCase()` - Requires token; validates ownership on backend
  - `deleteCase()` - Requires token; validates ownership on backend
  - All methods now include status code checking for 401/403 errors

#### 3. Case History Screen
- **File**: `lib/screens/case_history_screen.dart`
- **Changes**:
  - `_fetchCases()` - Detects 401 errors and redirects to login
  - `_deleteCase()` - Handles 401/403 errors appropriately
  - Added AuthService import for logout functionality
  - Displays user-friendly error messages for authorization failures

#### 4. Results Screen (Save/Update)
- **File**: `lib/screens/results_screen.dart`
- **Changes**:
  - `_saveCaseResult()` - Detects 401 errors during save/update
  - Redirects to login on authentication failure
  - Displays appropriate error messages for all failure scenarios

#### 5. App Startup Logic
- **File**: `lib/main.dart`
- **Changes**:
  - `_bootstrapApp()` - Now validates token existence on startup
  - Clears session if token not found or invalid
  - Auto-logins only if token AND remember-me are both set
  - Provides fallback to login screen if validation fails

## Testing Procedures

### 1. Database Setup
Before testing, apply the migration:

```bash
# Using Flask shell in backend directory:
python run.py  # Ensure db is initialized

# Or manually run migration in PostgreSQL:
psql -U med_calci_db_user -d med_calci_db -f db/003_add_user_id_to_cases.sql
```

### 2. User Isolation Testing

#### Test A: User A Cannot See User B's Cases
```
1. User A: Register account and save a case ("Case_A_1")
2. User B: Register account in NEW browser/device
3. User B: Verify case list is EMPTY (no Case_A_1 visible)
4. User B: Save a case ("Case_B_1")
5. User A: Login again, verify only Case_A_1 visible (not Case_B_1)
```

#### Test B: Ownership Verification
```
1. User A: Save case with ID=123
2. User B: Try accessing GET /api/calculator/cases/123 with their token
   - Expected: 403 Forbidden response
   - Message: "Unauthorized access to this case"
3. User A: Access same case with their token
   - Expected: 200 OK with full case data
```

#### Test C: Edit Operations
```
1. User A: Edit their own case (Case_A_1)
   - Expected: Success, case updated
2. User B: Attempt direct API call to PUT /api/calculator/cases/<A's_ID>
   - Expected: 403 Forbidden
3. User B: Cannot edit User A's case even if ID is known
```

#### Test D: Delete Operations
```
1. User A: Delete their own case
   - Expected: 200 OK, case removed from history
2. User B: Try deleting User A's case (if somehow known)
   - Expected: 403 Forbidden
3. Verify 404 error when deleting non-existent case (not 403)
```

### 3. Authentication Testing

#### Test E: Missing Token
```
1. User: Clear token from SharedPreferences
2. User: Try accessing GET /api/calculator/cases
   - Expected: 401 Unauthorized (no token header)
3. User: App should auto-redirect to login screen
```

#### Test F: Invalid/Expired Token
```
1. User: Manually modify stored token to invalid value
2. User: Try accessing case history
   - Expected: 401 Unauthorized (invalid token)
3. User: Automatically redirected to login screen
   - UserSession cleared
   - Token removed from storage
```

#### Test G: Auto-Login
```
1. User A: Login with "Remember Me" enabled
   - Verify token stored in SharedPreferences
2. Kill app completely and restart
   - Expected: Auto-login successful
   - User sees history screen immediately (no login required)
3. User A: Logout
4. Restart app
   - Expected: Login screen shown (remember-me cleared)
```

### 4. Multiple User Sessions

#### Test H: Concurrent User Access
```
1. Device 1: User A logs in
2. Device 2: User B logs in (different user)
3. Device 1: User A can view only their cases
4. Device 2: User B can view only their cases
5. Device 1: User A performs save/edit/delete
   - Device 2: No impact, User B's cases unchanged
```

### 5. Edge Cases

#### Test I: Token Refresh
```
1. User: Login, receive token with 30-day expiry
2. After token near expiry:
   - Expected: Backend returns 401
   - Frontend detects 401 and redirects to login
   - User must re-authenticate
```

#### Test J: Database Constraint Validation
```
1. Backend: Attempt to create case without user_id
   - Expected: Database constraint error (nullable=False)
2. Backend: Attempt to delete user with associated cases
   - Expected: ON DELETE CASCADE removes all cases
```

#### Test K: API Parameter Injection
```
1. User A: Try sending user_id=2 in JSON body
   - Expected: Backend IGNORES user_id parameter
   - Always uses user_id from JWT token
2. Verify case saved with User A's id (not id=2)
```

## Deployment Checklist

### Pre-Deployment
- [ ] Test database migration on staging database
- [ ] Verify all backend tests pass
- [ ] Verify all Flutter tests pass
- [ ] Check JWT secret key is secure and unique
- [ ] Verify CORS settings allow Flutter app domain

### Deployment Steps

#### 1. Backend Deployment
```bash
# 1. Apply database migration
cd backend
# Using Flask migration or manual SQL
python run.py  # to initialize schema

# 2. Deploy Flask app to production
# Update .env with production settings
# Restart Flask/Gunicorn

# 3. Monitor logs for errors
tail -f logs/app.log
```

#### 2. Flutter Deployment
```bash
# 1. Update API_CONFIG to production backend URL
# File: lib/config/api_config.dart

# 2. Build release APK/IPA
flutter build apk --release  # Android
flutter build ios --release   # iOS

# 3. Upload to app stores
# Google Play Store (Android)
# App Store (iOS)
```

### Post-Deployment
- [ ] Test login/register flow on production
- [ ] Verify case save works end-to-end
- [ ] Test auto-login functionality
- [ ] Verify token expiration handling
- [ ] Monitor API logs for 401/403 errors
- [ ] Verify no user can access others' cases

## Rollback Plan

If issues occur:

1. **Backend Rollback**:
   - Restore previous database backup (migration is reversible)
   - Revert Flask code to previous version
   - Clear token validation temporarily if needed

2. **Frontend Rollback**:
   - Revert to previous Flutter app build
   - Users with old version will lose token temporarily

3. **Emergency Mode**:
   - If needed, temporarily disable token requirement
   - Implement fix and re-enable

## Monitoring & Maintenance

### Key Metrics to Monitor
- 401 Unauthorized errors (token issues)
- 403 Forbidden errors (ownership violations)
- User session creation/destruction
- Failed login attempts
- Token expiration patterns

### Logs to Review
```bash
# Flask logs
tail -f backend/logs/app.log | grep -E "401|403|Unauthorized"

# Check for user_id issues in case operations
grep "user_id" backend/logs/app.log
```

### Future Enhancements
1. Token refresh mechanism (instead of hard expiration)
2. Rate limiting on login attempts
3. Session timeout warnings in UI
4. Audit log for case access/modifications
5. Role-based access control (e.g., admin can view all cases)

## Support & Troubleshooting

### Issue: User sees "Not authenticated" on startup
**Solution**: Clear app cache and login again. Verify token is stored in SharedPreferences.

### Issue: Case appears then disappears from history
**Solution**: Check for race condition in _fetchCases(). Add loading state.

### Issue: 403 Forbidden on user's own case
**Solution**: Verify case.user_id matches JWT token user_id. Check database constraints.

### Issue: Token not being sent in request headers
**Solution**: Verify AuthService.getToken() returns value. Check network logs.

## Testing Commands

```bash
# Test backend API directly
curl -X GET http://localhost:5000/api/calculator/cases \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"

# Test with invalid token
curl -X GET http://localhost:5000/api/calculator/cases \
  -H "Authorization: Bearer invalid_token"

# Test without token
curl -X GET http://localhost:5000/api/calculator/cases
```

## Success Criteria

✅ User A cannot see User B's cases
✅ User A cannot edit/delete User B's cases
✅ All case APIs require valid JWT token
✅ History updates correctly after save/edit/delete
✅ Multiple users can use app independently
✅ Token expiration redirects to login
✅ Auto-login works with remember-me enabled
✅ No cross-user data leakage detected
