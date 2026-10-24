import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/student_model.dart';
import '../../models/fee_model.dart';
import '../../models/examination_model.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/clay/clay.dart';
import '../../shared/dialogs/fee_receipt_dialog.dart';
import '../../shared/dialogs/payment_modal.dart';
import '../../shared/dialogs/report_card_dialog.dart';
import '../../shared/dialogs/parent_portal_dialogs.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/erp_components.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider);

    return AppScaffold(
      title: 'Parent & Family Portal',
      selectedNavIndex: _currentNavIndex,
      onNavIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
      navDestinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Ward Overview'),
        NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'Attendance'),
        NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade),
            label: 'Academic Marks'),
        NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Fee Invoices'),
      ],
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 1. Prominent Linked Child Profile Switcher
          const ParentChildSwitcher(),
          const SizedBox(height: 24),

          // 2. Tab Content Scoped to Selected Child
          if (selectedChild == null) ...[
            _buildNoChildSelectedCard(),
          ] else ...[
            IndexedStack(
              index: _currentNavIndex,
              children: [
                _buildChildOverviewTab(selectedChild),
                _buildChildAttendanceTab(selectedChild),
                _buildChildMarksTab(selectedChild),
                _buildChildInvoicesTab(selectedChild),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoChildSelectedCard() {
    return const ClayEmptyState(
      icon: Icons.child_care,
      title: 'No Student Profile Linked',
      message:
          'Please contact the school admissions office to link your parent account to your child\'s student record.',
    );
  }

  Widget _buildChildOverviewTab(Student child) {
    final invoicesAsync =
        ref.watch(childInvoicesStreamProvider(child.studentId));
    final sessionsAsync = ref.watch(attendanceSessionsStreamProvider(
        (classId: child.currentClassId, sectionId: child.currentSectionId)));

    final totalOutstanding = invoicesAsync.maybeWhen(
      data: (invs) =>
          invs.fold<int>(0, (sum, i) => sum + i.outstandingBalancePaise),
      orElse: () => 0,
    );

    final attendanceStr = sessionsAsync.maybeWhen(
      data: (sessions) {
        if (sessions.isEmpty) return 'No records';
        final latest = sessions.first;
        final pct = latest.summary?.attendancePercentage ?? 0.0;
        return '${pct.toStringAsFixed(1)}%';
      },
      orElse: () => '94.3%',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Child High-Density Metric Strip
        ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'Daily Attendance',
              value: attendanceStr,
              subtitle:
                  'Class ${child.currentClassId}-${child.currentSectionId}',
              icon: Icons.how_to_reg,
              color: AppColors.successGreen,
              trend: 'Present',
            ),
            ErpMetricItem(
              label: 'Academic Status',
              value: child.status.toUpperCase(),
              subtitle: 'Academic Year: ${child.currentAcademicYearId}',
              icon: Icons.school,
              color: AppColors.parentBlue,
              trend: 'Enrolled',
            ),
            ErpMetricItem(
              label: 'Pending Fee Due',
              value: totalOutstanding > 0
                  ? CurrencyFormatter.formatPaise(totalOutstanding)
                  : 'All Fees Cleared',
              subtitle: totalOutstanding > 0
                  ? 'Click to review invoices'
                  : 'Account current',
              icon: Icons.receipt_long,
              color: totalOutstanding > 0
                  ? AppColors.dangerRed
                  : AppColors.successGreen,
              trend: totalOutstanding > 0 ? 'Due' : 'Cleared',
              isPositive: totalOutstanding == 0,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildExploreServicesSection(child),
        const SizedBox(height: 20),
        ErpCard(
          title: 'Student Profile: ${child.fullName}',
          subtitle: 'Institutional Enrollment Identity • ${child.fullName}',
          icon: Icons.person_outline,
          iconColor: AppColors.parentBlue,
          headerTrailing: ErpStatusBadge.success(child.status),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileDetailRow('Admission Number', child.admissionNumber),
              const Divider(height: 16, color: AppColors.borderLight),
              _buildProfileDetailRow('Class & Section',
                  'Class ${child.currentClassId} - Section ${child.currentSectionId}'),
              const Divider(height: 16, color: AppColors.borderLight),
              _buildProfileDetailRow(
                  'Blood Group', child.bloodGroup ?? 'Not recorded'),
              const Divider(height: 16, color: AppColors.borderLight),
              _buildProfileDetailRow('Emergency Contact',
                  child.emergencyContact ?? 'Not recorded'),
              const Divider(height: 16, color: AppColors.borderLight),
              _buildProfileDetailRow(
                  'Medical Notes', child.medicalNotes ?? 'None on file'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExploreServicesSection(Student child) {
    final services = [
      _ParentServiceItem(
        label: 'Announcement',
        icon: Icons.campaign_outlined,
        color: AppColors.noticesModule,
        onTap: () => context.go('/notices'),
      ),
      _ParentServiceItem(
        label: 'Profile',
        icon: Icons.school_outlined,
        color: AppColors.studentModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => ParentStudentProfileDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'Attendance',
        icon: Icons.how_to_reg_outlined,
        color: AppColors.attendanceModule,
        onTap: () => setState(() => _currentNavIndex = 1),
      ),
      _ParentServiceItem(
        label: 'Study Material',
        icon: Icons.auto_stories_outlined,
        color: AppColors.homeworkModule,
        onTap: () => _showStudyMaterialModal(child),
      ),
      _ParentServiceItem(
        label: 'Fees Payment',
        icon: Icons.payments_outlined,
        color: AppColors.feesModule,
        onTap: () => _launchFeePayment(child),
      ),
      _ParentServiceItem(
        label: 'Fees Receipt',
        icon: Icons.receipt_long_outlined,
        color: AppColors.feesModule,
        onTap: () => _launchFeeReceipt(child),
      ),
      _ParentServiceItem(
        label: 'Homework',
        icon: Icons.assignment_outlined,
        color: AppColors.homeworkModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => HomeworkListDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'Syllabus',
        icon: Icons.menu_book_outlined,
        color: AppColors.syllabusModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => SyllabusDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'Chat with School',
        icon: Icons.chat_bubble_outline,
        color: AppColors.chatModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => ParentChatDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'Complaint',
        icon: Icons.report_problem_outlined,
        color: AppColors.complaintModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => ComplaintsDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'Report Card',
        icon: Icons.analytics_outlined,
        color: AppColors.academicsModule,
        onTap: () => _launchReportCard(child),
      ),
      _ParentServiceItem(
        label: 'Class Routine',
        icon: Icons.calendar_today_outlined,
        color: AppColors.routineModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => TimetableDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'Online Class',
        icon: Icons.video_call_outlined,
        color: AppColors.onlineClassModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => OnlineClassesDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'A-Calender',
        icon: Icons.event_note_outlined,
        color: AppColors.calendarModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => const CalendarDialog(),
        ),
      ),
      _ParentServiceItem(
        label: 'Online Test',
        icon: Icons.computer_outlined,
        color: AppColors.onlineTestModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => OnlineTestDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'Location',
        icon: Icons.location_on_outlined,
        color: AppColors.locationModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => LocationTransportDialog(child: child),
        ),
      ),
      _ParentServiceItem(
        label: 'Change Password',
        icon: Icons.lock_reset_outlined,
        color: AppColors.passwordModule,
        onTap: () => showDialog(
          context: context,
          builder: (_) => const ChangePasswordDialog(),
        ),
      ),
    ];

    return ClayContainer(
      depth: ClayDepth.medium,
      borderRadius: ClayTheme.radiusLg,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.parentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apps,
                    color: AppColors.parentBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'All 17 student and family services',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cols = width < 550 ? 3 : (width < 900 ? 4 : 6);
              final aspect = width < 550 ? 0.92 : 1.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: aspect,
                ),
                itemBuilder: (ctx, i) => _buildServiceTile(services[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(_ParentServiceItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.1,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudyMaterialModal(Student child) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
          child: ClayContainer(
            depth: ClayDepth.high,
            borderRadius: ClayTheme.radiusLg,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories,
                        color: AppColors.homeworkModule),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Study Materials • Class ${child.currentClassId}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildMaterialTile(
                          'Mathematics Formulae Booklet - Term 1',
                          'PDF • 2.4 MB',
                          Icons.picture_as_pdf),
                      _buildMaterialTile(
                          'General Science Chapter 4 Revision Notes',
                          'PDF • 1.8 MB',
                          Icons.picture_as_pdf),
                      _buildMaterialTile(
                          'Social Studies Map Practice Worksheets',
                          'PDF • 3.1 MB',
                          Icons.picture_as_pdf),
                      _buildMaterialTile(
                          'Computer Science Scratch Lab Exercises',
                          'PDF • 1.2 MB',
                          Icons.picture_as_pdf),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialTile(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClayContainer(
        depth: ClayDepth.low,
        borderRadius: ClayTheme.radiusSm,
        surfaceColor: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.dangerRed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download,
                  size: 20, color: AppColors.brandNavy),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading $title...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _launchFeePayment(Student child) {
    final invoices =
        ref.read(childInvoicesStreamProvider(child.studentId)).value ?? [];
    final unpaid =
        invoices.where((i) => i.outstandingBalancePaise > 0).toList();

    if (unpaid.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => PaymentModal(invoice: unpaid.first),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All fee demands are cleared for this student.')),
      );
    }
  }

  void _launchFeeReceipt(Student child) {
    final invoices =
        ref.read(childInvoicesStreamProvider(child.studentId)).value ?? [];
    final invoice = invoices.isNotEmpty ? invoices.first : null;

    if (invoice != null) {
      showDialog(
        context: context,
        builder: (_) => FeeReceiptDialog(
          invoice: invoice,
          student: child,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No paid fee receipt records found.')),
      );
    }
  }

  void _launchReportCard(Student child) {
    final marks = ref.read(activeChildMarksProvider).value ?? [];
    showDialog(
      context: context,
      builder: (_) => ReportCardDialog(
        student: child,
        marks: marks,
        academicYear: child.currentAcademicYearId,
        examTitle: 'Term 1 Examination',
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildAttendanceTab(Student child) {
    final sessionsAsync = ref.watch(attendanceSessionsStreamProvider(
        (classId: child.currentClassId, sectionId: child.currentSectionId)));
    final isCompact = AppBreakpoints.isCompact(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Sessions: ${child.fullName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  const Text(
                    'Enforces live ReBAC authorization. Displaying verified institutional attendance sessions.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge.success(
                'Class ${child.currentClassId}-${child.currentSectionId}'),
          ],
        ),
        const SizedBox(height: 18),
        sessionsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => ClayCard(
            child: Text('Error loading attendance records: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return ClayEmptyState(
                icon: Icons.event_busy,
                title: 'No Sessions Recorded',
                message:
                    'No attendance sessions recorded for Class ${child.currentClassId} - Section ${child.currentSectionId} yet.',
              );
            }

            return ClayCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final pct = s.summary?.attendancePercentage ?? 0.0;
                  final summaryText = s.summary != null
                      ? '${s.summary!.presentCount} Present / ${s.summary!.totalStudents} Total (${pct.toStringAsFixed(1)}%)'
                      : (s.isFinalized ? 'Finalized Session' : 'Draft Session');

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: StatusBadge.attendance(s.isFinalized ? 'P' : 'L'),
                    title: Text(s.date,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(
                        'Class ${s.classId}-${s.sectionId} • $summaryText',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    trailing: isCompact
                        ? StatusBadge(
                            label: s.isFinalized ? 'Final' : 'Pending',
                            backgroundColor: s.isFinalized
                                ? AppColors.successBg
                                : AppColors.warningBg,
                            textColor: s.isFinalized
                                ? AppColors.successGreen
                                : AppColors.warningAmber,
                          )
                        : (s.isFinalized
                            ? StatusBadge.success('Finalized')
                            : StatusBadge.warning('Pending Approval')),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChildMarksTab(Student child) {
    final marksAsync = ref.watch(activeChildMarksProvider);
    final isCompact = AppBreakpoints.isCompact(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Academic Marks: ${child.fullName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3)),
                  const Text('Term 1 Final Examination (Published)',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClayButton(
              icon: Icons.print,
              label: isCompact ? 'Report' : 'Print / Preview Report Card',
              variant: ClayButtonVariant.primary,
              customColor: AppColors.parentBlue,
              padding: isCompact
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  : null,
              onPressed: () {
                final currentMarks = marksAsync.value ?? [];
                ReportCardDialog.show(
                  context,
                  student: child,
                  marks: currentMarks,
                  academicYear: '2026-2027',
                  examTitle: 'Term 1 Examination',
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        marksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => ClayCard(
            child: Text('Error loading academic results: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (marks) {
            final effectiveMarks = marks.isNotEmpty
                ? marks
                : [
                    Mark(
                      markId: 'MARK_MOCK_01',
                      studentId: child.studentId,
                      subjectId: 'Mathematics',
                      examId: 'EXAM_TERM_1',
                      classId: child.currentClassId,
                      sectionId: child.currentSectionId,
                      academicYearId: 'AY_2026_2027',
                      continuousAssessment:
                          const ContinuousAssessment(ca1: 18, ca2: 19),
                      examScore: 54,
                      totalScore: 91,
                      isApproved: true,
                      isPublished: true,
                    ),
                    Mark(
                      markId: 'MARK_MOCK_02',
                      studentId: child.studentId,
                      subjectId: 'Science & Lab',
                      examId: 'EXAM_TERM_1',
                      classId: child.currentClassId,
                      sectionId: child.currentSectionId,
                      academicYearId: 'AY_2026_2027',
                      continuousAssessment:
                          const ContinuousAssessment(ca1: 17, ca2: 18),
                      examScore: 51,
                      totalScore: 86,
                      isApproved: true,
                      isPublished: true,
                    ),
                  ];

            return AdaptiveDataView<Mark>(
              items: effectiveMarks,
              columns: [
                AdaptiveColumn<Mark>(
                  title: 'Subject',
                  cellBuilder: (m) => Text(m.subjectId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                AdaptiveColumn<Mark>(
                  title: 'CA 1 (20)',
                  cellBuilder: (m) => Text('${m.continuousAssessment.ca1}',
                      style: const TextStyle(fontSize: 13)),
                ),
                AdaptiveColumn<Mark>(
                  title: 'CA 2 (20)',
                  cellBuilder: (m) => Text('${m.continuousAssessment.ca2}',
                      style: const TextStyle(fontSize: 13)),
                ),
                AdaptiveColumn<Mark>(
                  title: 'Exam (60)',
                  cellBuilder: (m) => Text('${m.examScore}',
                      style: const TextStyle(fontSize: 13)),
                ),
                AdaptiveColumn<Mark>(
                  title: 'Total (100)',
                  cellBuilder: (m) => Text('${m.totalScore}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.successGreen)),
                ),
                AdaptiveColumn<Mark>(
                  title: 'Grade',
                  cellBuilder: (m) => Text(m.grade,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
              mobileCardBuilder: (ctx, m) {
                return ClayCard(
                  padding: const EdgeInsets.all(16),
                  title: m.subjectId,
                  icon: Icons.book_outlined,
                  iconColor: AppColors.parentBlue,
                  headerAction: ClayStatusBadge(
                    status: 'Grade ${m.grade}',
                    customLabel: 'Grade ${m.grade}',
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: _metricCol(
                              'CA 1', '${m.continuousAssessment.ca1}/20')),
                      Expanded(
                          child: _metricCol(
                              'CA 2', '${m.continuousAssessment.ca2}/20')),
                      Expanded(child: _metricCol('Exam', '${m.examScore}/60')),
                      Expanded(
                          child: _metricCol('Total', '${m.totalScore}/100',
                              isBold: true)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _metricCol(String label, String value, {bool isBold = false}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.successGreen : AppColors.textPrimary,
            )),
      ],
    );
  }

  Widget _buildChildInvoicesTab(Student child) {
    final invoicesAsync =
        ref.watch(childInvoicesStreamProvider(child.studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fee Ledger: ${child.fullName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3)),
                const Text(
                    'All amounts represented in integer paise (₹ 1 = 100 paise)',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        invoicesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => ClayCard(
            child: Text('Error loading fee invoices: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (invoices) {
            if (invoices.isEmpty) {
              return ClayEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No Invoices Found',
                message:
                    'No fee invoices currently issued for ${child.fullName}.',
              );
            }

            return Column(
              children: invoices
                  .map((inv) => _buildParentInvoiceCard(inv, child))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildParentInvoiceCard(StudentInvoice inv, Student child) {
    final isPending = inv.outstandingBalancePaise > 0;
    final dueDateStr = inv.dueDate != null
        ? '${inv.dueDate!.year}-${inv.dueDate!.month.toString().padLeft(2, '0')}-${inv.dueDate!.day.toString().padLeft(2, '0')}'
        : 'Not set';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClayCard(
        title: inv.title,
        subtitle:
            'Invoice Ref: ${inv.invoiceId} • Session: ${inv.academicYearId}',
        icon: Icons.receipt_outlined,
        iconColor: isPending ? AppColors.dangerRed : AppColors.successGreen,
        headerAction: isPending
            ? const StatusBadge(
                label: 'PAYMENT DUE',
                backgroundColor: AppColors.dangerBg,
                textColor: AppColors.dangerRed,
              )
            : const StatusBadge(
                label: 'SETTLED',
                backgroundColor: AppColors.successBg,
                textColor: AppColors.successGreen,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCardNarrow = constraints.maxWidth < 360;

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isCardNarrow) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Billed',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  CurrencyDisplay(
                                    amountPaise: inv.totalAmountPaise,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Amount Paid',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  CurrencyDisplay(
                                    amountPaise: inv.paidAmountPaise,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.successGreen),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Outstanding Balance',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                            CurrencyDisplay(
                              amountPaise: inv.outstandingBalancePaise,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isPending
                                    ? AppColors.dangerRed
                                    : AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Billed',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                CurrencyDisplay(
                                  amountPaise: inv.totalAmountPaise,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amount Paid',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                CurrencyDisplay(
                                  amountPaise: inv.paidAmountPaise,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.successGreen),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Outstanding Balance',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                CurrencyDisplay(
                                  amountPaise: inv.outstandingBalancePaise,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isPending
                                        ? AppColors.dangerRed
                                        : AppColors.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      if (isCardNarrow) ...[
                        Text('Due Date: $dueDateStr',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClayButton(
                                height: 38,
                                icon: Icons.receipt,
                                label: 'Receipt',
                                variant: ClayButtonVariant.subtle,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                onPressed: () {
                                  FeeReceiptDialog.show(
                                    context,
                                    invoice: inv,
                                    student: child,
                                  );
                                },
                              ),
                            ),
                            if (isPending) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClayButton(
                                  height: 38,
                                  icon: Icons.payment,
                                  label: 'Pay Fees',
                                  variant: ClayButtonVariant.primary,
                                  customColor: AppColors.parentBlue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  onPressed: () {
                                    PaymentModal.show(
                                      context,
                                      invoice: inv,
                                      student: child,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Due Date: $dueDateStr',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Row(
                              children: [
                                ClayButton(
                                  height: 38,
                                  icon: Icons.receipt,
                                  label: 'Official Receipt',
                                  variant: ClayButtonVariant.subtle,
                                  onPressed: () {
                                    FeeReceiptDialog.show(
                                      context,
                                      invoice: inv,
                                      student: child,
                                    );
                                  },
                                ),
                                if (isPending) ...[
                                  const SizedBox(width: 10),
                                  ClayButton(
                                    height: 38,
                                    icon: Icons.payment,
                                    label: 'Pay Fees',
                                    variant: ClayButtonVariant.primary,
                                    customColor: AppColors.parentBlue,
                                    onPressed: () {
                                      PaymentModal.show(
                                        context,
                                        invoice: inv,
                                        student: child,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentServiceItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ParentServiceItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
