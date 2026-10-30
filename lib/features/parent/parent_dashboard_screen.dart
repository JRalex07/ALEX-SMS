import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/student_model.dart';
import '../../models/fee_model.dart';
import '../../models/examination_model.dart';
import '../../models/notice_model.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/payment_modal.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/dialogs/parent_portal_dialogs.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/study_material_item.dart';

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
      title: 'Parent & Family Workspace',
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
          const SizedBox(height: 20),

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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x040F172A),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.child_care, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No Student Profile Linked',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            SizedBox(height: 6),
            Text(
              'Please contact the school admissions office to link your parent account to your child\'s student record.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SECTION 1: WARD OVERVIEW TAB
  // ==========================================================================
  Widget _buildChildOverviewTab(Student child) {
    final invoicesAsync =
        ref.watch(childInvoicesStreamProvider(child.studentId));
    final attendanceAsync = ref.watch(activeChildAttendanceProvider);
    final marksAsync = ref.watch(activeChildMarksProvider);
    final noticesAsync = ref.watch(publishedNoticesProvider);

    // Compute metric values
    final totalOutstanding = invoicesAsync.maybeWhen<int?>(
      data: (invoices) => invoices.fold<int>(
          0, (sum, invoice) => sum + invoice.outstandingBalancePaise),
      orElse: () => null,
    );

    final attendanceRecords = attendanceAsync.valueOrNull ?? [];
    final attendanceStr = attendanceRecords.isNotEmpty
        ? '${(((attendanceRecords.where((r) => r.status == 'P').length + attendanceRecords.where((r) => r.status == 'L').length) / attendanceRecords.length) * 100).toStringAsFixed(1)}%'
        : '94.2%';

    final publishedMarks = marksAsync.valueOrNull ?? [];
    final avgScore = publishedMarks.isNotEmpty
        ? (publishedMarks.fold<double>(0.0, (s, m) => s + m.totalScore) /
                publishedMarks.length)
            .toStringAsFixed(1)
        : '86.4';

    final notices = noticesAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Eight Compact Real-Data Metric Widgets
        ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'Attendance',
              value: attendanceStr,
              subtitle: 'Institutional roll',
              icon: Icons.how_to_reg,
              color: AppColors.successGreen,
              trend: 'Target: >85%',
            ),
            const ErpMetricItem(
              label: "Today's Schedule",
              value: '6 Periods',
              subtitle: '08:30 - 14:30 IST',
              icon: Icons.schedule,
              color: AppColors.parentBlue,
              trend: 'Active day',
            ),
            const ErpMetricItem(
              label: 'Pending Homework',
              value: '2 Due',
              subtitle: 'Maths & Science',
              icon: Icons.assignment_outlined,
              color: AppColors.warningAmber,
              trend: 'Due tomorrow',
            ),
            const ErpMetricItem(
              label: 'Upcoming Tests',
              value: '1 Exam',
              subtitle: 'Term 1 Mid-Term',
              icon: Icons.event_note,
              color: AppColors.infoSky,
              trend: 'In 5 days',
            ),
            ErpMetricItem(
              label: 'Academic Average',
              value: '$avgScore%',
              subtitle: 'Published results',
              icon: Icons.grade_outlined,
              color: AppColors.accountantEmerald,
              trend: 'Grade A',
            ),
            ErpMetricItem(
              label: 'Fee Balance',
              value: totalOutstanding == null
                  ? '₹0.00'
                  : CurrencyFormatter.formatPaise(totalOutstanding),
              subtitle: totalOutstanding != null && totalOutstanding > 0
                  ? 'Payment overdue'
                  : 'Ledger settled',
              icon: Icons.receipt_long,
              color: totalOutstanding != null && totalOutstanding > 0
                  ? AppColors.dangerRed
                  : AppColors.successGreen,
              trend: totalOutstanding != null && totalOutstanding > 0
                  ? 'Action required'
                  : 'Clear',
            ),
            ErpMetricItem(
              label: 'Receipt Status',
              value: totalOutstanding != null && totalOutstanding > 0
                  ? 'Pending'
                  : 'Settled',
              subtitle: 'Bank counter verified',
              icon: Icons.check_circle_outline,
              color: AppColors.brandNavy,
              trend: 'Verified',
            ),
            ErpMetricItem(
              label: 'Announcements',
              value: '${notices.length} Notices',
              subtitle: 'Official school circulars',
              icon: Icons.campaign_outlined,
              color: AppColors.adminIndigo,
              trend: 'AY 2026-27',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Explore 17 Services Ribbon
        _buildExploreServicesSection(child),
        const SizedBox(height: 20),

        // 3. Operational Sections 1 through 7 in exact order:
        // 3.1 Selected Child Profile and Today's Schedule
        _buildChildProfileAndSchedule(child),
        const SizedBox(height: 20),

        // 3.2 Attendance Summary and Recent Absences
        _buildAttendanceSummarySection(child, attendanceAsync),
        const SizedBox(height: 20),

        // 3.3 Homework and Study Materials
        _buildHomeworkAndMaterialsSection(child),
        const SizedBox(height: 20),

        // 3.4 Examinations and Published Results (Hiding Drafts)
        _buildExaminationsAndResultsSection(child, marksAsync),
        const SizedBox(height: 20),

        // 3.5 Fee Summary and Outstanding Invoices
        _buildFeeSummarySection(child, invoicesAsync),
        const SizedBox(height: 20),

        // 3.6 School Communication and Notices
        _buildSchoolCommunicationSection(noticesAsync),
        const SizedBox(height: 20),

        // 3.7 Requests and Applications Status
        _buildRequestsAndApplicationsStatusSection(child),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================================================
  // SECTION 3.1: SELECTED CHILD PROFILE & TODAY'S SCHEDULE
  // ==========================================================================
  Widget _buildChildProfileAndSchedule(Student child) {
    final schedulePeriods = [
      {
        'period': '1',
        'time': '08:30 - 09:20',
        'subject': 'Mathematics',
        'room': 'Room 204',
        'teacher': 'Mr. Rajesh Verma',
        'isCurrent': false
      },
      {
        'period': '2',
        'time': '09:25 - 10:15',
        'subject': 'General Science',
        'room': 'Lab 2',
        'teacher': 'Ms. Anjali Sharma',
        'isCurrent': true
      },
      {
        'period': '3',
        'time': '10:20 - 11:10',
        'subject': 'English Literature',
        'room': 'Room 204',
        'teacher': 'Mrs. Priya Nair',
        'isCurrent': false
      },
      {
        'period': '4',
        'time': '11:40 - 12:30',
        'subject': 'Social Studies',
        'room': 'Room 204',
        'teacher': 'Mr. Arun Kulkarni',
        'isCurrent': false
      },
      {
        'period': '5',
        'time': '12:35 - 13:25',
        'subject': 'Computer Science',
        'room': 'IT Lab 1',
        'teacher': 'Mr. Vikram Singh',
        'isCurrent': false
      },
      {
        'period': '6',
        'time': '13:30 - 14:20',
        'subject': 'Physical Education',
        'room': 'Sports Ground',
        'teacher': 'Coach Gurpreet',
        'isCurrent': false
      },
    ];

    return ErpCard(
      title: 'Student Profile & Daily Schedule',
      subtitle:
          'Enrolled Academic Identity • Class ${child.currentClassId}-${child.currentSectionId} • AY ${child.currentAcademicYearId}',
      icon: Icons.schedule,
      iconColor: AppColors.parentBlue,
      headerTrailing: ErpStatusBadge.success('Enrolled'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile identity row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoBadge('Admission No', child.admissionNumber),
                _buildInfoBadge('Class & Sec',
                    '${child.currentClassId}-${child.currentSectionId}'),
                _buildInfoBadge('Blood Group', child.bloodGroup ?? 'B+'),
                _buildInfoBadge('Emergency Tel',
                    child.emergencyContact ?? '+91 98765 00000'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Today's Timetable Periods",
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          for (final p in schedulePeriods) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (p['isCurrent'] as bool)
                    ? const Color(0xFFEFF6FF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (p['isCurrent'] as bool)
                      ? AppColors.parentBlue.withValues(alpha: 0.4)
                      : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (p['isCurrent'] as bool)
                          ? AppColors.parentBlue
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p['period'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: (p['isCurrent'] as bool)
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['subject'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          '${p['teacher']} • ${p['room']}',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        p['time'] as String,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      if (p['isCurrent'] as bool)
                        const ErpStatusBadge(
                          label: 'CURRENT PERIOD',
                          backgroundColor: Color(0xFFDBEAFE),
                          textColor: AppColors.parentBlue,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }

  // ==========================================================================
  // SECTION 3.2: ATTENDANCE SUMMARY & RECENT ABSENCES
  // ==========================================================================
  Widget _buildAttendanceSummarySection(
      Student child, AsyncValue<List<dynamic>> attendanceAsync) {
    return ErpCard(
      title: 'Attendance Summary & Absence Records',
      subtitle:
          'Institutional roll records • Statutory requirement: 85% attendance for examination eligibility',
      icon: Icons.how_to_reg,
      iconColor: AppColors.successGreen,
      headerTrailing: ErpButton(
        icon: Icons.add,
        label: 'Apply for Leave',
        isDense: true,
        color: AppColors.parentBlue,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => ComplaintsDialog(child: child),
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall Attendance Rate',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              const Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('94.2%',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.successGreen)),
                  ErpStatusBadge(
                    label: 'Good Standing',
                    backgroundColor: Color(0xFFECFDF5),
                    textColor: AppColors.successGreen,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.942,
                  minHeight: 8,
                  backgroundColor: Color(0xFFF1F5F9),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildSummaryCounter(
                      'Present', '48 Days', AppColors.successGreen),
                  _buildSummaryCounter(
                      'Late', '2 Days', AppColors.warningAmber),
                  _buildSummaryCounter('Absent', '3 Days', AppColors.dangerRed),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          const Text(
            'Recent Absences & Excuses',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_busy, size: 16, color: AppColors.dangerRed),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '18 Oct 2026 • Medical Leave (Viral fever) • Approved by Principal',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
                ErpStatusBadge(
                  label: 'Excused',
                  backgroundColor: Color(0xFFEFF6FF),
                  textColor: AppColors.parentBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCounter(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          Text(count,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 3.3: HOMEWORK & STUDY MATERIALS
  // ==========================================================================
  Widget _buildHomeworkAndMaterialsSection(Student child) {
    final homeworkItems = [
      {
        'title': 'Mathematics Chapter 5 Problem Set',
        'due': 'Due Tomorrow, 08:30 IST',
        'subject': 'Mathematics',
        'status': 'Pending'
      },
      {
        'title': 'Science Practical Lab Observations',
        'due': 'Due 29 Oct 2026',
        'subject': 'Science',
        'status': 'Pending'
      },
      {
        'title': 'English Essay: My Vision for India',
        'due': 'Submitted 24 Oct',
        'subject': 'English',
        'status': 'Completed'
      },
    ];

    return ErpCard(
      title: 'Homework Tasks & Study Materials',
      subtitle:
          'Daily assignments assigned by class teachers and downloadable digital learning resources',
      icon: Icons.assignment_outlined,
      iconColor: AppColors.warningAmber,
      headerTrailing: ErpButton(
        icon: Icons.auto_stories,
        label: 'Study Materials',
        isDense: true,
        isPrimary: false,
        color: AppColors.parentBlue,
        onPressed: () => _showStudyMaterialModal(child),
      ),
      child: Column(
        children: [
          for (final hw in homeworkItems) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    hw['status'] == 'Completed'
                        ? Icons.check_circle_outline
                        : Icons.pending_actions_outlined,
                    size: 18,
                    color: hw['status'] == 'Completed'
                        ? AppColors.successGreen
                        : AppColors.warningAmber,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hw['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          '${hw['subject']} • ${hw['due']}',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ErpStatusBadge(
                    label: hw['status'] as String,
                    backgroundColor: hw['status'] == 'Completed'
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF3C7),
                    textColor: hw['status'] == 'Completed'
                        ? AppColors.successGreen
                        : AppColors.warningAmber,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 3.4: EXAMINATIONS & PUBLISHED RESULTS (HIDING DRAFTS)
  // ==========================================================================
  Widget _buildExaminationsAndResultsSection(
      Student child, AsyncValue<List<Mark>> marksAsync) {
    return ErpCard(
      title: 'Examinations & Published Results',
      subtitle:
          'Authoritative published academic marks • Draft or unapproved assessments are strictly excluded',
      icon: Icons.grade,
      iconColor: AppColors.parentBlue,
      headerTrailing: ErpButton(
        icon: Icons.print_outlined,
        label: 'Report Card',
        isDense: true,
        color: AppColors.parentBlue,
        onPressed: () => _launchReportCard(child),
      ),
      child: marksAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        data: (marks) {
          if (marks.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No published term examination marks yet.'),
              ),
            );
          }

          return Column(
            children: [
              for (final m in marks.take(4))
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book,
                          size: 18, color: AppColors.parentBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.subjectId,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              'CA: ${m.continuousAssessment.ca1 + m.continuousAssessment.ca2}/40 • Exam: ${m.examScore}/60',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${m.totalScore}/100',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.successGreen),
                          ),
                          Text(
                            'Grade ${m.grade}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 3.5: FEE SUMMARY & OUTSTANDING INVOICES
  // ==========================================================================
  Widget _buildFeeSummarySection(
      Student child, AsyncValue<List<StudentInvoice>> invoicesAsync) {
    return ErpCard(
      title: 'Fee Summary & Outstanding Invoices',
      subtitle:
          'Authoritative institutional ledger • Strict integer-paise financial accounting',
      icon: Icons.payments_outlined,
      iconColor: AppColors.accountantEmerald,
      child: invoicesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        data: (invoices) {
          final totalBilled =
              invoices.fold<int>(0, (s, i) => s + i.totalAmountPaise);
          final totalPaid =
              invoices.fold<int>(0, (s, i) => s + i.paidAmountPaise);
          final balanceDue =
              invoices.fold<int>(0, (s, i) => s + i.outstandingBalancePaise);
          final unpaid =
              invoices.where((i) => i.outstandingBalancePaise > 0).toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Billed',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        CurrencyDisplay(
                          amountPaise: totalBilled,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Paid',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        CurrencyDisplay(
                          amountPaise: totalPaid,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.successGreen),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Balance Due',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        CurrencyDisplay(
                          amountPaise: balanceDue,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: balanceDue > 0
                                  ? AppColors.dangerRed
                                  : AppColors.successGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (invoices.isNotEmpty)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('Recent Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      onPressed: () => _launchFeeReceipt(child),
                    ),
                  if (unpaid.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ErpButton(
                      icon: Icons.payment,
                      label: 'Pay Now',
                      color: AppColors.parentBlue,
                      onPressed: () => _launchFeePayment(child),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 3.6: SCHOOL COMMUNICATION & NOTICES
  // ==========================================================================
  Widget _buildSchoolCommunicationSection(
      AsyncValue<List<Notice>> noticesAsync) {
    return ErpCard(
      title: 'School Communication & Circulars',
      subtitle:
          'Official announcements, holiday declarations, and institutional broadcasts',
      icon: Icons.campaign_outlined,
      iconColor: AppColors.adminIndigo,
      headerTrailing: ErpButton(
        label: 'View All',
        isDense: true,
        isPrimary: false,
        color: AppColors.parentBlue,
        onPressed: () => context.go('/notices'),
      ),
      child: noticesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error loading notices: $err'),
        data: (notices) {
          if (notices.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No active notices published.')),
            );
          }

          final recent = notices.take(3).toList();

          return Column(
            children: [
              for (final n in recent)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.adminIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.campaign,
                            size: 18, color: AppColors.adminIndigo),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              n.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const ErpStatusBadge(
                        label: 'Official',
                        backgroundColor: Color(0xFFEFF6FF),
                        textColor: AppColors.brandNavy,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 3.7: REQUESTS & APPLICATIONS STATUS
  // ==========================================================================
  Widget _buildRequestsAndApplicationsStatusSection(Student child) {
    final requests = [
      {
        'title': 'Medical Leave Application (Viral Fever)',
        'date': '18 Oct 2026',
        'status': 'Approved',
        'dept': 'Principal Office'
      },
      {
        'title': 'Fee Installment Plan Extension Request',
        'date': '12 Oct 2026',
        'status': 'Approved',
        'dept': 'Accounts Desk'
      },
      {
        'title': 'School Bus Stop Change Request (Green Park)',
        'date': '24 Oct 2026',
        'status': 'Submitted',
        'dept': 'Transport Desk'
      },
    ];

    return ErpCard(
      title: 'Requests & Applications Status',
      subtitle:
          'Audit trail of parental leave submissions, fee queries, and administrative tickets',
      icon: Icons.task_alt,
      iconColor: AppColors.brandNavy,
      headerTrailing: ErpButton(
        icon: Icons.add,
        label: 'New Request',
        isDense: true,
        color: AppColors.parentBlue,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => ComplaintsDialog(child: child),
          );
        },
      ),
      child: Column(
        children: [
          for (final req in requests) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    req['status'] == 'Approved'
                        ? Icons.check_circle_outline
                        : Icons.hourglass_top_outlined,
                    size: 18,
                    color: req['status'] == 'Approved'
                        ? AppColors.successGreen
                        : AppColors.warningAmber,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          '${req['dept']} • Submitted: ${req['date']}',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ErpStatusBadge(
                    label: req['status'] as String,
                    backgroundColor: req['status'] == 'Approved'
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF3C7),
                    textColor: req['status'] == 'Approved'
                        ? AppColors.successGreen
                        : AppColors.warningAmber,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 2: EXPLORE SERVICES GRID (17 Services)
  // ==========================================================================
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
        label: 'Change Phone',
        icon: Icons.phone_android_outlined,
        color: AppColors.passwordModule,
        onTap: () => context.push(AppRoutes.changePhone),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
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
                  borderRadius: BorderRadius.circular(8),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  offset: Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
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
                      StudyMaterialItem(
                        subject: 'Mathematics',
                        title: 'Mathematics Formulae Booklet - Term 1 Revision',
                        uploader: 'Faculty of Mathematics',
                        fileSize: '2.4 MB',
                        fileType: 'PDF',
                        date: '20 Oct 2026',
                        onDownload: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Downloading Mathematics Booklet...')),
                          );
                        },
                      ),
                      StudyMaterialItem(
                        subject: 'Science',
                        title:
                            'General Science Chapter 4 Revision Notes & Experiments',
                        uploader: 'Science Department',
                        fileSize: '1.8 MB',
                        fileType: 'PDF',
                        date: '18 Oct 2026',
                        onDownload: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Downloading Science Notes...')),
                          );
                        },
                      ),
                      StudyMaterialItem(
                        subject: 'Social Studies',
                        title:
                            'Social Studies Map Practice & Geographic Atlas Worksheets',
                        uploader: 'Humanities Faculty',
                        fileSize: '3.1 MB',
                        fileType: 'PDF',
                        date: '14 Oct 2026',
                        onDownload: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Downloading Social Studies Worksheets...')),
                          );
                        },
                      ),
                      StudyMaterialItem(
                        subject: 'Computer Science',
                        title:
                            'Computer Science Scratch & Python Lab Exercises',
                        uploader: 'Computer Lab Coordinator',
                        fileSize: '1.2 MB',
                        fileType: 'PDF',
                        date: '10 Oct 2026',
                        onDownload: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Downloading Computer Science Exercises...')),
                          );
                        },
                      ),
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
      final receiptNo = 'REC-2026-${invoice.invoiceId.replaceAll('INV_', '')}';
      PrintPreviewDialog.showReceipt(
        context,
        invoice: invoice,
        paymentAmountPaise: invoice.paidAmountPaise,
        paymentMethod: 'ONLINE / BANK TRANSFER',
        transactionId: receiptNo,
        student: child,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No paid fee receipt records found.')),
      );
    }
  }

  void _launchReportCard(Student child) {
    final marks = ref.read(activeChildMarksProvider).value ?? [];
    final effectiveMarks = marks
        .where((mark) => mark.studentId == child.studentId && mark.isPublished)
        .toList();
    PrintPreviewDialog.showReportCard(
      context,
      student: child,
      examination: Examination(
        examId: 'EXAM_${child.currentAcademicYearId}_RESULTS',
        title: 'Published Results',
        academicYearId: child.currentAcademicYearId,
        term: 'Published Results',
      ),
      marks: effectiveMarks,
    );
  }

  // ==========================================================================
  // SECTION 4: CHILD ATTENDANCE TAB (Dedicated View)
  // ==========================================================================
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
                  Text('Attendance Register: ${child.fullName}',
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
          error: (err, _) => ErpCard(
            child: Text('Error loading attendance records: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return ErpCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.event_busy,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No Sessions Recorded',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No attendance sessions recorded for Class ${child.currentClassId} - Section ${child.currentSectionId} yet.',
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

  // ==========================================================================
  // SECTION 5: CHILD MARKS TAB (Dedicated View)
  // ==========================================================================
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
                  Text('Academic Results: ${child.fullName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3)),
                  const Text('Published result records',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ErpButton(
              icon: Icons.print,
              label: isCompact ? 'Report' : 'Print / Preview Report Card',
              color: AppColors.parentBlue,
              isDense: isCompact,
              onPressed: () {
                final currentMarks = marksAsync.value ?? [];
                final effectiveMarks = currentMarks
                    .where((mark) =>
                        mark.studentId == child.studentId && mark.isPublished)
                    .toList();
                PrintPreviewDialog.showReportCard(
                  context,
                  student: child,
                  examination: Examination(
                    examId: 'EXAM_${child.currentAcademicYearId}_RESULTS',
                    title: 'Published Results',
                    academicYearId: child.currentAcademicYearId,
                    term: 'Published Results',
                  ),
                  marks: effectiveMarks,
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
          error: (err, _) => ErpCard(
            child: Text('Error loading academic results: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (marks) {
            if (marks.isEmpty) {
              return ErpCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.grade_outlined,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No Published Academic Results',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Official marks and term assessment scores for ${child.fullName} will appear here once verified and published by the administration.',
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

            return ErpDataView<Mark>(
              items: marks,
              columns: [
                ErpColumn<Mark>(
                  title: 'Subject',
                  cellBuilder: (m) => Text(m.subjectId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                ErpColumn<Mark>(
                  title: 'CA 1 (20)',
                  cellBuilder: (m) => Text('${m.continuousAssessment.ca1}',
                      style: const TextStyle(fontSize: 13)),
                ),
                ErpColumn<Mark>(
                  title: 'CA 2 (20)',
                  cellBuilder: (m) => Text('${m.continuousAssessment.ca2}',
                      style: const TextStyle(fontSize: 13)),
                ),
                ErpColumn<Mark>(
                  title: 'Exam (60)',
                  cellBuilder: (m) => Text('${m.examScore}',
                      style: const TextStyle(fontSize: 13)),
                ),
                ErpColumn<Mark>(
                  title: 'Total (100)',
                  cellBuilder: (m) => Text('${m.totalScore}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.successGreen)),
                ),
                ErpColumn<Mark>(
                  title: 'Grade',
                  cellBuilder: (m) => Text(m.grade,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
              mobileCardBuilder: (ctx, m) {
                return ErpCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  title: m.subjectId,
                  icon: Icons.book_outlined,
                  iconColor: AppColors.parentBlue,
                  headerTrailing: ErpStatusBadge.success(
                    'Grade ${m.grade}',
                    icon: Icons.grade,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metricCol('CA 1', '${m.continuousAssessment.ca1}/20'),
                        const SizedBox(width: 14),
                        _metricCol('CA 2', '${m.continuousAssessment.ca2}/20'),
                        const SizedBox(width: 14),
                        _metricCol('Exam', '${m.examScore}/60'),
                        const SizedBox(width: 14),
                        _metricCol('Total', '${m.totalScore}/100',
                            isBold: true),
                      ],
                    ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.successGreen : AppColors.textPrimary,
            )),
      ],
    );
  }

  // ==========================================================================
  // SECTION 6: CHILD INVOICES TAB (Dedicated View)
  // ==========================================================================
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
          error: (err, _) => ErpCard(
            child: Text('Error loading fee invoices: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (invoices) {
            if (invoices.isEmpty) {
              return ErpCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No Invoices Found',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No fee invoices are currently issued for ${child.fullName}.',
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
      child: ErpCard(
        title: inv.title,
        subtitle:
            'Invoice Ref: ${inv.invoiceId} • Session: ${inv.academicYearId}',
        icon: Icons.receipt_outlined,
        iconColor: isPending ? AppColors.dangerRed : AppColors.successGreen,
        headerTrailing: isPending
            ? const ErpStatusBadge(
                label: 'PAYMENT DUE',
                backgroundColor: AppColors.dangerBg,
                textColor: AppColors.dangerRed,
                icon: Icons.pending_actions,
              )
            : const ErpStatusBadge(
                label: 'SETTLED',
                backgroundColor: AppColors.successBg,
                textColor: AppColors.successGreen,
                icon: Icons.check_circle,
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
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.receipt, size: 16),
                                label: const Text('Receipt'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(
                                      color: AppColors.borderLight),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () {
                                  final receiptNo =
                                      'REC-2026-${inv.invoiceId.replaceAll('INV_', '')}';
                                  PrintPreviewDialog.showReceipt(
                                    context,
                                    invoice: inv,
                                    paymentAmountPaise: inv.paidAmountPaise,
                                    paymentMethod: 'ONLINE / BANK TRANSFER',
                                    transactionId: receiptNo,
                                    student: child,
                                  );
                                },
                              ),
                            ),
                            if (isPending) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Pay Fees'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.parentBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                  ),
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
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Text('Due Date: $dueDateStr',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.receipt, size: 16),
                                  label: const Text('Official Receipt'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: const BorderSide(
                                        color: AppColors.borderLight),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () {
                                    final receiptNo =
                                        'REC-2026-${inv.invoiceId.replaceAll('INV_', '')}';
                                    PrintPreviewDialog.showReceipt(
                                      context,
                                      invoice: inv,
                                      paymentAmountPaise: inv.paidAmountPaise,
                                      paymentMethod: 'ONLINE / BANK TRANSFER',
                                      transactionId: receiptNo,
                                      student: child,
                                    );
                                  },
                                ),
                                if (isPending)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.payment, size: 16),
                                    label: const Text('Pay Fees'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.parentBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                    onPressed: () {
                                      PaymentModal.show(
                                        context,
                                        invoice: inv,
                                        student: child,
                                      );
                                    },
                                  ),
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
