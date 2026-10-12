# Campusync Water API (Flask + MySQL)

The Flask service keeps the Gemini key on the server, accepts uploaded leak photos, stores incident records in MySQL, and exposes the admin status workflow.

## 1. Configure

Use Python 3.10 or newer. From the project root:

```bash
cd backend
python -m venv .venv
# Windows: .venv\\Scripts\\activate
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `backend/.env` and set `GEMINI_API_KEY`, `GEMINI_MODEL`, and the MySQL credentials. The `.env.example` model name follows the supplied Python snippet; verify that model ID is available to your Google AI account. If it is not, set `GEMINI_MODEL` to an enabled Gemini model. A failed/unconfigured Gemini call produces a clearly marked `fallback` result rather than a false AI label.

Create the database/table (the database account needs permission):

```bash
mysql -u root -p < schema.sql
```

If using a different database name, update `DB_NAME` in `.env` and change the `CREATE DATABASE` / `USE` lines in `schema.sql` accordingly.

## 2. Run

```bash
python app.py
```

The server listens on `0.0.0.0:5000` by default. Check readiness at `http://localhost:5000/health`; it returns 200 only when MySQL and the `water_incidents` table are reachable. Use HTTPS, a restricted `CORS_ORIGINS`, and authentication before any real deployment. The demo status endpoint intentionally has no authentication because the app's role switch is demo-only.

Run the backend endpoint tests from the project root (they use a fake MySQL connection, so no live database is needed):

```bash
python -m unittest discover -s backend -p 'test_*.py' -v
```

## API

### `GET /health`

Readiness check for the API and MySQL connection.

### `POST /analyze`

Compatibility/preview route. Accepts `multipart/form-data` with an `image` file and returns the normalized analysis; this route does not create a database record.

### `POST /api/water/incidents`

Creates and persists an incident. Use `multipart/form-data`.

Photo-backed (Flask analyzes the image and stores the result):

```bash
curl -X POST http://localhost:5000/api/water/incidents \\
  -F 'image=@../assets/images/sample_leak.png' \\
  -F 'location=Hostel B washroom' \\
  -F 'estimatedDurationHours=2' \\
  -F 'reporterNote=Leak is near the east-side sink'
```

Manual report (no image):

```bash
curl -X POST http://localhost:5000/api/water/incidents \\
  -F 'location=Library washroom' \\
  -F 'estimatedDurationHours=1.5' \\
  -F 'issueType=leaking_tap' \\
  -F 'severity=low' \\
  -F 'estimatedLitresPerHour=5' \\
  -F 'description=Tap is dripping steadily'
```

A successful create returns `201` and an `incident` object with `id`, location, estimate, `source` (`ai`, `fallback`, or `manual`), and status `open`. Images are stored under `backend/uploads/`; the database stores the filename.

### `GET /api/water/incidents`

Returns all persisted records newest first: `{ "incidents": [...], "count": N }`.

### `PATCH /api/water/incidents/<id>/status`

Updates repair status; JSON body must use one of `open`, `in_progress`, `resolved`, or `dismissed`:

```bash
curl -X PATCH http://localhost:5000/api/water/incidents/INCIDENT_UUID/status \\
  -H 'Content-Type: application/json' \\
  -d '{"status":"in_progress"}'
```

### `GET /api/water/incidents/<id>/image`

Serves the uploaded image attached to a saved report, if present.

## Flutter app connection

- Android emulator default: `http://10.0.2.2:5000`.
- Desktop/web default: `http://127.0.0.1:5000`.
- Physical phone: use the computer's LAN address, e.g. `http://192.168.x.x:5000`, and allow port 5000 through the firewall.
- Or configure the app at build time with `--dart-define=WATER_API_URL=http://<host>:5000`. The report and admin Water screens also expose the server address.

The Android demo build permits local cleartext HTTP. Use HTTPS and remove that allowance for production.
