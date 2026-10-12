import 'package:flutter/material.dart';

/// Standard wrapper for module screens.
class ModuleScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;
  const ModuleScaffold({super.key, required this.title, required this.body, this.fab, this.actions});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: SafeArea(child: body),
        floatingActionButton: fab,
      );
}
