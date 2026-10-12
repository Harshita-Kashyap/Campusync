import 'package:flutter/material.dart';
import '../../../models/room_reading.dart';

/// Card showing live sub-meter readings for a classroom or laboratory,
/// comparing actual draw to the timetable-derived baseline.
class RoomEnergyTile extends StatelessWidget {
  final RoomReading reading;
  final VoidCallback? onTap;

  const RoomEnergyTile({
    super.key,
    required this.reading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnomaly = reading.hasWastageAnomaly;

    final badgeColor = isAnomaly
        ? const Color(0xFFD32F2F)
        : (reading.isScheduledOccupied
            ? const Color(0xFF1976D2)
            : const Color(0xFF388E3C));

    final badgeLabel = isAnomaly
        ? 'WASTAGE DETECTED'
        : (reading.isScheduledOccupied ? 'OCCUPIED' : 'STANDBY (VACANT)');

    // Relative load bar (normalize up to 6.0 kWh max scale)
    final double maxScale = 6.0;
    final double actualFraction = (reading.actualKwh / maxScale).clamp(0.0, 1.0);
    final double expectedFraction = (reading.expectedKwh / maxScale).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isAnomaly
              ? const Color(0xFFD32F2F).withAlpha(120)
              : theme.colorScheme.outlineVariant.withAlpha(60),
          width: isAnomaly ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: Room name & occupancy badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        reading.roomType.contains('Lab')
                            ? Icons.computer_rounded
                            : Icons.meeting_room_rounded,
                        size: 20,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reading.roomName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${reading.roomType})',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withAlpha(80)),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Timetable schedule status
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reading.activeActivity ??
                          '${reading.activeClassId ?? ""} • ${reading.activeCourseCode ?? ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAnomaly
                            ? const Color(0xFFD32F2F)
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isAnomaly ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Visual Load Comparison Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Actual: ${reading.actualKwh.toStringAsFixed(2)} kWh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isAnomaly ? const Color(0xFFD32F2F) : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Baseline Expected: ${reading.expectedKwh.toStringAsFixed(2)} kWh',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      // Background track
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Expected marker (gray/green line)
                      FractionallySizedBox(
                        widthFactor: expectedFraction,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Actual draw fill
                      FractionallySizedBox(
                        widthFactor: actualFraction,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: isAnomaly
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFF388E3C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Sub-meter Electrical Telemetry metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⚡ ${reading.voltage.toStringAsFixed(1)} V  |  ${reading.currentAmps.toStringAsFixed(1)} A  |  PF: ${reading.powerFactor.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (isAnomaly)
                    Text(
                      'Leak: +${reading.excessKwh.toStringAsFixed(2)} kWh',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
