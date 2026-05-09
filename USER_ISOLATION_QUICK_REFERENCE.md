# User-Based Data Isolation - Quick Reference

## What Was Changed?

### Backend (Flask + PostgreSQL)

#### Files Modified:
1. **backend/app/models/case.py**
   - Added `user_id` foreign key column
   - Added `user` relationship to User model
   - Updated `Case.create()` signature to require `user_id`
   - Updated `Case.get_all()` to filter by user_id
   - Updated `Case.get_by_id()` with ownership check
   - Added `Case.update()` method with ownership verification
   - Updated `Case.delete()` with ownership verification

2. **backend/app/routes/cases.py**
   - Added `@require_token` decorator to all endpoints
   - Updated route handlers to accept `current_user` parameter
   - Extract user_id from JWT token and pass to model methods
   - Return 403 for unauthorized access attempts
   - Return 401 for missing/invalid tokens
   - Added new PUT endpoint for case updates

3. **backend/db/003_add_user_id_to_cases.sql** (NEW)
   - Migration to add user_id column
   - Add foreign key constraint
   - Create index for performance
   - Handle existing data

#### No Changes Needed:
- `backend/app/utils/decorators.py` - Already has `@require_token`
- `backend/app/utils/security.py` - Already has JWT handling
- `backend/app/routes/auth.py` - Already returns token in login/register

### Frontend (Flutter)

#### Files Modified:
1. **lib/services/case_service.dart**
   - `getAllCases()` - Now sends Authorization header with token
   - `getCaseById()` - Now sends Authorization header with token
   - `updateCase()` - Now sends Authorization header with token (already did)
   - `deleteCase()` - Now sends Authorization header with token
   - All methods check statusCode 401/403 in responses

2. **lib/screens/case_history_screen.dart**
   - `_fetchCases()` - Detects 401 and redirects to login
   - `_deleteCase()` - Detects 401/403 and redirects/shows error
   - Added import for AuthService

3. **lib/screens/results_screen.dart**
   - `_saveCaseResult()` - Detects 401 and redirects to login
   - Shows appropriate error messages for 401/403/other errors

4. **lib/main.dart**
   - `_bootstrapApp()` - Now validates token on app startup
   - Clears session if token not found
   - Only auto-logs in if token + remember-me both set

#### No Changes Needed:
- `lib/services/auth_service.dart` - Already stores/retrieves token
- Token is already stored on login/register

## Key Architecture Points

### JWT Token Flow
```
1. User Logs In → Backend generates JWT with user_id
2. Frontend stores token in SharedPreferences
3. Frontend sends token in Authorization: Bearer <token> header
4. Backend @require_token decorator validates token
5. current_user dict injected with user_id from JWT payload
6. All case operations filter/verify by current_user.user_id
```

### Data Access Pattern
```
Old (No Isolation):
Case.get_all() → returns ALL cases from database

New (With Isolation):
1. JWT token required
2. Extract user_id from token
3. Case.get_all(user_id=user_id) → returns only that user's cases
4. Ownership verification on GET/PUT/DELETE
```

### Error Handling
```
401 Unauthorized:
- Missing/invalid/expired token
- Frontend: Logout and redirect to login

403 Forbidden:
- Token valid but user doesn't own resource
- Frontend: Show error, don't redirect

404 Not Found:
- Resource doesn't exist
- Frontend: Show error
```

## Testing Checklist

**Before Deployment:**
- [ ] Apply migration to staging database
- [ ] Test login with multiple users
- [ ] Verify User A cannot see User B's cases
- [ ] Verify User A cannot edit User B's cases
- [ ] Verify User A cannot delete User B's cases
- [ ] Test token expiration handling
- [ ] Test auto-login functionality
- [ ] Test logout functionality

**After Deployment:**
- [ ] Monitor logs for 401/403 errors
- [ ] Test end-to-end save/edit/delete
- [ ] Verify token is sent in all requests
- [ ] Verify no data leakage between users

## Critical Security Notes

⚠️ **IMPORTANT**: Never trust user_id from request body:
```python
# ❌ WRONG - trusts frontend user_id
case.user_id = data.get('user_id')

# ✅ CORRECT - uses user_id from JWT token
case.user_id = current_user['user_id']
```

⚠️ **IMPORTANT**: Always verify ownership before modifying/deleting:
```python
# ❌ WRONG - no ownership check
case = Case.query.get(case_id)
db.session.delete(case)

# ✅ CORRECT - ownership verified
if case.user_id != current_user['user_id']:
    return error, 403
```

## API Endpoints Summary

| Method | Endpoint | Requires Auth | Filters By | Notes |
|--------|----------|---|---|---|
| POST | /api/calculator/cases | ✅ | Auto-set from token | Creates case for current user |
| GET | /api/calculator/cases | ✅ | user_id in token | Returns only user's cases |
| GET | /api/calculator/cases/{id} | ✅ | Ownership check | 403 if not owner |
| PUT | /api/calculator/cases/{id} | ✅ | Ownership check | 403 if not owner (NEW) |
| DELETE | /api/calculator/cases/{id} | ✅ | Ownership check | 403 if not owner |

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| 401 on all requests | Missing token | Check AuthService.getToken() returns value |
| 403 on own case | Wrong user_id in JWT | Verify token was created with correct user_id |
| User sees other's cases | Filter not applied | Check Case.get_all(user_id=...) is called |
| App crashes on logout | UserSession not cleared | Verify AuthService.logout() clears all data |
| Token not sent | Headers not set | Check CaseService sends Authorization header |

## Migration Instructions

### For Existing Users with Cases

The migration script assigns all existing cases (without user_id) to user_id = 1:

```sql
UPDATE cases SET user_id = 1 WHERE user_id IS NULL;
```

**After migration**, you may want to:
1. Notify users with existing cases that they now own them
2. Provide admin endpoint to reassign cases if needed
3. Archive old cases if preferred

### Rollback (if needed)

To reverse the migration:
```sql
-- Remove user_id column (WARNING: loses data association)
ALTER TABLE cases DROP COLUMN user_id;
DROP INDEX IF EXISTS idx_cases_user_id;
ALTER TABLE cases DROP CONSTRAINT IF EXISTS fk_cases_user_id;
```

## Performance Considerations

✅ Added index on cases(user_id) for faster queries
✅ JWT token validation is lightweight (no database lookup)
✅ Cases filtered in database, not in application code
✅ Foreign key with ON DELETE CASCADE ensures data integrity

## Future Enhancements

1. **Token Refresh**: Implement refresh token mechanism for longer sessions
2. **Rate Limiting**: Prevent brute force login attempts
3. **Session Timeout**: Show warning before auto-logout
4. **Audit Trail**: Log who accessed what cases and when
5. **Sharing**: Allow users to share cases with colleagues
6. **Admin Panel**: Let admins view statistics across all users

## Support

For issues or questions:
1. Check USER_ISOLATION_IMPLEMENTATION.md for detailed testing guide
2. Review error logs for 401/403 patterns
3. Verify token is being stored and sent correctly
4. Check database migration was applied successfully
