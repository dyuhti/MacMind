# 🔄 MongoDB → MySQL Migration Summary

This document outlines the changes made to migrate the MacMind backend from MongoDB to MySQL.

## 📋 What Changed

### 1. Dependencies (requirements.txt)

**Removed:**
- `pymongo==4.5.0` - MongoDB Python driver

**Added:**
- `Flask-SQLAlchemy==3.0.5` - SQLAlchemy ORM with Flask integration
- `PyMySQL==1.1.0` - Pure Python MySQL driver
- `cryptography==41.0.4` - Required for secure MySQL connections

### 2. Database Configuration (config.py)

**Before (MongoDB):**
```python
MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017/macmind')
```

**After (MySQL):**
```python
SQLALCHEMY_DATABASE_URI = os.getenv(
    'DATABASE_URL',
    'mysql+pymysql://root:password@localhost:3306/macmind'
)
SQLALCHEMY_TRACK_MODIFICATIONS = False
```

### 3. Database Initialization (app/__init__.py)

**Before (MongoDB):**
```python
from pymongo import MongoClient
mongo_client = MongoClient(mongo_uri)
db = mongo_client.macmind
```

**After (MySQL with SQLAlchemy):**
```python
from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()
db.init_app(app)
with app.app_context():
    db.create_all()  # Auto-creates tables
```

### 4. User Model (app/models/user.py)

**Before (Document-based MongoDB):**
```python
# Collection operations
db[User.COLLECTION_NAME].find_one({'email': email})
db[User.COLLECTION_NAME].insert_one(user_data)
```

**After (Table-based SQLAlchemy):**
```python
# ORM operations
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True)
    # ...

User.query.filter_by(email=email).first()
db.session.add(user)
db.session.commit()
```

### 5. Routes (app/routes/auth.py)

**Changed:**
- Removed MongoDB-specific ObjectId operations
- Simplified to use integer user IDs
- Removed deprecated `@before_app_first_request` decorator

### 6. Environment Configuration (.env)

**Before:**
```env
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/macmind
```

**After:**
```env
DATABASE_URL=mysql+pymysql://root:password@localhost:3306/macmind
```

---

## 🗄️ Database Schema

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

**Differences from MongoDB:**
- Fixed schema with defined columns
- Automatic timestamps with SQL defaults
- Better indexing for performance
- Referential integrity possible
- ACID transactions

---

## ✨ Advantages of MySQL

1. **Structured Data** - Fixed schema with validation
2. **Performance** - Better query optimization
3. **Transactions** - ACID compliance
4. **Relationships** - Foreign keys (for future tables)
5. **Backup** - Simple mysqldump utility
6. **Scalability** - Better for relational data
7. **Cost** - Free, self-hosted or managed options
8. **Familiarity** - SQL is widely known

---

## 🔄 Migration Path

If you have existing MongoDB data, here's how to migrate:

### 1. Export MongoDB Data

```bash
mongoexport --uri="mongodb+srv://..." --collection=users --out=users.json
```

### 2. Transform JSON to SQL

```python
import json
from datetime import datetime

with open('users.json', 'r') as f:
    users = json.load(f)

sql_statements = []
for user in users:
    sql = f"""
    INSERT INTO users (username, email, password, hospital_id, created_at, is_active)
    VALUES ('{user["username"]}', '{user["email"]}', '{user["password"]}', 
            '{user.get("hospital_id", "")}', NOW(), {1 if user.get("is_active", True) else 0});
    """
    sql_statements.append(sql)

# Save to file and execute
with open('migration.sql', 'w') as f:
    f.write('\n'.join(sql_statements))
```

### 3. Import into MySQL

```bash
mysql -u root -p macmind < migration.sql
```

### 4. Verify Data

```sql
SELECT COUNT(*) FROM users;
SELECT * FROM users LIMIT 5;
```

---

## 🔍 API Endpoint Changes

### Response Format

**Before (MongoDB ObjectId):**
```json
{
  "user_id": "507f1f77bcf86cd799439011",
  "email": "doctor@hospital.com"
}
```

**After (MySQL Integer ID):**
```json
{
  "user_id": 1,
  "email": "doctor@hospital.com"
}
```

The endpoints work the same, but user_id is now a simpler integer.

---

## 📊 Performance Considerations

### MongoDB
- Good for: Flexible schema, document storage
- Query: `db.users.find({'email': 'x@y.com'})`
- Scaling: Horizontal (sharding)

### MySQL
- Good for: Structured data, relationships
- Query: `SELECT * FROM users WHERE email = 'x@y.com'`
- Scaling: Vertical + read replicas

---

## 🚀 Quick Setup for New Installation

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Create MySQL database
mysql -u root -p
CREATE DATABASE macmind CHARACTER SET utf8mb4;
EXIT;

# 3. Update .env
# DATABASE_URL=mysql+pymysql://root:password@localhost:3306/macmind

# 4. Start server (tables auto-created)
python run.py
```

---

## 📚 Files Modified

- ✅ `requirements.txt` - Added SQLAlchemy, PyMySQL
- ✅ `config/config.py` - Updated database configuration
- ✅ `app/__init__.py` - Replaced MongoDB with SQLAlchemy
- ✅ `app/models/user.py` - Converted to SQLAlchemy ORM
- ✅ `app/routes/auth.py` - Updated for SQLAlchemy
- ✅ `.env` - Updated connection string
- ✅ `.env.example` - Updated template
- ✅ `README.md` - Updated documentation

## 📝 New Files Created

- ✨ `MYSQL_SETUP.md` - MySQL installation guide
- ✨ `MIGRATION_GUIDE.md` - This file

---

## 🔗 Resources

- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Flask-SQLAlchemy Documentation](https://flask-sqlalchemy.palletsprojects.com/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [PyMySQL Documentation](https://pymysql.readthedocs.io/)

---

## ❓ FAQ

**Q: Will my old MongoDB data work?**
A: Not directly. You'll need to migrate (see Migration Path above).

**Q: Is MySQL faster than MongoDB?**
A: Depends on use case. MySQL is better for relational data, MongoDB for documents.

**Q: Can I switch back to MongoDB?**
A: Yes, but you'll need to update the models and configuration again.

**Q: What about data that doesn't fit a schema?**
A: Add new columns as needed, or use JSON column type in MySQL 5.7+.

---

**Migration Complete! 🎉**

The backend now uses MySQL with SQLAlchemy ORM for better structure, performance, and scalability.
