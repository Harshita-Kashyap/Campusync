# Water module: Flutter + Flask + MySQL

## Student report flow

`ReportWaterScreen` supports two paths:

1. **Photo report:** choose/take a photo (or select the bundled demo image), enter location and duration, then submit. Flutter sends a `multipart/form-data` request with field `image` to Flask. Flask calls the Gemini function, normalizes the response, marks its source as `ai` or `fallback`, saves the incident and image, and returns the persisted record. The app adds that record to the shared `AppRepository`.
2. **Manual report:** enter issue type, severity, estimated litres/hour, duration, and description. Flutter sends it to Flask and MySQL with `source=manual`. If the server is unavailable, the app keeps a local demo-only copy and clearly says it was not stored in MySQL.

The Gemini key is read only by the Python server. A fallback analysis is marked `fallback`; it must never be shown as AI. Estimates are not sensor measurements.

## Flask API

Run instructions and MySQL setup are in [`../backend/README.md`](../backend/README.md). Configure `backend/.env`, create the database with `backend/schema.sql`, then start `python backend/app.py` (or run `python app.py` from `backend/`).

- `GET /health` — Flask and MySQL readiness.
- `POST /analyze` — multipart field `image`; analysis-only compatibility endpoint.
- `POST /api/water/incidents` — multipart `image`, `location`, and `estimatedDurationHours` to analyze + persist; or submit manual fields without `image`.
- `GET /api/water/incidents` — all MySQL incidents, newest first.
- `PATCH /api/water/incidents/<id>/status` — JSON `{"status":"in_progress"}` (valid: `open`, `in_progress`, `resolved`, `dismissed`).
- `GET /api/water/incidents/<id>/image` — serves an uploaded report image.

Images are limited to 10 MB and JPG, PNG, or WebP. Uploaded image files are stored under `backend/uploads/`; incident data and the stored filename are kept in MySQL. The database schema stores the shared app contract: lowercase issue types, severity, source, status, rate, duration, description, location, timestamp, and ID.

## Flutter server address

- Android emulator default: `http://10.0.2.2:5000`.
- Desktop/web default: `http://127.0.0.1:5000`.
- Physical phone: `http://<computer-LAN-IP>:5000` (allow the port through the firewall).
- Override the default with `--dart-define=WATER_API_URL=http://<host>:5000`.

Both Student Report and Admin Water screens allow editing the address. Android development builds enable local cleartext HTTP; use HTTPS and remove that setting before production.

## Operational/security notes

The demo role switch is not authorization, and the API currently has no authentication. Restrict CORS, add authentication and authorization, use HTTPS, and protect uploaded files before exposing this beyond a trusted demo network. Do not commit `.env`, virtual environments, or uploaded photos.
