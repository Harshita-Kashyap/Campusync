import 'package:flutter/material.dart';
import 'format.dart';

IconData _icon(String s) => switch (s) {
      'open' || 'active' => Icons.replay,
      'in_progress' => Icons.autorenew,
      'resolved' => Icons.check_circle_outline,
      _ => Icons.block,
    };

/// "Update status" buttons used in every detail sheet.
class StatusActions extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onPick;
  const StatusActions({super.key, required this.options, required this.onPick});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Update status', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in options)
            FilledButton.tonalIcon(
              onPressed: () => onPick(s),
              icon: Icon(_icon(s), size: 18),
              label: Text(prettyStatus(s)),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
        ]),
      ]);
}
