import 'package:flutter_test/flutter_test.dart';
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
    expect(r.label, contains('Sample'));
  });
}
