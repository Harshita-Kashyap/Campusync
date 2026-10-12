import 'package:flutter/material.dart';
import '../../app.dart';

class RoleSwitchButton extends StatelessWidget {
  const RoleSwitchButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Switch demo role',
        icon: const Icon(Icons.swap_horiz),
        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (_) => false),
      );
}
