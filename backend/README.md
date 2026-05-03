# 🏥 MacMind Medical Calculator Backend

A production-ready Python Flask backend for the MacMind medical calculator mobile application. Provides secure user authentication, medication dosage calculations, and data persistence with PostgreSQL.

## ✨ Features

- ✅ **User Authentication** - Secure registration and login with JWT tokens
- ✅ **Medication Dosage Calculator** - Intelligent dosage computation with safety adjustments
- ✅ **PostgreSQL Integration** - Persistent user data and calculation history with SQLAlchemy ORM
- ✅ **CORS Enabled** - Compatible with Flutter and web clients
- ✅ **Error Handling** - Comprehensive error responses with proper HTTP status codes
- ✅ **Security** - Password hashing with bcrypt, JWT token validation
- ✅ **Modular Architecture** - Clean code with Flask Blueprints
- ✅ **Environment Configuration** - Easy setup with .env files
- ✅ **Production Ready** - Follows best practices and industry standards

---

## 📋 Prerequisites

Before starting, ensure you have:

- **Python 3.8+** installed ([Download](https://www.python.org/downloads/))
- **PostgreSQL Server** (Free at [PostgreSQL.com](https://dev.PostgreSQL.com/downloads/) or use [XAMPP](https://www.apachefriends.org/), [WAMP](http://www.wampserver.com/), [MAMP](https://www.mamp.info/))
- **pip** (Python package manager) - comes with Python
- **Git** (for version control)
- **Postman** or **cURL** (for API testing, optional)

### Check Python Installation

```bash
python --version
pip --version
```

---

## 🚀 Quick Start (5 minutes)

### 1. Set Up Virtual Environment

Create a Python virtual environment to isolate dependencies:

```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

You should see `(venv)` in your terminal prompt.

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment Variables

1. Copy `.env.example` to `.env`:
   ```bash
   # Windows
   copy .env.example .env
   
   # macOS/Linux
   cp .env.example .env
   ```

2. Update `.env` with your PostgreSQL connection string:
   ```env
   DATABASE_URL=postgresql+psycopg://root:password@localhost:3306/macmind
   ```
   Replace:
   - `root` with your PostgreSQL username
   - `password` with your PostgreSQL password
   - `localhost` with your PostgreSQL host
   - `3306` with your PostgreSQL port (default is 3306)
   - `macmind` with your database name

### 4. Create PostgreSQL Database (First Time)

```bash
# Open PostgreSQL command line
PostgreSQL -u root -p

# Enter your password and run:
CREATE DATABASE IF NOT EXISTS macmind CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

Or use PostgreSQL Workbench / phpMyAdmin to create the database.

### 5. Start the Server

```bash
python run.py
```

Expected output:
```
╔════════════════════════════════════════════╗
║     MacMind Medical Calculator Backend     ║
╚════════════════════════════════════════════╝

🚀 Server starting on http://127.0.0.1:5000
🔧 Environment: DEVELOPMENT
🐛 Debug Mode: ON
📦 Database: PostgreSQL
🔐 CORS: Enabled

✅ Server is ready!
✅ Database tables initialized
```

### 6. Test the Server

Open your browser or use a terminal:

```bash
# Test health endpoint
curl http://127.0.0.1:5000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "message": "Server is running",
  "timestamp": "2024-01-15T10:30:45.123456"
}
```

✅ **Server is running successfully!**

---

## 📁 Project Structure

```
backend/
├── run.py                    # Entry point - start server here
├── requirements.txt          # Python dependencies
├── .env                      # Environment variables (your config)
├── .env.example              # Environment template
├── config/
│   └── config.py            # Configuration classes for dev/prod
├── app/
│   ├── __init__.py          # Flask app factory
│   ├── routes/              # API endpoints (blueprints)
│   │   ├── health.py        # Health check endpoint
│   │   ├── auth.py          # Authentication routes
│   │   └── calculator.py    # Dosage calculation routes
│   ├── models/              # Database models
│   │   └── user.py          # User model with MongoDB
│   └── utils/               # Helper functions
│       ├── security.py      # Password hashing & JWT tokens
│       └── decorators.py    # Route protection decorators
└── README.md                # This file
```

---

## 🔌 API Endpoints

### Base URL
```
http://127.0.0.1:5000/api
```

### Health Check

**GET** `/health`

Check if server is running.

```bash
curl http://127.0.0.1:5000/api/health
```

Response:
```json
{
  "status": "healthy",
  "message": "Server is running",
  "timestamp": "2024-01-15T10:30:45"
}
```

---

### Authentication

#### Register User

**POST** `/auth/register`

Create a new user account.

Request:
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

Request body:
```json
{
  "email": "doctor@hospital.com",      // Required: Email address
  "password": "SecurePass123",         // Required: Min 6 characters
  "username": "dr_smith",              // Required: Min 3 characters
  "hospital_id": "HOSP_001"            // Optional: Hospital identifier
}
```

Response (201 Created):
```json
{
  "message": "Registration successful",
  "user": {
    "user_id": "507f1f77bcf86cd799439011",
    "email": "doctor@hospital.com",
    "username": "dr_smith"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

#### Login User

**POST** `/auth/login`

Login with email and password.

Request:
```bash
curl -X POST http://127.0.0.1:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@hospital.com",
    "password": "SecurePass123"
  }'
```

Response (200 OK):
```json
{
  "message": "Login successful",
  "user": {
    "user_id": "507f1f77bcf86cd799439011",
    "email": "doctor@hospital.com",
    "username": "dr_smith"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

#### Verify Token

**POST** `/auth/verify-token`

Verify JWT token validity.

Request:
```bash
curl -X POST http://127.0.0.1:5000/api/auth/verify-token \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

Response (200 OK):
```json
{
  "message": "Token is valid",
  "user": {
    "user_id": "507f1f77bcf86cd799439011",
    "email": "doctor@hospital.com"
  }
}
```

---

#### Get User Profile

**GET** `/auth/profile`

Get current user's profile information.

Request:
```bash
curl http://127.0.0.1:5000/api/auth/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

Response (200 OK):
```json
{
  "user": {
    "user_id": "507f1f77bcf86cd799439011",
    "email": "doctor@hospital.com",
    "username": "dr_smith",
    "hospital_id": "HOSP_001",
    "created_at": "2024-01-15T10:30:45",
    "is_active": true
  }
}
```

---

### Medication Calculator

#### Calculate Dosage

**POST** `/calculator/calculate`

Calculate medication dosage with safety adjustments.

Request:
```bash
curl -X POST http://127.0.0.1:5000/api/calculator/calculate \
  -H "Content-Type: application/json" \
  -d '{
    "weight": 70,
    "concentration": 5,
    "age": 45,
    "comorbidities": ["renal_impairment"]
  }'
```

Request body:
```json
{
  "weight": 70,                          // Required: Patient weight in kg
  "concentration": 5,                    // Required: Drug concentration (mg/mL)
  "age": 45,                             // Optional: Patient age
  "comorbidities": ["renal_impairment"]  // Optional: List of conditions
}
```

Response (200 OK):
```json
{
  "success": true,
  "calculation": {
    "base_dosage": 1050,
    "adjusted_dosage": 1050,
    "final_dosage": 525,
    "volume_needed": 105,
    "concentration": 5,
    "warnings": [
      "Renal impairment: Reduced dosage by 50%"
    ],
    "unit": "mg",
    "volume_unit": "mL"
  }
}
```

**Supported Comorbidities:**
- `renal_impairment` - Reduces dosage by 50%
- `hepatic_impairment` - Reduces dosage by 25%
- `pregnancy` - Adds safety warning

---

#### Quick Calculate

**POST** `/calculator/quick-calculate`

Fast dosage calculation without detailed analysis.

Request:
```bash
curl -X POST http://127.0.0.1:5000/api/calculator/quick-calculate \
  -H "Content-Type: application/json" \
  -d '{
    "weight": 70,
    "concentration": 5
  }'
```

Response (200 OK):
```json
{
  "dosage": 1050,
  "volume": 210,
  "unit": "mg",
  "volume_unit": "mL"
}
```

---

#### Get Calculation History

**GET** `/calculator/history`

Get user's previous calculations.

Request:
```bash
curl http://127.0.0.1:5000/api/calculator/history \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

Response (200 OK):
```json
{
  "user_id": "507f1f77bcf86cd799439011",
  "calculations": [],
  "message": "No calculation history yet"
}
```

---

## 🔐 Authentication

The API uses **JWT (JSON Web Token)** for authentication.

### How It Works

1. **Register** - Create account, receive token
2. **Login** - Provide credentials, receive token
3. **Protected Routes** - Include token in `Authorization` header
4. **Token Format** - `Bearer <token>`

### Using Tokens

Add this header to protected requests:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTA3ZjFmNzdiY2Y4NmNkNzk5NDM5MDExIiwiZW1haWwiOiJkb2N0b3JAaG9zcGl0YWwuY29tIiwiaWF0IjoxNzA1MzEzODQ1LCJleHAiOjE3MDgwMzI2NDV9.abc123...
```

**Important:** Never share or expose your JWT token!

---

## 📊 Database Schema

### Users Table

```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(80) UNIQUE NOT NULL,
  email VARCHAR(120) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  hospital_id VARCHAR(120),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  INDEX idx_email (email),
  INDEX idx_username (username)
);
```

**SQL Example:**
```sql
SELECT * FROM users WHERE email = 'doctor@hospital.com';
INSERT INTO users (username, email, password, hospital_id) 
VALUES ('dr_smith', 'doctor@hospital.com', '$2b$12$...', 'HOSP_001');
```

---

## 🛠️ Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+psycopg://user:pass@localhost:3306/macmind` |
| `FLASK_ENV` | Environment type | `development` or `production` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `5000` |
| `SECRET_KEY` | Flask session secret | Auto-generated |
| `JWT_SECRET_KEY` | JWT signing key | Auto-generated |
| `EMAIL_USER` | Email sender address | None |
| `EMAIL_PASS` | Email password | None |
| `CORS_ORIGINS` | Allowed origins | `*` |

### Generate Secure Keys

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

---

## 🗄️ MongoDB Setup

### Create Free MongoDB Database

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Sign up for free account
3. Create new project
4. Create M0 (free) cluster
5. Get connection string:
   - Database Deployments → Connect → Connect with MongoDB Compass
   - Copy connection string
   - Replace `<password>` with your database user password
   - Replace `myFirstDatabase` with `macmind`

### Connection String Format

```
mongodb+srv://username:password@cluster.mongodb.net/macmind?retryWrites=true&w=majority
```

### Test Connection

```bash
# From Python
python -c "
from pymongo import MongoClient
uri = 'YOUR_MONGO_URI'
client = MongoClient(uri)
print('✅ Connected to MongoDB!')
print(f'Databases: {client.list_database_names()}')
"
```

---

## 🧪 Testing the API

### Using cURL (Command Line)

Test health endpoint:
```bash
curl http://127.0.0.1:5000/api/health
```

### Using Postman

1. Download [Postman](https://www.postman.com/downloads/)
2. Create new request
3. Set method to `POST`
4. URL: `http://127.0.0.1:5000/api/auth/register`
5. Headers → Add: `Content-Type: application/json`
6. Body → Raw (JSON):
```json
{
  "email": "test@example.com",
  "password": "TestPass123",
  "username": "testuser"
}
```
7. Click Send

### Using Python

```python
import requests

# Test health
response = requests.get('http://127.0.0.1:5000/api/health')
print(response.json())

# Register
data = {
    'email': 'test@example.com',
    'password': 'TestPass123',
    'username': 'testuser'
}
response = requests.post('http://127.0.0.1:5000/api/auth/register', json=data)
print(response.json())
```

---

## 🐛 Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'flask'"

**Solution:** Install requirements
```bash
pip install -r requirements.txt
```

### Issue: "Can't connect to PostgreSQL server" or "Access denied"

**Troubleshooting:**
1. Check DATABASE_URL in `.env`
2. Verify PostgreSQL server is running
3. Verify username and password are correct
4. Ensure database exists:
   ```bash
   PostgreSQL -u root -p
   CREATE DATABASE macmind CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

**Test connection:**
```bash
PostgreSQL -u root -p -h localhost -e "SELECT 1"
```

### Issue: "(1045, "Access denied for user 'root'@'localhost'"

**Solution:** Reset PostgreSQL password or use correct credentials
- Check DATABASE_URL format: `postgresql+psycopg://username:password@localhost:3306/dbname`
- If using localhost without password: `postgresql+psycopg://root@localhost:3306/macmind`

### Issue: "Table 'macmind.users' doesn't exist"

**Solution:** Database tables are created automatically on first run, but if needed:
```bash
PostgreSQL -u root -p macmind < schema.sql
```

Or manually create:
```sql
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(80) UNIQUE NOT NULL,
  email VARCHAR(120) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  hospital_id VARCHAR(120),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  INDEX idx_email (email)
);
```

### Issue: Port 5000 is already in use

**Solution:** Use different port
```bash
# Change PORT in .env
PORT=5001

# Or run with different port
python run.py  # Will use PORT from .env
```

### Issue: "CORS policy" errors in browser

**Solution:** Update CORS_ORIGINS in `.env`
```env
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:8080
```

### Issue: TypeError when starting server

**Solution:** Check Python version
```bash
python --version  # Should be 3.8 or higher
```

---

## 📦 Production Deployment

### Before Deploying

1. **Change security keys:**
   ```bash
   python -c "import secrets; print(secrets.token_hex(32))"
   ```
   Use generated values for `SECRET_KEY` and `JWT_SECRET_KEY`

2. **Update environment:**
   ```env
   FLASK_ENV=production
   DEBUG=False
   ```

3. **Set strong CORS origins:**
   ```env
   CORS_ORIGINS=https://yourdomain.com,https://api.yourdomain.com
   ```

### Deploy to Render

1. Push code to GitHub
2. Go to [Render.com](https://render.com)
3. Create new Web Service
4. Connect GitHub repository
5. Set environment variables
6. Deploy

### Deploy to Heroku

```bash
# Install Heroku CLI
heroku login
heroku create macmind-backend
git push heroku main
```

---

## 📚 Additional Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [Flask-SQLAlchemy Documentation](https://flask-sqlalchemy.palletsprojects.com/)
- [PostgreSQL Documentation](https://dev.PostgreSQL.com/doc/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [JWT Guide](https://jwt.io/introduction)
- [REST API Best Practices](https://www.restfulapi.net/)
- [Security Best Practices](https://owasp.org/www-project-web-security-testing-guide/)

---

## 📝 API Documentation

### Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | Success | Login successful |
| 201 | Created | User registered |
| 400 | Bad Request | Invalid input |
| 401 | Unauthorized | Invalid credentials |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Database connection failed |

### Error Response Format

```json
{
  "error": "Error description",
  "details": "Additional information (optional)"
}
```

---

## 🤝 Contributing

Guidelines for contributing to this backend:

1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes and test
3. Commit: `git commit -am 'Add new feature'`
4. Push: `git push origin feature/new-feature`
5. Create Pull Request

---

## 📄 License

This project is part of the MacMind medical calculator application.

---

## ❓ FAQ

**Q: Can I use this backend with iOS app?**
A: Yes! The backend is platform-agnostic and works with any client that makes HTTP requests.

**Q: Is the calculator dosage medically accurate?**
A: This calculator is for **demonstration purposes only**. Always consult medical professionals for actual medication dosing.

**Q: How do I enable database logging?**
A: Set in `.env`:
```env
SQLALCHEMY_ECHO=true
```

**Q: Can I migrate from MongoDB to PostgreSQL?**
A: Yes! The new version uses PostgreSQL with SQLAlchemy ORM. Data won't migrate automatically, but the schema is cleaner and easier to maintain.

**Q: How do I connect to a remote PostgreSQL database?**
A: Update DATABASE_URL in `.env`:
```env
DATABASE_URL=postgresql+psycopg://username:password@hostname.com:3306/macmind
```

**Q: How do I backup my PostgreSQL database?**
A: Use pg_dump:
```bash
pg_dump -u root -p macmind > backup.sql
```

**Q: Can I modify the API endpoints?**
A: Yes! Follow the existing patterns in `app/routes/` and update the Flutter client accordingly.

---

## 🆘 Support

For issues or questions:
1. Check this README
2. Review error messages and terminal output
3. Check [Stack Overflow](https://stackoverflow.com/) for similar issues
4. Open GitHub issue with error details

---

**Happy coding! 🚀**

Generated: 2024
Version: 1.0


