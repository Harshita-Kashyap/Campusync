import 'package:flutter_test/flutter_test.dart';
import 'package:campusync/models/water_incident.dart';
import 'package:campusync/services/app_repository.dart';
import 'package:campusync/services/water_service.dart';

void main() {
  test('negative / zero / non-numeric rate rejected', () {
    expect(WaterService.validateRate('-5'), isNotNull);
    expect(WaterService.validateRate('0'), isNotNull);
    expect(WaterService.validateRate('abc'), isNotNull);
    expect(WaterService.validateRate('6'), isNull);
  });

  test('negative duration rejected, zero allowed', () {
    expect(WaterService.validateDuration('-1'), isNotNull);
    expect(WaterService.validateDuration('0'), isNull);
  });

  test('missing location/description rejected', () {
    expect(WaterService.validateRequired('  ', 'Location'), isNotNull);
    expect(WaterService.validateDescription(''), isNotNull);
  });

  test('submitReport stores open incident with stable id; invalid input throws', () async {
    final repo = AppRepository(emptyEnergy: true);
    final svc = WaterService(repo);
    final i = await svc.submitReport(location: 'Lab tap', issueType: 'leaking_tap', severity: 'low',
        litresPerHour: 5, durationHours: 4, description: 'drip');
    expect(i.status, 'open');
    expect(i.estimatedLitresLost, 20);
    expect(svc.getEstimatedWaterLossLitres(), 20);
    expect(() => svc.submitReport(location: 'x', issueType: 'leaking_tap', severity: 'low',
        litresPerHour: -1, durationHours: 1, description: 'd'), throwsArgumentError);
    await svc.updateIncidentStatus(i.id, 'resolved');
    expect(svc.getEstimatedWaterLossLitres(), 0);
  });

  test('analysis JSON from un-fixed script is normalised; source never faked as AI', () {
    final r = LeakAnalysisResult.fromJson({
      'severity': 'Critical', 'estimatedLitresPerHour': 1500.0,
      'issueType': 'High-Pressure Pipe Coupling Failure', 'description': 'spray'});
    expect(r.severity, 'critical');
    expect(r.issueType, 'pipe_leak');
    expect(r.isAi, isFalse);
    expect(LeakAnalysisResult.fromJson({'source': 'ai', 'estimatedLitresPerHour': 5}).isAi, isTrue);
  });

  test('offline fixture works and is labelled as sample', () async {
    final r = await const FixtureLeakAnalyzer().analyze();
    expect(r.label, contains('sample'));
  });

  test('WaterIncident parses the Flask API contract and preserves source/image URL', () {
    final incident = WaterIncident.fromJson({
      'id': '52ae4a0e-15ce-432b-8ab5-ddab63e8a230',
      'locationName': 'Hostel B washroom',
      'issueType': 'pipe_leak',
      'estimatedLitresPerHour': 1500.0,
      'reportedAt': '2026-10-12T10:00:00Z',
      'estimatedDurationHours': 2.0,
      'severity': 'critical',
      'description': 'Pipe coupling leak',
      'status': 'open',
      'source': 'ai',
      'imageUrl': '/api/water/incidents/52ae4a0e-15ce-432b-8ab5-ddab63e8a230/image',
    });
    expect(incident.estimatedLitresLost, 3000);
    expect(incident.source, 'ai');
    expect(incident.imageUrl, contains('/image'));
    expect(incident.reportedAt.isUtc, isTrue);
  });
}
