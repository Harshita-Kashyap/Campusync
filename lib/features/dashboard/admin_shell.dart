import 'package:flutter/material.dart';
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
        body: IndexedStack(index: _i, children: [
          AdminOverviewScreen(onOpenTab: (t) => setState(() => _i = t)),
          const EnergyScreen(),
          const WaterScreen(),
          const SubmissionsScreen(),
          const ActivityScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
            NavigationDestination(icon: Icon(Icons.bolt), label: 'Energy'),
            NavigationDestination(icon: Icon(Icons.water_drop_outlined), label: 'Water'),
            NavigationDestination(icon: Icon(Icons.upload_file), label: 'Submissions'),
            NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
          ],
        ),
      );
}
