import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'format.dart';

/// The required honesty label for demo metrics. One quiet line.
class DemoNote extends StatelessWidget {
  const DemoNote({super.key});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 14, color: context.pal.warning)),
        const SizedBox(width: 6),
        Expanded(child: Text(demoLabel, style: Theme.of(context).textTheme.bodySmall)),
      ]);
}
