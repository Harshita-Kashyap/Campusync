import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();
  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static OutlineInputBorder _outline(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

  static ThemeData _build(Brightness b, AppPalette p) {
    final base = ThemeData(brightness: b, useMaterial3: true);
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.forest, brightness: b).copyWith(
      primary: p.brand, onPrimary: p.onBrand, secondary: AppColors.leaf,
      surface: p.surface, onSurface: p.ink, onSurfaceVariant: p.muted, error: p.danger,
      outline: p.muted, outlineVariant: p.line,
      primaryContainer: p.brandSoft, onPrimaryContainer: p.ink,
      secondaryContainer: p.brandSoft, onSecondaryContainer: p.ink,
      surfaceContainerLowest: p.canvas, surfaceContainerLow: p.surface, surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceHigh, surfaceContainerHighest: p.surfaceHigh,
      inverseSurface: p.ink, onInverseSurface: p.canvas,
    );
    final t = base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink);
    final text = t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.08),
      headlineMedium: t.headlineMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.15),
      headlineSmall: t.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2),
      titleLarge: t.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: t.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: t.titleSmall?.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: t.bodySmall?.copyWith(fontSize: 12.5, height: 1.35, color: p.muted),
      labelLarge: t.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: t.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: p.muted),
    );
    final btnShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return ThemeData(
      useMaterial3: true, brightness: b, colorScheme: scheme, scaffoldBackgroundColor: p.canvas,
      textTheme: text, extensions: <ThemeExtension<dynamic>>[p],
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        for (final plat in TargetPlatform.values) plat: const ZoomPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas, foregroundColor: p.ink, elevation: 0, scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent, centerTitle: false, titleTextStyle: text.titleLarge,
        systemOverlayStyle: b == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: p.surface, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.line)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 52), shape: btnShape, textStyle: text.labelLarge)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52), foregroundColor: p.ink,
            side: BorderSide(color: p.line), shape: btnShape, textStyle: text.labelLarge)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.brand,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: text.labelLarge)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _outline(p.line), enabledBorder: _outline(p.line), focusedBorder: _outline(p.brand, 2),
        errorBorder: _outline(p.danger), focusedErrorBorder: _outline(p.danger, 2),
        labelStyle: TextStyle(color: p.muted), helperStyle: TextStyle(color: p.muted, fontSize: 12),
        errorStyle: TextStyle(color: p.danger, fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface, selectedColor: p.brandSoft, side: BorderSide(color: p.line),
        shape: const StadiumBorder(), showCheckmark: false,
        labelStyle: text.labelLarge?.copyWith(color: p.ink),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: p.ink),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.brandSoft : p.surface),
          foregroundColor: WidgetStatePropertyAll(p.ink),
          side: WidgetStatePropertyAll(BorderSide(color: p.line)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface, surfaceTintColor: Colors.transparent, shadowColor: Colors.transparent,
        elevation: 0, height: 68, indicatorColor: p.brandSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return text.labelMedium?.copyWith(color: sel ? p.ink : p.muted, fontWeight: sel ? FontWeight.w700 : FontWeight.w500);
        }),
        iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? p.ink : p.muted)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface, modalBackgroundColor: p.surface, surfaceTintColor: Colors.transparent,
        showDragHandle: true, dragHandleColor: p.line, clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating, backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.canvas, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brand, linearTrackColor: p.surfaceHigh),
    );
  }
}
