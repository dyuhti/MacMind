# ⚡ Quick Reference - Backend Cheat Sheet

Print this or bookmark it! ⭐

---

## 🚀 Start Backend (3 Commands)

```bash
cd backend
source venv/bin/activate          # macOS/Linux
# or: venv\Scripts\activate       # Windows
python run.py
```

✅ Server ready at: `http://127.0.0.1:5000`

---

## 🧪 Test Everything (1 Command)

```bash
python test_auth.py
```

✅ Should show: `6/6 tests passed`

---

## 📝 Register User (cURL)

```bash
curl -X POST http://127.0.0.1:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@hospital.com",
    "password": "SecurePass123",
    "username": "dr_smith"
  }'
```

**Response:** `201 Created` + token

---

## 🔐 Login User (cURL)

```bash
curl -X POST http://127.0.0.1:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@hospital.com",
    "password": "SecurePass123"
  }'
```

**Response:** `200 OK` + token

---

## ✅ Health Check (cURL)

```bash
curl http://127.0.0.1:5000/api/health
```

**Response:** `200 OK` + timestamp

---

## 🔑 Verify Token (cURL)

```bash
curl -X POST http://127.0.0.1:5000/api/auth/verify-token \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response:** `200 OK` + user data

---

## 👤 Get Profile (cURL)

```bash
curl http://127.0.0.1:5000/api/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response:** `200 OK` + user profile

---

## 📊 Calculate Dosage (cURL)

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

**Response:** `200 OK` + dosage calculation

---

## ⚙️ Configuration Files

### `.env` - Main Configuration

```env
FLASK_ENV=development
DATABASE_URL=mysql+pymysql://root:password@localhost:3306/macmind
PORT=5000
CORS_ORIGINS=*
```

### `config/config.py` - App Configuration

Environment-specific settings (dev/test/prod)

---

## 📂 Project Structure

```
backend/
├── run.py                 ← Start here
├── test_auth.py          ← Test here
├── requirements.txt       ← Dependencies
├── .env                  ← Configuration
│
├── app/
│   ├── __init__.py       ← App factory
│   ├── routes/
│   │   ├── health.py     ← Health endpoint
│   │   ├── auth.py       ← Login/Register
│   │   └── calculator.py ← Calculations
│   ├── models/
│   │   └── user.py       ← User model
│   └── utils/
│       ├── security.py   ← JWT/Hashing
│       └── decorators.py ← Auth decorators
│
├── config/
│   └── config.py         ← Settings
│
└── docs/
    ├── README.md                 ← Main docs
    ├── MYSQL_SETUP.md           ← MySQL guide
    ├── API_TESTING.md           ← API tests
    ├── FLUTTER_INTEGRATION.md   ← Flutter guide
    └── TESTING_DEPLOYMENT.md    ← Deployment
```

---

## 🔧 Common Commands

| Task | Command |
|------|---------|
| Start server | `python run.py` |
| Run tests | `python test_auth.py` |
| Install deps | `pip install -r requirements.txt` |
| List deps | `pip freeze` |
| Connect to MySQL | `mysql -u root -p macmind` |
| View logs | `tail -f app.log` |
| Stop server | `CTRL+C` |

---

## 🐛 Troubleshooting

| Problem | Fix |
|---------|-----|
| Server won't start | Check `.env`, MySQL running |
| Tests fail | Run `python run.py` first |
| MySQL connection error | Verify DATABASE_URL in `.env` |
| Flutter can't connect | Use `10.0.2.2` for emulator |
| CORS error | Update CORS_ORIGINS in `.env` |

---

## 📱 Flutter Integration

Update `api_config.dart`:

```dart
// Emulator
static const String localApiUrl = 'http://10.0.2.2:5000';

// Real device (get IP with: ipconfig)
// static const String localApiUrl = 'http://192.168.1.100:5000';
```

Update `auth_service.dart` with:

```dart
static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/auth/login"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email, "password": password}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {"success": true, "token": data['token']};
  }
  return {"success": false, "error": "Login failed"};
}
```

---

## ✅ Success Checklist

- [ ] Backend starts without errors
- [ ] `python test_auth.py` passes all 6 tests
- [ ] MySQL database has `users` table
- [ ] Can register user via cURL
- [ ] Can login user via cURL
- [ ] Token is returned and valid
- [ ] Flutter app connects to backend
- [ ] Flutter login screen works

---

## 📊 HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success ✅ |
| 201 | Created ✅ |
| 400 | Bad request ❌ |
| 401 | Unauthorized ❌ |
| 404 | Not found ❌ |
| 500 | Server error ❌ |

---

## 🎯 Workflow

```
1. Start Backend          → python run.py
   ↓
2. Run Tests             → python test_auth.py
   ↓
3. Test cURL            → curl http://127.0.0.1:5000/api/health
   ↓
4. Test Flutter         → flutter run
   ↓
5. Deploy (if ready)    → See TESTING_DEPLOYMENT.md
```

---

## 🔐 Security Reminders

✅ Passwords hashed with bcrypt
✅ JWT tokens for authentication
✅ SQL injection protected (SQLAlchemy)
✅ CORS enabled for Flutter
✅ Password validation (min 6 chars)
✅ Email format validation

---

## 📞 Quick Help

| Question | Answer |
|----------|--------|
| Where's my API? | `http://127.0.0.1:5000/api` |
| How do I login? | POST `/auth/login` with email + password |
| Where's the database? | MySQL at `localhost:3306` |
| How do I test? | Run `python test_auth.py` |
| How do I deploy? | See `TESTING_DEPLOYMENT.md` |
| Is it secure? | Yes, bcrypt + JWT + SQLAlchemy |

---

## 💾 File Locations

| Purpose | File |
|---------|------|
| Start server | `run.py` |
| Run tests | `test_auth.py` |
| Config | `.env` |
| Auth routes | `app/routes/auth.py` |
| User model | `app/models/user.py` |
| Security utils | `app/utils/security.py` |

---

## 🚀 Quick Deploy (Render)

```bash
# 1. Push to GitHub
git push origin main

# 2. Go to render.com
# 3. Connect GitHub repo
# 4. Set environment variables
# 5. Deploy!
```

Get URL: `https://your-app.onrender.com`

Update Flutter: `static const String productionBaseUrl = "https://your-app.onrender.com";`

---

## ⚡ One-Liner Commands

```bash
# Full test flow
python run.py & sleep 2 && python test_auth.py

# Check MySQL
mysql -u root -p -e "SELECT * FROM macmind.users;"

# View all endpoints
grep -r "@.*route" app/routes/

# Kill server on port 5000
lsof -ti:5000 | xargs kill -9
```

---

## 📋 Endpoints Reference

```
GET  /api/health                    ← Health check
POST /api/auth/register             ← Create account
POST /api/auth/login                ← Login
GET  /api/auth/profile              ← Get profile (auth required)
POST /api/auth/verify-token         ← Verify token (auth required)
POST /api/calculator/calculate      ← Calculate dosage
POST /api/calculator/quick-calculate ← Quick calc
```

---

## 🎓 Learning Resources

- **API Docs** → See `API_TESTING.md`
- **MySQL Help** → See `MYSQL_SETUP.md`
- **Flutter Guide** → See `FLUTTER_INTEGRATION.md`
- **Deployment** → See `TESTING_DEPLOYMENT.md`
- **Full README** → See `README.md`

---

**Bookmark this page!** 📌

Print and keep next to your desk for quick reference during development! 👍

---

**Status: ✅ READY TO USE**

Your backend is production-ready. Just start it and go! 🚀
