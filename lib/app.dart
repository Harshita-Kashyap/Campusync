import 'package:flutter/material.dart';
import 'services/app_repository.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_controller.dart';
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
  final ThemeController _theme = ThemeController(); // follows the device until the user toggles

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  Route<void> _route(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      Routes.student => const StudentShell(),
      Routes.admin => const AdminShell(),
      _ => const RoleSelectionScreen(),
    };
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
    );
  }

  @override
  Widget build(BuildContext context) => RepositoryScope(
        repository: _repo,
        child: ThemeScope(
          controller: _theme,
          child: ListenableBuilder(
            listenable: _theme,
            builder: (context, _) => MaterialApp(
              title: 'Campusync',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: _theme.value,
              themeAnimationDuration: const Duration(milliseconds: 350),
              themeAnimationCurve: Curves.easeOutCubic,
              initialRoute: Routes.welcome,
              onGenerateRoute: _route,
            ),
          ),
        ),
      );
}
