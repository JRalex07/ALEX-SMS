import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/print_service.dart';
import '../../models/student_model.dart';

class AttendanceRegisterDialog extends StatelessWidget {
  final String classId;
  final String sectionId;
  final DateTime date;
  final List<Student> students;
  final Map<String, String> attendanceMap;

  const AttendanceRegisterDialog({
    super.key,
    required this.classId,
    required this.sectionId,
    required this.date,
    this.students = const [],
    this.attendanceMap = const {},
  });

  static Future<void> show(
    BuildContext context, {
    required String classId,
    required String sectionId,
    required DateTime date,
    List<Student> students = const [],
    Map<String, String> attendanceMap = const {},
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AttendanceRegisterDialog(
        classId: classId,
        sectionId: sectionId,
        date: date,
        students: students,
        attendanceMap: attendanceMap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStudents = students.isNotEmpty
        ? students
        : const [
            Student(
              studentId: 'STU_001',
              admissionNumber: 'ADM-2026-001',
              fullName: 'Aarav Sharma',
              currentClassId: '10',
              currentSectionId: 'A',
              currentAcademicYearId: 'AY_2026_2027',
            ),
            Student(
              studentId: 'STU_002',
              admissionNumber: 'ADM-2026-002',
              fullName: 'Diya Patel',
              currentClassId: '10',
              currentSectionId: 'A',
              currentAcademicYearId: 'AY_2026_2027',
            ),
            Student(
              studentId: 'STU_003',
              admissionNumber: 'ADM-2026-003',
              fullName: 'Rohan Gupta',
              currentClassId: '10',
              currentSectionId: 'A',
              currentAcademicYearId: 'AY_2026_2027',
            ),
          ];
    final effectiveMap = attendanceMap.isNotEmpty
        ? attendanceMap
        : const {'STU_001': 'P', 'STU_002': 'P', 'STU_003': 'A'};

    final dateStr = date.toIso8601String().split('T').first;
    final presentCount = effectiveMap.values.where((v) => v == 'P').length;
    final absentCount = effectiveMap.values.where((v) => v == 'A').length;
    final lateCount = effectiveMap.values.where((v) => v == 'L').length;
    final excusedCount = effectiveMap.values.where((v) => v == 'E').length;
    final total = effectiveStudents.length;
    final rate = total > 0 ? (presentCount / total) * 100 : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border:
                    Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.how_to_reg,
                            size: 20, color: AppColors.teacherTeal),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text('Official Attendance Roll Register',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print Register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teacherTeal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => PrintService.printDocument(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),

            // Printable Sheet Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'LAV INTERNATIONAL ACADEMY',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                  color: Color(0xFF0F172A)),
                            ),
                            const Text(
                              'DAILY CLASS ATTENDANCE REGISTER • ACADEMIC YEAR 2026-2027',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'CLASS $classId — SECTION $sectionId • DATE: $dateStr',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.teacherTeal),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24, thickness: 1),

                      // Metric Summary
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _badge('Total Roster: $total',
                              const Color(0xFFF1F5F9), const Color(0xFF334155)),
                          _badge('Present: $presentCount',
                              const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                          _badge('Absent: $absentCount',
                              const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
                          _badge('Late/Excused: ${lateCount + excusedCount}',
                              const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                          _badge('Rate: ${rate.toStringAsFixed(1)}%',
                              const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Roster Table
                      Table(
                        border: TableBorder.all(color: const Color(0xFFCBD5E1)),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(3),
                          3: FlexColumnWidth(1.5),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xFF0F172A)),
                            children: [
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Roll',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11))),
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Student ID',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11))),
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Student Name',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11))),
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Status',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11))),
                            ],
                          ),
                          ...List.generate(effectiveStudents.length, (index) {
                            final s = effectiveStudents[index];
                            final sId = s.studentId;
                            final sName = s.fullName;
                            final status = effectiveMap[sId] ?? 'P';
                            final color = status == 'P'
                                ? const Color(0xFF16A34A)
                                : (status == 'A'
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFD97706));

                            return TableRow(
                              children: [
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('${index + 1}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12))),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(sId,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(sName,
                                        style: const TextStyle(fontSize: 12))),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(status,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: color))),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Signatures
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Container(
                                  width: 140, height: 1, color: Colors.black87),
                              const SizedBox(height: 4),
                              const Text('Class Teacher Signature',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                  width: 140, height: 1, color: Colors.black87),
                              const SizedBox(height: 4),
                              const Text('Principal Verification Stamp',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: textCol)),
    );
  }
}
