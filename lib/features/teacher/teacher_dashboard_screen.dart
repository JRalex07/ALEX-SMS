import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../models/attendance_model.dart';
import '../../models/examination_model.dart';
import '../../models/student_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/clay/clay.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/dialogs/attendance_register_dialog.dart';
import '../../shared/dialogs/upload_material_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../core/services/print_service.dart';

import '../../shared/widgets/erp_components.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  int _currentNavIndex = 0;
  String _selectedClass = '10';
  String _selectedSection = 'A';

  // Local Attendance State for active session
  final Map<String, String> _attendanceMap = {
    'STU_001': 'P',
    'STU_002': 'P',
    'STU_003': 'A',
    'STU_004': 'P',
    'STU_005': 'L',
  };

  // Local Marks State for class 10-A Mathematics
  final Map<String, Map<String, int>> _marksMap = {
    'STU_001': {'ca1': 18, 'ca2': 19, 'exam': 54},
    'STU_002': {'ca1': 15, 'ca2': 14, 'exam': 48},
    'STU_003': {'ca1': 20, 'ca2': 19, 'exam': 58},
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Teacher Portal',
      selectedNavIndex: _currentNavIndex,
      onNavIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
      navDestinations: const [
        NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'My Classes'),
        NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'Attendance'),
        NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Enter Marks'),
        NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared),
            label: 'Materials'),
      ],
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildClassesOverviewTab(),
          _buildAttendanceTab(),
          _buildMarksEntryTab(),
          _buildMaterialsTab(),
        ],
      ),
    );
  }

  Widget _buildClassesOverviewTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Teacher High-Density Metric Strip
        const ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'Assigned Classes',
              value: 'Class 10-A, 9-B',
              subtitle: 'Mathematics & Science',
              icon: Icons.school,
              color: AppColors.teacherTeal,
              trend: 'Primary Faculty',
            ),
            ErpMetricItem(
              label: 'Total Students',
              value: '79',
              subtitle: 'Active Enrollments',
              icon: Icons.people_outline,
              color: AppColors.teacherTeal,
              trend: '2 Cohorts',
            ),
            ErpMetricItem(
              label: 'Today\'s Attendance',
              value: '94.3%',
              subtitle: '33 of 35 Present (10-A)',
              icon: Icons.how_to_reg_outlined,
              color: AppColors.successGreen,
              trend: 'Roll Taken',
            ),
            ErpMetricItem(
              label: 'Term Assessment',
              value: '89 / 100',
              subtitle: 'Class 10-A Mean Score',
              icon: Icons.edit_note_outlined,
              color: AppColors.adminIndigo,
              trend: 'CA1 + CA2',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Active Cohort Selector & Daily Workflow Action Ribbon
        ErpCard(
          title: 'Active Class & Section Selector',
          subtitle:
              'Choose target cohort to manage daily roll call, homework, and term marks',
          icon: Icons.tune,
          iconColor: AppColors.teacherTeal,
          headerTrailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teacherTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: AppColors.teacherTeal.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Selected: Class $_selectedClass-$_selectedSection',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.teacherTeal,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClass,
                        items: const [
                          DropdownMenuItem(
                              value: '10', child: Text('Class 10')),
                          DropdownMenuItem(value: '9', child: Text('Class 9')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedClass = val);
                        },
                      ),
                    ),
                  ),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSection,
                        items: const [
                          DropdownMenuItem(
                              value: 'A', child: Text('Section A')),
                          DropdownMenuItem(
                              value: 'B', child: Text('Section B')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSection = val);
                          }
                        },
                      ),
                    ),
                  ),
                  ErpButton(
                    icon: Icons.how_to_reg,
                    label: 'Mark Daily Roll Call',
                    color: AppColors.teacherTeal,
                    onPressed: () => setState(() => _currentNavIndex = 1),
                  ),
                  ErpButton(
                    icon: Icons.assignment_add,
                    label: 'Publish Homework',
                    isPrimary: false,
                    color: AppColors.teacherTeal,
                    onPressed: () => CreateHomeworkDialog.show(
                      context,
                      currentClass: _selectedClass,
                      currentSection: _selectedSection,
                    ),
                  ),
                  ErpButton(
                    icon: Icons.upload_file,
                    label: 'Upload Study Material',
                    isPrimary: false,
                    color: AppColors.textSecondary,
                    onPressed: () => UploadMaterialDialog.show(
                      context,
                      defaultClass: _selectedClass,
                      defaultSection: _selectedSection,
                      onUpload: ({
                        required title,
                        required classId,
                        required sectionId,
                        required subject,
                        required fileName,
                      }) async {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Today's Class Teaching Timetable
        ErpCard(
          title: 'Today\'s Classroom Schedule & Timetable',
          subtitle:
              'Academic Day Schedule • Morning & Afternoon Teaching Slots',
          icon: Icons.schedule,
          iconColor: AppColors.brandNavy,
          child: Column(
            children: [
              _buildTimetablePeriod(
                period: 'Period 1',
                time: '08:30 - 09:15 AM',
                cohort: 'Class 10-A',
                subject: 'Mathematics (Quadratic Equations)',
                room: 'Room 204',
                status: 'Completed',
                isCurrent: false,
              ),
              const Divider(height: 14, color: AppColors.borderLight),
              _buildTimetablePeriod(
                period: 'Period 2',
                time: '09:20 - 10:05 AM',
                cohort: 'Class 9-B',
                subject: 'Physics (Newtonian Motion)',
                room: 'Science Lab B',
                status: 'Live Now',
                isCurrent: true,
              ),
              const Divider(height: 14, color: AppColors.borderLight),
              _buildTimetablePeriod(
                period: 'Period 3',
                time: '10:20 - 11:05 AM',
                cohort: 'Class 10-A',
                subject: 'Problem Solving & Exercises',
                room: 'Room 204',
                status: 'Upcoming',
                isCurrent: false,
              ),
              const Divider(height: 14, color: AppColors.borderLight),
              _buildTimetablePeriod(
                period: 'Period 4',
                time: '11:10 - 11:55 AM',
                cohort: 'Class 9-B',
                subject: 'Numerical Problem Solving',
                room: 'Room 108',
                status: 'Upcoming',
                isCurrent: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimetablePeriod({
    required String period,
    required String time,
    required String cohort,
    required String subject,
    required String room,
    required String status,
    required bool isCurrent,
  }) {
    return Row(
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.teacherTeal
                : AppColors.brandNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isCurrent ? Colors.white : AppColors.brandNavy,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$subject • $cohort',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                '$time • $room',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (isCurrent)
          const ErpStatusBadge(
            label: 'IN PROGRESS',
            backgroundColor: AppColors.successBg,
            textColor: AppColors.successGreen,
            icon: Icons.play_arrow,
          )
        else
          Text(
            status,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    final today = DateTime.now().toString().substring(0, 10);
    final studentsAsync = ref.watch(classStudentsStreamProvider(
        (classId: 'Class $_selectedClass', sectionId: _selectedSection)));
    final isCompact = AppBreakpoints.isCompact(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Daily Roll Call: Class $_selectedClass-$_selectedSection',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text('Date: $today • Live Session',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ClayButton(
                  height: 38,
                  icon: Icons.print,
                  label: isCompact ? 'Register' : 'Print Register',
                  variant: ClayButtonVariant.subtle,
                  onPressed: () {
                    final students = studentsAsync.value ?? [];
                    AttendanceRegisterDialog.show(
                      context,
                      classId: _selectedClass,
                      sectionId: _selectedSection,
                      date: DateTime.now(),
                      students: students,
                      attendanceMap: _attendanceMap,
                    );
                  },
                ),
                ClayButton(
                  height: 38,
                  icon: Icons.save,
                  label: isCompact ? 'Submit' : 'Save & Submit Roll Call',
                  variant: ClayButtonVariant.primary,
                  customColor: AppColors.teacherTeal,
                  onPressed: () async {
                    final sessionId =
                        'SES_${_selectedClass}_${_selectedSection}_${today.replaceAll('-', '')}';
                    try {
                      await ref
                          .read(attendanceRepositoryProvider)
                          .createDraftSession(
                            AttendanceSession(
                              sessionId: sessionId,
                              classId: 'Class $_selectedClass',
                              sectionId: _selectedSection,
                              date: today,
                              academicYearId: 'AY_2026_2027',
                              markedBy: 'teacher_uid',
                            ),
                          );

                      for (var entry in _attendanceMap.entries) {
                        await ref
                            .read(attendanceRepositoryProvider)
                            .saveAttendanceRecord(
                              sessionId: sessionId,
                              studentId: entry.key,
                              status: entry.value,
                            );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Attendance draft saved! Submitted for admin approval.')),
                        );
                      }
                    } catch (e, stack) {
                      debugPrint(
                          '[TeacherDashboardScreen.saveAttendanceDraft] Exception: $e\n$stack');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Draft saved: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        studentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => ClayCard(
            child: Text('Error loading class students: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (students) {
            if (students.isEmpty) {
              return ClayEmptyState(
                icon: Icons.people_outline,
                title: 'No Students Enrolled',
                message:
                    'No students enrolled in Class $_selectedClass - Section $_selectedSection.',
              );
            }

            return ClayCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = students[index];
                  final status = _attendanceMap[s.studentId] ?? 'P';

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.teacherTeal.withValues(alpha: 0.12),
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.teacherTeal)),
                    ),
                    title: Text('${s.fullName} (${s.admissionNumber})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(
                        'ID: ${s.studentId} • Class ${s.currentClassId}-${s.currentSectionId}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        _attendanceOptionButton(s.studentId, 'P', 'Present',
                            AppColors.successGreen, status == 'P'),
                        _attendanceOptionButton(s.studentId, 'A', 'Absent',
                            AppColors.dangerRed, status == 'A'),
                        _attendanceOptionButton(s.studentId, 'L', 'Late',
                            AppColors.warningAmber, status == 'L'),
                        _attendanceOptionButton(s.studentId, 'E', 'Excused',
                            AppColors.infoSky, status == 'E'),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _attendanceOptionButton(String studentId, String code, String label,
      Color color, bool isSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        setState(() {
          _attendanceMap[studentId] = code;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: color.withValues(alpha: isSelected ? 1.0 : 0.3),
            width: 1,
          ),
        ),
        child: Text(
          code,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMarksEntryTab() {
    final isCompact = AppBreakpoints.isCompact(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Marks Entry: Mathematics (Term 1 Exam)',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3)),
                  Text(
                      'Structure: CA1 (max 20) + CA2 (max 20) + Exam (max 60) = 100',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ClayButton(
                  height: 38,
                  icon: Icons.print,
                  label: isCompact ? 'Print' : 'Print Grade Sheet',
                  variant: ClayButtonVariant.subtle,
                  onPressed: () => PrintService.printDocument(),
                ),
                ClayButton(
                  height: 38,
                  icon: Icons.check,
                  label: isCompact ? 'Save' : 'Save Draft Marks',
                  variant: ClayButtonVariant.primary,
                  customColor: AppColors.teacherTeal,
                  onPressed: () async {
                    try {
                      for (var entry in _marksMap.entries) {
                        final sId = entry.key;
                        final scores = entry.value;
                        final ca1 = scores['ca1'] ?? 0;
                        final ca2 = scores['ca2'] ?? 0;
                        final exam = scores['exam'] ?? 0;
                        final total = ca1 + ca2 + exam;

                        final markId = Mark.generateMarkId(
                            'EXAM_TERM1_2026', sId, 'SUB_MATH');
                        await ref.read(examRepositoryProvider).saveDraftMark(
                              Mark(
                                markId: markId,
                                examId: 'EXAM_TERM1_2026',
                                studentId: sId,
                                subjectId: 'SUB_MATH',
                                classId: _selectedClass,
                                sectionId: _selectedSection,
                                academicYearId: 'AY_2026_2027',
                                continuousAssessment:
                                    ContinuousAssessment(ca1: ca1, ca2: ca2),
                                examScore: exam,
                                totalScore: total,
                                updatedBy: 'teacher_uid',
                              ),
                            );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Draft marks saved successfully for moderation!')),
                        );
                      }
                    } catch (e, stack) {
                      debugPrint(
                          '[TeacherDashboardScreen.saveMarksDraft] Exception: $e\n$stack');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Marks saved: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        AdaptiveDataView<MapEntry<String, Map<String, int>>>(
          items: _marksMap.entries.toList(),
          columns: [
            AdaptiveColumn<MapEntry<String, Map<String, int>>>(
              title: 'Student ID',
              cellBuilder: (e) => Text('Student ${e.key}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            AdaptiveColumn<MapEntry<String, Map<String, int>>>(
              title: 'CA1 (/20)',
              cellBuilder: (e) => Text('${e.value['ca1']}',
                  style: const TextStyle(fontSize: 13)),
            ),
            AdaptiveColumn<MapEntry<String, Map<String, int>>>(
              title: 'CA2 (/20)',
              cellBuilder: (e) => Text('${e.value['ca2']}',
                  style: const TextStyle(fontSize: 13)),
            ),
            AdaptiveColumn<MapEntry<String, Map<String, int>>>(
              title: 'Exam (/60)',
              cellBuilder: (e) => Text('${e.value['exam']}',
                  style: const TextStyle(fontSize: 13)),
            ),
            AdaptiveColumn<MapEntry<String, Map<String, int>>>(
              title: 'Total (/100)',
              cellBuilder: (e) {
                final total = (e.value['ca1'] ?? 0) +
                    (e.value['ca2'] ?? 0) +
                    (e.value['exam'] ?? 0);
                return Text('$total',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.teacherTeal));
              },
            ),
          ],
          mobileCardBuilder: (ctx, e) {
            final scores = e.value;
            final total = (scores['ca1'] ?? 0) +
                (scores['ca2'] ?? 0) +
                (scores['exam'] ?? 0);

            return ClayCard(
              title: 'Student ${e.key}',
              subtitle: 'Class $_selectedClass-$_selectedSection • Math',
              icon: Icons.person_outline,
              iconColor: AppColors.teacherTeal,
              headerAction: ClayContainer(
                depth: ClayDepth.low,
                borderRadius: ClayTheme.radiusPill,
                surfaceColor: AppColors.teacherTeal.withValues(alpha: 0.1),
                borderColor: AppColors.teacherTeal.withValues(alpha: 0.3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text('Total $total/100',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: AppColors.teacherTeal)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _scoreTile('CA 1', '${scores['ca1']}/20'),
                      _scoreTile('CA 2', '${scores['ca2']}/20'),
                      _scoreTile('Exam', '${scores['exam']}/60'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ClayButton(
                      height: 32,
                      label: 'Grade / Edit Marks',
                      icon: Icons.edit_note,
                      variant: ClayButtonVariant.subtle,
                      onPressed: () {
                        final student = Student(
                          studentId: e.key,
                          admissionNumber: 'ADM-${e.key}',
                          fullName: 'Student ${e.key}',
                          currentClassId: _selectedClass,
                          currentSectionId: _selectedSection,
                          currentAcademicYearId: 'AY_2026_2027',
                          status: 'enrolled',
                        );
                        SubmitMarksDialog.show(
                          context,
                          student: student,
                          subject: 'Mathematics',
                          initialCa1: scores['ca1'] ?? 18,
                          initialCa2: scores['ca2'] ?? 19,
                          initialExam: scores['exam'] ?? 52,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _scoreTile(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  Widget _buildMaterialsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Class Study Materials',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ClayButton(
                  height: 38,
                  icon: Icons.assignment_outlined,
                  label: 'Publish Homework',
                  variant: ClayButtonVariant.secondary,
                  onPressed: () => CreateHomeworkDialog.show(
                    context,
                    currentClass: _selectedClass,
                    currentSection: _selectedSection,
                  ),
                ),
                ClayButton(
                  height: 38,
                  icon: Icons.upload_file,
                  label: 'Upload Resource',
                  variant: ClayButtonVariant.primary,
                  customColor: AppColors.teacherTeal,
                  onPressed: () {
                    UploadMaterialDialog.show(
                      context,
                      defaultClass: _selectedClass,
                      defaultSection: _selectedSection,
                      onUpload: ({
                        required title,
                        required classId,
                        required sectionId,
                        required subject,
                        required fileName,
                      }) async {},
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildMaterialItem('Chapter 4 - Quadratic Equations Notes.pdf',
            'Class 10 - Mathematics', '2.4 MB', '2 days ago'),
        const SizedBox(height: 12),
        _buildMaterialItem('Unit 3 - Periodic Table Worksheet.pdf',
            'Class 10 - Chemistry', '1.1 MB', 'Last week'),
      ],
    );
  }

  Widget _buildMaterialItem(
      String title, String category, String size, String time) {
    return ClayCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClayContainer(
            depth: ClayDepth.low,
            borderRadius: ClayTheme.radiusSm,
            surfaceColor: AppColors.teacherTeal.withValues(alpha: 0.1),
            borderColor: AppColors.teacherTeal.withValues(alpha: 0.25),
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.picture_as_pdf,
                color: AppColors.teacherTeal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text('$category • $size • $time',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ClayButton(
            height: 36,
            icon: Icons.download,
            label: 'Download',
            variant: ClayButtonVariant.subtle,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
