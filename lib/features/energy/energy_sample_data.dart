import '../../models/energy_alert.dart';
import '../../models/room_reading.dart';
import '../../models/timetable_schedule.dart';

/// Pre-seeded sample fixture data representing 10 classrooms and shared laboratories
/// at Shri Vaishnav Institute of Information Technology (SVIIT), Indore.
///
/// Designed to test both normal operations, ghost consumption anomalies,
/// and edge-case validations without requiring external hardware or APIs.
class EnergySampleData {
  static const double standardTariffPerKwh = 8.0; // ₹ 8.00 per kWh
  static const double standardCo2Factor = 0.82; // 0.82 kg CO2e per kWh

  /// Standard timetable slots matching the SVVV Shift-II (10:00 - 5:00)
  static final List<TimetableSlot> standardSlots = [
    const TimetableSlot(
      slot: 'L1',
      timeRange: '10:15 - 11:15',
      startHour: 10,
      startMinute: 15,
      endHour: 11,
      endMinute: 15,
    ),
    const TimetableSlot(
      slot: 'L2',
      timeRange: '11:15 - 12:15',
      startHour: 11,
      startMinute: 15,
      endHour: 12,
      endMinute: 15,
    ),
    const TimetableSlot(
      slot: 'LUNCH',
      timeRange: '12:15 - 12:45',
      startHour: 12,
      startMinute: 15,
      endHour: 12,
      endMinute: 45,
      isBreak: true,
    ),
    const TimetableSlot(
      slot: 'L3',
      timeRange: '12:45 - 1:45',
      startHour: 12,
      startMinute: 45,
      endHour: 13,
      endMinute: 45,
    ),
    const TimetableSlot(
      slot: 'L4',
      timeRange: '1:45 - 2:45',
      startHour: 13,
      startMinute: 45,
      endHour: 14,
      endMinute: 45,
    ),
    const TimetableSlot(
      slot: 'L5',
      timeRange: '2:45 - 3:45',
      startHour: 14,
      startMinute: 45,
      endHour: 15,
      endMinute: 45,
    ),
    const TimetableSlot(
      slot: 'L6',
      timeRange: '3:45 - 4:45',
      startHour: 15,
      startMinute: 45,
      endHour: 16,
      endMinute: 45,
    ),
  ];

  /// 10 Academic Classes with complete weekly schedules
  static List<TimetableClass> getTenClasses() {
    return [
      // 1. AI&DS - II (A)
      TimetableClass(
        id: 'CLASS-01',
        className: 'AI&DS - II (A)',
        program: 'B.Tech (AIML-Microsoft)',
        block: 'Main',
        roomNo: 'CSE-213',
        semester: 'III',
        classTeacher: 'Prof. Unnati Mishra',
        baselineOccupiedKwh: 1.9,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Monday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS306M', subjectName: 'Fundamentals of Data Structures', facultyCode: 'UM', location: 'CSE-213'),
            const TimetableEntry(slot: 'L2', courseCode: 'BTCS301N', subjectName: 'Discrete Structures', facultyCode: 'M-AD', location: 'CSE-213'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTCS307M', subjectName: 'Principles of Operating Systems', facultyCode: 'JP', location: 'CSE-213'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS402N', subjectName: 'Software Engineering', facultyCode: 'GGS', location: 'CSE-213'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTCS103N', subjectName: 'Computer System Organization', facultyCode: 'PJ', location: 'CSE-213'),
            const TimetableEntry(slot: 'L6', courseCode: 'BTCS301N', subjectName: 'Discrete Structures', facultyCode: 'M-AD', location: 'CSE-213'),
          ],
          'Tuesday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS306M', subjectName: 'Data Structures', facultyCode: 'UM', location: 'CSE-213'),
            const TimetableEntry(slot: 'L2', courseCode: 'LIB', subjectName: 'Library', facultyCode: '-', location: 'Library'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTCS307M(P)', subjectName: 'Operating Systems Lab', facultyCode: 'AI-JP', location: 'Lab 220 A+B', isLab: true),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS306M', subjectName: 'Data Structures', facultyCode: 'UM', location: 'CSE-213'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTCS103N', subjectName: 'Computer System Organization', facultyCode: 'PJ', location: 'CSE-213'),
            const TimetableEntry(slot: 'L6', courseCode: 'BTCS402N', subjectName: 'Software Engineering', facultyCode: 'GGS', location: 'CSE-213'),
          ],
          'Wednesday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS103N', subjectName: 'CSO', facultyCode: 'PJ', location: 'CSE-213'),
            const TimetableEntry(slot: 'L2', courseCode: 'SPORTS', subjectName: 'Sports', facultyCode: '-', location: 'Sports Ground'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTCS402(P)', subjectName: 'Software Engineering Lab', facultyCode: 'AI-GS', location: 'Lab 220 A+B', isLab: true),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS306M', subjectName: 'Data Structures', facultyCode: 'UM', location: 'CSE-213'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTCS103N(P)', subjectName: 'CSO Lab', facultyCode: 'EC-PJ', location: 'EC-Lab', isLab: true),
            const TimetableEntry(slot: 'L6', courseCode: 'BTCS402N', subjectName: 'Software Engineering', facultyCode: 'GGS', location: 'CSE-213'),
          ],
        },
      ),

      // 2. AI&DS - II (B)
      TimetableClass(
        id: 'CLASS-02',
        className: 'AI&DS - II (B)',
        program: 'B.Tech (AIML-Microsoft)',
        block: 'Main',
        roomNo: 'CSE-215',
        semester: 'III',
        classTeacher: 'Prof. Jayshree Pargee',
        baselineOccupiedKwh: 1.9,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Tuesday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS103N', subjectName: 'Computer System Organization', facultyCode: 'EC-AK', location: 'CSE-215'),
            const TimetableEntry(slot: 'L2', courseCode: 'BTCS402N', subjectName: 'Software Engineering', facultyCode: 'GGS', location: 'CSE-215'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTCS301N', subjectName: 'Discrete Structures', facultyCode: 'SY', location: 'CSE-215'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS306M', subjectName: 'Data Structures', facultyCode: 'PD', location: 'CSE-215'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTCS402N', subjectName: 'Software Engineering', facultyCode: 'GGS', location: 'CSE-215'),
            const TimetableEntry(slot: 'L6', courseCode: 'SPORTS', subjectName: 'Sports', facultyCode: '-', location: 'Ground'),
          ],
        },
      ),

      // 3. AI&DS - II (C)
      TimetableClass(
        id: 'CLASS-03',
        className: 'AI&DS - II (C)',
        program: 'B.Tech (DS-IBM+RH)+MA',
        block: 'Main',
        roomNo: 'CSE-214',
        semester: 'III',
        classTeacher: 'Prof. Amit Dangi',
        baselineOccupiedKwh: 1.9,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Monday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS402N', subjectName: 'Software Engineering', facultyCode: 'JS', location: 'CSE-214'),
            const TimetableEntry(slot: 'L2', courseCode: 'LIB', subjectName: 'Library', facultyCode: '-', location: 'Library'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTCS307M', subjectName: 'Operating Systems', facultyCode: 'JN', location: 'CSE-214'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS301N', subjectName: 'Discrete Structures', facultyCode: 'Maths', location: 'CSE-214'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTIT307N(P)', subjectName: 'Core Java Lab', facultyCode: 'AI-HB', location: 'IBM 320', isLab: true),
            const TimetableEntry(slot: 'L6', courseCode: 'BTIT307N(P)', subjectName: 'Core Java Lab', facultyCode: 'AI-HB', location: 'IBM 320', isLab: true),
          ],
        },
      ),

      // 4. AI&DS - II (D)
      TimetableClass(
        id: 'CLASS-04',
        className: 'AI&DS - II (D)',
        program: 'B.Tech AI-IBM',
        block: 'Main',
        roomNo: 'CSE-212',
        semester: 'III',
        classTeacher: 'Prof. Juhi Shrivastav',
        baselineOccupiedKwh: 1.9,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Wednesday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTIBMC401N', subjectName: 'Cloud App Dev', facultyCode: 'IBM-RC', location: 'CSE-212'),
            const TimetableEntry(slot: 'L2', courseCode: 'LIB', subjectName: 'Library', facultyCode: '-', location: 'Library'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTCS306M', subjectName: 'Data Structures', facultyCode: 'AD', location: 'CSE-212'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS402N', subjectName: 'Software Engineering', facultyCode: 'JS', location: 'CSE-212'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTIT301N', subjectName: 'Computer Networks', facultyCode: 'HB', location: 'CSE-212'),
            const TimetableEntry(slot: 'L6', courseCode: 'BTCS306M', subjectName: 'Data Structures', facultyCode: 'AD', location: 'CSE-212'),
          ],
        },
      ),

      // 5. AI&DS - III (A)
      TimetableClass(
        id: 'CLASS-05',
        className: 'AI&DS - III (A)',
        program: 'B.Tech (AIML-Microsoft)',
        block: 'Main',
        roomNo: 'CSE-301',
        semester: 'V',
        classTeacher: 'Dr. Abhishek Singh Rathore',
        baselineOccupiedKwh: 2.0,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Monday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTAIML501', subjectName: 'Deep Learning', facultyCode: 'ASR', location: 'CSE-301'),
            const TimetableEntry(slot: 'L2', courseCode: 'BTCS503', subjectName: 'Cloud DevOps', facultyCode: 'RC', location: 'CSE-301'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTAIML502', subjectName: 'AI Ethics & Policy', facultyCode: 'UM', location: 'CSE-301'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS504', subjectName: 'Compiler Design', facultyCode: 'Maths', location: 'CSE-301'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTAIML501(P)', subjectName: 'Deep Learning Lab', facultyCode: 'ASR', location: 'IBM 320', isLab: true),
            const TimetableEntry(slot: 'L6', courseCode: 'BTAIML501(P)', subjectName: 'Deep Learning Lab', facultyCode: 'ASR', location: 'IBM 320', isLab: true),
          ],
        },
      ),

      // 6. AI&DS - III (B)
      TimetableClass(
        id: 'CLASS-06',
        className: 'AI&DS - III (B)',
        program: 'B.Tech Data Science (IBM)',
        block: 'Main',
        roomNo: 'CSE-302',
        semester: 'V',
        classTeacher: 'Prof. Pooja Deshpande',
        baselineOccupiedKwh: 2.0,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Thursday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS506', subjectName: 'Agile Software Dev', facultyCode: 'GGS', location: 'CSE-302'),
            const TimetableEntry(slot: 'L2', courseCode: 'LIB', subjectName: 'Library', facultyCode: '-', location: 'Library'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTDS501', subjectName: 'Big Data Analytics', facultyCode: 'PD', location: 'CSE-302'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTAIML503', subjectName: 'NLP', facultyCode: 'JP', location: 'CSE-302'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTCS505(P)', subjectName: 'Distributed Systems Lab', facultyCode: 'AD', location: 'Lab 220 A+B', isLab: true),
            const TimetableEntry(slot: 'L6', courseCode: 'BTCS505(P)', subjectName: 'Distributed Systems Lab', facultyCode: 'AD', location: 'Lab 220 A+B', isLab: true),
          ],
        },
      ),

      // 7. AI&DS - IV (A)
      TimetableClass(
        id: 'CLASS-07',
        className: 'AI&DS - IV (A)',
        program: 'B.Tech AIML',
        block: 'Main',
        roomNo: 'CSE-401',
        semester: 'VII',
        classTeacher: 'Dr. Anand Rajavat',
        baselineOccupiedKwh: 2.1,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Friday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS704', subjectName: 'Cyber-Physical Systems', facultyCode: 'RC', location: 'CSE-401'),
            const TimetableEntry(slot: 'L2', courseCode: 'BTAIML703', subjectName: 'Reinforcement Learning', facultyCode: 'HB', location: 'CSE-401'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTAIML702', subjectName: 'MLOps in Production', facultyCode: 'ASR', location: 'CSE-401'),
            const TimetableEntry(slot: 'L4', courseCode: 'LIB', subjectName: 'Library', facultyCode: '-', location: 'Library'),
            const TimetableEntry(slot: 'L5', courseCode: 'MAJOR-PROJ', subjectName: 'Capstone Project', facultyCode: 'AR', location: 'R&D LAB', isLab: true),
            const TimetableEntry(slot: 'L6', courseCode: 'MAJOR-PROJ', subjectName: 'Capstone Project', facultyCode: 'AR', location: 'R&D LAB', isLab: true),
          ],
        },
      ),

      // 8. CSE - II (A)
      TimetableClass(
        id: 'CLASS-08',
        className: 'CSE - II (A)',
        program: 'B.Tech CSE Core',
        block: 'Main',
        roomNo: 'CSE-105',
        semester: 'III',
        classTeacher: 'Prof. Ashish Dixit',
        baselineOccupiedKwh: 1.9,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Wednesday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS304', subjectName: 'Computer Org & Arch', facultyCode: 'UM', location: 'CSE-105'),
            const TimetableEntry(slot: 'L2', courseCode: 'BTCS303', subjectName: 'Digital Logic', facultyCode: 'EC-PJ', location: 'CSE-105'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTCS301', subjectName: 'Data Structures & Algo', facultyCode: 'AD-CSE', location: 'CSE-105'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS302', subjectName: 'Discrete Mathematics', facultyCode: 'Maths', location: 'CSE-105'),
            const TimetableEntry(slot: 'L5', courseCode: 'SPORTS', subjectName: 'Sports', facultyCode: '-', location: 'Ground'),
            const TimetableEntry(slot: 'L6', courseCode: 'STUDY', subjectName: 'Self Study', facultyCode: '-', location: 'CSE-105'),
          ],
        },
      ),

      // 9. CSE - II (B)
      TimetableClass(
        id: 'CLASS-09',
        className: 'CSE - II (B)',
        program: 'B.Tech CSE Core',
        block: 'Main',
        roomNo: 'CSE-106',
        semester: 'III',
        classTeacher: 'Prof. Alka Karketta',
        baselineOccupiedKwh: 1.9,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Monday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS305', subjectName: 'OOPs with Java', facultyCode: 'JS', location: 'CSE-106'),
            const TimetableEntry(slot: 'L2', courseCode: 'BTCS308', subjectName: 'Database Management', facultyCode: 'SY', location: 'CSE-106'),
            const TimetableEntry(slot: 'L3', courseCode: 'BTCS309', subjectName: 'Computer Networks', facultyCode: 'MS', location: 'CSE-106'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTES301', subjectName: 'Environmental Studies', facultyCode: 'Faculty', location: 'CSE-106'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTCS305(P)', subjectName: 'Java OOPs Lab', facultyCode: 'JS', location: 'IBM 320', isLab: true),
            const TimetableEntry(slot: 'L6', courseCode: 'BTCS305(P)', subjectName: 'Java OOPs Lab', facultyCode: 'JS', location: 'IBM 320', isLab: true),
          ],
        },
      ),

      // 10. CSE - III (A)
      TimetableClass(
        id: 'CLASS-10',
        className: 'CSE - III (A)',
        program: 'B.Tech CSE Core',
        block: 'Main',
        roomNo: 'CSE-305',
        semester: 'V',
        classTeacher: 'Prof. Gangeshwari Sharma',
        baselineOccupiedKwh: 2.0,
        baselineVacantKwh: 0.2,
        weeklySchedule: {
          'Tuesday': [
            const TimetableEntry(slot: 'L1', courseCode: 'BTCS502', subjectName: 'Web Technologies', facultyCode: 'HB', location: 'CSE-305'),
            const TimetableEntry(slot: 'L2', courseCode: 'BTCS501', subjectName: 'Design & Analysis of Algo', facultyCode: 'GGS', location: 'CSE-305'),
            const TimetableEntry(slot: 'L3', courseCode: 'LIB', subjectName: 'Library', facultyCode: '-', location: 'Library'),
            const TimetableEntry(slot: 'L4', courseCode: 'BTCS507', subjectName: 'Theory of Computation', facultyCode: 'Maths', location: 'CSE-305'),
            const TimetableEntry(slot: 'L5', courseCode: 'BTCS502(P)', subjectName: 'Web Tech Lab', facultyCode: 'HB', location: 'Lab 220 A+B', isLab: true),
            const TimetableEntry(slot: 'L6', courseCode: 'BTCS502(P)', subjectName: 'Web Tech Lab', facultyCode: 'HB', location: 'Lab 220 A+B', isLab: true),
          ],
        },
      ),
    ];
  }

  /// Initial seeded alerts conforming strictly to INTEGRATION_CONTRACT.md
  static List<EnergyAlert> getInitialAlerts() {
    return [
      // Anomaly 1: Empty room ghost consumption
      EnergyAlert(
        id: 'ALERT-NRG-001',
        roomName: 'CSE-213',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        actualKwh: 2.85,
        expectedKwh: 0.20,
        tariffPerKwh: standardTariffPerKwh,
        co2KgPerKwh: standardCo2Factor,
        reason:
            'Ghost Consumption: Timetable indicates Class AI&DS-II(A) is currently in Lab 220 A+B for OS practicals, but classroom CSE-213 is drawing 2.85 kWh (4 fans, 8 tube lights & projector left running).',
        status: 'active',
      ),

      // Anomaly 2: Off-hours Lab HVAC and monitor leak
      EnergyAlert(
        id: 'ALERT-NRG-002',
        roomName: 'IBM 320 Lab',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
        actualKwh: 4.80,
        expectedKwh: 0.30,
        tariffPerKwh: standardTariffPerKwh,
        co2KgPerKwh: standardCo2Factor,
        reason:
            'Off-Hours Lab Leakage: Lab IBM 320 has 3 air conditioning split units and 40 desktop monitors left energized after Shift-II conclusion.',
        status: 'active',
      ),

      // Anomaly 3: Lunch break lights and ventilation left on
      EnergyAlert(
        id: 'ALERT-NRG-003',
        roomName: 'CSE-105',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        actualKwh: 1.45,
        expectedKwh: 0.15,
        tariffPerKwh: standardTariffPerKwh,
        co2KgPerKwh: standardCo2Factor,
        reason:
            'Recess Wastage: All ceiling fans and illumination kept running during the official 12:15 - 12:45 PM lunch break while room is vacant.',
        status: 'active',
      ),

      // Anomaly 4: Overload in CSE-302 during lecture
      EnergyAlert(
        id: 'ALERT-NRG-004',
        roomName: 'CSE-302',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        actualKwh: 3.40,
        expectedKwh: 2.00,
        tariffPerKwh: standardTariffPerKwh,
        co2KgPerKwh: standardCo2Factor,
        reason:
            'Equipment Overload: Auxiliary high-power testing hardware running concurrently with regular lecture load.',
        status: 'resolved',
      ),
    ];
  }

  /// Live Room Telemetry Snapshots across 10 campus spaces
  static List<RoomReading> getSampleRoomReadings() {
    final now = DateTime.now();
    return [
      // 1. CSE-213 (Anomaly - Ghost Consumption)
      RoomReading(
        roomId: 'R-213',
        roomName: 'CSE-213',
        roomType: 'Lecture Hall',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 2.85,
        expectedKwh: 0.20,
        isScheduledOccupied: false,
        activeClassId: 'AI&DS - II (A)',
        activeCourseCode: 'BTCS307M(P)',
        activeFaculty: 'AI-JP',
        activeActivity: 'Class relocated to Lab 220 A+B',
        voltage: 231.2,
        currentAmps: 12.3,
        powerFactor: 0.94,
      ),

      // 2. CSE-215 (Normal Occupied)
      RoomReading(
        roomId: 'R-215',
        roomName: 'CSE-215',
        roomType: 'Lecture Hall',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 1.85,
        expectedKwh: 1.90,
        isScheduledOccupied: true,
        activeClassId: 'AI&DS - II (B)',
        activeCourseCode: 'BTCS103N',
        activeFaculty: 'EC-AK',
        activeActivity: 'Lecture: Computer System Org',
        voltage: 229.8,
        currentAmps: 8.1,
        powerFactor: 0.96,
      ),

      // 3. CSE-214 (Normal Occupied)
      RoomReading(
        roomId: 'R-214',
        roomName: 'CSE-214',
        roomType: 'Lecture Hall',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 1.92,
        expectedKwh: 1.90,
        isScheduledOccupied: true,
        activeClassId: 'AI&DS - II (C)',
        activeCourseCode: 'BTCS402N',
        activeFaculty: 'JS',
        activeActivity: 'Lecture: Software Engineering',
        voltage: 230.5,
        currentAmps: 8.3,
        powerFactor: 0.95,
      ),

      // 4. CSE-212 (Normal Vacant - Library Slot)
      RoomReading(
        roomId: 'R-212',
        roomName: 'CSE-212',
        roomType: 'Lecture Hall',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 0.18,
        expectedKwh: 0.20,
        isScheduledOccupied: false,
        activeClassId: 'AI&DS - II (D)',
        activeCourseCode: 'LIB',
        activeFaculty: '-',
        activeActivity: 'Class scheduled in Library',
        voltage: 230.1,
        currentAmps: 0.8,
        powerFactor: 0.91,
      ),

      // 5. CSE-301 (Normal Occupied)
      RoomReading(
        roomId: 'R-301',
        roomName: 'CSE-301',
        roomType: 'Lecture Hall',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 2.05,
        expectedKwh: 2.00,
        isScheduledOccupied: true,
        activeClassId: 'AI&DS - III (A)',
        activeCourseCode: 'BTAIML501',
        activeFaculty: 'ASR',
        activeActivity: 'Lecture: Deep Learning',
        voltage: 230.0,
        currentAmps: 8.9,
        powerFactor: 0.95,
      ),

      // 6. CSE-302 (Normal Occupied)
      RoomReading(
        roomId: 'R-302',
        roomName: 'CSE-302',
        roomType: 'Lecture Hall',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 1.95,
        expectedKwh: 2.00,
        isScheduledOccupied: true,
        activeClassId: 'AI&DS - III (B)',
        activeCourseCode: 'BTDS501',
        activeFaculty: 'PD',
        activeActivity: 'Lecture: Big Data Analytics',
        voltage: 231.0,
        currentAmps: 8.5,
        powerFactor: 0.95,
      ),

      // 7. CSE-401 (Normal Vacant - Project Slot in Lab)
      RoomReading(
        roomId: 'R-401',
        roomName: 'CSE-401',
        roomType: 'Lecture Hall',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 0.19,
        expectedKwh: 0.20,
        isScheduledOccupied: false,
        activeClassId: 'AI&DS - IV (A)',
        activeCourseCode: 'MAJOR-PROJ',
        activeFaculty: 'AR',
        activeActivity: 'Capstone Project in R&D Lab',
        voltage: 230.4,
        currentAmps: 0.8,
        powerFactor: 0.90,
      ),

      // 8. CSE-105 (Anomaly - Recess Wastage)
      RoomReading(
        roomId: 'R-105',
        roomName: 'CSE-105',
        roomType: 'Lecture Hall',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 1.45,
        expectedKwh: 0.15,
        isScheduledOccupied: false,
        activeClassId: 'CSE - II (A)',
        activeCourseCode: 'LUNCH',
        activeFaculty: '-',
        activeActivity: 'Recess Break - Room should be dark',
        voltage: 230.2,
        currentAmps: 6.3,
        powerFactor: 0.93,
      ),

      // 9. Lab 220 A+B (Normal Active High Load Practical)
      RoomReading(
        roomId: 'LAB-220',
        roomName: 'Lab 220 A+B',
        roomType: 'Computer Lab (60 PCs)',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 4.75,
        expectedKwh: 4.80,
        isScheduledOccupied: true,
        activeClassId: 'AI&DS - II (A)',
        activeCourseCode: 'BTCS307M(P)',
        activeFaculty: 'AI-JP',
        activeActivity: 'Practical: OS Lab Session',
        voltage: 228.5,
        currentAmps: 20.8,
        powerFactor: 0.97,
      ),

      // 10. Lab IBM 320 (Anomaly - Off-Hours Leakage)
      RoomReading(
        roomId: 'LAB-IBM320',
        roomName: 'IBM 320 Lab',
        roomType: 'Analytics Lab (45 PCs)',
        block: 'Main Block',
        timestamp: now,
        actualKwh: 4.80,
        expectedKwh: 0.30,
        isScheduledOccupied: false,
        activeClassId: '-',
        activeCourseCode: 'UNSCHEDULED',
        activeFaculty: '-',
        activeActivity: 'Vacant - ACs & 40 PCs left ON',
        voltage: 231.8,
        currentAmps: 21.0,
        powerFactor: 0.96,
      ),
    ];
  }
}
