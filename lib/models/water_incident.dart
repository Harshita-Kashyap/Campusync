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
  /// Provenance returned by the Flask API: ai | fallback | manual | sample.
  final String source;
  /// Relative Flask URL for the uploaded image, when a report includes one.
  final String? imageUrl;

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
    this.source = 'manual',
    this.imageUrl,
  });

  double get estimatedLitresLost => estimatedLitresPerHour * estimatedDurationHours;

  factory WaterIncident.fromJson(Map<String, dynamic> json) {
    double asDouble(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final rawDate = json['reportedAt'] ?? json['reported_at'];
    final parsedDate = DateTime.tryParse(rawDate?.toString() ?? '');
    return WaterIncident(
      id: (json['id'] ?? '').toString(),
      locationName: (json['locationName'] ?? json['location_name'] ?? '').toString(),
      issueType: (json['issueType'] ?? json['issue_type'] ?? 'other').toString().toLowerCase(),
      estimatedLitresPerHour: asDouble(json['estimatedLitresPerHour'] ?? json['estimated_litres_per_hour']),
      reportedAt: parsedDate ?? DateTime.now(),
      estimatedDurationHours: asDouble(json['estimatedDurationHours'] ?? json['estimated_duration_hours']),
      severity: (json['severity'] ?? 'low').toString().toLowerCase(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString().toLowerCase(),
      latitude: json['latitude'] == null ? null : asDouble(json['latitude']),
      longitude: json['longitude'] == null ? null : asDouble(json['longitude']),
      source: (json['source'] ?? json['analysisSource'] ?? json['analysis_source'] ?? 'manual').toString().toLowerCase(),
      imageUrl: (json['imageUrl'] ?? json['image_url'])?.toString(),
    );
  }

  WaterIncident copyWith({String? status}) => WaterIncident(
        id: id,
        locationName: locationName,
        issueType: issueType,
        estimatedLitresPerHour: estimatedLitresPerHour,
        reportedAt: reportedAt,
        estimatedDurationHours: estimatedDurationHours,
        severity: severity,
        description: description,
        status: status ?? this.status,
        latitude: latitude,
        longitude: longitude,
        source: source,
        imageUrl: imageUrl,
      );
}
