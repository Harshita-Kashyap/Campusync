class DigitalSubmission {
  final String id; // e.g. ECO-SUB-0001
  final String studentId;
  final String assignmentId;
  final String fileName;
  final String sha256;
  final DateTime submittedAt;
  final double score;
  final double maxScore;
  final String gradingFeedback;
  final int pagesAvoidedEstimate;
  final bool duplicateDetected;

  const DigitalSubmission({
    required this.id,
    required this.studentId,
    required this.assignmentId,
    required this.fileName,
    required this.sha256,
    required this.submittedAt,
    required this.score,
    required this.maxScore,
    required this.gradingFeedback,
    required this.pagesAvoidedEstimate,
    required this.duplicateDetected,
  });
}
