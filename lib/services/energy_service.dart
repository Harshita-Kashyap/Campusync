import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/energy_alert.dart';
import '../models/room_reading.dart';
import '../models/timetable_schedule.dart';
import '../features/energy/energy_sample_data.dart';

/// Handoff interface defined in INTEGRATION_CONTRACT.md Section 4.
/// Guaranteed to be stable for Person 1 (Dashboard Lead) integration.
abstract class EnergyModuleContract {
  List<EnergyAlert> getAlerts();
  double getEstimatedExcessKwh();
  double getEstimatedCost();
  double getEstimatedCo2Kg();
  Future<void> updateAlertStatus(String id, String status);
}

/// Service implementing energy intelligence, timetable-driven baseline
/// evaluation, anomaly detection, and impact metrics.
class EnergyService extends ChangeNotifier implements EnergyModuleContract {
  // Singleton instance for shared in-memory repository access
  static final EnergyService _instance = EnergyService._internal();
  factory EnergyService() => _instance;

  EnergyService._internal() {
    _initDefaults();
  }

  final List<EnergyAlert> _alerts = [];
  final List<RoomReading> _roomReadings = [];
  final List<TimetableClass> _classes = [];

  double _tariffPerKwh = EnergySampleData.standardTariffPerKwh;
  double _co2KgPerKwh = EnergySampleData.standardCo2Factor;

  /// Tolerance margin in kWh before triggering an alert on minor fluctuations
  static const double anomalyThresholdBufferKwh = 0.35;

  void _initDefaults() {
    _alerts.clear();
    _alerts.addAll(EnergySampleData.getInitialAlerts());

    _roomReadings.clear();
    _roomReadings.addAll(EnergySampleData.getSampleRoomReadings());

    _classes.clear();
    _classes.addAll(EnergySampleData.getTenClasses());
  }

  // ==========================================
  // EnergyModuleContract Implementation
  // ==========================================

  @override
  List<EnergyAlert> getAlerts() {
    return List.unmodifiable(_alerts);
  }

  /// Calculates total excess kWh across all ACTIVE alerts.
  /// Formula: sum(excessKwh) where status == "active"
  @override
  double getEstimatedExcessKwh() {
    return _alerts
        .where((a) => a.isActive)
        .fold(0.0, (sum, a) => sum + a.excessKwh);
  }

  /// Calculates total estimated monetary cost wasted in INR across active alerts.
  /// Formula: sum(excessKwh * tariffPerKwh)
  @override
  double getEstimatedCost() {
    return _alerts
        .where((a) => a.isActive)
        .fold(0.0, (sum, a) => sum + a.estimatedCost);
  }

  /// Calculates total estimated greenhouse gas footprint in kg CO2e across active alerts.
  /// Formula: sum(excessKwh * co2KgPerKwh)
  @override
  double getEstimatedCo2Kg() {
    return _alerts
        .where((a) => a.isActive)
        .fold(0.0, (sum, a) => sum + a.estimatedCo2Kg);
  }

  /// Updates status of an alert ("active", "resolved", "dismissed").
  @override
  Future<void> updateAlertStatus(String id, String status) async {
    final validStatuses = {'active', 'resolved', 'dismissed'};
    final normalized = status.toLowerCase();
    if (!validStatuses.contains(normalized)) {
      throw ArgumentError('Invalid status: $status. Must be active, resolved, or dismissed.');
    }

    final index = _alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(status: normalized);
      notifyListeners();
    }
  }

  // ==========================================
  // Person 2 Extended Capabilities & Methods
  // ==========================================

  double get tariffPerKwh => _tariffPerKwh;
  set tariffPerKwh(double val) {
    if (val < 0) throw ArgumentError('Tariff cannot be negative');
    _tariffPerKwh = val;
    notifyListeners();
  }

  double get co2KgPerKwh => _co2KgPerKwh;
  set co2KgPerKwh(double val) {
    if (val < 0) throw ArgumentError('Emissions factor cannot be negative');
    _co2KgPerKwh = val;
    notifyListeners();
  }

  /// Returns active alerts requiring intervention
  List<EnergyAlert> getActiveAlerts() => _alerts.where((a) => a.isActive).toList();

  /// Returns resolved alerts
  List<EnergyAlert> getResolvedAlerts() => _alerts.where((a) => a.isResolved).toList();

  /// Returns dismissed alerts
  List<EnergyAlert> getDismissedAlerts() => _alerts.where((a) => a.isDismissed).toList();

  /// Returns all room sensor telemetry readings
  List<RoomReading> getRoomReadings() => List.unmodifiable(_roomReadings);

  /// Returns the 10 loaded sample academic classes
  List<TimetableClass> getAllClasses() => List.unmodifiable(_classes);

  /// Retrieves a class timetable by ID
  TimetableClass? getClassById(String classId) {
    try {
      return _classes.firstWhere((c) => c.id == classId);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves a class by assigned classroom number
  TimetableClass? getClassByRoom(String roomNo) {
    try {
      return _classes.firstWhere((c) => c.roomNo.toUpperCase() == roomNo.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  /// Pure deterministic calculation of energy excess.
  /// Strictly rejects negative consumption and handles zero-input safely.
  static double calculateExcessKwh(double actualKwh, double expectedKwh) {
    if (actualKwh < 0 || expectedKwh < 0) {
      throw ArgumentError('Energy readings cannot be negative: actual=$actualKwh, expected=$expectedKwh');
    }
    return max(0.0, actualKwh - expectedKwh);
  }

  /// Pure deterministic calculation of cost in INR.
  static double calculateCost(double excessKwh, double tariffPerKwh) {
    if (excessKwh < 0 || tariffPerKwh < 0) {
      throw ArgumentError('Inputs cannot be negative');
    }
    return excessKwh * tariffPerKwh;
  }

  /// Pure deterministic calculation of CO2e emissions in kg.
  static double calculateCo2Kg(double excessKwh, double co2KgPerKwh) {
    if (excessKwh < 0 || co2KgPerKwh < 0) {
      throw ArgumentError('Inputs cannot be negative');
    }
    return excessKwh * co2KgPerKwh;
  }

  /// Evaluates whether a room reading represents energy wastage based on timetable status.
  /// If an anomaly is detected, creates an EnergyAlert and appends it to the alert repository.
  EnergyAlert? evaluateReading(RoomReading reading) {
    final double actual = max(0.0, reading.actualKwh);
    final double expected = max(0.0, reading.expectedKwh);
    final double excess = max(0.0, actual - expected);

    // If reading is within expected baseline + buffer, no anomaly
    if (actual <= expected + anomalyThresholdBufferKwh) {
      return null;
    }

    // Determine plain-language reason based on timetable occupancy context
    String reason;
    if (!reading.isScheduledOccupied) {
      if (reading.activeActivity != null && reading.activeActivity!.contains('Relocated')) {
        reason = 'Ghost Consumption: Class relocated to lab per timetable, but ${reading.roomName} has ${actual.toStringAsFixed(2)} kWh active load (fans/lights/projector unswitched).';
      } else if (reading.activeCourseCode == 'LUNCH') {
        reason = 'Recess Wastage: Official lunch recess is scheduled, but ${reading.roomName} maintains continuous power draw of ${actual.toStringAsFixed(2)} kWh.';
      } else {
        reason = 'Off-Hours Wastage: Unscheduled high power consumption (${actual.toStringAsFixed(2)} kWh vs ${expected.toStringAsFixed(2)} kWh expected) during vacant interval.';
      }
    } else {
      reason = 'Load Overload: Active room load (${actual.toStringAsFixed(2)} kWh) exceeds maximum rated baseline (${expected.toStringAsFixed(2)} kWh) by ${excess.toStringAsFixed(2)} kWh.';
    }

    final newAlert = EnergyAlert(
      id: 'ALERT-NRG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      roomName: reading.roomName,
      timestamp: reading.timestamp,
      actualKwh: actual,
      expectedKwh: expected,
      tariffPerKwh: _tariffPerKwh,
      co2KgPerKwh: _co2KgPerKwh,
      reason: reason,
      status: 'active',
    );

    _alerts.insert(0, newAlert);
    notifyListeners();
    return newAlert;
  }

  /// Simulates a real-time smart meter refresh and re-evaluates all 10 campus spaces
  void refreshTelemetry() {
    // Re-evaluate current readings
    for (final reading in _roomReadings) {
      if (reading.hasWastageAnomaly) {
        // Check if an active alert for this room already exists
        final exists = _alerts.any((a) => a.roomName == reading.roomName && a.isActive);
        if (!exists) {
          evaluateReading(reading);
        }
      }
    }
    notifyListeners();
  }

  /// Manually adds an alert (useful for integration testing and Person 1 mock fixtures)
  void addAlert(EnergyAlert alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }

  /// Integration addition (Person 1): empties alerts (used for empty-state demo/tests).
  void clearAll() {
    _alerts.clear();
    notifyListeners();
  }

  /// Clears or resets state to initial sample fixtures
  void resetToDefaults() {
    _initDefaults();
    notifyListeners();
  }
}
