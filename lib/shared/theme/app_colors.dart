import 'package:flutter/material.dart';

/// Brand constants. In widgets use `context.pal` so colours follow light/dark mode.
class AppColors {
  AppColors._();
  static const forest = Color(0xFF183F35);
  static const leaf = Color(0xFF79A875);
  static const lime = Color(0xFFD5E7A3);
}

/// Semantic roles. Status is always text + icon; tone only reinforces it.
enum Tone { brand, success, warning, danger, info, neutral }

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas, required this.surface, required this.surfaceHigh, required this.line,
    required this.ink, required this.muted, required this.brand, required this.onBrand,
    required this.brandSoft, required this.hero, required this.onHero, required this.heroAccent,
    required this.success, required this.warning, required this.danger, required this.info,
  });

  final Color canvas, surface, surfaceHigh, line, ink, muted;
  final Color brand, onBrand, brandSoft;
  final Color hero, onHero, heroAccent;
  final Color success, warning, danger, info;

  Color of(Tone t) => switch (t) {
        Tone.brand => brand, Tone.success => success, Tone.warning => warning,
        Tone.danger => danger, Tone.info => info, Tone.neutral => muted,
      };

  static const light = AppPalette(
    canvas: Color(0xFFF3F5EF), surface: Color(0xFFFFFFFF), surfaceHigh: Color(0xFFEAEFE5),
    line: Color(0xFFDCE3D6), ink: Color(0xFF16221D), muted: Color(0xFF5B685F),
    brand: Color(0xFF183F35), onBrand: Color(0xFFFFFFFF), brandSoft: Color(0xFFD5E7A3),
    hero: Color(0xFF183F35), onHero: Color(0xFFF1F6EC), heroAccent: Color(0xFFD5E7A3),
    success: Color(0xFF2D7A4D), warning: Color(0xFF8F6209), danger: Color(0xFFB3402B), info: Color(0xFF2A6A8E),
  );

  static const dark = AppPalette(
    canvas: Color(0xFF0D1411), surface: Color(0xFF151F1A), surfaceHigh: Color(0xFF1D2A23),
    line: Color(0xFF2A3A32), ink: Color(0xFFE6EEE8), muted: Color(0xFF9BACA2),
    brand: Color(0xFFA9D18E), onBrand: Color(0xFF10291F), brandSoft: Color(0xFF27432F),
    hero: Color(0xFF1E3A2E), onHero: Color(0xFFE6EEE8), heroAccent: Color(0xFFB9DB9C),
    success: Color(0xFF7CC697), warning: Color(0xFFE2B25A), danger: Color(0xFFF08B74), info: Color(0xFF7DB6DA),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      canvas: l(canvas, other.canvas), surface: l(surface, other.surface), surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      line: l(line, other.line), ink: l(ink, other.ink), muted: l(muted, other.muted),
      brand: l(brand, other.brand), onBrand: l(onBrand, other.onBrand), brandSoft: l(brandSoft, other.brandSoft),
      hero: l(hero, other.hero), onHero: l(onHero, other.onHero), heroAccent: l(heroAccent, other.heroAccent),
      success: l(success, other.success), warning: l(warning, other.warning),
      danger: l(danger, other.danger), info: l(info, other.info),
    );
  }
}

extension PaletteX on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
