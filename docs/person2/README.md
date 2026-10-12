# Campusync — EcoNudge AI: Energy Intelligence (Person 2)
**Theme:** Kaushal 8.0 — Sustainable Tech Without Limits (PS-04)  
**Role:** Energy calculations and energy UI | Person 2 |  
**Module:** EcoNudge AI — Campus Sub-Metering & Timetable-Driven Anomaly Detection  
**Institution:** Shri Vaishnav Vidyapeeth Vishwavidyalaya (SVVV), Indore — SVIIT  

---

## 1. Mission & Overview
On college campuses, electricity wastage often goes undetected because conventional utility meters only measure aggregated monthly consumption without room-level occupancy context. 

**EcoNudge AI (Person 2 Module)** solves this by coupling simulated IoT sub-meter telemetry with the **10 official academic class timetables** from the Department of Artificial Intelligence & Data Science and Department of CSE. 

When a classroom is scheduled for practical labs, sports, library, or recess, the expected baseline energy draw drops to standby (`0.15 - 0.20 kWh`). If sensors detect high active draw (e.g. 4 ceiling fans, 8 tube lights, and a digital projector left on), EcoNudge AI immediately flags a **Ghost Consumption Anomaly**, calculates the exact monetary waste in Rupees (`₹`) and carbon emissions footprint in `kg CO₂e`, and offers one-click facility resolution.

---

## 2. Core Mathematical Formulas
Strictly implemented according to the `INTEGRATION_CONTRACT.md` and `02_person2_energy.md`:

$$\text{excessKwh} = \max(0, \text{actualKwh} - \text{expectedKwh})$$
$$\text{estimatedCost} = \text{excessKwh} \times \text{tariffPerKwh}$$
$$\text{estimatedCo2Kg} = \text{excessKwh} \times \text{co2KgPerKwh}$$

### Default Environmental & Tariff Assumptions:
- **Tariff Rate:** ₹8.00 / kWh (Standard institutional commercial energy tariff)
- **Emissions Factor:** 0.82 kg CO₂e / kWh (Central Electricity Authority of India grid emissions factor)

### Baseline Fixture Verification (Lab 3 from Specification):
- **Actual Draw:** 2.50 kWh
- **Expected Baseline:** 0.50 kWh
- **Calculated Excess:** $\max(0, 2.50 - 0.50) = 2.00\text{ kWh}$
- **Calculated Cost Leak:** $2.00 \times ₹8.00 = ₹16.00$
- **Calculated Excess Emissions:** $2.00 \times 0.82 = 1.64\text{ kg CO}_2\text{e}$
- *Verified in automated test suite with 100% precision.*

---

## 3. 10 Academic Class Timetables Integration
Conforming to the uploaded SVVV SVIIT departmental timetable document (`SVVV/SVIIT/CSE/CT/1`), 10 complete class schedules across Shift-II (10:00 AM – 5:00 PM) have been integrated:

1. **AI&DS - II (A)** | Room `CSE-213` | Class Teacher: Prof. Unnati Mishra (AIML Microsoft)
2. **AI&DS - II (B)** | Room `CSE-215` | Class Teacher: Prof. Jayshree Pargee (AIML Microsoft)
3. **AI&DS - II (C)** | Room `CSE-214` | Class Teacher: Prof. Amit Dangi (DS IBM + RH + MA)
4. **AI&DS - II (D)** | Room `CSE-212` | Class Teacher: Prof. Juhi Shrivastav (AI IBM)
5. **AI&DS - III (A)** | Room `CSE-301` | Sem V: Deep Learning, Cloud DevOps, AI Ethics
6. **AI&DS - III (B)** | Room `CSE-302` | Sem V: Big Data Analytics, NLP, Distributed Systems
7. **AI&DS - IV (A)** | Room `CSE-401` | Sem VII: Generative AI, MLOps, Capstone Project
8. **CSE - II (A)** | Room `CSE-105` | Sem III: Data Structures, Discrete Math, COA
9. **CSE - II (B)** | Room `CSE-106` | Sem III: OOP Java, Database Systems, Computer Networks
10. **CSE - III (A)** | Room `CSE-305` | Sem V: Analysis of Algorithms, Web Tech, Cyber Security

### Shared Campus Lab Venues Monitored:
- **Lab 220 A+B:** High Performance Computing Lab (60 PCs, 4 ACs)
- **IBM 320 Lab:** Big Data Analytics & Cloud Lab (45 PCs, 3 ACs)
- **EC-Lab:** Hardware, Logic & Microprocessor Lab
- **R&D LAB:** Advanced Research & Capstone Lab (30 PCs)
- **Apple Lab:** iOS Development & NLP Lab (35 iMacs)

---

## 4. Code Architecture & Owned Files

```
c:/Users/rajes/Downloads/Samyak/Campusync/
├── assets/
│   └── data/
│       └── timetables_10_classes.json      # Structured JSON dataset for 10 classes
├── lib/
│   ├── features/
│   │   └── energy/
│   │       ├── energy_sample_data.dart     # Sample fixtures (10 rooms, normal/anomaly cases)
│   │       ├── energy_screen.dart          # Primary UI Dashboard for Person 2
│   │       └── widgets/
│   │           ├── energy_alert_card.dart  # Alert card with resolve/dismiss actions
│   │           ├── energy_metric_card.dart # Stat banner widgets
│   │           ├── energy_quick_chart.dart # Zero-dependency CustomPainter bar chart
│   │           ├── room_energy_tile.dart   # Live sub-meter tile with load bar
│   │           └── timetable_schedule_view.dart # 10-Class interactive timetable viewer
│   ├── models/
│   │   ├── energy_alert.dart               # Shared EnergyAlert model (Contract Sec 3)
│   │   ├── room_reading.dart               # Telemetry reading model
│   │   └── timetable_schedule.dart         # Class & slot timetable data models
│   ├── services/
│   │   └── energy_service.dart             # EnergyModuleContract implementation
│   └── main.dart                           # Standalone runnable Flutter entry point
├── test/
│   └── energy_service_test.dart            # Flutter test suite
├── web_demo/
│   └── index.html                          # Standalone offline browser prototype for pitch
├── 02_person2_energy.md                    # Task brief
├── INTEGRATION_CONTRACT.md                 # Contract agreement
├── INTEGRATION_NOTE.md                     # Handoff instructions for Person 1
├── TIMETABLES_10_CLASSES.md                # Human-readable & printable timetable tables
├── test_runner.py                          # Automated Python validation suite
└── pubspec.yaml                            # Flutter package declaration
```

---

## 5. Acceptance Checklist & Verification
| Requirement | Status | Verification Evidence |
|---|:---:|---|
| **Anomaly flagged with clear reason** | PASS | Room `CSE-213` flagged for ghost consumption when timetable shows class is in `Lab 220 A+B`. |
| **Normal reading not misclassified** | PASS | Room `CSE-215` (lecture in session, actual 1.85 kWh vs 1.90 kWh expected) flagged as Normal. |
| **Formulas match contract** | PASS | $\text{excess} = \max(0, \text{act} - \text{exp})$, $\text{cost} = \text{excess} \times ₹8$, $\text{CO}_2 = \text{excess} \times 0.82$. |
| **Status mutation updates data** | PASS | Calling `updateAlertStatus(id, 'resolved')` reduces active excess and cost in real time. |
| **Dashboard consumes without parsing text** | PASS | Direct double and list getters: `getEstimatedExcessKwh()`, `getEstimatedCost()`, `getAlerts()`. |
| **100% Offline & No API Key Required** | PASS | Pure deterministic mathematics and in-memory sample repository. |

---

## 6. How to Run & Demo

### Option A: Immediate Python Acceptance Suite
Run the automated test runner in PowerShell or terminal:
```powershell
python test_runner.py
```
*Result: 16/16 tests pass with 100% success rate.*

### Option B: Interactive Live Demo (Offline Web Presentation)
Double click or launch `web_demo/index.html` in any browser (Chrome, Edge, Firefox):
```powershell
# Or via Python lightweight server:
python -m http.server 8080
# Open http://localhost:8080/web_demo/
```
Judges can:
1. Inspect live active anomaly cards with mathematical breakdown.
2. Click **"✓ Mark Resolved"** or **"Dismiss"** and observe real-time cost and CO₂e reductions.
3. Switch to **"10-Class Timetable Matrix"** to see all 10 classes from the official SVVV PDF.
4. Click **"⚡ Simulate Ghost Leak (CSE-213)"** or **"⚡ Simulate Night Lab HVAC"** to watch live sub-meter bars update dynamically.
5. View the side-by-side comparative chart.

### Option C: Flutter Integration
Person 1 can directly include Person 2 files:
```dart
import 'package:campusync_energy/services/energy_service.dart';
import 'package:campusync_energy/features/energy/energy_screen.dart';

// In Person 1 Navigation / Dashboard:
final energyService = EnergyService();
final activeExcess = energyService.getEstimatedExcessKwh();
final activeCost = energyService.getEstimatedCost();
```
