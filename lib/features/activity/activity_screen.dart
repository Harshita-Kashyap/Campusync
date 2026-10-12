import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../shared/widgets/widgets.dart';
import '../dashboard/role_switch_button.dart';

/// Admin: chronological log of record creation and status changes.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final log = RepositoryScope.of(context).getActivityLog();
    return Scaffold(
      appBar: AppBar(title: const Text('Activity'), actions: const [RoleSwitchButton()]),
      body: SafeArea(
        child: log.isEmpty
            ? const EmptyState(title: 'No activity yet', message: 'Status changes and new reports will appear here.', icon: Icons.history)
            : ListView(children: [
                for (final e in log) ListTile(leading: const Icon(Icons.fiber_manual_record, size: 12), title: Text(e.message), subtitle: Text(timeAgo(e.time))),
              ]),
      ),
    );
  }
}
