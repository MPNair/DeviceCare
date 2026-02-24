# Setup and Run Instructions

## 1. Backend Setup
1. Open a terminal in `backend/`
2. Run `npm install`
3. Run `node src/index.js`
   - The server will start on port 3000.
   - Database `database.sqlite` will be created automatically.

## 2. Frontend Setup
1. Open a terminal in `frontend/`
2. Run `flutter pub get`
3. Connect an Android emulator or device.
4. Run `flutter run`

## 3. Environment Notes
- **Android Studio**: I have configured the path and accepted SDK licenses.
- **Firebase**: You will need to add your own `google-services.json` (Android) and Firebase Admin credentials to `.env` for full cloud functionality.
- **Depreciation Engine**: Currently uses simulated data based on category and device age.
