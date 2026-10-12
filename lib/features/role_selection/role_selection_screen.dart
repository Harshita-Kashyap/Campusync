import 'package:flutter/material.dart';
import '../../app.dart';
import '../../shared/theme/app_colors.dart';

/// Demo navigation only — NOT production security.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Spacer(),
              const Icon(Icons.eco, size: 40, color: AppColors.leaf),
              const SizedBox(height: 8),
              Text('Campusync', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.forest, fontWeight: FontWeight.w800)),
              const Text('Small campus actions. Measurable environmental change.', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              Text('Notice waste. Take action. See the difference.', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, Routes.student),
                  icon: const Icon(Icons.school_outlined), label: const Text('Student view')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, Routes.admin),
                  icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Admin view')),
              const SizedBox(height: 16),
              const Text('Sample campus data · $demoLabelShort', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
        ),
      );
}

const demoLabelShort = 'role switch is for demo only';
