# Test checklist
## Core
- [ ] Launches on target device; Student and Admin reachable; ⇄ returns to welcome
- [ ] Student report appears in My activity, admin queue, water list, overview counts
- [ ] Admin status change refreshes queue, counts, current water loss, Activity log
- [ ] Energy metrics match seeded records; zero excess → 0
- [ ] Submission duplicate (same bytes) flagged and explained
- [ ] Recommendations show evidence + action
- [ ] Works offline
## Validation
- [ ] Negative rate/duration rejected; missing location/description rejected
- [ ] Invalid status throws ArgumentError (`flutter test`)
- [ ] Empty states for queue, activity, my activity, recommendations
## UI
- [ ] No overflow warnings at 360 px width and on wide window
- [ ] Status shown as text + icon; tap targets ≥ 48 px; contrast readable
- [ ] Demo/estimate label visible on overview, student home, impact
## Release
- [ ] `dart format .` · `flutter analyze` · `flutter test` clean
