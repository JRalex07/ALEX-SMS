import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../models/student_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../shared/dialogs/report_card_dialog.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

class StudentsResourceScreen extends ConsumerStatefulWidget {
  const StudentsResourceScreen({super.key});

  @override
  ConsumerState<StudentsResourceScreen> createState() =>
      _StudentsResourceScreenState();
}

class _StudentsResourceScreenState
    extends ConsumerState<StudentsResourceScreen> {
  String _searchQuery = '';
  String _filterClass = 'All';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final isParent = role == UserRoles.parentGuardian;

    // Use authentic providers based on role
    final AsyncValue<List<Student>> studentsAsync = isParent
        ? ref.watch(parentLinkedChildrenProvider)
        : ref.watch(studentsStreamProvider);

    return ResponsiveScaffold(
      title: isParent ? 'Linked Student Profiles' : 'Student Directory',
      currentRoute: '/students',
      body: studentsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.dangerRed),
                const SizedBox(height: 16),
                const Text(
                  'Error loading student records',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        data: (allStudents) {
          final visibleStudents = allStudents.where((s) {
            final matchesQuery =
                s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    s.admissionNumber
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
            final matchesClass =
                _filterClass == 'All' || s.currentClassId == _filterClass;
            return matchesQuery && matchesClass;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (!isParent) ...[
                // Staff Search & Filter Header
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText:
                                  'Search by student name or admission number...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _filterClass,
                          items: const [
                            DropdownMenuItem(
                                value: 'All', child: Text('All Classes')),
                            DropdownMenuItem(
                                value: '10', child: Text('Class 10')),
                            DropdownMenuItem(
                                value: '9', child: Text('Class 9')),
                            DropdownMenuItem(
                                value: '8', child: Text('Class 8')),
                            DropdownMenuItem(
                                value: '7', child: Text('Class 7')),
                          ],
                          onChanged: (v) => setState(() => _filterClass = v!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.parentBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.parentBlue.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 20, color: AppColors.parentBlue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Displaying verified students linked to your registered parent guardian account.',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.parentBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Student Records Table
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${visibleStudents.length} Students Listed',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          if (!isParent)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Export Directory (CSV)'),
                              onPressed: () =>
                                  DataExportService.exportStudentsCsv(
                                      visibleStudents),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (visibleStudents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No student records found matching current criteria.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleStudents.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: AppColors.borderLight),
                          itemBuilder: (ctx, idx) {
                            final s = visibleStudents[idx];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.brandNavy.withValues(alpha: 0.1),
                                child: Text(
                                  s.fullName.isNotEmpty
                                      ? s.fullName.substring(0, 1)
                                      : 'S',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandNavy),
                                ),
                              ),
                              title: Text(s.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              subtitle: Text(
                                  'Adm: ${s.admissionNumber} • Class ${s.currentClassId}-${s.currentSectionId}'),
                              trailing: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward, size: 14),
                                label: const Text('View Record'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandNavy,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () =>
                                    context.go('/students/${s.studentId}'),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Detail view for /students/:studentId
class StudentDetailResourceScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailResourceScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;

    // Strict Authorization Check: If user is parent_guardian, enforce studentId is in wardStudentIds!
    if (role == UserRoles.parentGuardian) {
      final wardIds = user?.wardStudentIds ?? [];
      if (!wardIds.contains(studentId)) {
        return const ResponsiveScaffold(
          title: 'Access Denied',
          currentRoute: '/students',
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gpp_bad, size: 48, color: AppColors.dangerRed),
                  SizedBox(height: 16),
                  Text('403 Forbidden: Unlinked Student Record',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text(
                    'You are not authorized to view student records outside your verified parent guardian ward relationship.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final studentAsync = ref.watch(studentByIdProvider(studentId));

    return studentAsync.when(
      loading: () => const ResponsiveScaffold(
        title: 'Loading Student Record...',
        currentRoute: '/students',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => ResponsiveScaffold(
        title: 'Error',
        currentRoute: '/students',
        body: Center(
          child: Text('Error loading student: $err',
              style: const TextStyle(color: AppColors.dangerRed)),
        ),
      ),
      data: (student) {
        if (student == null) {
          return ResponsiveScaffold(
            title: 'Student Not Found',
            currentRoute: '/students',
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No record found for student ID: $studentId'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/students'),
                    child: const Text('Back to Students'),
                  ),
                ],
              ),
            ),
          );
        }

        return ResponsiveScaffold(
          title: 'Student Profile: ${student.fullName}',
          currentRoute: '/students',
          actions: [
            IconButton(
              tooltip: 'Back to Students List',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/students'),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;
                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppColors.brandNavy
                                          .withValues(alpha: 0.1),
                                      child: Text(
                                        student.fullName.isNotEmpty
                                            ? student.fullName.substring(0, 1)
                                            : 'S',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.brandNavy),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.fullName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Admission: ${student.admissionNumber} • Class ${student.currentClassId}-${student.currentSectionId}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                StatusBadge.success('Enrolled'),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor:
                                    AppColors.brandNavy.withValues(alpha: 0.1),
                                child: Text(
                                  student.fullName.isNotEmpty
                                      ? student.fullName.substring(0, 1)
                                      : 'S',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandNavy),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Admission: ${student.admissionNumber} • Class ${student.currentClassId}-${student.currentSectionId}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              StatusBadge.success('Enrolled'),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 32, color: AppColors.borderLight),
                      const Text('Institutional Demographic Details',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text(
                          'Blood Group: ${student.bloodGroup ?? "Not Recorded"}'),
                      const SizedBox(height: 6),
                      Text(
                          'Emergency Contact: ${student.emergencyContact ?? "Not Provided"}'),
                      const SizedBox(height: 6),
                      Text(
                          'Residential Address: ${student.address ?? "Not Provided"}'),
                      if (student.medicalNotes != null &&
                          student.medicalNotes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Medical Notes: ${student.medicalNotes}'),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 16),
                        label:
                            const Text('Preview / Print Academic Report Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandNavy,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => ReportCardDialog.show(
                          context,
                          student: student,
                          marks: const [],
                          academicYear: student.currentAcademicYearId,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
