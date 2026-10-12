import 'package:flutter/material.dart';
import '../../../models/room_reading.dart';

/// Lightweight, self-contained comparative chart showing Actual vs Expected
/// energy draw across monitored campus spaces.
/// Pure Flutter CustomPainter implementation requiring zero external packages.
class EnergyQuickChart extends StatelessWidget {
  final List<RoomReading> readings;

  const EnergyQuickChart({
    super.key,
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Energy Audit: Actual vs Baseline',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              // Legend
              Row(
                children: [
                  _LegendDot(color: Colors.grey.shade400, label: 'Baseline'),
                  const SizedBox(width: 12),
                  const _LegendDot(color: Color(0xFF2E7D32), label: 'Normal'),
                  const SizedBox(width: 12),
                  const _LegendDot(color: Color(0xFFD32F2F), label: 'Anomaly'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: readings.isEmpty
                ? const Center(child: Text('No telemetry available'))
                : CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _EnergyChartPainter(
                      readings: readings,
                      isDark: theme.brightness == Brightness.dark,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Showing 10 Monitored Campus Zones (Classrooms & Shared Labs)',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _EnergyChartPainter extends CustomPainter {
  final List<RoomReading> readings;
  final bool isDark;

  _EnergyChartPainter({required this.readings, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    final double maxVal = 5.5; // Max scale in kWh
    final double bottomPadding = 24.0;
    final double chartHeight = size.height - bottomPadding;
    final double groupWidth = size.width / readings.length;
    final double barWidth = (groupWidth * 0.35).clamp(4.0, 14.0);

    // Draw baseline grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white12 : Colors.black12)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      final y = chartHeight - (chartHeight * (i / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < readings.length; i++) {
      final reading = readings[i];
      final centerX = (i * groupWidth) + (groupWidth / 2);

      // Expected bar (left)
      final expectedY = chartHeight - (chartHeight * (reading.expectedKwh / maxVal).clamp(0.0, 1.0));
      final expectedRect = Rect.fromLTWH(
        centerX - barWidth - 1,
        expectedY,
        barWidth,
        chartHeight - expectedY,
      );
      final expectedPaint = Paint()..color = Colors.grey.shade400;
      canvas.drawRRect(
        RRect.fromRectAndRadius(expectedRect, const Radius.circular(2)),
        expectedPaint,
      );

      // Actual bar (right)
      final actualY = chartHeight - (chartHeight * (reading.actualKwh / maxVal).clamp(0.0, 1.0));
      final actualRect = Rect.fromLTWH(
        centerX + 1,
        actualY,
        barWidth,
        chartHeight - actualY,
      );
      final actualColor = reading.hasWastageAnomaly
          ? const Color(0xFFD32F2F)
          : const Color(0xFF2E7D32);
      final actualPaint = Paint()..color = actualColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(actualRect, const Radius.circular(2)),
        actualPaint,
      );

      // Room label below chart
      final roomShort = reading.roomName.replaceAll('CSE-', '').replaceAll(' Lab', '');
      final textSpan = TextSpan(text: roomShort, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyChartPainter oldDelegate) {
    return oldDelegate.readings != readings || oldDelegate.isDark != isDark;
  }
}
