import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../shared/widgets/widgets.dart';

/// PLACEHOLDER — Person 3 replaces this with the validated report form.
/// Keep class name `ReportWaterScreen`; submit via repo.addIncident().
class ReportWaterScreen extends StatelessWidget {
  const ReportWaterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return ModuleScaffold(
      title: 'Report a water issue',
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final m = ScaffoldMessenger.of(context);
            await repo.addIncident(WaterIncident(
                id: 'WA-${DateTime.now().millisecondsSinceEpoch}', locationName: 'Demo: Library tap',
                issueType: 'leaking_tap', estimatedLitresPerHour: 5, reportedAt: DateTime.now(),
                estimatedDurationHours: 6, severity: 'medium', description: 'Demo leaking tap', status: 'open'));
            m.showSnackBar(const SnackBar(content: Text('Demo report submitted')));
          },
          child: const Text('Submit demo report (form coming from Person 3)'),
        ),
      ),
    );
  }
}
