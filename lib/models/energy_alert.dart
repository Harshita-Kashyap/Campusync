import 'dart:math';

/// Model representing an energy anomaly alert detected by EcoNudge AI.
/// Strictly conforms to the EcoCampus AI Integration Contract (Section 3).
class EnergyAlert {
  final String id;
  final String roomName;
  final DateTime timestamp;
  final double actualKwh;
  final double expectedKwh;
  final double tariffPerKwh;
  final double co2KgPerKwh;
  final String reason;
  final String status; // "active", "resolved", "dismissed"

  const EnergyAlert({
    required this.id,
    required this.roomName,
    required this.timestamp,
    required this.actualKwh,
    required this.expectedKwh,
    this.tariffPerKwh = 8.0,
    this.co2KgPerKwh = 0.82,
    required this.reason,
    this.status = 'active',
  });

  /// Derived value: excess energy consumption above expected baseline.
  /// Formula: max(0, actualKwh - expectedKwh)
  double get excessKwh => max(0.0, actualKwh - expectedKwh);

  /// Derived value: estimated monetary cost of the wasted energy in Indian Rupees (INR).
  /// Formula: excessKwh * tariffPerKwh
  double get estimatedCost => excessKwh * tariffPerKwh;

  /// Derived value: estimated carbon emissions of the excess energy in kg CO2e.
  /// Formula: excessKwh * co2KgPerKwh
  double get estimatedCo2Kg => excessKwh * co2KgPerKwh;

  /// Returns true if this alert is currently active and requires attention.
  bool get isActive => status.toLowerCase() == 'active';

  /// Returns true if this alert has been resolved.
  bool get isResolved => status.toLowerCase() == 'resolved';

  /// Returns true if this alert was dismissed.
  bool get isDismissed => status.toLowerCase() == 'dismissed';

  /// Creates a copy of this EnergyAlert with the specified fields replaced.
  EnergyAlert copyWith({
    String? id,
    String? roomName,
    DateTime? timestamp,
    double? actualKwh,
    double? expectedKwh,
    double? tariffPerKwh,
    double? co2KgPerKwh,
    String? reason,
    String? status,
  }) {
    return EnergyAlert(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      timestamp: timestamp ?? this.timestamp,
      actualKwh: actualKwh ?? this.actualKwh,
      expectedKwh: expectedKwh ?? this.expectedKwh,
      tariffPerKwh: tariffPerKwh ?? this.tariffPerKwh,
      co2KgPerKwh: co2KgPerKwh ?? this.co2KgPerKwh,
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  /// Serialization to JSON for interoperability with other modules.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomName': roomName,
      'timestamp': timestamp.toIso8601String(),
      'actualKwh': actualKwh,
      'expectedKwh': expectedKwh,
      'tariffPerKwh': tariffPerKwh,
      'co2KgPerKwh': co2KgPerKwh,
      'excessKwh': excessKwh,
      'estimatedCost': estimatedCost,
      'estimatedCo2Kg': estimatedCo2Kg,
      'reason': reason,
      'status': status,
    };
  }

  /// Deserialization from JSON.
  factory EnergyAlert.fromJson(Map<String, dynamic> json) {
    return EnergyAlert(
      id: json['id'] as String,
      roomName: json['roomName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      actualKwh: (json['actualKwh'] as num).toDouble(),
      expectedKwh: (json['expectedKwh'] as num).toDouble(),
      tariffPerKwh: json['tariffPerKwh'] != null
          ? (json['tariffPerKwh'] as num).toDouble()
          : 8.0,
      co2KgPerKwh: json['co2KgPerKwh'] != null
          ? (json['co2KgPerKwh'] as num).toDouble()
          : 0.82,
      reason: json['reason'] as String,
      status: (json['status'] as String?) ?? 'active',
    );
  }

  @override
  String toString() {
    return 'EnergyAlert($id, room: $roomName, excess: ${excessKwh.toStringAsFixed(2)} kWh, '
        'cost: ₹${estimatedCost.toStringAsFixed(2)}, CO2: ${estimatedCo2Kg.toStringAsFixed(2)} kg, status: $status)';
  }
}
