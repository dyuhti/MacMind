# 🧪 API Testing Guide (cURL Commands)

Quick commands to test all auth endpoints using `curl`.

---

## 📌 Prerequisites

- Backend running: `python run.py`
- cURL installed (comes with Windows 10+, macOS, Linux)
- Postman (optional, for GUI testing)

---

## 🏥 Health Check

Test if server is running:

```bash
curl http://127.0.0.1:5000/api/health
```

**Expected Response (200):**
```json
{
  "status": "healthy",
  "message": "Server is running",
  "timestamp": "2024-01-15T10:30:45"
}
```

---

## 📝 Register User

Create a new user account:

```bash
curl -X POST http://127.0.0.1:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@hospital.com",
    "password": "SecurePass123",
    "username": "dr_smith",
    "hospital_id": "HOSP_001"
  }'
```

**Expected Response (201 Created):**
```json
{
  "message": "Registration successful",
  "user": {
    "user_id": 1,
    "email": "doctor@hospital.com",
    "username": "dr_smith"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Common Errors:**

- **400: Email already registered**
  ```json
  {"error": "Email already registered"}
  ```

- **400: Password too short**
  ```json
  {"error": "Password must be at least 6 characters"}
  ```

- **400: Username too short**
  ```json
  {"error": "Username must be at least 3 characters"}
  ```

---

## 🔐 Login User

Login with email and password:

```bash
curl -X POST http://127.0.0.1:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@hospital.com",
    "password": "SecurePass123"
  }'
```

**Expected Response (200 OK):**
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

**Error Response (401 Unauthorized):**
```json
{"error": "Invalid password"}
```

or

```json
{"error": "User not found"}
```

---

## 🔑 Verify Token

Verify if JWT token is valid:

```bash
# Replace TOKEN with actual token from login response
curl -X POST http://127.0.0.1:5000/api/auth/verify-token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Expected Response (200 OK):**
```json
{
  "message": "Token is valid",
  "user": {
    "user_id": 1,
    "email": "doctor@hospital.com"
  }
}
```

**Error Response (401):**
```json
{"error": "Token is missing"}
```

or

```json
{"error": "Invalid token"}
```

---

## 👤 Get User Profile

Retrieve authenticated user profile:

```bash
# Replace TOKEN with actual JWT token
curl http://127.0.0.1:5000/api/auth/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Expected Response (200 OK):**
```json
{
  "user": {
    "user_id": 1,
    "username": "dr_smith",
    "email": "doctor@hospital.com",
    "hospital_id": "HOSP_001",
    "created_at": "2024-01-15T10:30:45",
    "is_active": true
  }
}
```

---

## 🧪 Full Test Flow (Windows PowerShell)

Complete registration → login → verify flow:

```powershell
# 1. Health check
curl http://127.0.0.1:5000/api/health

# 2. Register user
$register = curl -X POST http://127.0.0.1:5000/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{
    "email": "user@example.com",
    "password": "Password123",
    "username": "testuser"
  }'

# Parse response to extract token (in PowerShell, this requires more parsing)
# Copy token from response

# 3. Login
$login = curl -X POST http://127.0.0.1:5000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{
    "email": "user@example.com",
    "password": "Password123"
  }'

# 4. Verify token (replace TOKEN)
curl -X POST http://127.0.0.1:5000/api/auth/verify-token `
  -H "Authorization: Bearer TOKEN"

# 5. Get profile
curl http://127.0.0.1:5000/api/auth/profile `
  -H "Authorization: Bearer TOKEN"
```

---

## 🧪 Full Test Flow (Linux/macOS Bash)

```bash
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}1. Health Check${NC}"
curl http://127.0.0.1:5000/api/health
echo -e "\n"

echo -e "${BLUE}2. Register User${NC}"
REGISTER=$(curl -s -X POST http://127.0.0.1:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "Password123",
    "username": "testuser"
  }')

TOKEN=$(echo $REGISTER | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "Response: $REGISTER"
echo -e "\n"

echo -e "${BLUE}3. Login${NC}"
LOGIN=$(curl -s -X POST http://127.0.0.1:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "Password123"
  }')

TOKEN=$(echo $LOGIN | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "Response: $LOGIN"
echo -e "\n"

echo -e "${BLUE}4. Verify Token${NC}"
curl -s -X POST http://127.0.0.1:5000/api/auth/verify-token \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | python3 -m json.tool
echo -e "\n"

echo -e "${BLUE}5. Get Profile${NC}"
curl -s http://127.0.0.1:5000/api/auth/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | python3 -m json.tool

echo -e "\n${GREEN}✅ Test complete!${NC}\n"
```

Save as `test_api.sh`, make executable, and run:
```bash
chmod +x test_api.sh
./test_api.sh
```

---

## 🐛 Debugging Tips

### View formatted JSON response

```bash
curl -s http://127.0.0.1:5000/api/health | python3 -m json.tool
```

### Show HTTP headers

```bash
curl -i http://127.0.0.1:5000/api/health
```

### Show request details

```bash
curl -v http://127.0.0.1:5000/api/health
```

### Save response to file

```bash
curl http://127.0.0.1:5000/api/health > response.json
```

### Test with custom headers

```bash
curl -H "Custom-Header: value" http://127.0.0.1:5000/api/health
```

---

## 📊 Using Postman (GUI Alternative)

1. Download [Postman](https://www.postman.com/downloads/)
2. Create new request
3. Set method to `POST`
4. URL: `http://127.0.0.1:5000/api/auth/register`
5. Headers tab → Add: `Content-Type: application/json`
6. Body tab → Raw (JSON):
```json
{
  "email": "test@example.com",
  "password": "TestPass123",
  "username": "testuser"
}
```
7. Click `Send`

---

## 🔗 API Response Headers

All responses include:

```
Content-Type: application/json
```

For authentication endpoints with token:

```
Authorization: Bearer <token>
```

---

## ✅ Status Codes Reference

| Code | Meaning | Example |
|------|---------|---------|
| **200** | OK | Login successful |
| **201** | Created | User registered |
| **400** | Bad Request | Missing fields |
| **401** | Unauthorized | Invalid credentials or token |
| **404** | Not Found | Resource not found |
| **500** | Server Error | Database error |

---

## 💡 Tips

1. **Save token** from login response for subsequent requests
2. **Test register first** before login
3. **Use `-s` flag** in curl for silent mode (no progress bar)
4. **Use `python3 -m json.tool`** to pretty-print JSON responses
5. **Copy exact token** when testing verify-token endpoint

---

## 🆘 Common Issues

**"Connection refused"**
- Server not running: `python run.py`
- Wrong port: Check `.env` (default 5000)

**"404 Not Found"**
- Wrong endpoint URL
- Check the API route (e.g., `/api/auth/login`)

**"400 Bad Request"**
- Missing required fields
- Invalid JSON format
- Check request body

**"401 Unauthorized"**
- Invalid credentials
- Wrong token format
- Token expired

---

**Ready to test? Run: `python test_auth.py`** 🚀

