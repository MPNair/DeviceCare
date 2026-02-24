# Database Viewer & Management Tools

## Quick Database Access

The backend now includes utility scripts for database management:

### 1. View All Users
```bash
cd backend
node view_users.js
```

**Output shows:**
- User ID
- Email
- Display Name
- Firebase ID
- Password Hash (first 50 chars)
- Role
- Created/Updated timestamps

---

### 2. View with SQLite CLI (Advanced)

#### Install SQLite CLI (if needed):
```bash
choco install sqlite
```

#### Query the database directly:
```bash
cd backend

# View all users
sqlite3 database.sqlite "SELECT id, email, displayName, role FROM Users;"

# View specific user with all fields
sqlite3 database.sqlite "SELECT * FROM Users WHERE email='test@testauth.com';"

# View password hash length (to verify corruption fix)
sqlite3 database.sqlite "SELECT email, LENGTH(password) as hash_length FROM Users;"

# View timestamps
sqlite3 database.sqlite "SELECT email, createdAt, updatedAt FROM Users;"

# Export data to CSV
sqlite3 database.sqlite ".mode csv" ".output users_export.csv" "SELECT * FROM Users;" ".quit"
```

---

### 3. Database Schema

#### Users Table Structure:
```sql
CREATE TABLE Users (
    id UUID PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    password VARCHAR(255),
    displayName VARCHAR,
    firebaseId VARCHAR UNIQUE,
    role ENUM('user', 'admin') DEFAULT 'user',
    createdAt TIMESTAMP,
    updatedAt TIMESTAMP
);
```

#### Valid User Data Example:
```
Email: test@testauth.com
Password Hash: $2b$10$W0CmWfASmwLPGbB7mE6Ou.ts8X4O5KpvYL66bshrQBcuB1mGRDZV2
Hash Length: 60 characters (VALID)
```

---

### 4. Fix Corrupted Passwords
```bash
cd backend
node fix_passwords.js
```

**What it does:**
- Checks all users for corrupted/truncated password hashes
- Validates hash length (should be 60 characters)
- Regenerates hashes for corrupted records
- Outputs temporary passwords for affected users

---

### 5. User Management Scripts

#### Check specific user credentials:
```bash
# Script will prompt for email and password to verify
node check_users_data.js
```

#### Clean up users (careful!):
```bash
node clean_users.js
```

---

## Database File Location

**Local Database:**
```
c:\MAC\BTCSE\PROJECTS\DeviceCare\Device1.0\backend\database.sqlite
```

**Size:** Typically 100KB - 1MB (depending on records)

---

## Common Issues & Solutions

### ❌ "password hash is corrupted"
**Solution:** Run `node fix_passwords.js`

### ❌ "Invalid credentials on login"
- Hash length < 60 characters → Run fix script
- Wrong JWT_SECRET → Check .env file
- Bcrypt version mismatch → Run `npm install`

### ❌ "Cannot connect to database"
- Check database.sqlite file exists
- Verify permissions: `icacls database.sqlite`
- Try deleting and recreating: `rm database.sqlite && npm start`

---

## Data Backup

### Create Backup:
```bash
# Copy database file
copy backend\database.sqlite backend\database_backup_$(date /T).sqlite

# Or export to CSV for safety
sqlite3 backend\database.sqlite ".mode csv" ".output backup.csv" "SELECT * FROM Users;"
```

### Restore from Backup:
```bash
copy backend\database_backup_2026-02-17.sqlite backend\database.sqlite
npm start
```

---

## Viewing Database with File Explorer

1. Navigate to: `C:\MAC\BTCSE\PROJECTS\DeviceCare\Device1.0\backend\`
2. Find: `database.sqlite`
3. Right-click → Open with → VS Code
4. Or use SQLite browser extension

---

## Current Database Status

**Total Users:** 2
- ✅ test@testauth.com (Valid hash)
- ✅ guest@devicecare.io (Fixed - temp password: Fix_guest_1771349533402)

**Last Updated:** 2026-02-17 23:02:13 IST
