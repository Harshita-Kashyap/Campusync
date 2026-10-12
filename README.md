# Campusync

Small campus actions. Measurable environmental change. Campusync is a Flutter demo app with an optional Flask + MySQL backend for the water-leak workflow.

## Flutter app

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

The water report screen supports a photo upload for server-side Gemini analysis, a manual report path, and an explicitly labelled offline demo path. The admin Water screen loads incidents from MySQL and updates repair status through Flask.

### Connect Flutter to Flask

On Android the app defaults to `http://10.0.2.2:5000`; desktop/web defaults to `http://127.0.0.1:5000`. For a physical phone use the computer's LAN IP. You can edit the URL in either Water screen or set it at build time:

```bash
flutter run --dart-define=WATER_API_URL=http://<host>:5000
```

## Flask + MySQL API

See [`backend/README.md`](backend/README.md) for Python setup, environment variables, MySQL schema, and curl examples.

Quick start:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
cp .env.example .env       # then edit Gemini + MySQL credentials
mysql -u root -p < schema.sql
python app.py
```

The server listens on `0.0.0.0:5000`. Never put `GEMINI_API_KEY` in Flutter or commit `backend/.env`.

## App flow

Welcome (demo role) → Student (Home · Report · My activity · Impact) or Admin (Overview · Energy · Water · Submissions · Activity).

## Data notes

- Water estimates are not live sensor measurements. AI-generated, fallback, manual, and sample sources are labelled separately.
- When the Flask server is reachable, water records and status changes are persisted in MySQL. When it is unavailable, manual reports can be saved only in the in-memory demo state; the UI explicitly says they are not in MySQL.
- The role switch is demo-only. The Flask API currently has no authentication and is not production-hardened.
