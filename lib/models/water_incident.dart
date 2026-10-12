class WaterIncident {
  final String id;
  final String locationName;
  final String issueType; // "leaking_tap", "overflow", "pipe_leak", "other"
  final double estimatedLitresPerHour;
  final DateTime reportedAt;
  final double estimatedDurationHours;
  final String severity; // "low", "medium", "high", "critical"
  final String description;
  final String status; // "open", "in_progress", "resolved", "dismissed"
  final double? latitude;
  final double? longitude;

  const WaterIncident({
    required this.id,
    required this.locationName,
    required this.issueType,
    required this.estimatedLitresPerHour,
    required this.reportedAt,
    required this.estimatedDurationHours,
    required this.severity,
    required this.description,
    required this.status,
    this.latitude,
    this.longitude,
  });

  double get estimatedLitresLost => estimatedLitresPerHour * estimatedDurationHours;

  WaterIncident copyWith({String? status}) => WaterIncident(
        id: id, locationName: locationName, issueType: issueType,
        estimatedLitresPerHour: estimatedLitresPerHour, reportedAt: reportedAt,
        estimatedDurationHours: estimatedDurationHours, severity: severity,
        description: description, status: status ?? this.status,
        latitude: latitude, longitude: longitude,
      );
}
