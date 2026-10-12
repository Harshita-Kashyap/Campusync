import 'package:flutter/material.dart';
import 'services/app_repository.dart';
import 'shared/theme/app_theme.dart';
import 'features/role_selection/role_selection_screen.dart';
import 'features/dashboard/admin_shell.dart';
import 'features/dashboard/student_shell.dart';

class Routes {
  static const welcome = '/';
  static const admin = '/admin';
  static const student = '/student';
}

class CampusyncApp extends StatefulWidget {
  const CampusyncApp({super.key});
  @override
  State<CampusyncApp> createState() => _CampusyncAppState();
}

class _CampusyncAppState extends State<CampusyncApp> {
  final AppRepository _repo = AppRepository.seeded();

  @override
  Widget build(BuildContext context) => RepositoryScope(
        repository: _repo,
        child: MaterialApp(
          title: 'Campusync',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: Routes.welcome,
          routes: {
            Routes.welcome: (_) => const RoleSelectionScreen(),
            Routes.admin: (_) => const AdminShell(),
            Routes.student: (_) => const StudentShell(),
          },
        ),
      );
}
