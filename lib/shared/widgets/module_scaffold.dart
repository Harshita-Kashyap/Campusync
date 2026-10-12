import 'package:flutter/material.dart';

/// Standard wrapper for module screens: AppBar with automatic back button.
class ModuleScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? fab;
  const ModuleScaffold({super.key, required this.title, required this.body, this.fab});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(child: body),
        floatingActionButton: fab,
      );
}
