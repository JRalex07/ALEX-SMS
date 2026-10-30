import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/examination_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../providers/parent_services_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/dialogs/upload_material_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/study_material_item.dart';

class AcademicsResourceScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const AcademicsResourceScreen({super.key, this.initialTab});

  @override
  ConsumerState<AcademicsResourceScreen> createState() =>
      _AcademicsResourceScreenState();
}

class _AcademicsResourceScreenState
    extends ConsumerState<AcademicsResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Gradebook',
    'Timetable',
    'Homework',
    'Materials',
    'Examinations',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'timetable':
          initialIndex = 1;
          break;
        case 'homework':
          initialIndex = 2;
          break;
        case 'materials':
          initialIndex = 3;
          break;
        case 'examinations':
        case 'marks':
        case 'report-cards':
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
  void didUpdateWidget(covariant AcademicsResourceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      int targetIndex = 0;
      switch (widget.initialTab) {
        case 'timetable':
          targetIndex = 1;
          break;
        case 'homework':
          targetIndex = 2;
          break;
        case 'materials':
          targetIndex = 3;
          break;
        case 'examinations':
        case 'marks':
        case 'report-cards':
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final isTeacher = role == UserRoles.teacher;
    final isAdmin = role == UserRoles.schoolAdmin;

    return ResponsiveScaffold(
      title: 'Academics & Curriculum Desk',
      currentRoute: AppRoutes.academics,
      actions: [
        if (isTeacher) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.cloud_upload, size: 16),
            label: const Text('Upload Material'),
            onPressed: () => _tabController.animateTo(3),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add_task, size: 16),
            label: const Text('Create Homework'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teacherTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => CreateHomeworkDialog.show(context),
          ),
          const SizedBox(width: 8),
        ] else if (isAdmin) ...[
          FilledButton.icon(
            icon: const Icon(Icons.grading, size: 16),
            label: const Text('Enter Marks'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _tabController.animateTo(0),
          ),
          const SizedBox(width: 8),
        ],
      ],
      body: Column(
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
                _buildGradebookTab(role),
                _buildTimetableTab(),
                _buildHomeworkTab(isTeacher),
                _buildMaterialsTab(isTeacher),
                _buildExaminationsTab(role),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradebookTab(String role) {
    if (role == UserRoles.parentGuardian) {
      final selectedChild = ref.watch(selectedChildProvider);
      if (selectedChild == null) {
        return const Center(child: ParentChildSwitcher());
      }
      final marksAsync = ref.watch(activeChildMarksProvider);

      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 16),
          marksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading marks: $e'),
            data: (marks) {
              final published = marks.where((m) => m.isPublished).toList();
              final avg = published.isEmpty
                  ? 0.0
                  : published.fold<int>(0, (sum, m) => sum + m.totalScore) /
                      published.length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Average Academic Score',
                          value: published.isEmpty
                              ? '—'
                              : '${avg.toStringAsFixed(1)} / 100',
                          subtitle: '${published.length} subjects published',
                          icon: Icons.analytics_outlined,
                          iconColor: AppColors.parentBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Term Result Status',
                          value: published.isEmpty
                              ? 'Awaiting Publication'
                              : 'Published',
                          subtitle: 'AY 2026-2027 Mid-Term',
                          icon: Icons.verified_outlined,
                          iconColor: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ErpCard(
                    title:
                        'Published Subject Marks — ${selectedChild.fullName}',
                    subtitle:
                        'Internal Continuous Assessment (40) + Term Examination (60)',
                    headerTrailing: OutlinedButton.icon(
                      icon: const Icon(Icons.print_outlined, size: 14),
                      label: const Text('Print Report Card'),
                      onPressed: () {
                        PrintPreviewDialog.showReportCard(
                          context,
                          student: selectedChild,
                          examination: const Examination(
                            examId: 'EXAM_MIDTERM_2026',
                            title: 'Mid-Term Examinations 2026',
                            academicYearId: 'AY-2026-2027',
                            term: 'Term 1',
                          ),
                          marks: published,
                        );
                      },
                    ),
                    child: published.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                  'No published marks are available for this student yet.',
                                  style: TextStyle(color: AppColors.textMuted)),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: published.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: AppColors.borderLight),
                            itemBuilder: (ctx, idx) {
                              final mark = published[idx];
                              return ListTile(
                                title: Text(mark.subjectId.toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                    'CA1: ${mark.continuousAssessment.ca1}/20 • CA2: ${mark.continuousAssessment.ca2}/20 • Exam: ${mark.examScore}/60'),
                                trailing: Text(
                                  '${mark.totalScore}/100 • ${mark.grade}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }

    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Institutional Gradebook & Marks Moderation',
          subtitle:
              'Faculty draft scores and administrative publication controls',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter and audit student marks records',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Continuous assessments (CA1/CA2) and term exams are validated in real time against grading policies.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                studentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading students: $e'),
                  data: (students) {
                    if (students.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No students enrolled to grade.'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final s = students[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.fullName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'Adm: ${s.admissionNumber} • Class: ${s.currentClassId}-${s.currentSectionId}'),
                          trailing: FilledButton.icon(
                            icon: const Icon(Icons.grading, size: 14),
                            label: const Text('Enter Marks'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teacherTeal,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => SubmitMarksDialog.show(
                              context,
                              student: s,
                              subject: 'Mathematics',
                              examId: 'EXAM_MIDTERM_2026',
                              subjectId: 'SUB_MATH',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimetableTab() {
    final timetableAsync = ref.watch(childTimetableProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        timetableAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading timetable: $e'),
          data: (slots) {
            return ErpCard(
              title: 'Weekly Academic Schedule (Class 10-A)',
              subtitle:
                  'Daily subject periods, timing slots, and assigned faculty',
              child: slots.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No timetable slots configured.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: slots.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final slot = slots[idx];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.brandNavy.withValues(alpha: 0.1),
                            child: Text('${idx + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandNavy)),
                          ),
                          title: Text(slot.subjectName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'Teacher: ${slot.teacherName} • Room: ${slot.roomNumber}'),
                          trailing: Text('${slot.startTime} - ${slot.endTime}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        );
                      },
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeworkTab(bool isTeacher) {
    final homeworkAsync = ref.watch(childHomeworkProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Homework & Curriculum Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (isTeacher)
              FilledButton.icon(
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Create Homework'),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teacherTeal),
                onPressed: () => CreateHomeworkDialog.show(context),
              ),
          ],
        ),
        const SizedBox(height: 16),
        homeworkAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading homework: $e'),
          data: (items) {
            return ErpCard(
              title: 'Current Term Assignments (${items.length})',
              subtitle: 'Homework tasks and submission deadlines',
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No pending homework tasks.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final item = items[idx];
                        return ListTile(
                          title: Text(item.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'Subject: ${item.subjectName} • Due: ${item.dueDate.toLocal().toString().split(" ").first} • ${item.instructions}'),
                          trailing: Chip(
                            label: Text(item.submissionStatus.toUpperCase(),
                                style: const TextStyle(fontSize: 11)),
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

  Widget _buildMaterialsTab(bool isTeacher) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            const Text(
              'Subject Learning Materials & Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (isTeacher)
              FilledButton.icon(
                icon: const Icon(Icons.cloud_upload, size: 16),
                label: const Text('Upload Material'),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teacherTeal),
                onPressed: () => UploadMaterialDialog.show(
                  context,
                  defaultClass: '10',
                  defaultSection: 'A',
                  onUpload: ({
                    required title,
                    required classId,
                    required sectionId,
                    required subject,
                    required fileName,
                    required fileBytes,
                  }) async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Uploaded $fileName for Class $classId-$sectionId ($subject).')),
                    );
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ErpCard(
          title: 'Class 10 Curriculum Study Materials',
          subtitle:
              'Verified syllabi, practice worksheets, and reference guides',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudyMaterialItem(
                subject: 'Mathematics',
                title: 'Quadratic Equations & Arithmetic Progressions Practice Notes',
                uploader: 'Tarun Sharma (Faculty)',
                fileSize: '2.4 MB',
                fileType: 'PDF',
                date: '24 Oct 2026',
                onDownload: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Downloading Mathematics study material...')),
                  );
                },
              ),
              StudyMaterialItem(
                subject: 'Science',
                title: 'Chemical Reactions, Acids, Bases & Salts Master Worksheet',
                uploader: 'Dr. Anita Joshi (Senior Faculty)',
                fileSize: '1.8 MB',
                fileType: 'PDF',
                date: '22 Oct 2026',
                onDownload: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Downloading Science study material...')),
                  );
                },
              ),
              StudyMaterialItem(
                subject: 'Science',
                title: 'Life Processes & Control Coordination Laboratory Guide',
                uploader: 'Science Department',
                fileSize: '3.2 MB',
                fileType: 'PDF',
                date: '18 Oct 2026',
                onDownload: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Downloading Biology study material...')),
                  );
                },
              ),
              StudyMaterialItem(
                subject: 'Social Studies',
                title: 'Nationalism in India & Resource Development Map Workbook',
                uploader: 'Humanities Department',
                fileSize: '4.1 MB',
                fileType: 'PDF',
                date: '15 Oct 2026',
                onDownload: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Downloading Social Studies workbook...')),
                  );
                },
              ),
              StudyMaterialItem(
                subject: 'Computer Science',
                title: 'Python Programming, Data Structures & Lab Assignment Guide',
                uploader: 'IT Department',
                fileSize: '1.5 MB',
                fileType: 'PDF',
                date: '12 Oct 2026',
                onDownload: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Downloading Computer Science guide...')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExaminationsTab(String role) {
    final examsAsync = ref.watch(examinationsStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        examsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading exams: $e'),
          data: (exams) {
            return ErpCard(
              title: 'Examination Timetable & Assessment Schedule',
              subtitle: 'Active term examinations for AY 2026-2027',
              child: exams.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No active examinations scheduled.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exams.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final ex = exams[idx];
                        return ListTile(
                          title: Text(ex.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'Term: ${ex.term} • Year: ${ex.academicYearId} • Total Max Marks: ${ex.assessmentStructure.maxTotal}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ex.isPublished ? 'PUBLISHED' : 'SCHEDULED',
                              style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                            ),
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
}
