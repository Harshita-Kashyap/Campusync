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
- **State:** one in-memory `AppRepository` (`ChangeNotifier` + `RepositoryScope` InheritedNotifier). No extra packages.
- **Energy** is owned by Person 2's singleton `EnergyService`; `AppRepository` delegates to it, listens to it, and logs its changes (so changes made inside the Energy screen still refresh the dashboard).
- **Water / submissions** data lives in `AppRepository`. `WaterService` wraps it (validation, rates, analyzer).
- **Aggregation:** `ImpactService.compute(repo)` → `ImpactMetrics` (metrics, priority queue, recommendations). Widgets never hardcode metrics.
- **Navigation:** welcome (demo role pick) → **Student shell** (Home · Report · My activity · Impact) or **Admin shell** (Overview · Energy · Water · Submissions · Activity). Role switch (⇄) is demo-only, not security.
- **Recommendations:** rule-based fallback in `ImpactService`; Person 4's agent may override with `repo.setRecommendations(list)` (never call it inside `build()`).
- **Theme:** "Field Notes" tokens (canvas #F6F5EF, forest #183F35, leaf #79A875, coral #C65F48, amber #B9812B…), system fonts, status always text + icon.

## 3. Project structure
```
lib/
  main.dart, app.dart                      routes: / , /admin , /student
  models/            energy_alert, water_incident, digital_submission,
                     sustainability_recommendation, activity_entry (P1),
                     room_reading, timetable_schedule (P2)
  services/          app_repository, impact_service, energy_service (P2),
                     water_service (P1)   [submission_service, sustainability_agent: TODO]
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
assets/images/sample_leak.png              bundled demo photo (declare in pubspec!)
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
5. Person 3 shared `analyzeLeak.py` + `image.png`; reviewed and found problems (§7). Built water report form, admin water list, `water_service.dart` (offline fixture / online / fallback analyzer) and tests.
6. An early Claude Doc skeleton of teammate deliverables was **deleted** because it assumed everyone writes Flutter.

## 7. Open items by person
**Person 3 must fix/send**
- `analyzeLeak.py`: `except` indentation is a syntax error; remove the top-level `print(...)` call; return a dict (not a JSON string).
- Output must be lowercase `severity`, `issueType` ∈ the 4 allowed values, plus `"source": "ai"|"fallback"` (the canned 1500 L/h result must never look like AI).
- Confirm the Gemini model name (`gemini-3.8-flash` is suspect — a wrong name silently triggers the fallback).
- Flask/FastAPI wrapper: `POST /analyze` (multipart field `image`), `GET /health`, listen on `0.0.0.0`, state the port.
- `requirements.txt`, `.env.example` (no secrets), 4+ sample outputs, typical-rate/severity rules.
- **Never share `.env` or `venv`; rotate the key if it was exposed.**

**Person 4 must send:** SHA-256 duplicate-check logic, grading rules (labelled prototype), recommendation rules (evidence + action + priority; `isAiGenerated=false` for rules), fixtures. Person 1 then builds `SubmissionsScreen`, `submission_service.dart` and wires `setRecommendations`.

**Person 2:** keep the `clearAll()` addition when updating `energy_service.dart`.

## 8. Remaining work for Person 1
- [ ] Re-run `flutter pub get`, `dart format .`, `flutter analyze`, `flutter test`; fix anything it reports (nothing has been compiled by the assistant).
- [ ] Add `assets/images/sample_leak.png` to `pubspec.yaml`.
- [ ] Submissions UI + service once Person 4's logic arrives; agent → `setRecommendations`.
- [ ] Wire Person 3's real server (or keep the offline sample photo for the demo).
- [ ] Optional: role-switch button on the Energy tab; `image_picker` for real photos; persistence; filters/trends.
- [ ] Full offline run of `DEMO_SCRIPT.md`; tick `TEST_CHECKLIST.md`; screenshots + 60 s backup video; commit/push, invite team, PR per module.
- [ ] Feature freeze 45 min before the deadline (confirm 6 h vs 8 h window with organizers).

## 9. Known limitations
No persistence; online photo analysis always sends the bundled sample image and uses `dart:io` (not web); typical water rates (5/120/300/10 L/h) are assumptions; submissions module is a placeholder; code has not been compiled by the assistant.

## 10. Run
`flutter pub get` → `flutter run` (offline) → `flutter analyze` → `flutter test`.
Android emulator reaches a laptop server at `http://10.0.2.2:<port>`; a real phone needs the laptop's LAN IP.
