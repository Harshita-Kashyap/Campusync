import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../shared/widgets/widgets.dart';

/// PLACEHOLDER — Person 3 replaces this (list/filter/detail/status). Keep class name `WaterScreen`.
class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final items = RepositoryScope.of(context).getIncidents();
    return ModuleScaffold(
      title: 'Water',
      body: items.isEmpty
          ? const EmptyState(title: 'No incidents')
          : ListView(children: [
              for (final i in items)
                ListTile(title: Text(i.locationName), subtitle: Text('${i.severity} · ~${i.estimatedLitresLost.toStringAsFixed(0)} L (est.)'), trailing: StatusBadge.status(i.status)),
            ]),
    );
  }
}
