/// Model representing an energy telemetry reading from a room or laboratory.
class RoomReading {
  final String roomId;
  final String roomName;
  final String roomType; // "Classroom", "Computer Lab", "Hardware Lab", "Faculty Cabin"
  final String block; // "Main Block", "R&D Block", etc.
  final DateTime timestamp;
  final double actualKwh;
  final double expectedKwh;
  final bool isScheduledOccupied;
  final String? activeClassId;
  final String? activeCourseCode;
  final String? activeFaculty;
  final String? activeActivity;
  final double voltage; // e.g. 230.0 V
  final double currentAmps; // e.g. 10.5 A
  final double powerFactor; // e.g. 0.95

  const RoomReading({
    required this.roomId,
    required this.roomName,
    required this.roomType,
    this.block = 'Main Block',
    required this.timestamp,
    required this.actualKwh,
    required this.expectedKwh,
    required this.isScheduledOccupied,
    this.activeClassId,
    this.activeCourseCode,
    this.activeFaculty,
    this.activeActivity,
    this.voltage = 230.0,
    this.currentAmps = 8.5,
    this.powerFactor = 0.95,
  });

  /// Computed instantaneous excess kWh over expected baseline.
  double get excessKwh => actualKwh > expectedKwh ? (actualKwh - expectedKwh) : 0.0;

  /// Returns true if this room's actual energy draw significantly exceeds expectations.
  bool get hasWastageAnomaly => actualKwh > (expectedKwh + 0.3) && excessKwh > 0.4;

  /// Efficiency ratio (actual / expected). Ideal is ~ 1.0.
  double get efficiencyRatio => expectedKwh > 0 ? (actualKwh / expectedKwh) : 1.0;

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'roomType': roomType,
      'block': block,
      'timestamp': timestamp.toIso8601String(),
      'actualKwh': actualKwh,
      'expectedKwh': expectedKwh,
      'excessKwh': excessKwh,
      'isScheduledOccupied': isScheduledOccupied,
      'activeClassId': activeClassId,
      'activeCourseCode': activeCourseCode,
      'activeFaculty': activeFaculty,
      'activeActivity': activeActivity,
      'voltage': voltage,
      'currentAmps': currentAmps,
      'powerFactor': powerFactor,
      'hasWastageAnomaly': hasWastageAnomaly,
    };
  }
}
