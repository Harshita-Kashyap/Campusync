# Integration Note: Person 2 -> Person 1 (Handoff Guide)
**Module:** EcoNudge AI — Energy Intelligence  
**Author:** Person 2 (Energy calculations & Energy UI)  
**Consumer:** Person 1 (App entry, navigation, theme, shared dashboard)  
**Contract Reference:** `INTEGRATION_CONTRACT.md` (Sections 2, 3, 4, 5)

---

## 1. Quick Integration Summary
Person 1 can access all energy metrics, anomaly alerts, and UI screens with zero external package dependencies.

### Import Path:
```dart
import 'services/energy_service.dart';
import 'features/energy/energy_screen.dart';
import 'models/energy_alert.dart';
```

---

## 2. Shared Model: `EnergyAlert`
Location: `lib/models/energy_alert.dart`

```dart
class EnergyAlert {
  final String id;
  final String roomName;
  final DateTime timestamp;
  final double actualKwh;
  final double expectedKwh;
  final double tariffPerKwh; // default: 8.0 (₹8/kWh)
  final double co2KgPerKwh;  // default: 0.82 (kg CO2e/kWh)
  final String reason;
  final String status;       // "active", "resolved", "dismissed"

  // Derived getters (Zero parsing needed):
  double get excessKwh;      // max(0, actualKwh - expectedKwh)
  double get estimatedCost;  // excessKwh * tariffPerKwh
  double get estimatedCo2Kg; // excessKwh * co2KgPerKwh
  bool get isActive;
  bool get isResolved;
  bool get isDismissed;

  Map<String, dynamic> toJson();
  factory EnergyAlert.fromJson(Map<String, dynamic> json);
  EnergyAlert copyWith({...});
}
```

---

## 3. Public Service Interface: `EnergyService`
Location: `lib/services/energy_service.dart`  
Implements: `EnergyModuleContract` (defined in `INTEGRATION_CONTRACT.md` Section 4) and extends Flutter's `ChangeNotifier`.

### Method Signatures for Person 1 Dashboard:
| Method | Return Type | Description |
|---|---|---|
| `getAlerts()` | `List<EnergyAlert>` | Returns all alerts (active, resolved, dismissed). |
| `getEstimatedExcessKwh()` | `double` | Returns total excess kWh across all **active** alerts. |
| `getEstimatedCost()` | `double` | Returns total estimated waste cost in **Rupees (₹)** across active alerts. |
| `getEstimatedCo2Kg()` | `double` | Returns total estimated greenhouse emissions in **kg CO₂e** across active alerts. |
| `updateAlertStatus(id, status)` | `Future<void>` | Updates alert status to `"active"`, `"resolved"`, or `"dismissed"` and notifies listeners. |
| `getActiveAlerts()` | `List<EnergyAlert>` | Helper to retrieve only alerts with `status == "active"`. |
| `getRoomReadings()` | `List<RoomReading>` | Returns live sub-meter readings for all 10 campus spaces. |
| `getAllClasses()` | `List<TimetableClass>` | Returns the 10 academic timetable schedules. |
| `refreshTelemetry()` | `void` | Simulates smart sub-meter synchronization and re-evaluates baselines. |

---

## 4. Code Example for Person 1 Shared Dashboard

```dart
import 'package:flutter/material.dart';
import 'package:campusync_energy/services/energy_service.dart';
import 'package:campusync_energy/features/energy/energy_screen.dart';

class CampusDashboardScreen extends StatelessWidget {
  final EnergyService energyService = EnergyService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: energyService,
      builder: (context, _) {
        final double excessKwh = energyService.getEstimatedExcessKwh();
        final double costRupees = energyService.getEstimatedCost();
        final double co2Kg = energyService.getEstimatedCo2Kg();
        final int activeAlertsCount = energyService.getActiveAlerts().length;

        return Scaffold(
          body: Column(
            children: [
              // 1. Person 1 Shared Dashboard Metric Cards
              DashboardCard(
                title: "Energy Wastage",
                value: "${excessKwh.toStringAsFixed(1)} kWh",
                subtitle: "₹${costRupees.toStringAsFixed(0)} • ${co2Kg.toStringAsFixed(1)} kg CO₂e",
                badge: "$activeAlertsCount Active Alerts",
                onTap: () {
                  // Navigate directly to Person 2 Energy Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnergyScreen(service: energyService),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 5. UI Route Integration
Person 2's screen can be mounted directly into the main bottom navigation bar or drawer:
```dart
// Route or Tab:
EnergyScreen(service: EnergyService())
```

---

## 6. Dependencies & Known Limitations
- **External Dependencies:** Zero! No external charting or state management packages required. Works out of the box with Flutter standard library.
- **Offline Operation:** 100% offline. Operates with in-memory sample fixtures and deterministic timetable baseline algorithms.
- **AI / LLM:** None required for core anomaly logic. An optional LLM can be attached later to generate customized facility warden nudges if desired.
