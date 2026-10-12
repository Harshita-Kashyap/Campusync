import '../models/models.dart';

/// Offline demo data. Modules may replace with their own fixtures via the repository.
class SeedData {
  static List<WaterIncident> water() {
    final now = DateTime.now();
    return [
      WaterIncident(id: 'WA-001', locationName: 'Hostel B washroom', issueType: 'leaking_tap',
          estimatedLitresPerHour: 6, reportedAt: now.subtract(const Duration(hours: 10)),
          estimatedDurationHours: 10, severity: 'medium', description: 'Dripping tap', status: 'open'),
      WaterIncident(id: 'WA-002', locationName: 'Main block overhead tank', issueType: 'overflow',
          estimatedLitresPerHour: 120, reportedAt: now.subtract(const Duration(hours: 4)),
          estimatedDurationHours: 4, severity: 'high', description: 'Tank overflowing', status: 'in_progress'),
    ];
  }

  static List<DigitalSubmission> submissions() => [
        DigitalSubmission(id: 'ECO-SUB-0001', studentId: 'S101', assignmentId: 'CS-A1',
            fileName: 'assignment1.pdf', sha256: 'demo-hash-0001', submittedAt: DateTime.now().subtract(const Duration(days: 1)),
            score: 8, maxScore: 10, gradingFeedback: 'Good structure.', pagesAvoidedEstimate: 12, duplicateDetected: false),
        DigitalSubmission(id: 'ECO-SUB-0002', studentId: 'S102', assignmentId: 'CS-A1',
            fileName: 'report.pdf', sha256: 'demo-hash-0002', submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
            score: 7, maxScore: 10, gradingFeedback: 'Needs more detail.', pagesAvoidedEstimate: 8, duplicateDetected: false),
      ];
}
