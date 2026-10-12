import 'dart:math';

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
    required this.tariffPerKwh,
    required this.co2KgPerKwh,
    required this.reason,
    required this.status,
  });

  double get excessKwh => max(0, actualKwh - expectedKwh);
  double get estimatedCost => excessKwh * tariffPerKwh;
  double get estimatedCo2Kg => excessKwh * co2KgPerKwh;

  EnergyAlert copyWith({String? status}) => EnergyAlert(
        id: id, roomName: roomName, timestamp: timestamp, actualKwh: actualKwh,
        expectedKwh: expectedKwh, tariffPerKwh: tariffPerKwh, co2KgPerKwh: co2KgPerKwh,
        reason: reason, status: status ?? this.status,
      );
}
