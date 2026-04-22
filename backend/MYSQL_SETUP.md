# 🗄️ MySQL Setup Guide

This guide will help you set up MySQL for the MacMind backend.

## Quick Start Options

Choose your preferred method based on your operating system and preferences.

---

## 📌 Option 1: Local MySQL (Easiest for Beginners)

### Windows

#### 1. Install MySQL via XAMPP (Recommended)

1. Download [XAMPP](https://www.apachefriends.org/)
2. Run the installer
3. Select MySQL component during installation
4. Start the MySQL service from XAMPP Control Panel

#### 2. Create Database

Open Command Prompt and run:
```bash
mysql -u root
```

Then paste:
```sql
CREATE DATABASE macmind CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

#### 3. Update `.env`

```env
DATABASE_URL=mysql+pymysql://root@localhost:3306/macmind
```

### macOS

#### 1. Install MySQL via Homebrew

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install MySQL
brew install mysql

# Start MySQL
brew services start mysql

# Secure installation (optional)
mysql_secure_installation
```

#### 2. Create Database

```bash
mysql -u root -p
```

Then:
```sql
CREATE DATABASE macmind CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

#### 3. Update `.env`

If you set a password:
```env
DATABASE_URL=mysql+pymysql://root:your_password@localhost:3306/macmind
```

Without password:
```env
DATABASE_URL=mysql+pymysql://root@localhost:3306/macmind
```

### Linux (Ubuntu/Debian)

#### 1. Install MySQL

```bash
sudo apt update
sudo apt install mysql-server

# Secure installation (recommended)
sudo mysql_secure_installation
```

#### 2. Create Database

```bash
sudo mysql -u root
```

Then:
```sql
CREATE DATABASE macmind CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

#### 3. Update `.env`

```env
DATABASE_URL=mysql+pymysql://root:your_password@localhost:3306/macmind
```

---

## 📌 Option 2: MySQL via Docker (For Advanced Users)

### Prerequisites

Install [Docker Desktop](https://www.docker.com/products/docker-desktop)

### 1. Run MySQL Container

```bash
docker run --name macmind-mysql \
  -e MYSQL_ROOT_PASSWORD=your_password \
  -e MYSQL_DATABASE=macmind \
  -p 3306:3306 \
  -d mysql:8.0
```

### 2. Update `.env`

```env
DATABASE_URL=mysql+pymysql://root:your_password@localhost:3306/macmind
```

### 3. Verify Connection

```bash
mysql -u root -p -h localhost -e "SELECT 1"
```

---

## 📌 Option 3: Cloud MySQL (For Production)

### AWS RDS

1. Go to [AWS RDS Console](https://aws.amazon.com/rds/)
2. Create MySQL instance
3. Configure security groups
4. Get endpoint and credentials
5. Update `.env`:
   ```env
   DATABASE_URL=mysql+pymysql://username:password@rds-endpoint.amazonaws.com:3306/macmind
   ```

### DigitalOcean Managed Databases

1. Go to [DigitalOcean](https://www.digitalocean.com/)
2. Create Managed MySQL Database
3. Get connection details
4. Update `.env`:
   ```env
   DATABASE_URL=mysql+pymysql://doadmin:password@host:25061/macmind
   ```

### PlanetScale (MySQL Compatible)

1. Go to [PlanetScale](https://planetscale.com/)
2. Create free MySQL database
3. Get connection string
4. Update `.env`:
   ```env
   DATABASE_URL=mysql+pymysql://username:password@pscale-endpoint:3306/macmind
   ```

---

## ✅ Verify MySQL Connection

### Using Command Line

```bash
# Test MySQL connection
mysql -u root -p -h localhost -e "SELECT 1"

# You should see:
# +---+
# | 1 |
# +---+
# | 1 |
# +---+
```

### Using Python

```bash
python -c "
import mysql.connector
try:
    conn = mysql.connector.connect(
        host='localhost',
        user='root',
        password='your_password',
        database='macmind'
    )
    print('✅ MySQL connection successful!')
    conn.close()
except Exception as e:
    print(f'❌ Connection failed: {e}')
"
```

### Using Flask App

```bash
python run.py
```

Look for:
```
✅ Database tables initialized
```

---

## 🛠️ Common MySQL Commands

### Connect to MySQL

```bash
# As root user
mysql -u root -p

# Specific host
mysql -u root -p -h 192.168.1.100

# Specific port
mysql -u root -p -P 3307
```

### Database Operations

```sql
-- Show databases
SHOW DATABASES;

-- Use database
USE macmind;

-- Show tables
SHOW TABLES;

-- Show table structure
DESCRIBE users;

-- Check table contents
SELECT * FROM users;

-- Check row count
SELECT COUNT(*) FROM users;
```

### User Management

```sql
-- Create MySQL user
CREATE USER 'macmind_user'@'localhost' IDENTIFIED BY 'strong_password';

-- Grant permissions
GRANT ALL PRIVILEGES ON macmind.* TO 'macmind_user'@'localhost';
FLUSH PRIVILEGES;

-- Remove user
DROP USER 'macmind_user'@'localhost';
```

### Backup & Restore

```bash
# Backup database
mysqldump -u root -p macmind > backup.sql

# Backup all databases
mysqldump -u root -p --all-databases > all_databases.sql

# Restore database
mysql -u root -p macmind < backup.sql

# Restore all databases
mysql -u root -p < all_databases.sql
```

---

## 🐛 Troubleshooting

### "Can't connect to MySQL server"

**Check if MySQL is running:**
```bash
# Windows (XAMPP)
# Check MySQL service in XAMPP Control Panel

# macOS
brew services list

# Linux
sudo service mysql status
sudo systemctl status mysql
```

### "Access denied for user 'root'@'localhost'"

**Solutions:**
1. Check password in `.env`
2. Verify MySQL user exists:
   ```bash
   mysql -u root -e "SELECT USER();"
   ```
3. Reset password (see MySQL docs for your OS)

### "Database 'macmind' doesn't exist"

**Create database:**
```bash
mysql -u root -p
```

```sql
CREATE DATABASE macmind CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SHOW DATABASES;
EXIT;
```

### "Can't load plugin 'validate_password'"

**Solution:** Disable validation plugin or update config:
```bash
# Edit MySQL config file and restart MySQL
```

### Connection timeout

**Check firewall:**
```bash
# Allow MySQL port
# Windows: Check Windows Firewall
# Linux: sudo ufw allow 3306
# macOS: System Preferences → Security & Privacy
```

---

## 📊 Database Monitoring

### Using MySQL Workbench (GUI)

1. Download [MySQL Workbench](https://dev.mysql.com/downloads/workbench/)
2. Create new connection
3. Enter credentials
4. Browse and manage database

### Using phpMyAdmin (Web Interface)

1. Install with XAMPP or standalone
2. Go to `http://localhost/phpmyadmin`
3. Login with credentials
4. Browse and manage database

### Command Line Monitoring

```bash
# Monitor real-time queries
mysqladmin -u root -p processlist --verbose

# Check server status
mysqladmin -u root -p status

# Show variables
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"
```

---

## 🔒 Security Best Practices

1. **Change Default Password**
   ```bash
   mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'strong_password';"
   ```

2. **Create Limited User**
   ```sql
   CREATE USER 'macmind'@'localhost' IDENTIFIED BY 'password';
   GRANT SELECT, INSERT, UPDATE, DELETE ON macmind.* TO 'macmind'@'localhost';
   ```

3. **Disable Remote Root Login**
   ```sql
   DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
   FLUSH PRIVILEGES;
   ```

4. **Enable SSL/TLS** (for production)
   - Configure MySQL SSL
   - Update connection string with SSL parameters

5. **Regular Backups**
   ```bash
   mysqldump -u root -p macmind > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

---

## 📚 Additional Resources

- [MySQL Official Documentation](https://dev.mysql.com/doc/)
- [MySQL Tutorial](https://www.mysqltutorial.org/)
- [MySQL Workbench Guide](https://dev.mysql.com/doc/workbench/en/)
- [SQLAlchemy MySQL Guide](https://docs.sqlalchemy.org/en/20/dialects/mysql.html)

---

**Need Help?** Check the main README.md or troubleshooting section!
