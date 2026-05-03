# 🔐 Authentication System Setup Guide

## Overview

This document provides a comprehensive guide for the updated authentication system using SQLAlchemy and PostgreSQL.

## Database Schema

### Users Table

```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Fields:**
- `id`: Auto-incrementing primary key
- `full_name`: User's full name (required)
- `email`: User's email address (unique, required)
- `password`: Hashed password using bcrypt (required)
- `created_at`: Account creation timestamp

## Environment Configuration

Update your `.env` file with the following:

```env
# Flask Configuration
FLASK_ENV=development
PORT=5000

# PostgreSQL Database
DATABASE_URL=postgresql+psycopg://root:root123@localhost:3306/med_calci_app

# Security Keys
SECRET_KEY=abc123supersecretkey
JWT_SECRET_KEY=jwt123supersecretkey

# CORS
CORS_ORIGINS=*
```

## Setup Instructions

### 1. Initialize Database

Run the database initialization script:

```bash
cd backend
python init_db.py init
```

This will:
- Create the users table with the correct schema
- Create indexes for better performance
- Verify the table structure

### 2. Test User Operations

Test basic user creation and password verification:

```bash
python init_db.py test
```

### 3. Start the Flask Server

```bash
python run.py
```

The server will start on `http://127.0.0.1:5000`

## API Endpoints

### Register User

**Endpoint:** `POST /api/auth/register`

**Request Body:**
```json
{
    "full_name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePassword123",
    "confirm_password": "SecurePassword123"
}
```

**Success Response (201):**
```json
{
    "success": true,
    "message": "Registration successful",
    "user": {
        "id": 1,
        "email": "john@example.com",
        "full_name": "John Doe"
    },
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Error Response (400):**
```json
{
    "success": false,
    "message": "Email already registered"
}
```

### Login User

**Endpoint:** `POST /api/auth/login`

**Request Body:**
```json
{
    "email": "john@example.com",
    "password": "SecurePassword123"
}
```

**Success Response (200):**
```json
{
    "success": true,
    "message": "Login successful",
    "user": {
        "id": 1,
        "email": "john@example.com",
        "full_name": "John Doe"
    },
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Error Response (401):**
```json
{
    "success": false,
    "message": "Invalid password"
}
```

### Get User Profile

**Endpoint:** `GET /api/auth/profile`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
    "success": true,
    "message": "Profile retrieved successfully",
    "user": {
        "id": 1,
        "email": "john@example.com",
        "full_name": "John Doe",
        "created_at": "2024-01-15T10:30:00"
    }
}
```

**Error Response (401):**
```json
{
    "success": false,
    "message": "Token is missing"
}
```

### Verify Token

**Endpoint:** `POST /api/auth/verify-token`

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
    "success": true,
    "message": "Token is valid",
    "user": {
        "user_id": "1",
        "email": "john@example.com",
        "iat": 1705314600,
        "exp": 1708006600
    }
}
```

## Testing

### Run Full API Test Suite

```bash
python test_api.py
```

This will test:
1. User registration ✅
2. Duplicate email validation ✅
3. Password mismatch validation ✅
4. Missing fields validation ✅
5. User login ✅
6. Wrong password validation ✅
7. Non-existent user validation ✅
8. Get user profile ✅
9. Profile without token validation ✅
10. Token verification ✅

### Manual Testing with cURL

**Register:**
```bash
curl -X POST http://127.0.0.1:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Doe",
    "email": "john@example.com",
    "password": "Test1234",
    "confirm_password": "Test1234"
  }'
```

**Login:**
```bash
curl -X POST http://127.0.0.1:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "Test1234"
  }'
```

**Get Profile:**
```bash
curl -X GET http://127.0.0.1:5000/api/auth/profile \
  -H "Authorization: Bearer <token>"
```

## Security Features

✅ **Password Hashing:** Uses bcrypt with 12 rounds of salt

✅ **Email Validation:** Validates email format before storing

✅ **Password Validation:** Ensures passwords match during registration

✅ **Token-Based Auth:** JWT tokens with 30-day expiration

✅ **SQL Injection Protection:** Uses SQLAlchemy ORM

✅ **Error Handling:** Comprehensive try/except blocks

✅ **Unique Email:** Database constraint prevents duplicate emails

## Implementation Details

### Password Hashing (bcrypt)

```python
from app.utils.security import hash_password, verify_password

# Hash password
hashed = hash_password("plaintext_password")

# Verify password
is_valid = verify_password("plaintext_password", hashed)
```

### User Model

**Location:** `app/models/user.py`

**Key Methods:**
- `User.create(full_name, email, password)` - Create new user
- `User.find_by_email(email)` - Find user by email
- `User.find_by_id(user_id)` - Find user by ID
- `User.verify_password(email, password)` - Verify password
- `user.to_dict()` - Convert user to dictionary

### Authentication Routes

**Location:** `app/routes/auth.py`

**Endpoints:**
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get user profile (protected)
- `POST /api/auth/verify-token` - Verify JWT token (protected)

## Troubleshooting

### Issue: "Email already registered"
**Solution:** Use a different email address or delete the user from database

### Issue: "Password must be at least 6 characters"
**Solution:** Use a password with at least 6 characters

### Issue: "Passwords do not match"
**Solution:** Ensure password and confirm_password are identical

### Issue: "Token is missing"
**Solution:** Include Authorization header with Bearer token

### Issue: Database connection error
**Solution:** Verify PostgreSQL is running and DATABASE_URL in .env is correct

## Files Modified

1. **app/models/user.py** - Updated User model with new schema
2. **app/routes/auth.py** - Updated authentication endpoints
3. **app/utils/decorators.py** - Updated error response format
4. **config/config.py** - Database configuration (unchanged)

## What Was Removed

❌ `username` field - No longer needed (using email)
❌ `hospital_id` field - Removed per requirements
❌ `is_active` field - All users are active by default
❌ `updated_at` field - Not needed for basic auth
❌ `find_by_username()` method - Removed
❌ `update()` method - Simplified

## Next Steps

1. ✅ Initialize database with `python init_db.py init`
2. ✅ Test endpoints with `python test_api.py`
3. ✅ Integrate with Flutter frontend
4. ✅ Update API documentation
5. ✅ Deploy to production

## Support

For issues or questions, refer to:
- [API Documentation](API_TESTING.md)
- [Backend Architecture](ARCHITECTURE.md)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)


