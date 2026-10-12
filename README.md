# Campusync — Person 1 (App Lead, Dashboards & Integration)

## Run
Copy `lib/` into your `flutter create campusync` project (no extra packages), then `flutter run` / `flutter analyze`.
Uses system fonts (offline-safe). No network needed.

## Flow
Welcome (demo role pick) → **Student** shell (Home · Report · My activity · Impact) or **Admin** shell (Overview · Energy · Water · Submissions · Activity).
Role switch (⇄ icon) is demo navigation, not security.

## Data-access pattern (all modules)
`AppRepository` (ChangeNotifier) via `RepositoryScope.of(context)`.
Read: `getAlerts() / getIncidents() / getSubmissions()`. Write: `addAlert/addIncident/addSubmission`, `updateAlertStatus / updateIncidentStatus(id, status)`.
Invalid status or unknown id throws `ArgumentError`. Every write notifies listeners and adds to the Activity log.

## Replace-me placeholders (keep class names)
`EnergyScreen` (P2) · `WaterScreen`, `ReportWaterScreen` (P3) · `SubmissionsScreen` (P4; call `repo.setRecommendations()` from the agent).

## Metric scope
Energy: active alerts. Water current loss: open + in-progress (resolved excluded); historical loss shown on Impact screen. Units never combined.

## Test checklist
1. Launch → pick Student / Admin; ⇄ returns to welcome.
2. Student → Report → "Submit demo report" → Home/My activity show it; Admin Overview open count + current water loss rise.
3. Admin → tap queue item → set Resolved → open count drops, current loss drops, Activity logs it.
4. Invalid: `repo.updateIncidentStatus('WA-001','bogus')` throws ArgumentError.
5. Empty: use `AppRepository()` in app.dart → empty states appear.

## Known limitations
No persistence; modules 2–4 placeholders; no automated tests yet.
