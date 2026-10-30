import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/print_service.dart';
import '../../core/services/print_document_generator.dart';
import '../../models/examination_model.dart';
import '../../models/student_model.dart';

class ReportCardDialog extends StatelessWidget {
  final Student student;
  final List<Mark> marks;
  final String academicYear;
  final String examTitle;

  const ReportCardDialog({
    super.key,
    required this.student,
    required this.marks,
    this.academicYear = 'Not supplied',
    this.examTitle = 'Published Results',
  });

  static Future<void> show(
    BuildContext context, {
    required Student student,
    required List<Mark> marks,
    String? academicYear,
    String? examTitle,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ReportCardDialog(
        student: student,
        marks: marks,
        academicYear: academicYear ?? student.currentAcademicYearId,
        examTitle: examTitle ?? 'Published Results',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMarks = marks
        .where((mark) => mark.studentId == student.studentId && mark.isPublished)
        .toList();

    final grandTotal =
        effectiveMarks.fold<int>(0, (sum, m) => sum + m.totalScore);
    final maxPossible = effectiveMarks.length * 100;
    final percentage = maxPossible > 0 ? (grandTotal / maxPossible) * 100 : 0.0;
    final overallGrade = percentage >= 90
        ? 'A1'
        : (percentage >= 80 ? 'A2' : (percentage >= 70 ? 'B1' : 'B2'));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Action Bar
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
                        Icon(Icons.print, size: 20, color: AppColors.brandNavy),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Official Institutional Report Card',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print Report Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandNavy,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        onPressed: effectiveMarks.isEmpty
                            ? null
                            : () {
                                final exam = Examination(
                                  examId: 'EXAM_${academicYear}_RESULTS',
                                  title: examTitle,
                                  academicYearId: academicYear,
                                  term: examTitle,
                                );
                                final ref = 'REP-${exam.examId}-${student.studentId}';
                                final html =
                                    PrintDocumentGenerator.generateReportCardHtml(
                                  student: student,
                                  examination: exam,
                                  marks: effectiveMarks,
                                  referenceNumber: ref,
                                );
                                PrintService.printDocument(
                                  htmlContent: html,
                                  documentTitle:
                                      'Report Card - ${student.fullName}',
                                );
                              },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Printable Document Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF0F172A), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Institutional Crest & Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.brandNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school,
                                  color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'LAV INTERNATIONAL ACADEMY',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'ANNUAL ACADEMIC PROGRESS REPORT — $academicYear',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ACADEMIC PROGRESS REPORT — $academicYear',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.parentBlue),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                examTitle.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D4ED8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          height: 32, thickness: 1.5, color: Color(0xFF0F172A)),

                      // Student Particulars
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoRow('Student Name', student.fullName),
                                  const SizedBox(height: 6),
                                  _infoRow(
                                      'Admission No.', student.admissionNumber),
                                  const SizedBox(height: 6),
                                  _infoRow('Class & Section',
                                      'Class ${student.currentClassId} — Section ${student.currentSectionId}'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoRow('Academic Session', academicYear),
                                  const SizedBox(height: 6),
                                  _infoRow(
                                      'Attendance Rate', 'Not supplied'),
                                  const SizedBox(height: 6),
                                  _infoRow('Result Status',
                                      effectiveMarks.isEmpty ? 'No published results' : 'Published'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (effectiveMarks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Text('No published marks are available for this student. This preview does not generate placeholder scores.'),
                        )
                      else
                      // Marks Table
                      Table(
                        border: TableBorder.all(
                            color: const Color(0xFFCBD5E1), width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1.2),
                          4: FlexColumnWidth(1.2),
                          5: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            decoration:
                                const BoxDecoration(color: Color(0xFF0F172A)),
                            children: [
                              _tableHeader('Subject'),
                              _tableHeader('CA 1\n(/20)'),
                              _tableHeader('CA 2\n(/20)'),
                              _tableHeader('Exam\n(/60)'),
                              _tableHeader('Total\n(/100)'),
                              _tableHeader('Grade'),
                            ],
                          ),
                          ...effectiveMarks.map((m) {
                            return TableRow(
                              decoration:
                                  const BoxDecoration(color: Colors.white),
                              children: [
                                _tableCell(m.subjectId, isBold: true),
                                _tableCell('${m.continuousAssessment.ca1}'),
                                _tableCell('${m.continuousAssessment.ca2}'),
                                _tableCell('${m.examScore}'),
                                _tableCell('${m.totalScore}',
                                    isBold: true,
                                    color: const Color(0xFF0F172A)),
                                _tableCell(m.grade,
                                    isBold: true,
                                    color: const Color(0xFF1D4ED8)),
                              ],
                            );
                          }),
                          TableRow(
                            decoration:
                                const BoxDecoration(color: Color(0xFFF1F5F9)),
                            children: [
                              _tableCell('GRAND TOTAL & AGGREGATE',
                                  isBold: true),
                              _tableCell(''),
                              _tableCell(''),
                              _tableCell(''),
                              _tableCell('$grandTotal / $maxPossible',
                                  isBold: true, color: const Color(0xFF0F172A)),
                              _tableCell(overallGrade,
                                  isBold: true, color: const Color(0xFF16A34A)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Remarks
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Teacher & Evaluator Remarks:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              effectiveMarks
                                      .map((mark) => mark.teacherComment?.trim() ?? '')
                                      .where((comment) => comment.isNotEmpty)
                                      .join(' · ')
                                  .isNotEmpty
                                  ? effectiveMarks
                                      .map((mark) => mark.teacherComment?.trim() ?? '')
                                      .where((comment) => comment.isNotEmpty)
                                      .join(' · ')
                                  : 'No teacher remarks have been recorded.',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Signatures
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Container(
                                  width: 140,
                                  height: 1,
                                  color: const Color(0xFF0F172A)),
                              const SizedBox(height: 4),
                              const Text('Class Teacher Signature',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.brandNavy, width: 1.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('SEAL OF INSTITUTION',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8)),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                  width: 140,
                                  height: 1,
                                  color: const Color(0xFF0F172A)),
                              const SizedBox(height: 4),
                              const Text('Principal Signature',
                                  style: TextStyle(
                                      fontSize: 11,
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

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text('$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF0F172A))),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  Widget _tableCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          fontSize: 12,
          color: color ?? const Color(0xFF334155),
        ),
      ),
    );
  }
}
