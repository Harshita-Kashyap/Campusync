import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../activity/activity_screen.dart';
import '../energy/energy_screen.dart';
import '../submissions/submissions_screen.dart';
import '../water/water_screen.dart';
import 'admin_overview_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FadeIndexedStack(index: _i, children: [
          AdminOverviewScreen(onOpenTab: (t) => setState(() => _i = t)),
          const EnergyScreen(),
          WaterScreen(isActive: _i == 2),
          const SubmissionsScreen(),
          const ActivityScreen(),
        ]),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.pal.line))),
          child: NavigationBar(
            selectedIndex: _i,
            onDestinationSelected: (v) => setState(() => _i = v),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
              NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Energy'),
              NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop), label: 'Water'),
              NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Submissions'),
              NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'Activity'),
            ],
          ),
        ),
      );
}
