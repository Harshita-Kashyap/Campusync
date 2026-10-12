# Campusync
Small campus actions. Measurable environmental change. (Flutter, offline-capable MVP, demo data)

See **docs/PROJECT_CONTEXT.md** for architecture, history, ownership and open items.

## Run
`flutter pub get` · `flutter run` · `flutter analyze` · `flutter test`
Add to `pubspec.yaml`: `flutter: assets: [assets/images/sample_leak.png]`

## App flow
Welcome (demo role) → Student (Home · Report · My activity · Impact) or Admin (Overview · Energy · Water · Submissions · Activity).

## Data pattern
Shared `AppRepository` via `RepositoryScope.of(context)`; energy delegated to `EnergyService`. Metrics from `ImpactService`.

## Modules
Energy (Person 2, integrated) · Water (UI by Person 1, logic/AI helper from Person 3) · Submissions (placeholder, awaiting Person 4 logic).

## Demo
Metrics are simulated estimates. Offline path: "Use sample photo" on the water report form.
