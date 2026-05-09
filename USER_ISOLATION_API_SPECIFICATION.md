# User-Based Data Isolation - API Specification

## Authentication Header Format

All protected endpoints require JWT token in Authorization header:

```
Authorization: Bearer <JWT_TOKEN>
```

Example:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMSIsImVtYWlsIjoiam9obkBlbWFpbC5jb20ifQ...
```

## API Endpoints

### 1. Save Case (Create)
**Endpoint**: `POST /api/calculator/cases`  
**Authentication**: Required ✅  
**Access Control**: Automatically associated with logged-in user

#### Request Headers
```json
{
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
}
```

#### Request Body
```json
{
  "patient_name": "John Doe",
  "patient_id": "P12345",
  "date": "2026-05-09",
  "surgery_type": "General Surgery",
  "anesthetic_agent": "Sevoflurane",
  "molecular_mass": "200.5",
  "vapor_constant": "45.8",
  "density": "1.52",
  "fresh_gas_flow": 3.5,
  "dial_concentration": 2.0,
  "time_minutes": 120,
  "initial_weight": 75.0,
  "final_weight": 73.5,
  "biro_formula": 45.2,
  "dion_formula": 48.1,
  "weight_based": 46.5,
  "notes": "Uneventful case",
  "induction_fgf": 4.0,
  "induction_concentration": 8.0,
  "induction_time": 5,
  "induction_biro": 50.0,
  "induction_dion": 52.0,
  "final_biro": 45.2,
  "final_dion": 48.1,
  "maintenance_rows": [...],
  "maintenance_calculations": [...]
}
```

#### Successful Response (201)
```json
{
  "success": true,
  "message": "Case saved successfully",
  "case": {
    "id": 123,
    "patient_name": "John Doe",
    "patient_id": "P12345",
    "date": "2026-05-09"
  }
}
```

#### Error Responses

**401 Unauthorized** (Missing/Invalid Token)
```json
{
  "success": false,
  "message": "Token is missing"
}
```

**400 Bad Request** (Missing Required Fields)
```json
{
  "success": false,
  "message": "Request body is empty"
}
```

---

### 2. Get All Cases (Current User Only)
**Endpoint**: `GET /api/calculator/cases`  
**Authentication**: Required ✅  
**Access Control**: Returns only cases belonging to authenticated user

#### Request Headers
```json
{
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
}
```

#### Successful Response (200)
```json
{
  "success": true,
  "message": "Cases retrieved successfully",
  "cases": [
    {
      "id": 123,
      "patient_name": "John Doe",
      "patient_id": "P12345",
      "date": "2026-05-09",
      "surgery_type": "General Surgery",
      "anesthetic_agent": "Sevoflurane",
      "molecular_mass": "200.5",
      "vapor_constant": "45.8",
      "density": "1.52",
      "fresh_gas_flow": 3.5,
      "dial_concentration": 2.0,
      "time_minutes": 120,
      "initial_weight": 75.0,
      "final_weight": 73.5,
      "biro_formula": 45.2,
      "dion_formula": 48.1,
      "weight_based": 46.5,
      "notes": "Uneventful case",
      "created_at": "2026-05-09T14:30:00"
    },
    {
      "id": 124,
      "patient_name": "Jane Smith",
      ...
    }
  ],
  "count": 2
}
```

#### Error Responses

**401 Unauthorized**
```json
{
  "success": false,
  "message": "Token is missing",
  "cases": []
}
```

---

### 3. Get Specific Case
**Endpoint**: `GET /api/calculator/cases/{case_id}`  
**Authentication**: Required ✅  
**Access Control**: User can only access their own cases (403 if not owner)

#### Request
```
GET /api/calculator/cases/123
Authorization: Bearer <token>
```

#### Successful Response (200)
```json
{
  "success": true,
  "message": "Case retrieved successfully",
  "case": {
    "id": 123,
    "patient_name": "John Doe",
    "patient_id": "P12345",
    "date": "2026-05-09",
    "surgery_type": "General Surgery",
    "anesthetic_agent": "Sevoflurane",
    "created_at": "2026-05-09T14:30:00"
  }
}
```

#### Error Responses

**401 Unauthorized** (Invalid/Missing Token)
```json
{
  "success": false,
  "message": "Token is missing"
}
```

**403 Forbidden** (Case belongs to different user)
```json
{
  "success": false,
  "message": "Unauthorized access to this case"
}
```

**404 Not Found** (Case doesn't exist)
```json
{
  "success": false,
  "message": "Case not found"
}
```

---

### 4. Update Case
**Endpoint**: `PUT /api/calculator/cases/{case_id}`  
**Authentication**: Required ✅  
**Access Control**: User can only update their own cases (403 if not owner)

#### Request Headers
```json
{
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
}
```

#### Request Body (only include fields to update)
```json
{
  "patient_name": "John Doe Updated",
  "biro_formula": 46.5,
  "dion_formula": 49.2,
  "notes": "Updated notes"
}
```

#### Successful Response (200)
```json
{
  "success": true,
  "message": "Case updated successfully",
  "case": {
    "id": 123,
    "patient_name": "John Doe Updated",
    "patient_id": "P12345",
    "date": "2026-05-09",
    "biro_formula": 46.5,
    "dion_formula": 49.2,
    "notes": "Updated notes",
    "created_at": "2026-05-09T14:30:00"
  }
}
```

#### Error Responses

**401 Unauthorized**
```json
{
  "success": false,
  "message": "Token is missing"
}
```

**403 Forbidden** (Not case owner)
```json
{
  "success": false,
  "message": "Unauthorized access to this case"
}
```

**404 Not Found**
```json
{
  "success": false,
  "message": "Case not found"
}
```

---

### 5. Delete Case
**Endpoint**: `DELETE /api/calculator/cases/{case_id}`  
**Authentication**: Required ✅  
**Access Control**: User can only delete their own cases (403 if not owner)

#### Request
```
DELETE /api/calculator/cases/123
Authorization: Bearer <token>
```

#### Successful Response (200)
```json
{
  "success": true,
  "message": "Case deleted successfully"
}
```

#### Error Responses

**401 Unauthorized**
```json
{
  "success": false,
  "message": "Token is missing"
}
```

**403 Forbidden** (Case belongs to different user)
```json
{
  "success": false,
  "message": "Unauthorized access to this case"
}
```

**404 Not Found**
```json
{
  "success": false,
  "message": "Case not found"
}
```

---

## Authentication Endpoints (Already Implemented)

### Login
**Endpoint**: `POST /api/auth/login`  
**Authentication**: Not Required  

#### Request
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Response
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Register
**Endpoint**: `POST /api/auth/register`  
**Authentication**: Not Required  

#### Request
```json
{
  "full_name": "John Doe",
  "email": "user@example.com",
  "password": "password123",
  "confirm_password": "password123"
}
```

#### Response
```json
{
  "success": true,
  "message": "Registration successful",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## Status Codes Reference

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Operation completed successfully |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid input or missing required fields |
| 401 | Unauthorized | Missing or invalid authentication token |
| 403 | Forbidden | Authenticated but no permission for resource |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Internal server error |

---

## Security Notes

### Token Validation
1. Token is extracted from `Authorization: Bearer <token>` header
2. Token is validated using JWT signature and expiration time
3. User ID is extracted from decoded token payload
4. User ID is used to verify resource ownership

### Data Access Control
1. **CREATE**: Automatically associates case with authenticated user
2. **READ**: Only returns/allows access to user's own cases
3. **UPDATE**: Only allows modification of user's own cases
4. **DELETE**: Only allows deletion of user's own cases

### What the Backend Does NOT Trust
- ❌ `user_id` sent in request body (ignored)
- ❌ `user_id` sent as query parameter (ignored)
- ❌ `user_id` from any source except JWT token
- ✅ Only trusts user_id from validated JWT token payload

---

## Example Client Code (cURL)

### Get all cases
```bash
curl -X GET "http://localhost:5000/api/calculator/cases" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

### Create new case
```bash
curl -X POST "http://localhost:5000/api/calculator/cases" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "John Doe",
    "patient_id": "P12345",
    "date": "2026-05-09",
    "surgery_type": "General Surgery",
    "anesthetic_agent": "Sevoflurane",
    "molecular_mass": "200.5",
    "vapor_constant": "45.8",
    "density": "1.52"
  }'
```

### Update case
```bash
curl -X PUT "http://localhost:5000/api/calculator/cases/123" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "John Doe Updated",
    "biro_formula": 46.5
  }'
```

### Delete case
```bash
curl -X DELETE "http://localhost:5000/api/calculator/cases/123" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Difference from Previous API

### BEFORE (No Isolation)
```
GET /api/calculator/cases
→ Returns ALL cases from database (any user could see any case)
→ No authentication required
```

### AFTER (With Isolation)
```
GET /api/calculator/cases
→ Requires Authorization header with valid JWT token
→ Returns ONLY cases belonging to authenticated user
→ Returns 401 if token missing/invalid
```

---

## Migration Guide for Client Apps

If updating from the old API:

1. **Login and store token**
   ```dart
   final token = response['token'];
   await SharedPreferences.getInstance()
     .setString('authToken', token);
   ```

2. **Send token in all requests**
   ```dart
   final token = await SharedPreferences.getInstance()
     .getString('authToken');
   headers['Authorization'] = 'Bearer $token';
   ```

3. **Handle 401 errors**
   ```dart
   if (response.statusCode == 401) {
     await AuthService.logout();
     Navigator.pushReplacementNamed(context, '/login');
   }
   ```

4. **Handle 403 errors**
   ```dart
   if (response.statusCode == 403) {
     showErrorDialog('You do not have permission for this action');
   }
   ```

---

## Testing the API

Use Postman, Insomnia, or similar tools:

1. **Register**: POST /api/auth/register
2. **Copy token** from response
3. **Set Authorization** header with Bearer token
4. **Test endpoints** with your token
5. **Try with invalid token** to see 401 error
6. **Try accessing others' cases** to see 403 error

---

## Rate Limiting (Future)

Recommended rate limits per authenticated user:
- Login attempts: 5 per minute
- API requests: 100 per minute
- Case creation: 10 per hour
- Case deletion: 5 per hour
