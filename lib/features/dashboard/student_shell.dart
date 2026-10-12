import 'package:flutter/material.dart';
import '../activity/my_activity_screen.dart';
import '../impact/impact_screen.dart';
import '../water/report_water_screen.dart';
import 'student_home_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _i, children: [
          StudentHomeScreen(onOpenTab: (t) => setState(() => _i = t)),
          const ReportWaterScreen(),
          const MyActivityScreen(),
          const ImpactScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Report'),
            NavigationDestination(icon: Icon(Icons.list_alt), label: 'My activity'),
            NavigationDestination(icon: Icon(Icons.insights), label: 'Impact'),
          ],
        ),
      );
}
