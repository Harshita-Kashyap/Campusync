# Water module integration
UI: `features/water/` (report form, admin list). Logic: `services/water_service.dart`.
Required from Person 3: fixed `analyzeLeak.py` (valid syntax, no top-level call, returns object with lowercase
severity, issueType in leaking_tap|overflow|pipe_leak|other, `source`: "ai"|"fallback"), Flask/FastAPI `POST /analyze`
(multipart field `image`) + `GET /health`, requirements.txt, .env.example (no secrets), 4+ example outputs.
Offline path ("Use sample photo") works with no server. Add to pubspec.yaml:
  flutter:
    assets:
      - assets/images/sample_leak.png
