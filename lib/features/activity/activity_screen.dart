import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../dashboard/role_switch_button.dart';

/// Admin: chronological log of record creation and status changes.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = RepositoryScope.of(context).getActivityLog();
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Activity'), actions: const [ThemeToggleButton(), RoleSwitchButton(), SizedBox(width: 4)]),
      body: SafeArea(
        child: log.isEmpty
            ? const EmptyState(title: 'No activity yet', message: 'Status changes and new reports will appear here.', icon: Icons.history)
            : PageBody(children: [
                for (var i = 0; i < log.length; i++)
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      SizedBox(
                        width: 20,
                        child: Column(children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: i == 0 ? pal.brand : pal.line, shape: BoxShape.circle),
                          ),
                          if (i < log.length - 1) Expanded(child: Container(width: 2, color: pal.line)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(log[i].message, style: t.bodyLarge),
                            Text(timeAgo(log[i].time), style: t.bodySmall),
                          ]),
                        ),
                      ),
                    ]),
                  ),
              ]),
      ),
    );
  }
}
