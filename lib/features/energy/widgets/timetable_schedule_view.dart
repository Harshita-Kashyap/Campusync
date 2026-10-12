import 'package:flutter/material.dart';
import '../../../models/timetable_schedule.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

/// Browse a class's weekly timetable. Shows why expected energy draw changes:
/// when a class is away in a lab, its home room is expected to be vacant.
class TimetableScheduleView extends StatefulWidget {
  final List<TimetableClass> classes;
  const TimetableScheduleView({super.key, required this.classes});
  @override
  State<TimetableScheduleView> createState() => _TimetableScheduleViewState();
}

class _TimetableScheduleViewState extends State<TimetableScheduleView> {
  late String _classId;
  String _day = 'Tuesday';
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _classId = widget.classes.isNotEmpty ? widget.classes.first.id : '';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.classes.isEmpty) {
      return const AppCard(child: EmptyState(title: 'No timetables loaded', icon: Icons.calendar_month_outlined));
    }
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final cls = widget.classes.firstWhere((c) => c.id == _classId, orElse: () => widget.classes.first);
    final entries = cls.weeklySchedule[_day] ?? const <TimetableEntry>[];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final c in widget.classes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text('${c.className} (${c.roomNo})'), selected: c.id == _classId, onSelected: (_) => setState(() => _classId = c.id)),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${cls.className}, ${cls.program}', style: t.titleSmall),
          const SizedBox(height: 2),
          Text('Room ${cls.roomNo}, ${cls.block} block, ${cls.classTeacher}', style: t.bodySmall),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Baseline(label: 'Expected when in use', value: '${cls.baselineOccupiedKwh.toStringAsFixed(2)} kWh', color: pal.info)),
            Expanded(child: _Baseline(label: 'Expected when vacant', value: '${cls.baselineVacantKwh.toStringAsFixed(2)} kWh', color: pal.success)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final d in _days)
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(d), selected: d == _day, onSelected: (_) => setState(() => _day = d))),
        ]),
      ),
      const SizedBox(height: 14),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Column(
          key: ValueKey('$_classId-$_day'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entries.isEmpty)
              AppCard(child: EmptyState(title: 'Nothing scheduled on $_day', message: 'Free study or revision.', icon: Icons.event_available_outlined))
            else
              for (final e in entries)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: _SlotRow(entry: e, atHome: e.location == cls.roomNo)),
          ],
        ),
      ),
    ]);
  }
}

class _Baseline extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Baseline({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(children: [
      Container(width: 4, height: 34, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: t.bodySmall),
          Text(value, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ]),
      ),
    ]);
  }
}

class _SlotRow extends StatelessWidget {
  final TimetableEntry entry;
  final bool atHome;
  const _SlotRow({required this.entry, required this.atHome});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final c = atHome ? pal.info : pal.warning;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(entry.slot, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${entry.courseCode}: ${entry.subjectName}', style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${entry.facultyCode}, ${entry.location}', style: t.bodySmall),
          ]),
        ),
        const SizedBox(width: 8),
        StatusBadge(
          label: atHome ? 'Room in use' : 'Room empty',
          icon: atHome ? Icons.people_outline : Icons.door_front_door_outlined,
          tone: atHome ? Tone.info : Tone.warning,
        ),
      ]),
    );
  }
}
