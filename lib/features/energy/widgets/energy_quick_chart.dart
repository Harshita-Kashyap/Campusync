import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/room_reading.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

/// Expected vs actual draw per room. Pure CustomPainter; bars grow in once.
class EnergyQuickChart extends StatelessWidget {
  final List<RoomReading> readings;
  const EnergyQuickChart({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final flagged = readings.where((r) => r.hasWastageAnomaly).length;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Actual vs expected draw', style: t.titleSmall),
        const SizedBox(height: 10),
        Wrap(spacing: 14, runSpacing: 6, children: [
          _Dot(color: pal.muted.withValues(alpha: 0.45), label: 'Expected'),
          _Dot(color: pal.success, label: 'Actual, normal'),
          _Dot(color: pal.danger, label: 'Actual, above baseline'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          width: double.infinity,
          child: readings.isEmpty
              ? const Center(child: Text('No telemetry available'))
              : Semantics(
                  label: 'Bar chart of ${readings.length} rooms, $flagged above baseline',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, p, __) => CustomPaint(
                      painter: _ChartPainter(
                        readings: readings, progress: p, expected: pal.muted.withValues(alpha: 0.45),
                        normal: pal.success, anomaly: pal.danger, grid: pal.line, label: pal.muted,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text('${readings.length} monitored rooms, simulated sub-meter readings', style: t.bodySmall),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class _ChartPainter extends CustomPainter {
  final List<RoomReading> readings;
  final double progress;
  final Color expected, normal, anomaly, grid, label;
  const _ChartPainter({required this.readings, required this.progress, required this.expected,
      required this.normal, required this.anomaly, required this.grid, required this.label});

  void _text(Canvas canvas, String s, Offset at, {double width = 60, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: label, fontSize: 9, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…',
    )..layout(maxWidth: width);
    tp.paint(canvas, Offset(center ? at.dx - tp.width / 2 : at.dx, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;
    final peak = readings.fold<double>(0, (m, r) => math.max(m, math.max(r.actualKwh, r.expectedKwh)));
    final maxVal = math.max(5.5, peak * 1.1);
    const left = 26.0, bottomPad = 22.0;
    final chartH = size.height - bottomPad;
    final group = (size.width - left) / readings.length;
    final barW = (group * 0.34).clamp(4.0, 14.0);
    final gridPaint = Paint()..color = grid..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = chartH - chartH * (i / 4);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      _text(canvas, (maxVal * i / 4).toStringAsFixed(0), Offset(0, y - 5), width: left - 4);
    }
    for (var i = 0; i < readings.length; i++) {
      final r = readings[i];
      final cx = left + i * group + group / 2;
      double h(double v) => chartH * (v / maxVal).clamp(0.0, 1.0) * progress;
      final eH = h(r.expectedKwh);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW - 1, chartH - eH, barW, eH), const Radius.circular(3)), Paint()..color = expected);
      final aH = h(r.actualKwh);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 1, chartH - aH, barW, aH), const Radius.circular(3)),
          Paint()..color = r.hasWastageAnomaly ? anomaly : normal);
      _text(canvas, r.roomName.replaceAll('CSE-', '').replaceAll(' Lab', ''), Offset(cx, size.height - 16), width: group, center: true);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter o) =>
      o.progress != progress || o.readings != readings || o.expected != expected || o.normal != normal ||
      o.anomaly != anomaly || o.grid != grid || o.label != label;
}
