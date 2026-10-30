import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../models/student_model.dart';
import '../../models/examination_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

class StudentsResourceScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const StudentsResourceScreen({super.key, this.initialTab});

  @override
  ConsumerState<StudentsResourceScreen> createState() =>
      _StudentsResourceScreenState();
}

class _StudentsResourceScreenState
    extends ConsumerState<StudentsResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _filterClass = 'All';

  final List<String> _tabs = [
    'All Students',
    'Transfers',
    'Promotions',
    'Archives',
    'Guardians',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'transfers':
          initialIndex = 1;
          break;
        case 'promotions':
          initialIndex = 2;
          break;
        case 'archives':
          initialIndex = 3;
          break;
        case 'guardians':
        case 'link-guardians':
          initialIndex = 4;
          break;
        default:
          initialIndex = 0;
      }
    }
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void didUpdateWidget(covariant StudentsResourceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      int targetIndex = 0;
      switch (widget.initialTab) {
        case 'transfers':
          targetIndex = 1;
          break;
        case 'promotions':
          targetIndex = 2;
          break;
        case 'archives':
          targetIndex = 3;
          break;
        case 'guardians':
        case 'link-guardians':
          targetIndex = 4;
          break;
        default:
          targetIndex = 0;
      }
      if (_tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
      title: isParent ? 'Linked Student Profiles' : 'Student Management',
      currentRoute: AppRoutes.students,
      actions: [
        if (!isParent) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Transfer Student'),
            onPressed: () => TransferStudentDialog.show(context),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Add Student'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.go(AppRoutes.admissionsNew),
          ),
          const SizedBox(width: 8),
        ],
      ],
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
          if (isParent) {
            return _buildParentStudentDirectory(allStudents);
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.brandNavy,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.brandNavy,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStaffDirectoryTab(allStudents),
                    _buildTransfersTab(allStudents),
                    _buildPromotionsTab(allStudents),
                    _buildArchivesTab(allStudents),
                    _buildGuardiansTab(allStudents),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParentStudentDirectory(List<Student> students) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.parentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.parentBlue.withValues(alpha: 0.2)),
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
        _buildStudentCardsList(students, isParent: true),
      ],
    );
  }

  Widget _buildStaffDirectoryTab(List<Student> allStudents) {
    final filtered = allStudents.where((s) {
      final matchesQuery = s.fullName
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          s.admissionNumber
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesClass =
          _filterClass == 'All' || s.currentClassId == _filterClass;
      return matchesQuery && matchesClass;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildFilterHeader(),
        const SizedBox(height: 16),
        _buildStudentCardsList(filtered, isParent: false),
      ],
    );
  }

  Widget _buildTransfersTab(List<Student> students) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Class & Section Transfers Desk',
          subtitle:
              'Transfer enrolled students between classes or sections with authoritative audit logging',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Execute Cohort or Section Transfer',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text(
                      'Authoritatively updates student record and invalidates teacher cohort caches.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Initiate Transfer'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandNavy),
                  onPressed: () => TransferStudentDialog.show(context),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ErpCard(
          title: 'Currently Enrolled Cohorts',
          subtitle: 'Active students available for transfer processing',
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.take(10).length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.borderLight),
            itemBuilder: (ctx, idx) {
              final s = students[idx];
              return ListTile(
                title: Text(s.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    'Adm: ${s.admissionNumber} • Current: Class ${s.currentClassId}-${s.currentSectionId}'),
                trailing: OutlinedButton(
                  onPressed: () => TransferStudentDialog.show(context),
                  child: const Text('Transfer'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionsTab(List<Student> students) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Annual Student Promotion Engine',
          subtitle:
              'Batch progression of classes from AY 2026-2027 to next academic year',
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Promotion moves students who meet passing criteria to the next standard (e.g. Class 9 -> Class 10).',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildPromotionStep('Class 6 → 7', 32),
                    _buildPromotionStep('Class 7 → 8', 28),
                    _buildPromotionStep('Class 8 → 9', 30),
                    _buildPromotionStep('Class 9 → 10', 35),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionStep(String label, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('$count Eligible Students',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildArchivesTab(List<Student> students) {
    final archived = students
        .where((s) => s.status == 'withdrawn' || s.status == 'archived')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Student Status & Historical Archives (${archived.length})',
          subtitle: 'Withdrawn, alumni, and transferred-out student archives',
          child: archived.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No archived or withdrawn student records for current session.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: archived.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final s = archived[idx];
                    return ListTile(
                      title: Text(s.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Status: ${s.status.toUpperCase()}'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGuardiansTab(List<Student> students) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Parent / Guardian Directory & Linkages',
          subtitle:
              'Verified phone relationships linking guardians to student wards',
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.borderLight),
            itemBuilder: (ctx, idx) {
              final s = students[idx];
              final hasGuardian = s.guardianUserIds.isNotEmpty;
              return ListTile(
                title: Text(s.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Adm: ${s.admissionNumber} • Emergency: ${s.emergencyContact ?? "None"}\n'
                  'Guardians Linked: ${hasGuardian ? s.guardianUserIds.length : "None (Pending)"}',
                ),
                trailing: OutlinedButton.icon(
                  icon: const Icon(Icons.link, size: 14),
                  label: const Text('Manage Link'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Guardian linkage desk active for ${s.fullName}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    return Card(
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
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by student name or admission number...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _filterClass,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Classes')),
                DropdownMenuItem(value: '10', child: Text('Class 10')),
                DropdownMenuItem(value: '9', child: Text('Class 9')),
                DropdownMenuItem(value: '8', child: Text('Class 8')),
                DropdownMenuItem(value: '7', child: Text('Class 7')),
                DropdownMenuItem(value: '6', child: Text('Class 6')),
              ],
              onChanged: (v) => setState(() => _filterClass = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCardsList(List<Student> visibleStudents,
      {required bool isParent}) {
    return Card(
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
                        DataExportService.exportStudentsCsv(visibleStudents),
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
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (ctx, idx) {
                  final s = visibleStudents[idx];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.brandNavy.withValues(alpha: 0.1),
                      child: Text(
                        s.fullName.isNotEmpty ? s.fullName.substring(0, 1) : 'S',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandNavy),
                      ),
                    ),
                    title: Text(s.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    subtitle: Text(
                        'Adm: ${s.admissionNumber} • Class ${s.currentClassId}-${s.currentSectionId}'),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text('View Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => context.go('/students/${s.studentId}'),
                    ),
                  );
                },
              ),
          ],
        ),
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
          currentRoute: AppRoutes.students,
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
        currentRoute: AppRoutes.students,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => ResponsiveScaffold(
        title: 'Error',
        currentRoute: AppRoutes.students,
        body: Center(
          child: Text('Error loading student: $err',
              style: const TextStyle(color: AppColors.dangerRed)),
        ),
      ),
      data: (student) {
        if (student == null) {
          return ResponsiveScaffold(
            title: 'Student Not Found',
            currentRoute: AppRoutes.students,
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
                    onPressed: () => context.go(AppRoutes.students),
                    child: const Text('Back to Students'),
                  ),
                ],
              ),
            ),
          );
        }

        return ResponsiveScaffold(
          title: 'Student Profile: ${student.fullName}',
          currentRoute: AppRoutes.students,
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Print Record'),
              onPressed: () {
                PrintPreviewDialog.showStudentProfile(context,
                    student: student);
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Back to Students List',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(AppRoutes.students),
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
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onPressed: () =>
                            PrintPreviewDialog.showReportCard(
                          context,
                          student: student,
                          examination: Examination(
                            examId:
                                'EXAM_${student.currentAcademicYearId}_RESULTS',
                            title: 'Academic Progress Report',
                            academicYearId: student.currentAcademicYearId,
                            term: 'Annual Evaluation',
                          ),
                          marks: const [],
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
