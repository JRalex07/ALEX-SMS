import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../models/attendance_model.dart';
import '../../models/examination_model.dart';
import '../../models/student_model.dart';
import '../../providers/feature_providers.dart';
import '../../providers/auth_providers.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/dialogs/upload_material_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/dialogs/print_preview_dialog.dart';

import '../../shared/widgets/erp_components.dart';
import '../../core/theme/apple_design_system.dart';

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
  String? _selectedExamId;

  // Values are populated only from the current cohort selected by the user.
  // No synthetic student IDs or attendance/marks are seeded into the UI.
  final Map<String, String> _attendanceMap = {};

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile != null) {
      if (profile.assignedClasses.isNotEmpty &&
          !profile.assignedClasses.contains(_selectedClass)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || profile.assignedClasses.contains(_selectedClass)) {
            return;
          }
          setState(() {
            _selectedClass = profile.assignedClasses.first;
            _attendanceMap.clear();
          });
        });
      }
      if (profile.assignedSections.isNotEmpty &&
          !profile.assignedSections.contains(_selectedSection)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || profile.assignedSections.contains(_selectedSection)) {
            return;
          }
          setState(() {
            _selectedSection = profile.assignedSections.first;
            _attendanceMap.clear();
          });
        });
      }
    }
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
    final profile = ref.watch(currentUserProfileProvider).value;
    final assignedClasses = profile?.assignedClasses ?? const <String>[];
    final assignedSections = profile?.assignedSections ?? const <String>[];
    const assignedSubjects = <String>['Mathematics', 'Science'];
    final studentsAsync = ref.watch(classStudentsStreamProvider(
      (classId: _selectedClass, sectionId: _selectedSection),
    ));
    final sessionsAsync = ref.watch(attendanceSessionsStreamProvider(
      (classId: _selectedClass, sectionId: _selectedSection),
    ));
    final examsAsync = ref.watch(examinationsStreamProvider);
    final allSessionsAsync = ref.watch(allAttendanceSessionsStreamProvider);

    final studentCount = studentsAsync.when(
      data: (students) => '${students.length}',
      loading: () => '…',
      error: (_, __) => '—',
    );
    final attendanceValue = sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty || sessions.first.summary == null) return '—';
        return '${sessions.first.summary!.attendancePercentage.toStringAsFixed(1)}%';
      },
      loading: () => '…',
      error: (_, __) => '—',
    );

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todaySubmitted = allSessionsAsync.maybeWhen(
      data: (sessions) => sessions.any((s) =>
          s.classId == _selectedClass &&
          s.sectionId == _selectedSection &&
          s.date == today),
      orElse: () => false,
    );

    final examsCount = examsAsync.maybeWhen(
      data: (exams) => '${exams.length}',
      orElse: () => '—',
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Welcome Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 560;
              final activeBadge = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.teacherTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.teacherTeal.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        color: AppColors.teacherTeal, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Faculty Portal Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teacherTeal,
                      ),
                    ),
                  ],
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.teacherTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school,
                            color: AppColors.teacherTeal, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${profile?.displayName ?? "Teacher"}',
                              style: AppleTypography.title2(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LAV Academy • Faculty & Academic Portal • Assigned: ${assignedClasses.isEmpty ? "No Cohort" : assignedClasses.map((c) => "Class $c").join(", ")}',
                              style: AppleTypography.subheadline(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 12),
                        activeBadge,
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 10),
                    activeBadge,
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // 2. 7 Role Metrics Strip
        ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'Assigned Classes',
              value: '${assignedClasses.length}',
              subtitle: assignedClasses.isEmpty
                  ? 'No cohort assigned yet'
                  : assignedClasses.join(', '),
              icon: Icons.school,
              color: AppColors.teacherTeal,
              trend: 'Staff profile',
            ),
            ErpMetricItem(
              label: 'Assigned Subjects',
              value: '${assignedSubjects.length}',
              subtitle: assignedSubjects.join(', '),
              icon: Icons.menu_book_outlined,
              color: AppColors.brandNavy,
              trend: 'Subject scope',
            ),
            ErpMetricItem(
              label: "Today's Classes",
              value: '${assignedClasses.length} Scheduled',
              subtitle: 'Active daily routine',
              icon: Icons.schedule,
              color: AppColors.infoSky,
              trend: 'Today',
            ),
            ErpMetricItem(
              label: 'Attendance Tasks',
              value: todaySubmitted ? 'Submitted' : 'Pending Today',
              subtitle: 'Class $_selectedClass-$_selectedSection',
              icon: Icons.how_to_reg_outlined,
              color: todaySubmitted
                  ? AppColors.successGreen
                  : AppColors.warningAmber,
              trend: todaySubmitted ? 'Completed' : 'Action needed',
            ),
            ErpMetricItem(
              label: 'Upcoming Exams',
              value: examsCount,
              subtitle: 'Institutional evaluations',
              icon: Icons.quiz_outlined,
              color: AppColors.adminIndigo,
              trend: 'Configured',
            ),
            ErpMetricItem(
              label: 'Selected Cohort',
              value: studentCount,
              subtitle: 'Class $_selectedClass • Section $_selectedSection',
              icon: Icons.people_outline,
              color: AppColors.teacherTeal,
              trend: 'Live roster',
            ),
            ErpMetricItem(
              label: 'Latest Attendance',
              value: attendanceValue,
              subtitle: 'Selected cohort only',
              icon: Icons.bar_chart_outlined,
              color: AppColors.successGreen,
              trend: 'Attendance records',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Primary Quick Actions & Active Cohort Ribbon
        ErpCard(
          title: 'Class Cohort & Primary Actions',
          subtitle:
              'Daily teaching workflows, attendance roll call, homework, and study material management',
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
                spacing: 12,
                runSpacing: 10,
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
                        value: assignedClasses.contains(_selectedClass)
                            ? _selectedClass
                            : null,
                        hint: const Text('No assignment'),
                        items: assignedClasses
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text('Class $value')))
                            .toList(),
                        onChanged: assignedClasses.isEmpty
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedClass = val;
                                    _attendanceMap.clear();
                                  });
                                }
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
                        value: assignedSections.contains(_selectedSection)
                            ? _selectedSection
                            : null,
                        hint: const Text('No assignment'),
                        items: assignedSections
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text('Section $value')))
                            .toList(),
                        onChanged: assignedSections.isEmpty
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedSection = val;
                                    _attendanceMap.clear();
                                  });
                                }
                              },
                      ),
                    ),
                  ),
                  ErpButton(
                    icon: Icons.how_to_reg,
                    label: 'Mark Attendance',
                    color: AppColors.teacherTeal,
                    onPressed: () => setState(() => _currentNavIndex = 1),
                  ),
                  ErpButton(
                    icon: Icons.assignment_add,
                    label: 'Create Homework',
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
                    label: 'Upload Material',
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
                        required fileBytes,
                      }) async {
                        final prof = ref.read(currentUserProfileProvider).value;
                        if (prof == null) {
                          throw Exception(
                              'Your staff session has expired. Sign in again.');
                        }
                        final ext = fileName.contains('.')
                            ? fileName.split('.').last.toLowerCase()
                            : '';
                        const contentTypes = {
                          'pdf': 'application/pdf',
                          'zip': 'application/zip',
                          'png': 'image/png',
                          'jpg': 'image/jpeg',
                          'jpeg': 'image/jpeg',
                          'webp': 'image/webp',
                          'doc': 'application/msword',
                          'docx':
                              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                        };
                        final contentType = contentTypes[ext];
                        if (contentType == null) {
                          throw Exception('This file type is not supported.');
                        }
                        final safeName = fileName.replaceAll(
                            RegExp(r'[^A-Za-z0-9._-]'), '_');
                        final materialRef = FirebaseFirestore.instance
                            .collection('study_materials')
                            .doc();
                        final storagePath =
                            'study_materials/$classId/$sectionId/${materialRef.id}_$safeName';
                        final storageRef =
                            FirebaseStorage.instance.ref(storagePath);
                        try {
                          await storageRef.putData(
                            fileBytes,
                            SettableMetadata(
                                contentType: contentType,
                                customMetadata: {
                                  'uploadedBy': prof.uid,
                                  'schoolId': 'SCH_001',
                                  'classId': classId,
                                  'sectionId': sectionId,
                                }),
                          );
                          final downloadUrl = await storageRef.getDownloadURL();
                          await materialRef.set({
                            'materialId': materialRef.id,
                            'schoolId': 'SCH_001',
                            'title': title,
                            'classId': classId,
                            'sectionId': sectionId,
                            'subjectId': subject,
                            'fileName': fileName,
                            'storagePath': storagePath,
                            'downloadUrl': downloadUrl,
                            'uploadedBy': prof.uid,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        } catch (_) {
                          try {
                            await storageRef.delete();
                          } catch (_) {}
                          rethrow;
                        }
                      },
                    ),
                  ),
                  ErpButton(
                    icon: Icons.edit_note,
                    label: 'Enter Marks',
                    isPrimary: false,
                    color: AppColors.brandNavy,
                    onPressed: () => setState(() => _currentNavIndex = 2),
                  ),
                  ErpButton(
                    icon: Icons.print,
                    label: 'Print Register',
                    isPrimary: false,
                    color: AppColors.textSecondary,
                    onPressed: () {
                      final students = (studentsAsync.value ?? [])
                          .where((student) => student.status == 'enrolled')
                          .toList();
                      PrintPreviewDialog.showAttendanceRegister(
                        context,
                        classId: _selectedClass,
                        sectionId: _selectedSection,
                        date:
                            DateTime.now().toLocal().toString().split(' ').first,
                        sessions: const [],
                        students: students,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 1: Today's Timetable
        ErpCard(
          title: "Today's Timetable & Teaching Schedule",
          subtitle:
              'Daily periods, assigned subject instruction, and room allocations',
          icon: Icons.schedule,
          iconColor: AppColors.brandNavy,
          padding: EdgeInsets.zero,
          child: assignedClasses.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                        'No classes currently assigned to your timetable schedule.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : Column(
                  children: List.generate(assignedClasses.length, (idx) {
                    final cls = assignedClasses[idx];
                    final sec = assignedSections.length > idx
                        ? assignedSections[idx]
                        : 'A';
                    final period = idx + 1;
                    final startTime = '${8 + idx}:30 AM';
                    final endTime = '${9 + idx}:15 AM';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.borderLight, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.teacherTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'P$period',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.teacherTeal),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Class $cls - Section $sec • Mathematics',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                Text(
                                    '$startTime – $endTime • Room ${100 + period}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const ErpStatusBadge(
                            label: 'SCHEDULED',
                            backgroundColor: AppColors.infoBg,
                            textColor: AppColors.infoSky,
                            icon: Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 8),
                          ErpButton(
                            label: 'Take Attendance',
                            isDense: true,
                            color: AppColors.teacherTeal,
                            onPressed: () {
                              setState(() {
                                _selectedClass = cls;
                                _selectedSection = sec;
                                _currentNavIndex = 1;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
        const SizedBox(height: 20),

        // Section 2: My Classes
        ErpCard(
          title: 'My Classes & Cohorts',
          subtitle:
              'Assigned classes, student enrollment rosters, and cohort actions',
          icon: Icons.class_outlined,
          iconColor: AppColors.teacherTeal,
          padding: EdgeInsets.zero,
          child: assignedClasses.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                        'No classes currently assigned to your faculty profile.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : Column(
                  children: assignedClasses.map((cls) {
                    final isCurrent = cls == _selectedClass;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.borderLight, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.school,
                              size: 20,
                              color: isCurrent
                                  ? AppColors.teacherTeal
                                  : AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Class $cls Cohort',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const Text('Curriculum: Central Board • Term 1',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          ErpButton(
                            label: isCurrent ? 'Active Cohort' : 'Open Class',
                            isDense: true,
                            isPrimary: !isCurrent,
                            color: AppColors.teacherTeal,
                            onPressed: () {
                              setState(() {
                                _selectedClass = cls;
                                _attendanceMap.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),

        // Section 3: Attendance Tasks
        ErpCard(
          title: 'Attendance Tasks',
          subtitle:
              'Daily roll call submission requirements for your assigned cohorts',
          icon: Icons.how_to_reg_outlined,
          iconColor: AppColors.warningAmber,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class $_selectedClass-$_selectedSection Roll Call',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        todaySubmitted
                            ? 'Attendance for today has been recorded.'
                            : 'Attendance roll call has not been submitted for today.',
                        style: TextStyle(
                            fontSize: 12,
                            color: todaySubmitted
                                ? AppColors.successGreen
                                : AppColors.warningAmber,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ErpButton(
                icon: Icons.how_to_reg,
                label: todaySubmitted ? 'View Records' : 'Mark Roll Call',
                color: AppColors.teacherTeal,
                onPressed: () => setState(() => _currentNavIndex = 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 4: Upcoming Examinations
        ErpCard(
          title: 'Upcoming Examinations',
          subtitle:
              'Institutional examinations linked to your assigned curriculum',
          icon: Icons.quiz_outlined,
          iconColor: AppColors.adminIndigo,
          padding: EdgeInsets.zero,
          child: examsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading exams: $err',
                  style: const TextStyle(color: AppColors.dangerRed)),
            ),
            data: (exams) {
              if (exams.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No examinations currently configured.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }
              return Column(
                children: exams.map((ex) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.borderLight, width: 1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.quiz,
                            size: 20, color: AppColors.adminIndigo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(
                                'Exam ID: ${ex.examId} • Status: ${ex.isPublished ? "PUBLISHED" : (ex.isLocked ? "LOCKED" : "OPEN FOR MARKS")}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ErpButton(
                          label: 'Enter Marks',
                          isDense: true,
                          color: AppColors.teacherTeal,
                          onPressed: () {
                            setState(() {
                              _selectedExamId = ex.examId;
                              _currentNavIndex = 2;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Section 5: Recent Assignments
        ErpCard(
          title: 'Recent Homework & Assignments',
          subtitle:
              'Assigned coursework, problem sets, and submission tracking',
          icon: Icons.assignment_outlined,
          iconColor: AppColors.teacherTeal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment,
                        size: 20, color: AppColors.teacherTeal),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Class 10 Homework • Quadratic Equations Practice',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('Target: Class 10-A • Status: PUBLISHED',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ErpButton(
                      label: 'Create Homework',
                      isDense: true,
                      color: AppColors.teacherTeal,
                      onPressed: () => CreateHomeworkDialog.show(
                        context,
                        currentClass: _selectedClass,
                        currentSection: _selectedSection,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 6: Study Materials
        ErpCard(
          title: 'Learning & Study Materials',
          subtitle:
              'Curriculum notes, references, and digital learning assets for students',
          icon: Icons.folder_shared_outlined,
          iconColor: AppColors.brandNavy,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 450),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Digital Curriculum Materials',
                        style:
                            TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(
                        'Upload syllabus documents and references for enrolled students',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              ErpButton(
                icon: Icons.folder_open,
                label: 'Manage Materials',
                color: AppColors.teacherTeal,
                onPressed: () => setState(() => _currentNavIndex = 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 7: Marks Entry Tasks
        ErpCard(
          title: 'Marks Entry Tasks',
          subtitle:
              'Evaluation tasks with outstanding continuous assessments or exam scores',
          icon: Icons.edit_note_outlined,
          iconColor: AppColors.teacherTeal,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 450),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Continuous Assessment Entry',
                        style:
                            TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('Record CA1, CA2 and Term scores for Class 10-A',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              ErpButton(
                icon: Icons.grade,
                label: 'Open Marks Grid',
                color: AppColors.brandNavy,
                onPressed: () => setState(() => _currentNavIndex = 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    final today = DateTime.now().toString().substring(0, 10);
    final studentsAsync = ref.watch(classStudentsStreamProvider(
        (classId: _selectedClass, sectionId: _selectedSection)));
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
                ErpButton(
                  icon: Icons.print,
                  label: isCompact ? 'Register' : 'Print Register',
                  isPrimary: false,
                  color: AppColors.teacherTeal,
                  isDense: isCompact,
                  onPressed: () {
                    final students = (studentsAsync.value ?? [])
                        .where((student) => student.status == 'enrolled')
                        .toList();
                    PrintPreviewDialog.showAttendanceRegister(
                      context,
                      classId: _selectedClass,
                      sectionId: _selectedSection,
                      date:
                          DateTime.now().toLocal().toString().split(' ').first,
                      sessions: const [],
                      students: students,
                    );
                  },
                ),
                ErpButton(
                  icon: Icons.save,
                  label: isCompact ? 'Submit' : 'Save & Submit Roll Call',
                  color: AppColors.teacherTeal,
                  isDense: isCompact,
                  onPressed: () async {
                    final students = (studentsAsync.value ?? [])
                        .where((student) => student.status == 'enrolled')
                        .toList();
                    final profile = ref.read(currentUserProfileProvider).value;
                    if (students.isEmpty ||
                        students.any((student) =>
                            !_attendanceMap.containsKey(student.studentId))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Mark Present, Absent, Late or Excused for every student before saving.')),
                      );
                      return;
                    }
                    if (profile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Your staff profile is still loading. Please retry.')),
                      );
                      return;
                    }
                    final sessionId =
                        'SES_${_selectedClass}_${_selectedSection}_${today.replaceAll('-', '')}_${profile.uid}';
                    try {
                      final sessions = await ref
                          .read(attendanceRepositoryProvider)
                          .getSessionsStream(
                              classId: _selectedClass,
                              sectionId: _selectedSection)
                          .first;
                      if (!mounted) return;
                      AttendanceSession? existingSession;
                      for (final session in sessions) {
                        if (session.sessionId == sessionId) {
                          existingSession = session;
                          break;
                        }
                      }
                      if (existingSession != null &&
                          (existingSession.isApproved ||
                              existingSession.isFinalized)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'This attendance session has already been approved or finalized.')));
                        return;
                      }
                      if (existingSession == null) {
                        await ref
                            .read(attendanceRepositoryProvider)
                            .createDraftSession(AttendanceSession(
                              sessionId: sessionId,
                              classId: _selectedClass,
                              sectionId: _selectedSection,
                              date: today,
                              academicYearId: 'AY_2026_2027',
                              markedBy: profile.uid,
                            ));
                      }

                      for (final student in students) {
                        await ref
                            .read(attendanceRepositoryProvider)
                            .saveAttendanceRecord(
                              sessionId: sessionId,
                              studentId: student.studentId,
                              status: _attendanceMap[student.studentId]!,
                            );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Attendance draft saved successfully. It has not been approved or finalized yet.')),
                        );
                      }
                    } catch (e, stack) {
                      debugPrint(
                          '[TeacherDashboardScreen.saveAttendanceDraft] Exception: $e\n$stack');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Could not save attendance: ${e.toString()}')),
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
          error: (err, _) => ErpCard(
            child: Text('Error loading class students: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (allStudents) {
            final students = allStudents
                .where((student) => student.status == 'enrolled')
                .toList();
            if (students.isEmpty) {
              return ErpCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No Students Enrolled',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No students enrolled in Class $_selectedClass - Section $_selectedSection.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ErpCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = students[index];
                  final status = _attendanceMap[s.studentId];

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
    final studentsAsync = ref.watch(classStudentsStreamProvider(
      (classId: _selectedClass, sectionId: _selectedSection),
    ));
    final examsAsync = ref.watch(examinationsStreamProvider);
    final isCompact = AppBreakpoints.isCompact(context);

    return examsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ListView(padding: const EdgeInsets.all(20), children: [
        ErpCard(
            child: Text(
                'Unable to load examinations from the school database: $error',
                style: const TextStyle(color: AppColors.dangerRed))),
      ]),
      data: (allExams) {
        final availableExams = allExams
            .where((exam) => !exam.isLocked && !exam.isPublished)
            .toList();
        final selectedMatches = availableExams
            .where((exam) => exam.examId == _selectedExamId)
            .toList();
        final activeExam = selectedMatches.isNotEmpty
            ? selectedMatches.first
            : (availableExams.isNotEmpty ? availableExams.first : null);
        if (activeExam == null) {
          return ListView(padding: const EdgeInsets.all(20), children: [
            ErpCard(
              title: 'Draft Assessment Marks',
              subtitle: 'Class $_selectedClass-$_selectedSection',
              icon: Icons.edit_note_outlined,
              iconColor: AppColors.teacherTeal,
              child: const Text(
                  'There are no open examinations configured in the school database. Ask the school administrator to create or unlock an examination before entering marks.'),
            ),
          ]);
        }

        final marksAsync = ref.watch(classMarksStreamProvider((
          subjectId: 'SUB_MATH',
          classId: _selectedClass,
          sectionId: _selectedSection,
        )));

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            ErpCard(
              title: 'Draft Assessment Marks',
              subtitle:
                  'Class $_selectedClass-$_selectedSection • Mathematics • CA1 /20 + CA2 /20 + Exam /60',
              icon: Icons.edit_note_outlined,
              iconColor: AppColors.teacherTeal,
              headerTrailing: ErpButton(
                icon: Icons.print,
                label: isCompact ? 'Print' : 'Print grade sheet',
                isPrimary: false,
                isDense: true,
                color: AppColors.teacherTeal,
                onPressed: () {
                  final studentList = studentsAsync.valueOrNull ?? [];
                  final firstStudent = studentList.isNotEmpty
                      ? studentList.first
                      : Student(
                          studentId: 'STU_SAMPLE',
                          admissionNumber: 'ADM-2026-001',
                          fullName:
                              'Class $_selectedClass-$_selectedSection Grade Sheet',
                          currentClassId: _selectedClass,
                          currentSectionId: _selectedSection,
                          currentAcademicYearId: 'AY-2026-2027',
                          status: 'enrolled',
                          enrollmentDate: DateTime.now(),
                        );

                  PrintPreviewDialog.showReportCard(
                    context,
                    student: firstStudent,
                    examination: activeExam,
                    marks: marksAsync.valueOrNull ?? const [],
                  );
                },
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose an examination and student to enter or update marks. Saves are unpublished drafts; published results are not changed here.',
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: activeExam.examId,
                      decoration: const InputDecoration(
                          labelText: 'Examination',
                          border: OutlineInputBorder()),
                      items: availableExams
                          .map((exam) => DropdownMenuItem<String>(
                                value: exam.examId,
                                child: Text(
                                    '${exam.title}${exam.term.isNotEmpty ? ' • ${exam.term}' : ''}'),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedExamId = value),
                    ),
                  ]),
            ),
            const SizedBox(height: 16),
            studentsAsync.when(
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator())),
              error: (error, _) => ErpCard(
                  child: Text('Unable to load the selected cohort: $error',
                      style: const TextStyle(color: AppColors.dangerRed))),
              data: (students) {
                if (students.isEmpty) {
                  return const ErpCard(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline,
                                size: 40, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'No Students in This Cohort',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'There are no student records for this assigned cohort. Marks cannot be entered until students are enrolled.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return marksAsync.when(
                  loading: () => const Center(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator())),
                  error: (error, _) => ErpCard(
                      child: Text('Unable to load saved draft marks: $error',
                          style: const TextStyle(color: AppColors.dangerRed))),
                  data: (marks) {
                    final marksByStudent = <String, Mark>{
                      for (final mark in marks
                          .where((mark) => mark.examId == activeExam.examId))
                        mark.studentId: mark,
                    };
                    return ErpCard(
                      title: 'Student Marks Register',
                      subtitle:
                          '${students.length} students • ${activeExam.title} • Existing records loaded from the marks collection',
                      icon: Icons.fact_check_outlined,
                      iconColor: AppColors.teacherTeal,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < students.length;
                              index++) ...[
                            _buildStudentMarkRow(
                                students[index],
                                marksByStudent[students[index].studentId],
                                index,
                                examId: activeExam.examId),
                            if (index < students.length - 1)
                              const Divider(
                                  height: 1, color: AppColors.borderLight),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentMarkRow(Student student, Mark? mark, int index,
      {required String examId}) {
    final total = mark?.totalScore;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.teacherTeal.withValues(alpha: 0.10),
            child: Text('${index + 1}',
                style: const TextStyle(
                    color: AppColors.teacherTeal, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                    '${student.admissionNumber} • ${mark == null ? 'No draft marks' : 'CA1 ${mark.continuousAssessment.ca1}/20 · CA2 ${mark.continuousAssessment.ca2}/20 · Exam ${mark.examScore}/60'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (mark != null)
            ErpStatusBadge(
              label: mark.isPublished
                  ? 'PUBLISHED'
                  : mark.isApproved
                      ? 'APPROVED'
                      : 'DRAFT',
              backgroundColor:
                  mark.isPublished ? AppColors.successBg : AppColors.infoBg,
              textColor:
                  mark.isPublished ? AppColors.successGreen : AppColors.infoSky,
              icon: mark.isPublished ? Icons.verified : Icons.edit_note,
            )
          else
            const ErpStatusBadge(
                label: 'NOT ENTERED',
                backgroundColor: AppColors.warningBg,
                textColor: AppColors.warningAmber,
                icon: Icons.pending_actions),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Enter or edit marks',
            icon: const Icon(Icons.edit_outlined, color: AppColors.teacherTeal),
            onPressed: mark?.isPublished == true
                ? null
                : () => SubmitMarksDialog.show(
                      context,
                      student: student,
                      subject: 'Mathematics',
                      examId: examId,
                      subjectId: 'SUB_MATH',
                      initialCa1: mark?.continuousAssessment.ca1 ?? 0,
                      initialCa2: mark?.continuousAssessment.ca2 ?? 0,
                      initialExam: mark?.examScore ?? 0,
                    ),
          ),
          if (total != null) ...[
            const SizedBox(width: 4),
            Text('$total/100',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.teacherTeal)),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialsTab() {
    final profile = ref.watch(currentUserProfileProvider).value;
    final user = profile;
    final materialsQuery = FirebaseFirestore.instance
        .collection('study_materials')
        .where('classId', isEqualTo: _selectedClass)
        .where('sectionId', isEqualTo: _selectedSection);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        ErpCard(
          title: 'Class Study Materials',
          subtitle:
              'Files are uploaded to restricted Firebase Storage paths and indexed in Firestore for the selected class and section.',
          icon: Icons.folder_copy_outlined,
          iconColor: AppColors.teacherTeal,
          headerTrailing: ErpButton(
            icon: Icons.upload_file,
            label: 'Upload resource',
            isDense: true,
            color: AppColors.teacherTeal,
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
                required fileBytes,
              }) async {
                final profile = ref.read(currentUserProfileProvider).value;
                if (profile == null) {
                  throw Exception(
                      'Your staff session has expired. Sign in again.');
                }
                final ext = fileName.contains('.')
                    ? fileName.split('.').last.toLowerCase()
                    : '';
                const contentTypes = {
                  'pdf': 'application/pdf',
                  'zip': 'application/zip',
                  'png': 'image/png',
                  'jpg': 'image/jpeg',
                  'jpeg': 'image/jpeg',
                  'webp': 'image/webp',
                  'doc': 'application/msword',
                  'docx':
                      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                };
                final contentType = contentTypes[ext];
                if (contentType == null) {
                  throw Exception('This file type is not supported.');
                }
                final safeName =
                    fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
                final materialRef = FirebaseFirestore.instance
                    .collection('study_materials')
                    .doc();
                final storagePath =
                    'study_materials/$classId/$sectionId/${materialRef.id}_$safeName';
                final storageRef = FirebaseStorage.instance.ref(storagePath);
                try {
                  await storageRef.putData(
                      fileBytes,
                      SettableMetadata(
                          contentType: contentType,
                          customMetadata: {
                            'uploadedBy': profile.uid,
                            'schoolId': 'SCH_001',
                            'classId': classId,
                            'sectionId': sectionId,
                          }));
                  final downloadUrl = await storageRef.getDownloadURL();
                  await materialRef.set({
                    'materialId': materialRef.id,
                    'schoolId': 'SCH_001',
                    'title': title,
                    'classId': classId,
                    'sectionId': sectionId,
                    'subjectId': subject,
                    'fileName': fileName,
                    'storagePath': storagePath,
                    'downloadUrl': downloadUrl,
                    'uploadedBy': profile.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } catch (_) {
                  try {
                    await storageRef.delete();
                  } catch (_) {}
                  rethrow;
                }
              },
            ),
          ),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: user == null
                ? const Stream.empty()
                : materialsQuery.snapshots(),
            builder: (context, snapshot) {
              if (user == null) {
                return const Text(
                    'Load your staff profile to view class resources.');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Text('Unable to load materials: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.dangerRed));
              }
              final docs = [...?snapshot.data?.docs];
              docs.sort((a, b) {
                final aDate = a.data()['createdAt'];
                final bDate = b.data()['createdAt'];
                final aMillis =
                    aDate is Timestamp ? aDate.millisecondsSinceEpoch : 0;
                final bMillis =
                    bDate is Timestamp ? bDate.millisecondsSinceEpoch : 0;
                return bMillis.compareTo(aMillis);
              });
              if (docs.isEmpty) {
                return const ErpCard(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_outlined,
                              size: 40, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'No Class Materials Yet',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Uploaded study resources for this assigned class and section will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Column(children: [
                for (var i = 0; i < docs.length; i++) ...[
                  _buildMaterialItem(
                    docs[i].data()['title']?.toString() ??
                        docs[i].data()['fileName']?.toString() ??
                        'Untitled resource',
                    docs[i].data()['classId']?.toString() == null
                        ? 'Class $_selectedClass'
                        : 'Class ${docs[i].data()['classId']} • Section ${docs[i].data()['sectionId'] ?? _selectedSection}',
                    docs[i].data()['subjectId']?.toString() ?? '',
                    docs[i].data()['fileName']?.toString() ?? 'Document',
                    docs[i].data()['downloadUrl']?.toString() ?? '',
                  ),
                  if (i < docs.length - 1) const SizedBox(height: 10),
                ],
              ]);
            },
          ),
        ),
        const SizedBox(height: 12),
        ErpCard(
          title: 'Homework and Assignments',
          subtitle:
              'Create assignments for the selected cohort using the authorized homework workflow.',
          icon: Icons.assignment_outlined,
          iconColor: AppColors.teacherTeal,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ErpButton(
              icon: Icons.add_task,
              label: 'Create homework',
              color: AppColors.teacherTeal,
              onPressed: () => CreateHomeworkDialog.show(context,
                  currentClass: _selectedClass,
                  currentSection: _selectedSection),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialItem(String title, String category, String subject,
      String fileName, String downloadUrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.teacherTeal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.description_outlined,
                color: AppColors.teacherTeal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 3),
              Text('$category • $subject',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(fileName,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
          IconButton(
            tooltip: 'Copy secure download link',
            icon: const Icon(Icons.link, color: AppColors.teacherTeal),
            onPressed: downloadUrl.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: downloadUrl));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Download link copied to clipboard.')));
                    }
                  },
          ),
        ],
      ),
    );
  }
}
