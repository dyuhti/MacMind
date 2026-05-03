# 🏗️ MacMind Architecture Overview

Complete system architecture and data flow diagrams.

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MacMind Medical Calculator                    │
└─────────────────────────────────────────────────────────────────────┘

                              PRESENTATION LAYER
┌──────────────────────────────────────────────────────────────────────┐
│                          Flutter Mobile App                           │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Login Screen  │  Dashboard  │  Calculator  │  History      │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────────────────────────┬────────────────────────────────────┘
                                │
                   HTTP/HTTPS (REST API calls)
                                │
                                ▼
                          APPLICATION LAYER
┌───────────────────────────────────────────────────────────────────────┐
│                    Flask Backend (Python 3)                            │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  API Routes                                                     │ │
│  │  ┌──────────────┐  ┌───────────────┐  ┌─────────────────────┐ │ │
│  │  │ Auth Routes  │  │ Calculator    │  │ Health Check       │ │ │
│  │  │              │  │ Routes        │  │                    │ │ │
│  │  │ • Register   │  │               │  │ • Status endpoint  │ │ │
│  │  │ • Login      │  │ • Calculate   │  │                    │ │ │
│  │  │ • Verify     │  │ • Quick-calc  │  └─────────────────────┘ │ │
│  │  │ • Profile    │  │ • History     │                          │ │
│  │  └──────────────┘  └───────────────┘                          │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  Middleware & Security                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   │ │
│  │  │ JWT Auth     │  │ CORS         │  │ Validation          │   │ │
│  │  │ Decorators   │  │ Protection   │  │ Decorators          │   │ │
│  │  └──────────────┘  └──────────────┘  └─────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  Business Logic Layer                                           │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   │ │
│  │  │ User Model   │  │ Auth Service │  │ Calculation Engine  │   │ │
│  │  │              │  │              │  │                     │   │ │
│  │  │ • CRUD ops   │  │ • Password   │  │ • Dosage calc       │   │ │
│  │  │ • Validation │  │   hashing    │  │ • Age adjustment    │   │ │
│  │  │              │  │ • Token gen  │  │ • Comorbidity logic │   │ │
│  │  └──────────────┘  └──────────────┘  └─────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  Security Layer                                                 │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   │ │
│  │  │ Bcrypt       │  │ JWT          │  │ Password            │   │ │
│  │  │              │  │              │  │ Validation          │   │ │
│  │  │ • Hash pwd   │  │ • Create tok │  │ • Min 6 chars       │   │ │
│  │  │ • Verify pwd │  │ • Verify tok │  │ • Email format      │   │ │
│  │  │              │  │ • 30-day exp │  │ • Unique check      │   │ │
│  │  └──────────────┘  └──────────────┘  └─────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                    SQL Queries (SQLAlchemy ORM)
                             │
                             ▼
                          DATA LAYER
┌───────────────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database (localhost:3306)                     │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  macmind Database                                              │  │
│  │  ┌──────────────────────────────────────────────────────────┐ │  │
│  │  │  users table                                             │ │  │
│  │  │  ┌─────┬──────────┬──────────────┬──────────┬────────┐  │ │  │
│  │  │  │ id  │ username │ email        │ password │ ...    │  │ │  │
│  │  │  ├─────┼──────────┼──────────────┼──────────┼────────┤  │ │  │
│  │  │  │ 1   │ dr_smith │ dr@hosp.com  │ $bcrypt  │ active │  │ │  │
│  │  │  │ 2   │ nurse_jo │ jo@hosp.com  │ $bcrypt  │ active │  │ │  │
│  │  │  └─────┴──────────┴──────────────┴──────────┴────────┘  │ │  │
│  │  └──────────────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                          │
└─────────────────────────────────────────────────────────────────┘

1. USER REGISTRATION
═══════════════════
   Flutter App                          Backend
   │                                    │
   ├─ Email: doctor@hospital.com ────────►│
   ├─ Password: SecurePass123 ──────────►│
   └─ Username: dr_smith ────────────────►│
                                         │
                                    Validation
                                         │
                                    Email format ✓
                                    Pass min 6 ✓
                                    User unique ✓
                                         │
                                    Hash password
                                    (bcrypt)
                                         │
                                    Store in DB
                                         │
                                    Generate JWT
                                         │
   ◄───────────────────────────────────── ◄
   Receive token + user data
   Save to SharedPreferences

2. USER LOGIN
════════════
   Flutter App                          Backend
   │                                    │
   ├─ Email: doctor@hospital.com ────────►│
   └─ Password: SecurePass123 ──────────►│
                                         │
                                    Find user in DB
                                         │
                                    Verify password
                                    (bcrypt compare)
                                         │
                                    Password ✓
                                         │
                                    Generate JWT
                                    Expires: 30 days
                                         │
   ◄───────────────────────────────────── ◄
   {
     "message": "Login successful",
     "user": {...},
     "token": "eyJhbGc..."
   }
   Save token to SharedPreferences


3. AUTHENTICATED REQUEST
════════════════════════
   Flutter App                          Backend
   │                                    │
   ├─ Authorization: Bearer TOKEN ─────►│
   ├─ GET /api/auth/profile ──────────►│
                                         │
                                    Extract token
                                    from header
                                         │
                                    Verify JWT
                                    signature ✓
                                    Decode payload
                                    Check expiry ✓
                                         │
                                    Token valid ✓
                                         │
                                    Return user data
                                         │
   ◄───────────────────────────────────── ◄
   {
     "user": {
       "user_id": 1,
       "email": "doctor@hospital.com",
       "username": "dr_smith"
     }
   }
```

---

## 🧮 Calculator Flow

```
┌─────────────────────────────────────────────────────────────────┐
│              DOSAGE CALCULATION FLOW                            │
└─────────────────────────────────────────────────────────────────┘

Flask App                           Backend
│                                   │
├─ POST /api/calculator/calculate──►│
│  {                                │
│    "weight": 70,                  │
│    "concentration": 5,            │
│    "age": 45,                     │
│    "comorbidities": ["renal_..."]│
│  }                                │
                                    │
                               Input Validation
                                    │
                          weight: 70 kg ✓
                          concentration: 5 ✓
                          age: 45 years ✓
                                    │
                          Base Calculation
                          ─────────────────
                          Base = Weight × 15
                          Base = 70 × 15 = 1050
                                    │
                       Age Adjustment (< 50)
                          ─────────────────
                          Age < 50: 1.0x
                          Adjusted = 1050 × 1.0
                          Adjusted = 1050
                                    │
                    Comorbidity Adjustment
                          ─────────────────
                          Renal impairment: 0.75x
                          Final = 1050 × 0.75
                          Final = 787.5
                                    │
                          Volume Needed
                          ─────────────
                          Volume = Final / Concentration
                          Volume = 787.5 / 5
                          Volume = 157.5 mL
                                    │
                             Warnings
                          ─────────────
                          □ High dose warning
                          □ Renal dosing noted
                          □ Age consideration noted
                                    │
   ◄───────────────────────────────────────── ◄
   {
     "base_dosage": 1050,
     "adjusted_dosage": 1050,
     "final_dosage": 787.5,
     "volume_needed": 157.5,
     "warnings": ["Renal impairment dosing applied"]
   }
```

---

## 🗄️ Database Schema

```
PostgreSQL Database: macmind
───────────────────────

┌─────────────────────────────────────────────────────────────┐
│ users table                                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Column         │ Type             │ Key        │ Default │
│  ────────────────────────────────────────────────────────  │
│  id             │ INT              │ PRIMARY    │ AUTO    │
│  username       │ VARCHAR(80)      │ UNIQUE NOT │         │
│                 │                  │ NULL       │         │
│  email          │ VARCHAR(120)     │ UNIQUE NOT │         │
│                 │                  │ NULL       │         │
│  password       │ VARCHAR(255)     │ NOT NULL   │ (hashed)│
│  hospital_id    │ VARCHAR(120)     │            │ NULL    │
│  created_at     │ DATETIME         │            │ NOW()   │
│  updated_at     │ DATETIME         │            │ NOW()   │
│  is_active      │ BOOLEAN          │            │ TRUE    │
│                                                             │
│ INDEXES:                                                    │
│  • idx_email (email)                                        │
│  • idx_username (username)                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Example Data:
─────────────
id  | username | email              | password    | hospital_id
─────────────────────────────────────────────────────────────
1   | dr_smith | dr@hospital.com   | $2b$12$... | HOSP_001
2   | nurse_jo | jo@hospital.com   | $2b$12$... | HOSP_001
3   | dr_jones | jones@hosp2.com   | $2b$12$... | HOSP_002
```

---

## 🔒 Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              SECURITY LAYERS                                │
└─────────────────────────────────────────────────────────────┘

1. INPUT VALIDATION
   ├─ Email format validation (RFC-compliant)
   ├─ Password strength (min 6 chars)
   ├─ Username validation
   └─ Field presence checking

2. AUTHENTICATION
   ├─ JWT Token (30-day expiration)
   ├─ Bearer token in Authorization header
   ├─ Token signature verification
   └─ Payload extraction and validation

3. PASSWORD SECURITY
   ├─ bcrypt hashing (12 rounds)
   ├─ Never store plaintext passwords
   ├─ Salt generated per password
   └─ Constant-time comparison

4. AUTHORIZATION
   ├─ @require_token decorator
   ├─ Current user extraction
   ├─ Role-based access (future)
   └─ Token expiry checking

5. DATA PROTECTION
   ├─ SQLAlchemy ORM (SQL injection protection)
   ├─ No sensitive data in error messages
   ├─ Secure headers
   └─ CORS protection

6. TRANSPORT SECURITY
   ├─ HTTPS in production
   ├─ HTTP in development
   └─ Secure token transmission
```

---

## 📱 Mobile App State Management

```
┌──────────────────────────────────────────────────────┐
│       FLUTTER APP STATE MANAGEMENT                  │
└──────────────────────────────────────────────────────┘

SharedPreferences Storage:
────────────────────────
┌─────────────────────────────────────┐
│ auth_token                          │
│ "eyJhbGciOiJIUzI1NiIsInR5cCI6..." │
└─────────────────────────────────────┘
        ▲ Persists across sessions
        │ Retrieved on app launch
        │ Used for authenticated requests

┌──────────────────────────────────────┐
│ user_data                            │
│ {                                   │
│   "user_id": 1,                     │
│   "email": "doctor@hospital.com",   │
│   "username": "dr_smith"            │
│ }                                   │
└──────────────────────────────────────┘
        ▲ User profile cached locally
        │ Updated after login
        │ Cleared on logout

App Session Flow:
─────────────────
1. App Launch
   └─► Check SharedPreferences for token
       ├─ Token exists? → Verify with backend
       │  └─ Valid? → Go to Dashboard
       │  └─ Invalid? → Go to Login
       └─ No token? → Go to Login

2. User Login
   └─► POST /auth/login
       ├─ Success → Save token & user
       └─ Save to SharedPreferences
       └─ Navigate to Dashboard

3. Authenticated Request
   └─► Add Bearer token to header
       ├─ GET /auth/profile
       ├─ POST /calculator/calculate
       └─ Use saved token

4. User Logout
   └─► Clear SharedPreferences
       ├─ Remove token
       ├─ Remove user data
       └─ Navigate to Login
```

---

## 🔄 Request/Response Cycle

```
1. HTTP REQUEST FLOW
════════════════════

Client                          Flask App                Database
│                               │                         │
├─ POST /api/auth/login ───────►│                         │
│  Headers: {                   │                         │
│    Content-Type: json         │                         │
│  }                            │                         │
│  Body: {email, password}      │                         │
                                │                         │
                            Parse Request               │
                                │                         │
                         Check Content-Type             │
                                │                         │
                      Validate Fields                    │
                                │                         │
                         Hash Password                   │
                                │                         │
                    Find User in Database ─────────────►│
                                │◄─ User Record ────────│
                                │                         │
                         Compare Hashes                  │
                                │                         │
                         Generate JWT                    │
                                │                         │
                        Build Response                   │
                                │                         │
    ◄────────────────────────────────────────────────────│
    HTTP 200 OK                                         │
    {                                                    │
      "message": "Login successful",                    │
      "user": {...},                                    │
      "token": "eyJhbGc..."                             │
    }

2. AUTHENTICATED REQUEST FLOW
═════════════════════════════

Client                          Flask App                Database
│                               │                         │
├─ GET /api/auth/profile ──────►│                         │
│  Headers: {                   │                         │
│    Authorization: Bearer TOKEN│                         │
│  }                            │                         │
                                │                         │
                        Extract Bearer Token             │
                                │                         │
                        Verify JWT Signature             │
                                │                         │
                         Decode Payload                  │
                                │                         │
                        Get User ID from Payload         │
                                │                         │
                    Query User from Database ────────────►│
                                │◄─ User Record ────────│
                                │                         │
                      Build Response                    │
                                │                         │
    ◄────────────────────────────────────────────────────│
    HTTP 200 OK                                         │
    {                                                    │
      "user": {                                          │
        "user_id": 1,                                    │
        "email": "doctor@hospital.com",                 │
        "username": "dr_smith"                          │
      }                                                  │
    }
```

---

## 📈 Deployment Architecture (Future)

```
┌──────────────────────────────────────────────────────────┐
│          PRODUCTION DEPLOYMENT ARCHITECTURE              │
└──────────────────────────────────────────────────────────┘

┌─────────────┐
│  Flutter    │
│   Mobile    │
│    App      │
└──────┬──────┘
       │ HTTPS
       │
       ▼
  ┌─────────────┐
  │   Render    │
  │  (or AWS)   │
  │  CDN/LB     │
  └──────┬──────┘
         │
         ▼
   ┌──────────────┐
   │  Render      │
   │  Container   │
   │   (Flask)    │
   └──────┬───────┘
          │
          ▼
   ┌──────────────────┐
   │  AWS RDS         │
   │  (PostgreSQL)         │
   │  Multi-AZ        │
   │  Backup enabled  │
   └──────────────────┘

Features:
─────────
✓ Auto-scaling
✓ Load balancing
✓ SSL/TLS encryption
✓ Database backups
✓ Monitoring & alerts
✓ Log aggregation
✓ CDN for static files
```

---

## 🎯 Technology Stack

```
Frontend:
────────
🔹 Flutter          - Cross-platform mobile framework
🔹 Dart             - Programming language
🔹 HTTP package     - REST API communication
🔹 SharedPreferences - Local data storage

Backend:
───────
🔹 Flask 2.3        - Web framework
🔹 Python 3.8+      - Programming language
🔹 SQLAlchemy 3.0   - ORM for database abstraction
🔹 psycopg 1.1      - PostgreSQL driver
🔹 bcrypt 4.0       - Password hashing
🔹 PyJWT 2.8        - JWT token creation/validation
🔹 Flask-CORS 4.0   - Cross-origin support

Database:
────────
🔹 PostgreSQL 5.7/8.0    - Relational database
🔹 InnoDB engine    - Transaction support

DevOps:
──────
🔹 Docker           - Containerization
🔹 Render/Heroku    - Cloud hosting
🔹 GitHub           - Version control
🔹 Nginx            - Reverse proxy (self-hosted)
```

---

## ✅ Architecture Validation

```
Security:      ✅ JWT + bcrypt + SQLAlchemy ORM
Scalability:   ✅ Stateless design, easily containerized
Reliability:   ✅ Error handling, input validation
Maintainability: ✅ Modular routes, clean separation
Performance:   ✅ Database indexes, efficient queries
```

---

**Your architecture is enterprise-ready!** 🚀


