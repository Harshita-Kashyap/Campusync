import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.forest, surface: AppColors.surface)
        .copyWith(primary: AppColors.forest, secondary: AppColors.leaf, error: AppColors.coral);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: ThemeData.light().textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.forest, foregroundColor: Colors.white, centerTitle: false),
      cardTheme: CardThemeData(
        color: AppColors.surface, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.line)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.surface, indicatorColor: AppColors.lime),
    );
  }
}
