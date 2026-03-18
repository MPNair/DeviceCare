# DeviceCare

DeviceCare is a full-stack device inventory and maintenance management app.

It helps users:
- track gadgets (phones, laptops, cameras, and more)
- organize devices in folders (category, brand, room, ownership, or custom)
- log maintenance and repair history with cost tracking
- view analytics and depreciation-style estimated values
- import and export device data for reporting

## Product Architecture

The project has two main parts:

1. Backend API (Node.js + Express + Sequelize + SQLite)
   - location: backend/
   - default API URL: http://localhost:3000
   - auto-creates and updates local SQLite database on startup

2. Frontend app (Flutter)
   - location: frontend/
   - runs on Android, Windows, web, and other Flutter targets
   - consumes backend APIs for authentication, gadgets, folders, logs, and analytics

## Main Features

### Authentication
- user registration and login
- JWT-based access token
- refresh token endpoint for renewing sessions

### Gadget Management
- create, read, update, delete gadgets
- attach metadata: serial number, price, status, tags, custom fields, documents
- CSV import and Excel export support

### Folder Organization
- hierarchical folders
- folder types: category, brand, room, ownership, custom

### Maintenance Logs
- create service entries per gadget
- track service type, date, technician details, and costs

### Analytics
- API endpoints for dashboard/summary analytics
- estimated value fields in gadget records for depreciation-style views

## Prerequisites

Install these before running:

- Node.js 18+ and npm
- Flutter SDK (stable channel)
- Android Studio (for Android emulator/device tooling)
- Git (recommended)

Optional:
- SQLite CLI for direct database inspection
- Firebase configuration if you plan to use cloud integrations

## Quick Start (Local Development)

Run backend first, then frontend.

### 1. Start Backend

1. Open terminal in backend/
2. Install dependencies:

```bash
npm install
```

3. Start server:

```bash
npm start
```

Backend behavior on startup:
- binds to PORT from environment or 3000
- checks SQLite connection
- runs sequelize.sync({ force: false })
- creates/updates tables without dropping existing data

Expected success signals:
- "Database connected successfully"
- "Database synced successfully"
- "Server is running on http://localhost:3000"

Health check endpoint:

```http
GET http://localhost:3000/health
```

### 2. Start Frontend

1. Open terminal in frontend/
2. Install Flutter packages:

```bash
flutter pub get
```

3. Start emulator/device
4. Run app:

```bash
flutter run
```

If backend and frontend run on different hosts/devices, update the frontend API base URL accordingly.

## API Surface (High-Level)

- POST /api/auth/register
- POST /api/auth/login
- POST /api/auth/refresh-token
- GET|POST|PUT|DELETE /api/gadgets/*
- GET|POST|PUT|DELETE /api/folders/*
- POST|GET /api/logs/:gadgetId/logs
- DELETE /api/logs/logs/:id
- GET /api/analytics/*
- POST /api/upload/*

Most domain routes require authentication.

## Environment and Configuration Notes

### Backend
- SQLite file location: backend/database.sqlite
- CORS currently allows all origins (origin: '*') for development
- Logging enabled with morgan('dev')

### Frontend
- add your own Firebase files only if your flow requires Firebase services
- verify emulator/device network can reach backend host and port

## Common Problems and Fixes

### "Failed to fetch" in frontend
- backend is not running
- wrong API host/port in frontend
- emulator cannot access localhost (use host machine IP when needed)

### Backend fails on startup
- run npm install again in backend/
- check Node.js version
- verify no process is already using port 3000

### Flutter build or run issues
- run flutter doctor -v
- run flutter clean then flutter pub get
- verify Android SDK and platform tools are installed

## Useful Project Scripts

From backend/:

- npm start - start API server
- node view_users.js - inspect user records
- node database_report.js - generate user/password summary report
- node fix_passwords.js - repair corrupted password hashes

## Detailed Database Operations

For full DB table details, relationship mapping, backup, restore, and troubleshooting:

- see DATABASE_GUIDE.md

## Recommended First Test Flow

1. Start backend
2. Call /health
3. Start frontend
4. Register or login a user
5. Create a folder
6. Add a gadget
7. Add a maintenance log
8. Confirm data persistence after backend restart
