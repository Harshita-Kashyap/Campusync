import 'package:flutter/material.dart';

/// Light / dark / system choice. In memory only.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.value = ThemeMode.system]);
  void toggle(Brightness current) =>
      value = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({super.key, required ThemeController controller, required super.child})
      : super(notifier: controller);
  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
}
