import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/room_reading.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

/// A room's live draw against what the timetable says it should be.
class RoomEnergyTile extends StatelessWidget {
  final RoomReading reading;
  final VoidCallback? onTap;
  const RoomEnergyTile({super.key, required this.reading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final r = reading;
    final anomaly = r.hasWastageAnomaly;
    final badge = anomaly
        ? const StatusBadge(label: 'Wasting energy', icon: Icons.bolt, tone: Tone.danger)
        : (r.isScheduledOccupied
            ? const StatusBadge(label: 'In use', icon: Icons.people_outline, tone: Tone.info)
            : const StatusBadge(label: 'Vacant', icon: Icons.door_front_door_outlined, tone: Tone.success));
    final what = r.activeActivity ?? [r.activeClassId, r.activeCourseCode].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    final top = math.max(6.0, math.max(r.actualKwh, r.expectedKwh) * 1.1);

    return AppCard(
      accent: anomaly ? pal.danger : null,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(r.roomType.contains('Lab') ? Icons.computer_outlined : Icons.meeting_room_outlined, size: 20, color: pal.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.roomName, style: t.titleSmall),
              Text(what.isEmpty ? r.roomType : '${r.roomType}, $what', style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          badge,
        ]),
        const SizedBox(height: 14),
        LoadBar(actual: r.actualKwh, expected: r.expectedKwh, max: top, over: anomaly),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Expected ${r.expectedKwh.toStringAsFixed(2)} kWh', style: t.bodySmall),
          Text(
            anomaly ? 'Actual ${r.actualKwh.toStringAsFixed(2)} kWh (+${r.excessKwh.toStringAsFixed(2)})' : 'Actual ${r.actualKwh.toStringAsFixed(2)} kWh',
            style: t.bodySmall?.copyWith(color: anomaly ? pal.danger : pal.muted, fontWeight: FontWeight.w700),
          ),
        ]),
      ]),
    );
  }
}
