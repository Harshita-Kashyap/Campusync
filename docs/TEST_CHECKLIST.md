# Test checklist

## Flutter app
- [ ] Launches on target device; Student and Admin reachable; ⇄ returns to welcome
- [ ] Student report appears in My activity, admin queue, water list, and overview counts
- [ ] Photo picker (gallery/camera) preview; photo report uploads to Flask
- [ ] Admin status change updates queue, counts, current water loss, and Activity log
- [ ] Water screen indicates whether records/status updates are MySQL-backed or local demo only
- [ ] Energy metrics match seeded records; zero excess → 0
- [ ] Submission duplicate (same bytes) flagged and explained
- [ ] Recommendations show evidence + action
- [ ] Works offline; manual/local fallback is not presented as MySQL-persisted

## Flask + MySQL
- [ ] `GET /health` returns 200 with MySQL/schema configured
- [ ] `POST /api/water/incidents` with `image` stores AI/fallback output and image
- [ ] `POST /api/water/incidents` without image stores a manual report
- [ ] `GET /api/water/incidents` returns records newest-first
- [ ] `PATCH /api/water/incidents/<id>/status` accepts valid statuses and rejects invalid ones
- [ ] Missing/unsupported/oversized images and missing DB configuration return readable JSON errors

## Validation
- [ ] Negative / zero / non-numeric leak rate rejected
- [ ] Negative duration rejected; zero accepted
- [ ] Missing location/description rejected on manual reports
- [ ] Resolved/dismissed incidents are excluded from current loss
