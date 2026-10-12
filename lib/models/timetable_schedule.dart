/// Represents a scheduled time slot in the college day.
class TimetableSlot {
  final String slot; // e.g. "L1", "L2", "LUNCH", "L3", "L4", "L5", "L6"
  final String timeRange; // e.g. "10:15 - 11:15"
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isBreak;

  const TimetableSlot({
    required this.slot,
    required this.timeRange,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.isBreak = false,
  });

  /// Checks if a given hour and minute falls within this slot.
  bool matches(int hour, int minute) {
    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;
    final currentTotal = hour * 60 + minute;
    return currentTotal >= startTotal && currentTotal < endTotal;
  }
}

/// Represents an individual class schedule entry.
class TimetableEntry {
  final String slot; // "L1", "L2", ...
  final String courseCode; // e.g. "BTCS306M"
  final String subjectName; // e.g. "Fundamentals of Data Structures"
  final String facultyCode; // e.g. "UM"
  final String location; // e.g. "CSE-213" or "Lab 220 A+B"
  final bool isLab;

  const TimetableEntry({
    required this.slot,
    required this.courseCode,
    required this.subjectName,
    required this.facultyCode,
    required this.location,
    this.isLab = false,
  });

  Map<String, dynamic> toJson() => {
        'slot': slot,
        'courseCode': courseCode,
        'subjectName': subjectName,
        'facultyCode': facultyCode,
        'location': location,
        'isLab': isLab,
      };
}

/// Represents a full academic class and its weekly schedule.
class TimetableClass {
  final String id; // e.g. "CLASS-01"
  final String className; // e.g. "AI&DS - II (A)"
  final String program; // e.g. "B.Tech (AIML-Microsoft)"
  final String block; // "Main"
  final String roomNo; // e.g. "CSE-213"
  final String semester; // e.g. "III"
  final String classTeacher; // e.g. "Prof. Unnati Mishra"
  final double baselineOccupiedKwh; // default ~1.9 kWh
  final double baselineVacantKwh; // default ~0.2 kWh
  final Map<String, List<TimetableEntry>> weeklySchedule; // "Monday" -> entries

  const TimetableClass({
    required this.id,
    required this.className,
    required this.program,
    required this.block,
    required this.roomNo,
    required this.semester,
    required this.classTeacher,
    this.baselineOccupiedKwh = 1.9,
    this.baselineVacantKwh = 0.2,
    required this.weeklySchedule,
  });

  /// Finds the scheduled activity for this class at a specific day and slot.
  TimetableEntry? getEntryFor(String dayName, String slot) {
    final dayEntries = weeklySchedule[dayName];
    if (dayEntries == null) return null;
    for (final entry in dayEntries) {
      if (entry.slot == slot) return entry;
    }
    return null;
  }

  /// Determines whether this class is physically scheduled in its home room at the slot.
  bool isHomeRoomOccupiedAt(String dayName, String slot) {
    final entry = getEntryFor(dayName, slot);
    if (entry == null) return false;
    // If the class is in a lab, library, sports, or online, the home room is vacant!
    final loc = entry.location.toLowerCase();
    if (loc.contains('lab') ||
        loc.contains('library') ||
        loc.contains('sport') ||
        loc.contains('online') ||
        loc.contains('ground')) {
      return false;
    }
    return true;
  }
}
