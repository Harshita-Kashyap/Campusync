import 'package:flutter_test/flutter_test.dart';
import 'package:campusync/app.dart';
import 'package:campusync/services/app_repository.dart';
import 'package:campusync/services/impact_service.dart';

void main() {
  test('resolving a water incident drops current loss but keeps history', () async {
    final repo = AppRepository.seeded();
    final before = ImpactService.compute(repo).waterActiveLossLitres;
    await repo.updateIncidentStatus('WA-002', 'resolved');
    final m = ImpactService.compute(repo);
    expect(m.waterActiveLossLitres, lessThan(before));
    expect(m.waterHistoricalLossLitres, greaterThan(m.waterActiveLossLitres));
  });

  test('invalid status is rejected', () {
    final repo = AppRepository.seeded();
    expect(repo.updateIncidentStatus('WA-001', 'bogus'), throwsArgumentError);
  });

  test('empty repository gives zero metrics and empty queue', () {
    final m = ImpactService.compute(AppRepository());
    expect(m.excessKwh, 0);
    expect(m.queue, isEmpty);
  });

  testWidgets('welcome -> admin overview', (tester) async {
    await tester.pumpWidget(const CampusyncApp());
    await tester.tap(find.text('Admin view'));
    await tester.pumpAndSettle();
    expect(find.text('Campus overview'), findsWidgets);
  });
}