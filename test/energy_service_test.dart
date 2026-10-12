import 'package:flutter_test/flutter_test.dart';
import 'package:campusync/models/energy_alert.dart';
import 'package:campusync/models/room_reading.dart';
import 'package:campusync/services/energy_service.dart';

void main() {
  group('Person 2 — EcoNudge AI Acceptance & Verification Tests', () {
    late EnergyService service;

    setUp(() {
      service = EnergyService();
      service.resetToDefaults();
    });

    test('Formula Verification: excessKwh, cost, and co2Kg match exact spec', () {
      // Fixture from 02_person2_energy.md:
      // Room: Lab 3, Actual: 2.5 kWh, Expected: 0.5 kWh, Tariff: ₹8/kWh, CO2: 0.82 kg/kWh
      final alert = EnergyAlert(
        id: 'TEST-001',
        roomName: 'Lab 3',
        timestamp: DateTime.now(),
        actualKwh: 2.5,
        expectedKwh: 0.5,
        tariffPerKwh: 8.0,
        co2KgPerKwh: 0.82,
        reason: 'Test anomaly fixture',
      );

      // Excess = max(0, 2.5 - 0.5) = 2.0 kWh
      expect(alert.excessKwh, closeTo(2.0, 0.001));

      // Estimated cost = 2.0 * 8.0 = ₹16.00
      expect(alert.estimatedCost, closeTo(16.0, 0.001));

      // Estimated emissions = 2.0 * 0.82 = 1.64 kg CO2e
      expect(alert.estimatedCo2Kg, closeTo(1.64, 0.001));
    });

    test('Normal case is NOT flagged as wastage (No false positive)', () {
      final normalReading = RoomReading(
        roomId: 'R-215',
        roomName: 'CSE-215',
        roomType: 'Lecture Hall',
        timestamp: DateTime.now(),
        actualKwh: 1.85,
        expectedKwh: 1.90, // Scheduled occupied lecture
        isScheduledOccupied: true,
        activeClassId: 'AI&DS - II (B)',
      );

      expect(normalReading.hasWastageAnomaly, isFalse);
      final alert = service.evaluateReading(normalReading);
      expect(alert, isNull, reason: 'Normal reading must not trigger an alert');
    });

    test('Anomaly case: Ghost consumption in empty room is flagged with clear explanation', () {
      final anomalyReading = RoomReading(
        roomId: 'R-213',
        roomName: 'CSE-213',
        roomType: 'Lecture Hall',
        timestamp: DateTime.now(),
        actualKwh: 2.85,
        expectedKwh: 0.20, // Class relocated to lab per timetable
        isScheduledOccupied: false,
        activeActivity: 'Class Relocated to Lab 220 A+B',
      );

      expect(anomalyReading.hasWastageAnomaly, isTrue);
      final alert = service.evaluateReading(anomalyReading);
      expect(alert, isNotNull);
      expect(alert!.excessKwh, closeTo(2.65, 0.001));
      expect(alert.estimatedCost, closeTo(21.20, 0.01));
      expect(alert.estimatedCo2Kg, closeTo(2.173, 0.01));
      expect(alert.reason.toLowerCase(), contains('ghost consumption'));
    });

    test('Zero and Negative input validation safeguards', () {
      // Zero actual draw when expected > 0 -> excess must be 0, not negative
      final zeroReadingAlert = EnergyAlert(
        id: 'TEST-ZERO',
        roomName: 'Room Zero',
        timestamp: DateTime.now(),
        actualKwh: 0.0,
        expectedKwh: 1.5,
        reason: 'Zero power test',
      );
      expect(zeroReadingAlert.excessKwh, equals(0.0));
      expect(zeroReadingAlert.estimatedCost, equals(0.0));
      expect(zeroReadingAlert.estimatedCo2Kg, equals(0.0));

      // Pure method check rejects negative arguments
      expect(
        () => EnergyService.calculateExcessKwh(-1.0, 2.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Status changes update the underlying alert repository and metrics', () async {
      final activeBefore = service.getActiveAlerts().length;
      final initialCost = service.getEstimatedCost();
      expect(activeBefore, greaterThan(0));

      final targetAlert = service.getActiveAlerts().first;
      final targetCost = targetAlert.estimatedCost;

      // Resolve the alert
      await service.updateAlertStatus(targetAlert.id, 'resolved');

      final activeAfter = service.getActiveAlerts().length;
      expect(activeAfter, equals(activeBefore - 1));

      // Active cost metric drops by the resolved alert's amount
      final updatedCost = service.getEstimatedCost();
      expect(updatedCost, closeTo(initialCost - targetCost, 0.01));

      // Dismiss the alert
      await service.updateAlertStatus(targetAlert.id, 'dismissed');
      expect(service.getDismissedAlerts().any((a) => a.id == targetAlert.id), isTrue);
    });

    test('Module contract methods expose aggregated values for Person 1 Dashboard', () {
      final excessKwh = service.getEstimatedExcessKwh();
      final cost = service.getEstimatedCost();
      final co2 = service.getEstimatedCo2Kg();
      final alerts = service.getAlerts();

      expect(excessKwh, isNonNegative);
      expect(cost, isNonNegative);
      expect(co2, isNonNegative);
      expect(alerts, isNotEmpty);
      expect(alerts.length, greaterThanOrEqualTo(3));
    });

    test('10 Academic Classes timetable verification', () {
      final classes = service.getAllClasses();
      expect(classes.length, equals(10), reason: 'Must contain 10 sample classes');

      // Verify AI&DS-II(A) details match uploaded SVVV PDF
      final classA = service.getClassById('CLASS-01');
      expect(classA, isNotNull);
      expect(classA!.roomNo, equals('CSE-213'));
      expect(classA.className, equals('AI&DS - II (A)'));
      expect(classA.classTeacher, equals('Prof. Unnati Mishra'));
    });
  });
}
