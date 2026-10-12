import 'package:flutter/material.dart';
import '../../../models/timetable_schedule.dart';

/// Interactive viewer for the 10 academic class timetables.
/// Illustrates how timetabled room allocation directly informs EcoNudge AI
/// baseline expectations and ghost-consumption detection.
class TimetableScheduleView extends StatefulWidget {
  final List<TimetableClass> classes;

  const TimetableScheduleView({
    super.key,
    required this.classes,
  });

  @override
  State<TimetableScheduleView> createState() => _TimetableScheduleViewState();
}

class _TimetableScheduleViewState extends State<TimetableScheduleView> {
  late String _selectedClassId;
  String _selectedDay = 'Tuesday';

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classes.isNotEmpty ? widget.classes.first.id : '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedClass = widget.classes.firstWhere(
      (c) => c.id == _selectedClassId,
      orElse: () => widget.classes.first,
    );

    final entries = selectedClass.weeklySchedule[_selectedDay] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class Selector Horizontal Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.classes.map((cls) {
              final isSelected = cls.id == _selectedClassId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('${cls.className} (${cls.roomNo})'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedClassId = cls.id;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Class Metadata Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.school_rounded, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedClass.className} • ${selectedClass.program}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Room: ${selectedClass.roomNo} | Block: ${selectedClass.block} | Teacher: ${selectedClass.classTeacher}',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⚡ Dynamic Baselines: Occupied = ${selectedClass.baselineOccupiedKwh} kWh | Standby = ${selectedClass.baselineVacantKwh} kWh',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Day Selector Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days.map((day) {
              final isDaySelected = day == _selectedDay;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(day),
                  selected: isDaySelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedDay = day);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Schedule Slots List
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Text(
              'No scheduled slots for $_selectedDay (Free study / revision)',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          )
        else
          ...entries.map((entry) {
            final isHome = entry.location == selectedClass.roomNo;
            final isLab = entry.isLab || entry.location.contains('Lab');
            final color = isHome
                ? const Color(0xFF1976D2)
                : (isLab ? const Color(0xFF7B1FA2) : const Color(0xFFF57C00));

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.slot,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.courseCode}: ${entry.subjectName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Faculty: ${entry.facultyCode} • Venue: ${entry.location}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isHome
                          ? Colors.blue.withAlpha(15)
                          : Colors.purple.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isHome ? 'Room Occupied' : 'Vacates Home Room',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isHome ? Colors.blue.shade800 : Colors.purple.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
