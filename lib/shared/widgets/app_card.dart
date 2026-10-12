import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The one card style used everywhere: flat surface, hairline border, optional tap and accent.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.accent});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Material(
      color: pal.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent?.withValues(alpha: 0.5) ?? pal.line, width: accent == null ? 1 : 1.5),
      ),
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}
