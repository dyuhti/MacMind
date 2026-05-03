# ✅ Testing & Deployment Checklist

Complete guide for testing your backend and deploying to production.

---

## 📋 Pre-Deployment Checklist

### Backend Testing

- [ ] **PostgreSQL Database Configured**
  ```bash
  PostgreSQL -u root -p -e "SELECT 1 FROM macmind.users LIMIT 1;"
  ```

- [ ] **Environment Variables Set**
  ```bash
  # Check .env has all required fields
  cat .env
  ```

- [ ] **Dependencies Installed**
  ```bash
  pip install -r requirements.txt
  ```

- [ ] **Virtual Environment Active**
  ```bash
  # Should show (venv) in terminal
  python --version
  ```

### Running Tests

- [ ] **Health Check Passes**
  ```bash
  python run.py &
  # Wait 2 seconds, then:
  curl http://127.0.0.1:5000/api/health
  ```

- [ ] **Run Full Test Suite**
  ```bash
  python test_auth.py
  ```

- [ ] **Manual API Testing (cURL)**
  - Register user
  - Login with user
  - Verify token
  - Get profile

---

## 🧪 Detailed Testing Guide

### Step 1: Start Backend

```bash
cd backend
python -m venv venv

# Activate
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start server
python run.py
```

Expected output:
```
✅ Database tables initialized
🚀 Server starting on http://127.0.0.1:5000
✅ Server is ready!
```

### Step 2: Run Automated Tests

```bash
# In a new terminal (keep server running)
python test_auth.py
```

Expected output:
```
✅ Health check PASSED
✅ Register user PASSED
✅ Login PASSED
✅ Verify token PASSED
✅ Get profile PASSED
✅ Invalid credentials handling PASSED
Total: 6/6 tests passed
🎉 All tests passed! Backend is working correctly!
```

### Step 3: Manual Testing (cURL)

```bash
# 1. Health check
curl http://127.0.0.1:5000/api/health

# 2. Register
curl -X POST http://127.0.0.1:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Pass123","username":"testuser"}'

# 3. Login (copy token from response)
curl -X POST http://127.0.0.1:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Pass123"}'

# 4. Verify token (use token from previous response)
curl -X POST http://127.0.0.1:5000/api/auth/verify-token \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 5. Get profile
curl http://127.0.0.1:5000/api/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Step 4: Flutter Testing

1. Start backend (keep running)
2. Update Flutter `api_config.dart`:
   ```dart
   // For emulator
   static const String localApiUrl = 'http://10.0.2.2:5000';
   
   // For real device (replace X's with your PC IP)
   // static const String localApiUrl = 'http://192.168.X.X:5000';
   ```

3. Run Flutter app:
   ```bash
   flutter run
   ```

4. Test login flow:
   - Click "Create Account"
   - Enter email, password
   - Submit and verify navigation to dashboard
   - Return to login screen
   - Login with same credentials
   - Verify navigation to dashboard

---

## 🚀 Production Deployment

### Option 1: Deploy to Render (Easiest)

#### Prerequisites
- GitHub account
- Render account (free at render.com)
- Backend pushed to GitHub

#### Steps

1. **Push to GitHub**
   ```bash
   cd backend
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/macmind-backend.git
   git push -u origin main
   ```

2. **Create Render Service**
   - Go to https://dashboard.render.com
   - Click "New +"
   - Select "Web Service"
   - Connect GitHub repository
   - Select your macmind-backend repo

3. **Configure Service**
   - **Name:** `macmind-backend`
   - **Environment:** `Python 3`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `gunicorn run:app`
   - **Instance Type:** Free

4. **Set Environment Variables**
   Add in Render dashboard:
   ```
   FLASK_ENV=production
   DATABASE_URL=postgresql+psycopg://user:pass@host:3306/macmind
   SECRET_KEY=<generate-using-secrets>
   JWT_SECRET_KEY=<generate-using-secrets>
   CORS_ORIGINS=https://yourdomain.com
   ```

5. **Deploy**
   - Click "Create Web Service"
   - Wait for deployment (~2 minutes)
   - Get URL from dashboard

6. **Update Flutter App**
   ```dart
   static const String productionBaseUrl = "https://your-render-app.onrender.com";
   ```

### Option 2: Deploy to Heroku

#### Steps

1. **Install Heroku CLI**
   ```bash
   # Windows/macOS/Linux
   # Download from https://devcenter.heroku.com/articles/heroku-cli
   ```

2. **Login to Heroku**
   ```bash
   heroku login
   ```

3. **Create App**
   ```bash
   cd backend
   heroku create macmind-backend
   ```

4. **Set Environment Variables**
   ```bash
   heroku config:set FLASK_ENV=production
   heroku config:set DATABASE_URL=postgresql+psycopg://user:pass@host:3306/macmind
   heroku config:set SECRET_KEY=your-secret-key
   heroku config:set JWT_SECRET_KEY=your-jwt-secret-key
   ```

5. **Deploy**
   ```bash
   git push heroku main
   ```

6. **View Logs**
   ```bash
   heroku logs --tail
   ```

### Option 3: Self-Hosted (Advanced)

#### Prerequisites
- VPS or dedicated server
- SSH access
- PostgreSQL server
- Python 3.8+

#### Steps

1. **SSH into Server**
   ```bash
   ssh user@your-server-ip
   ```

2. **Install Dependencies**
   ```bash
   sudo apt update
   sudo apt install python3 python3-pip PostgreSQL-server nginx
   ```

3. **Clone Repository**
   ```bash
   git clone https://github.com/YOU/macmind-backend.git
   cd macmind-backend
   ```

4. **Setup Python Environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   pip install gunicorn
   ```

5. **Configure Systemd Service**
   ```bash
   sudo nano /etc/systemd/system/macmind.service
   ```

   Add:
   ```ini
   [Unit]
   Description=MacMind Backend
   After=network.target

   [Service]
   User=ubuntu
   WorkingDirectory=/home/ubuntu/macmind-backend
   ExecStart=/home/ubuntu/macmind-backend/venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 run:app
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

6. **Start Service**
   ```bash
   sudo systemctl start macmind
   sudo systemctl enable macmind
   ```

7. **Configure Nginx (Reverse Proxy)**
   ```bash
   sudo nano /etc/nginx/sites-available/macmind
   ```

   Add:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://127.0.0.1:5000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

8. **Enable Site**
   ```bash
   sudo ln -s /etc/nginx/sites-available/macmind /etc/nginx/sites-enabled/
   sudo systemctl restart nginx
   ```

---

## 🔐 Security Checklist

Before Going to Production:

- [ ] **Change Default Passwords**
  ```bash
  # Generate new secrets
  python -c "import secrets; print(secrets.token_hex(32))"
  ```

- [ ] **Update .env (Production)**
  ```env
  FLASK_ENV=production
  SECRET_KEY=<new-generated-key>
  JWT_SECRET_KEY=<new-generated-key>
  CORS_ORIGINS=https://yourdomain.com
  ```

- [ ] **Enable HTTPS**
  - Use Render/Heroku auto-HTTPS
  - Or install Let's Encrypt SSL certificate

- [ ] **Set Strong Database Password**
  ```bash
  PostgreSQL -u root -p
  ALTER USER 'macmind'@'localhost' IDENTIFIED BY 'strong_password_here';
  FLUSH PRIVILEGES;
  ```

- [ ] **Enable Firewall**
  ```bash
  # Linux
  sudo ufw allow 22  # SSH
  sudo ufw allow 80  # HTTP
  sudo ufw allow 443 # HTTPS
  sudo ufw enable
  ```

- [ ] **Setup Database Backups**
  ```bash
  # Daily backup script
  pg_dump -u macmind -p macmind > /backups/macmind_$(date +%Y%m%d).sql
  ```

---

## 📊 Performance Monitoring

### Monitor Server Resources

```bash
# CPU/Memory
top

# Disk usage
df -h

# Network connections
netstat -tulpn | grep 5000
```

### Monitor Application

```bash
# Backend logs (if self-hosted)
tail -f /var/log/macmind/app.log

# Render logs
# View in dashboard

# Heroku logs
heroku logs --tail
```

### Database Monitoring

```bash
# Check connections
PostgreSQL -u root -p -e "SHOW PROCESSLIST;"

# Check table sizes
PostgreSQL -u root -p -e "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) 'Size in MB' FROM information_schema.tables WHERE table_schema='macmind';"
```

---

## 🐛 Debugging Production Issues

### Issue: 500 Server Error

1. Check logs:
   ```bash
   # Render: View in dashboard
   # Heroku: heroku logs --tail
   # Self-hosted: tail -f /var/log/macmind/app.log
   ```

2. Check database connection:
   ```bash
   PostgreSQL -u macmind -p -h your-host -e "SELECT 1;"
   ```

3. Check environment variables:
   ```bash
   # Render: Check dashboard
   # Heroku: heroku config
   ```

### Issue: Login Fails in Production

1. Verify database has users table:
   ```bash
   PostgreSQL -u root -p macmind -e "SHOW TABLES;"
   ```

2. Check user exists:
   ```bash
   PostgreSQL -u root -p macmind -e "SELECT * FROM users;"
   ```

3. Verify JWT keys are set:
   ```bash
   # Should not be null
   echo $JWT_SECRET_KEY
   ```

### Issue: CORS Errors

1. Check CORS_ORIGINS in production config
2. Ensure Flutter app domain is in the list
3. Verify https vs http matches

---

## 📈 Scaling (When You Grow)

### Add Caching (Redis)

```python
from flask_caching import Cache

cache = Cache(app, config={'CACHE_TYPE': 'redis'})

@app.route('/profile')
@cache.cached(timeout=300)
def get_profile():
    # ...
```

### Add Rate Limiting

```python
from flask_limiter import Limiter

limiter = Limiter(app, key_func=lambda: request.remote_addr)

@auth_bp.route('/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    # ...
```

### Database Optimization

```bash
# Add indexes
PostgreSQL -u root -p macmind -e "ALTER TABLE users ADD INDEX idx_email (email);"

# Analyze tables
PostgreSQL -u root -p macmind -e "ANALYZE TABLE users;"
```

---

## ✅ Final Verification

After deployment:

```bash
# 1. Health check
curl https://your-backend-url/api/health

# 2. Test registration
curl -X POST https://your-backend-url/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Pass123","username":"testuser"}'

# 3. Test login
curl -X POST https://your-backend-url/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Pass123"}'

# 4. Update Flutter app to use production URL
# In api_config.dart:
# static const String productionBaseUrl = "https://your-backend-url";
```

---

## 🎯 Deployment Checklist Summary

- [ ] All tests pass locally (`python test_auth.py`)
- [ ] PostgreSQL database configured
- [ ] Environment variables set (production)
- [ ] Security keys changed
- [ ] SSL/HTTPS enabled
- [ ] Firewall configured
- [ ] Backups configured
- [ ] Monitoring set up
- [ ] Flutter app updated with production URL
- [ ] Final testing on deployed backend
- [ ] Documentation updated
- [ ] Team notified

---

## 🆘 Need Help?

1. **Local issues:** Run `python test_auth.py`
2. **Deployment issues:** Check platform docs (Render/Heroku)
3. **Database issues:** Check `POSTGRESQL_SETUP.md`
4. **Flutter issues:** Check `FLUTTER_INTEGRATION.md`

---

**Congratulations! Your backend is production-ready!** 🚀

Next: Monitor, optimize, and iterate based on user feedback.


