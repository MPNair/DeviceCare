# DeviceCare Database Guide

This guide explains how DeviceCare stores data, how tables are related, and how to safely inspect, back up, restore, and troubleshoot the local database.

## 1. Database Engine and Location

- Engine: SQLite (via Sequelize ORM)
- Runtime mode: local file database
- File path: backend/database.sqlite
- Auto-initialization: created on backend startup if not present

Backend startup runs:

```js
sequelize.sync({ force: false })
```

This means:
- missing tables are created
- existing data is preserved
- tables are not dropped automatically

## 2. Core Data Model

DeviceCare backend uses four main models:

1. User
2. Folder
3. Gadget
4. MaintenanceLog

### 2.1 User

Primary purpose: authentication and ownership of user data.

Key fields:
- id (UUID, primary key)
- firebaseId (string, unique, nullable)
- password (string, up to 255 chars, nullable)
- email (string, unique, required)
- displayName (string)
- role (user or admin, default user)

### 2.2 Folder

Primary purpose: organize gadgets in hierarchies.

Key fields:
- id (UUID, primary key)
- name (string, required)
- description (text)
- folderType (category, brand, room, ownership, custom)
- parentId (self-reference to Folders.id, nullable)
- userId (owner reference to Users.id, required)

### 2.3 Gadget

Primary purpose: track device lifecycle, metadata, and value.

Key fields:
- identity and ownership: id, userId, folderId
- basic info: name, category, brand, model, serialNumber
- purchase and warranty: purchaseDate, purchasePrice, warrantyExpiryDate, warrantyPeriod
- condition and status: conditionScore, status
- valuation: currentEstimatedValue, depreciationAdjustedValue
- metadata: storageCapacity, color, purchaseStore, ownershipStatus, room, description
- JSON fields: imageUrls, technicalSpecs, documents, tags, customFields

### 2.4 MaintenanceLog

Primary purpose: maintenance and repair history per gadget.

Key fields:
- id (UUID, primary key)
- serviceType (required)
- description
- cost (default 0)
- serviceDate (required)
- technicianDetails
- documentUrl
- gadgetId (via association)

## 3. Relationships

Defined associations:

- User has many Gadgets (User -> Gadget)
- User has many Folders (User -> Folder)
- Folder has many subFolders (Folder -> Folder, self hierarchy)
- Folder has many Gadgets (Folder -> Gadget)
- Gadget has many MaintenanceLogs (Gadget -> MaintenanceLog)

Delete behavior highlights:
- deleting a parent folder cascades to subfolders
- deleting a folder sets gadget folderId to null

## 4. Quick Operational Commands

Run from project root unless noted.

### 4.1 Start backend and initialize DB

```bash
cd backend
npm install
npm start
```

### 4.2 Check server and DB health

```bash
curl http://localhost:3000/health
```

Expected JSON response includes status: "ok".

### 4.3 View users with utility script

```bash
cd backend
node view_users.js
```

### 4.4 Generate user/password report

```bash
cd backend
node database_report.js
```

## 5. SQLite CLI Usage (Advanced)

### 5.1 Install SQLite CLI on Windows (if needed)

```bash
choco install sqlite
```

### 5.2 Open database

```bash
cd backend
sqlite3 database.sqlite
```

### 5.3 Useful inspection queries

List tables:

```sql
.tables
```

Show schema for a table:

```sql
.schema Users
.schema Gadgets
.schema Folders
.schema MaintenanceLogs
```

Count records:

```sql
SELECT COUNT(*) AS users FROM Users;
SELECT COUNT(*) AS gadgets FROM Gadgets;
SELECT COUNT(*) AS folders FROM Folders;
SELECT COUNT(*) AS logs FROM MaintenanceLogs;
```

Inspect users safely:

```sql
SELECT id, email, displayName, role, createdAt, updatedAt FROM Users;
```

Check for suspicious password hash lengths:

```sql
SELECT email, LENGTH(password) AS hash_length
FROM Users
WHERE password IS NOT NULL;
```

Inspect gadget ownership and folder mapping:

```sql
SELECT g.id, g.name, g.category, g.status, g.userId, g.folderId
FROM Gadgets g;
```

Inspect maintenance history with gadget names:

```sql
SELECT m.id, m.serviceType, m.serviceDate, m.cost, g.name AS gadget_name
FROM MaintenanceLogs m
LEFT JOIN Gadgets g ON g.id = m.gadgetId
ORDER BY m.serviceDate DESC;
```

Exit SQLite:

```sql
.quit
```

## 6. Utility Scripts and When to Use Them

From backend/:

- node view_users.js
  - quick user visibility
- node database_report.js
  - generate a summary report and JSON output
- node fix_passwords.js
  - scan and repair invalid/corrupted password hashes
- node check_users_data.js
  - validate specific credential data paths
- node clean_users.js
  - cleanup/reset style operation (use with caution)

## 7. Backup and Restore

Always stop the backend before file-level backup or restore to avoid partial writes.

### 7.1 Create file backup (PowerShell)

```powershell
Copy-Item backend\database.sqlite backend\database_backup.sqlite
```

Timestamped backup:

```powershell
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item backend\database.sqlite "backend\database_backup_$ts.sqlite"
```

### 7.2 Export selected data to CSV

```bash
sqlite3 backend/database.sqlite ".headers on" ".mode csv" ".output users_export.csv" "SELECT id,email,displayName,role,createdAt FROM Users;" ".quit"
```

### 7.3 Restore backup

```powershell
Copy-Item backend\database_backup.sqlite backend\database.sqlite -Force
```

Then restart backend:

```bash
cd backend
npm start
```

## 8. Common Database Issues

### Issue: Invalid credentials for known user

Checks:
- ensure user exists
- validate password hash length in Users
- confirm backend uses expected JWT_SECRET

Fix path:

```bash
cd backend
node fix_passwords.js
```

### Issue: Database locked or write errors

Checks:
- confirm only one backend process is writing
- close external SQLite viewers during writes
- verify file permissions

### Issue: Data missing after restart

Checks:
- ensure you are running correct backend folder
- verify active DB file path is backend/database.sqlite
- check scripts are not cleaning records unexpectedly

## 9. Safe Data Handling Practices

- do not manually edit password hashes unless necessary
- avoid deleting DB file in active development unless doing full reset
- create backups before running cleanup or migration scripts
- test destructive scripts in a copied DB file first

## 10. Recommended Routine for Developers

1. Start backend and confirm /health
2. Run node view_users.js
3. Do feature testing from frontend/API
4. Run node database_report.js after major auth/data changes
5. Take a backup snapshot before large refactors or data cleanup
