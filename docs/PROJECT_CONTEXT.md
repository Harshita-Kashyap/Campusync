# Campusync — Project Context & History
*Last updated: 12 Oct 2026 · Hackathon: KAUSHAL 8.0, PS-04 "Sustainable Tech Without Limits" · Flutter/Dart*

**Tagline:** Small campus actions. Measurable environmental change.
**Core story:** student reports a leak → admin sees it in the priority queue → admin changes status → estimated water loss and dashboard update → recommendation with evidence.
**Principles:** offline-capable demo · honest "estimated/simulated" labelling · no decorative AI (AI optional, rules first) · one shared repository as the single source of truth · units never combined into one score.
**Required label on demo metrics:** "Demo data · Estimates, not live sensor measurements".

---

## 1. Team and who actually builds what (UPDATED)
| Person | Role | Delivers | Status |
|---|---|---|---|
| **1 (you)** | App lead: shell, theme, dashboards, **all UI**, integration | Flutter app | Shell, dashboards, water UI, energy integrated |
| **2** | Energy | Full Flutter module (`EnergyService`, screens, widgets, sample data, tests) | **Integrated** |
| **3** | Water | **Logic only** (Python `analyzeLeak.py` using Gemini vision) — *not Flutter* | Script received, needs fixes (see §7) |
| **4** | Submissions + agent | **Logic/models only** — *not Flutter* | Nothing received yet |

> Change from the original plan: Persons 3 and 4 are not writing Flutter. Person 1 builds the water and submissions **screens**, and plugs their logic into `water_service.dart` / `submission_service.dart`.

## 2. Architecture
- **State:** shared `AppRepository` (`ChangeNotifier` + `RepositoryScope` InheritedNotifier); water records are synced from Flask/MySQL when configured, with clearly labelled in-memory demo fallback.
- **Energy** is owned by Person 2's singleton `EnergyService`; `AppRepository` delegates to it, listens to it, and logs its changes (so changes made inside the Energy screen still refresh the dashboard).
- **Water** uses `WaterService` for validation/rates and `WaterApiClient` for multipart uploads, MySQL list refresh, and repair-status updates. Flask performs Gemini analysis and stores uploaded images + incidents.
- **Submissions** data remains in `AppRepository` pending Person 4's service.
- **Aggregation:** `ImpactService.compute(repo)` → `ImpactMetrics` (metrics, priority queue, recommendations). Widgets never hardcode metrics.
- **Navigation:** welcome (demo role pick) → **Student shell** (Home · Report · My activity · Impact) or **Admin shell** (Overview · Energy · Water · Submissions · Activity). Role switch (⇄) is demo-only, not security.
- **Recommendations:** rule-based fallback in `ImpactService`; Person 4's agent may override with `repo.setRecommendations(list)` (never call it inside `build()`).
- **Theme:** "Field Notes" tokens (canvas #F6F5EF, forest #183F35, leaf #79A875, coral #C65F48, amber #B9812B…), system fonts, status always text + icon.

## 3. Project structure
```
backend/
  app.py                                    Flask + Gemini + MySQL water API
  schema.sql, requirements.txt, .env.example
lib/
  main.dart, app.dart                      routes: / , /admin , /student
  models/            energy_alert, water_incident, digital_submission,
                     sustainability_recommendation, activity_entry (P1),
                     room_reading, timetable_schedule (P2)
  services/          app_repository, impact_service, energy_service (P2),
                     water_service, water_api_client   [submission_service, sustainability_agent: TODO]
  data/seed_data.dart                      water + submissions fixtures (energy comes from P2)
  shared/theme/      app_colors, app_theme
  shared/widgets/    metric_tile, status_badge, empty_state, section_heading,
                     module_scaffold, format (timeAgo, demoLabel)
  features/
    role_selection/  welcome screen
    dashboard/       admin_shell, admin_overview_screen, student_shell,
                     student_home_screen, role_switch_button
    energy/          P2 screen + widgets + sample data
    water/           report_water_screen (student form), water_screen (admin list)
    submissions/     PLACEHOLDER (SubmissionsScreen)
    activity/        activity_screen (admin log), my_activity_screen (student)
    impact/          impact_screen (methodology)
assets/images/sample_leak.png              bundled demo photo (declared in pubspec)
test/                widget_test, energy_service_test (P2), water_service_test
docs/                PROJECT_CONTEXT, DEMO_SCRIPT, TEST_CHECKLIST, DECISIONS,
                     WATER_INTEGRATION, person2/
```

## 4. Shared models (contract — do not change silently)
`EnergyAlert`, `WaterIncident`, `DigitalSubmission`, `SustainabilityRecommendation` exactly as in `INTEGRATION_CONTRACT.md`.
Valid statuses — energy: `active|resolved|dismissed`; water: `open|in_progress|resolved|dismissed` (repository throws `ArgumentError` otherwise).
Issue types: `leaking_tap|overflow|pipe_leak|other`. Severity: `low|medium|high|critical`.

## 5. Metric rules
- Energy: excess = max(0, actual − expected); cost = excess × tariff (₹8/kWh default); CO₂e = excess × 0.82 kg/kWh. Counted for **active** alerts only.
- Water: litres lost = L/h × hours. **Current loss = open + in_progress only**; historical (excl. dismissed) shown on the Impact screen.
- Pages avoided: sum of declared `pagesAvoidedEstimate` (counterfactual, not verified).
- Priority queue: unresolved items sorted by severity then recency; energy priority derived (excess >15 kWh high, >5 medium).

## 6. History (what happened, in order)
1. Read `INTEGRATION_CONTRACT.md` and Person 1 brief; built the first shell, models, repository, dashboard, placeholders.
2. Read the full development plan; reworked to match: demo role switch, Student/Admin shells, "Field Notes" theme, priority queue with status actions, Activity log, Impact/methodology screen, water "current vs historical" rule, status validation.
3. Analyzer issues fixed (unused import, `withOpacity`, stale test); a RenderFlex overflow in the queue rows fixed by replacing `ListTile` with a card layout; docs and tests added.
4. Team split clarified; Person 2's standalone `campusai` project integrated: models/service/screens copied, repository now delegates to `EnergyService` (+ one additive `clearAll()` method), log/notify wiring added.
5. Person 3 shared the Gemini analysis snippet; its output/model/fallback concerns are documented below. Built water report form, admin water list, `water_service.dart` and water tests.
6. Added `backend/app.py` (Flask + Gemini + MySQL), schema/environment examples, file-upload and incident/status endpoints; connected the Flutter photo/manual form and admin queue through `WaterApiClient`.
7. An early Claude Doc skeleton of teammate deliverables was **deleted** because it assumed everyone writes Flutter.

## 7. Open items by person
**Water backend follow-up**
- The supplied analysis flow is now in `backend/app.py`; it returns a labelled `fallback` result on errors and never exposes the Gemini key to Flutter.
- `gemini-3.8-flash` is listed as a stable Gemini model in Google's current model documentation; verify that the team's API key has access, and change `GEMINI_MODEL` only if needed: https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash
- Set MySQL credentials, create the schema with `backend/schema.sql`, run the Flask service, then test `GET /health`, photo upload, list, and status update.
- **Never share `.env` or `venv`; rotate the key if it was exposed.** The demo API currently has no authentication.

**Person 4 must send:** SHA-256 duplicate-check logic, grading rules (labelled prototype), recommendation rules (evidence + action + priority; `isAiGenerated=false` for rules), fixtures. Person 1 then builds `SubmissionsScreen`, `submission_service.dart` and wires `setRecommendations`.

**Person 2:** keep the `clearAll()` addition when updating `energy_service.dart`.

## 8. Remaining work for Person 1
- [ ] Run `flutter pub get`, `dart format .`, `flutter analyze`, and `flutter test` in a Flutter SDK environment; fix anything reported (Flutter/Dart CLI is not available in the current workspace).
- [x] Declare `assets/images/sample_leak.png` and add image picker + HTTP client dependencies.
- [ ] Configure `backend/.env`, initialize MySQL, and verify the backend endpoints against a live database/Gemini key.
- [x] Add Flask/MySQL water API integration, upload UI, admin refresh, and remote status updates.
- [ ] Submissions UI + service once Person 4's logic arrives; agent → `setRecommendations`.
- [ ] Full offline run of `DEMO_SCRIPT.md`; tick `TEST_CHECKLIST.md`; screenshots + 60 s backup video; commit/push, invite team, PR per module.
- [ ] Full offline run of `DEMO_SCRIPT.md`; tick `TEST_CHECKLIST.md`; screenshots + 60 s backup video; commit/push, invite team, PR per module.
- [ ] Feature freeze 45 min before the deadline (confirm 6 h vs 8 h window with organizers).

## 9. Known limitations
Water persistence requires a running Flask/MySQL service; without it, the app uses clearly labelled in-memory demo data. Gemini/model availability and the live MySQL connection have not been verified here; typical manual water rates (5/120/300/10 L/h) are assumptions. The demo API has no authentication, submissions remains a placeholder, and Flutter/Dart checks could not run because the SDK is not available in this workspace.

## 10. Run
Flutter: `flutter pub get` → `flutter run` → `flutter analyze` → `flutter test`. Backend: install `backend/requirements.txt`, copy `backend/.env.example` to `.env`, create MySQL schema with `backend/schema.sql`, then run `python backend/app.py`. Android emulator reaches the host at `http://10.0.2.2:5000`, desktop/web uses `http://127.0.0.1:5000`, and a real phone needs the computer's LAN IP.
