import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/dialogs/create_notice_dialog.dart';
import '../../shared/dialogs/confirm_action_dialog.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../models/examination_model.dart';
import '../../core/services/data_export_service.dart';
import '../../providers/feature_providers.dart';
import '../../providers/auth_providers.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';

import '../../shared/widgets/erp_components.dart';
import '../../core/theme/apple_design_system.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentNavIndex = 0;
  String _searchFilter = '';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Administrator Portal',
      selectedNavIndex: _currentNavIndex,
      onNavIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
      navDestinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview'),
        NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified),
            label: 'Approvals'),
        NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Notices'),
        NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Audit Logs'),
      ],
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildOverviewTab(),
          _buildApprovalsTab(),
          _buildNoticesTab(),
          _buildAuditLogsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final user = ref.watch(currentUserProfileProvider).value;
    final studentsAsync = ref.watch(allStudentsStreamProvider);
    final staffAsync = ref.watch(allStaffUsersStreamProvider);
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);
    final attendanceSessionsAsync =
        ref.watch(allAttendanceSessionsStreamProvider);
    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);
    final examsAsync = ref.watch(examinationsStreamProvider);
    final noticesAsync = ref.watch(publishedNoticesProvider);
    final auditLogsAsync = ref.watch(auditLogsStreamProvider);

    final enrolledCount = studentsAsync.maybeWhen(
      data: (s) => '${s.where((st) => st.status == 'enrolled').length}',
      orElse: () => '—',
    );

    final activeStaffCount = staffAsync.maybeWhen(
      data: (staff) => '${staff.where((st) => st.isActive).length}',
      orElse: () => '—',
    );

    final classesSections = studentsAsync.maybeWhen(
      data: (s) {
        final cls = s.map((st) => st.currentClassId).toSet().length;
        final sec = s
            .map((st) => '${st.currentClassId}-${st.currentSectionId}')
            .toSet()
            .length;
        return '$cls Classes • $sec Cohorts';
      },
      orElse: () => '4 Classes • 8 Sections',
    );

    final attendanceRate = attendanceSessionsAsync.maybeWhen(
      data: (sessions) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final todaySessions = sessions.where((s) => s.date == today).toList();
        if (todaySessions.isEmpty) return 'Not recorded today';
        final totalPct = todaySessions.fold<double>(
          0.0,
          (acc, s) => acc + (s.summary?.attendancePercentage ?? 0.0),
        );
        return '${(totalPct / todaySessions.length).toStringAsFixed(1)}%';
      },
      orElse: () => '—',
    );

    final pendingAdmissionsCount = enquiriesAsync.maybeWhen(
      data: (enq) => '${enq.where((e) => [
            'enquiry',
            'applied',
            'documents_verified'
          ].contains(e['status'])).length}',
      orElse: () => '—',
    );

    final examStatus = examsAsync.maybeWhen(
      data: (exams) {
        if (exams.isEmpty) return 'AY Term 1 Active';
        final published = exams.where((e) => e.isPublished).length;
        return published > 0
            ? '$published Published'
            : '${exams.length} Scheduled';
      },
      orElse: () => 'AY Term 1 Active',
    );

    final feeRealized = invoicesAsync.maybeWhen(
      data: (invs) {
        final paid = invs.fold<int>(0, (total, i) => total + i.paidAmountPaise);
        final due =
            invs.fold<int>(0, (total, i) => total + i.outstandingBalancePaise);
        return '₹${(paid / 100).toStringAsFixed(0)} / ₹${(due / 100).toStringAsFixed(0)}';
      },
      orElse: () => '—',
    );

    final noticesCount = noticesAsync.maybeWhen(
      data: (n) => '${n.length} Active',
      orElse: () => '—',
    );

    final pendingApprovalsCount = attendanceSessionsAsync.maybeWhen(
      data: (sessions) {
        final unapproved = sessions.where((s) => !s.isApproved).length;
        final unverifiedEnq = enquiriesAsync.maybeWhen(
          data: (enq) => enq.where((e) => e['status'] == 'enquiry').length,
          orElse: () => 0,
        );
        return '${unapproved + unverifiedEnq} Pending';
      },
      orElse: () => '—',
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Role-Specific Welcome Header
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.adminIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.admin_panel_settings,
                            color: AppColors.adminIndigo, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${user?.displayName ?? "School Administrator"}',
                              style: AppleTypography.title2(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LAV Academy • School Administrator Portal • Academic Year 2026-2027 Active',
                              style: AppleTypography.subheadline(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.adminIndigo.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    AppColors.adminIndigo.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  color: AppColors.adminIndigo, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'AY 2026-2027 Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.adminIndigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.adminIndigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.adminIndigo.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              color: AppColors.adminIndigo, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'AY 2026-2027 Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.adminIndigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // 2. High-Density 10 Operational Metrics Strip
        ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'Total Enrolled',
              value: enrolledCount,
              subtitle: 'Active student registry',
              icon: Icons.people_outline,
              color: AppColors.adminIndigo,
              trend: 'Live registry',
            ),
            ErpMetricItem(
              label: 'Active Staff',
              value: activeStaffCount,
              subtitle: 'Teachers & personnel',
              icon: Icons.badge_outlined,
              color: AppColors.teacherTeal,
              trend: 'ReBAC active',
            ),
            ErpMetricItem(
              label: 'Classes & Sections',
              value: classesSections,
              subtitle: 'Active grade cohorts',
              icon: Icons.class_outlined,
              color: AppColors.brandNavy,
              trend: 'Configured',
            ),
            const ErpMetricItem(
              label: 'Academic Year',
              value: '2026-2027',
              subtitle: 'Term 1 in progress',
              icon: Icons.calendar_month_outlined,
              color: AppColors.infoSky,
              trend: 'Current AY',
            ),
            ErpMetricItem(
              label: "Today's Attendance",
              value: attendanceRate,
              subtitle: 'School-wide rate',
              icon: Icons.how_to_reg_outlined,
              color: AppColors.successGreen,
              trend: 'Daily aggregate',
            ),
            ErpMetricItem(
              label: 'Pending Admissions',
              value: pendingAdmissionsCount,
              subtitle: 'Awaiting review/decision',
              icon: Icons.person_add_alt_outlined,
              color: AppColors.warningAmber,
              trend: 'Intake queue',
            ),
            ErpMetricItem(
              label: 'Examination Status',
              value: examStatus,
              subtitle: 'Term evaluation state',
              icon: Icons.quiz_outlined,
              color: AppColors.librarianViolet,
              trend: 'Official records',
            ),
            ErpMetricItem(
              label: 'Fee Realized / Due',
              value: feeRealized,
              subtitle: 'Collections vs outstanding',
              icon: Icons.currency_rupee,
              color: AppColors.accountantEmerald,
              trend: 'Ledger totals',
            ),
            ErpMetricItem(
              label: 'Active Notices',
              value: noticesCount,
              subtitle: 'Broadcast circulars',
              icon: Icons.campaign_outlined,
              color: AppColors.adminIndigo,
              trend: 'Live broadcasts',
            ),
            ErpMetricItem(
              label: 'Pending Approvals',
              value: pendingApprovalsCount,
              subtitle: 'Attendance & tasks',
              icon: Icons.pending_actions_outlined,
              color: AppColors.dangerRed,
              trend: 'Action needed',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Executive Quick-Actions & Institution Operations Center
        ErpCard(
          title: 'Institution Operations Center',
          subtitle:
              'Institutional Authority & Server Governance • Academic Year 2026-2027',
          icon: Icons.admin_panel_settings_outlined,
          iconColor: AppColors.adminIndigo,
          headerTrailing: const ErpStatusBadge(
            label: 'Institutional Authority',
            backgroundColor: AppColors.infoBg,
            textColor: AppColors.infoSky,
            icon: Icons.verified_user_outlined,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Execute authorized operations across institutional cohorts, academic examinations, and staff accounts. All operations strictly invoke authenticated Cloud Functions.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ErpButton(
                    icon: Icons.person_add,
                    label: 'Add Student Record',
                    color: AppColors.adminIndigo,
                    onPressed: () => TransferStudentDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.manage_accounts,
                    label: 'Add / Manage Staff',
                    color: AppColors.brandNavy,
                    onPressed: () => StaffManagementDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.class_outlined,
                    label: 'Create Class / Section',
                    isPrimary: false,
                    color: AppColors.brandNavy,
                    onPressed: () => AssignTeacherDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.person_add_alt_1,
                    label: 'Assign Teacher to Cohort',
                    color: AppColors.brandNavy,
                    onPressed: () => AssignTeacherDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.rate_review_outlined,
                    label: 'Review Admissions',
                    isPrimary: false,
                    color: AppColors.warningAmber,
                    onPressed: () => setState(() => _currentNavIndex = 1),
                  ),
                  ErpButton(
                    icon: Icons.calendar_month_outlined,
                    label: 'Configure Academic Year',
                    isPrimary: false,
                    color: AppColors.infoSky,
                    onPressed: () => _showConfigureAyDialog(),
                  ),
                  ErpButton(
                    icon: Icons.add_alert,
                    label: 'Publish School Notice',
                    isPrimary: false,
                    color: AppColors.adminIndigo,
                    onPressed: () => _showCreateNoticeDialog(),
                  ),
                  ErpButton(
                    icon: Icons.publish,
                    label: 'Publish Exam Results',
                    color: AppColors.adminIndigo,
                    onPressed: () => _showPublishExamDialog(),
                  ),
                  ErpButton(
                    icon: Icons.print,
                    label: 'Preview Report Card',
                    isPrimary: false,
                    color: AppColors.textSecondary,
                    onPressed: () {
                      final students =
                          ref.read(allStudentsStreamProvider).value ?? [];
                      final enrolled = students
                          .where((s) => s.status == 'enrolled')
                          .toList();
                      if (enrolled.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'No enrolled student record is available to preview.')),
                        );
                        return;
                      }
                      PrintPreviewDialog.showReportCard(
                        context,
                        student: enrolled.first,
                        examination: const Examination(
                          examId: 'EXAM_PREVIEW',
                          title: 'Annual Academic Evaluation',
                          academicYearId: 'AY-2026-2027',
                          term: 'Published Results',
                        ),
                        marks: const [],
                      );
                    },
                  ),
                  ErpButton(
                    icon: Icons.file_download,
                    label: 'Export Registry (CSV)',
                    isPrimary: false,
                    color: AppColors.textSecondary,
                    onPressed: () {
                      final students =
                          ref.read(allStudentsStreamProvider).value ?? [];
                      DataExportService.exportStudentsCsv(students);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 1: Today's School Activity / Executive Summary
        ErpCard(
          title: "Today's School Activity",
          subtitle:
              'Real-time operational status, attendance updates, and institutional events',
          icon: Icons.insights_outlined,
          iconColor: AppColors.brandNavy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdaptiveFormRow(
                spacing: 12,
                runSpacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attendance Status',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(attendanceRate,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending Enquiries',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(pendingAdmissionsCount,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warningAmber)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Security Verification',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('RBAC Active',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.successGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 2: Admission Review Queue
        ErpCard(
          title: 'Admission Review Queue',
          subtitle:
              'Applications requiring administrative approval or status verification',
          icon: Icons.how_to_reg_outlined,
          iconColor: AppColors.warningAmber,
          padding: EdgeInsets.zero,
          child: enquiriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading admissions: $err',
                  style: const TextStyle(color: AppColors.dangerRed)),
            ),
            data: (enquiries) {
              final pending = enquiries
                  .where((e) => ['enquiry', 'applied', 'documents_verified']
                      .contains(e['status']))
                  .toList();
              if (pending.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 36, color: AppColors.successGreen),
                        SizedBox(height: 8),
                        Text('Admission Review Queue is Clear',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        SizedBox(height: 4),
                        Text(
                            'All student admission applications have been reviewed.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: pending.map((e) {
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e['studentName']?.toString() ?? 'Applicant',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(
                                'Class ${e['targetClass']} • Guardian: ${e['parentName'] ?? '—'} (${e['parentPhone'] ?? '—'})',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ErpStatusBadge.warning((e['status'] ?? 'pending')
                            .toString()
                            .toUpperCase()),
                        const SizedBox(width: 8),
                        ErpButton(
                          label: 'Review',
                          isDense: true,
                          isPrimary: false,
                          color: AppColors.adminIndigo,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Application for ${e['studentName']} is in ${e['status']} status.'),
                              ),
                            );
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

        // Section 3: Attendance Overview (Class-Wise Attendance from Real Sessions)
        ErpCard(
          title: 'Class-Wise Attendance Overview',
          subtitle:
              'Authoritative attendance records and submission status across active cohorts',
          icon: Icons.fact_check_outlined,
          iconColor: AppColors.teacherTeal,
          padding: EdgeInsets.zero,
          child: attendanceSessionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading attendance sessions: $err',
                  style: const TextStyle(color: AppColors.dangerRed)),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                        'No attendance sessions have been logged yet for the current term.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }
              final displaySessions = sessions.take(6).toList();
              return Column(
                children: displaySessions.map((s) {
                  final isApproved = s.isApproved;
                  final pct =
                      s.summary?.attendancePercentage.toStringAsFixed(1) ?? '—';
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? AppColors.successBg
                                : AppColors.warningAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isApproved
                                ? Icons.check_circle_outline
                                : Icons.schedule,
                            size: 18,
                            color: isApproved
                                ? AppColors.successGreen
                                : AppColors.warningAmber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class ${s.classId}-${s.sectionId}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(
                                'Date: ${s.date} • Present: ${s.summary?.presentCount ?? 0} / ${s.summary?.totalStudents ?? 0} ($pct%)',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ErpStatusBadge(
                          label: isApproved ? 'APPROVED' : 'DRAFT',
                          backgroundColor: isApproved
                              ? AppColors.successBg
                              : AppColors.warningAmber.withValues(alpha: 0.15),
                          textColor: isApproved
                              ? AppColors.successGreen
                              : AppColors.warningAmber,
                        ),
                        if (!isApproved) ...[
                          const SizedBox(width: 8),
                          ErpButton(
                            label: 'Approve',
                            isDense: true,
                            color: AppColors.adminIndigo,
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(attendanceRepositoryProvider)
                                    .approveAttendanceSession(s.sessionId);
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Session ${s.sessionId} approved.')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                        content: Text('Approval error: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Section 4: Academic Assignment Summary
        ErpCard(
          title: 'Academic Assignment Summary',
          subtitle:
              'Allocated classes, sections, and teacher workloads across academic departments',
          icon: Icons.co_present_outlined,
          iconColor: AppColors.brandNavy,
          padding: EdgeInsets.zero,
          child: staffAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading staff: $err',
                  style: const TextStyle(color: AppColors.dangerRed)),
            ),
            data: (staff) {
              final teachers =
                  staff.where((s) => s.role == UserRoles.teacher).toList();
              if (teachers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No teacher accounts currently registered.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }
              return Column(
                children: teachers.map((t) {
                  final classes = t.assignedClasses.isEmpty
                      ? 'No class assigned'
                      : 'Classes: ${t.assignedClasses.join(", ")}';
                  final sections = t.assignedSections.isEmpty
                      ? ''
                      : ' (Sections: ${t.assignedSections.join(", ")})';
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
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              AppColors.teacherTeal.withValues(alpha: 0.12),
                          child: Text(
                            t.displayName.isNotEmpty
                                ? t.displayName[0].toUpperCase()
                                : 'T',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teacherTeal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text('$classes$sections',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        ErpButton(
                          label: 'Reallocate',
                          isDense: true,
                          isPrimary: false,
                          color: AppColors.brandNavy,
                          onPressed: () => AssignTeacherDialog.show(context),
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

        // Section 5: Fee Overview (Actual Collected & Outstanding for Term)
        ErpCard(
          title: 'Fee Overview & Ledger Realization',
          subtitle:
              'Authoritative invoice settlements and outstanding receivables for current term',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.accountantEmerald,
          child: invoicesAsync.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())),
            error: (err, _) => Text('Error loading fee overview: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
            data: (invoices) {
              final active = invoices.where((i) => !i.isArchived).toList();
              final totalInvoiced =
                  active.fold<int>(0, (acc, i) => acc + i.totalAmountPaise);
              final totalPaid =
                  active.fold<int>(0, (acc, i) => acc + i.paidAmountPaise);
              final totalDue = active.fold<int>(
                  0, (acc, i) => acc + i.outstandingBalancePaise);
              final collectionRate = totalInvoiced > 0
                  ? (totalPaid * 100 / totalInvoiced).toStringAsFixed(1)
                  : '0.0';

              return Column(
                children: [
                  AdaptiveFormRow(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Invoiced',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                                '₹${(totalInvoiced / 100).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Realized',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('₹${(totalPaid / 100).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.successGreen)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Outstanding Dues',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('₹${(totalDue / 100).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.dangerRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Ledger Realization Rate: $collectionRate% (${active.length} Invoices Active)',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      ErpButton(
                        label: 'Open Fee Ledger',
                        isDense: true,
                        isPrimary: false,
                        color: AppColors.accountantEmerald,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Navigating to Fee Management Ledger...')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Section 6: Recent Announcements
        ErpCard(
          title: 'Recent Announcements & Notices',
          subtitle:
              'Published administrative notices, academic circulars, and broadcasts',
          icon: Icons.campaign_outlined,
          iconColor: AppColors.adminIndigo,
          padding: EdgeInsets.zero,
          child: noticesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading notices: $err',
                  style: const TextStyle(color: AppColors.dangerRed)),
            ),
            data: (notices) {
              if (notices.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                        'No notices published for the current academic term.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }
              return Column(
                children: notices.take(4).map((n) {
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
                        const Icon(Icons.campaign,
                            size: 20, color: AppColors.adminIndigo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(
                                'Audience: ${n.targetAudience.toUpperCase()} • ${n.content}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const ErpStatusBadge(
                          label: 'PUBLISHED',
                          backgroundColor: AppColors.successBg,
                          textColor: AppColors.successGreen,
                          icon: Icons.check_circle,
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

        // Section 7: Recent Audit Events
        ErpCard(
          title: 'Recent Audit Events',
          subtitle:
              'Authoritative append-only security logs and sensitive operation records',
          icon: Icons.history_outlined,
          iconColor: AppColors.brandNavy,
          padding: EdgeInsets.zero,
          child: auditLogsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading audit events: $err',
                  style: const TextStyle(color: AppColors.dangerRed)),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No audit events recorded yet.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }
              return Column(
                children: logs.take(5).map((l) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.borderLight, width: 1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint,
                            size: 18, color: AppColors.adminIndigo),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${l["action"] ?? "AUDIT_EVENT"} by ${l["actorRole"] ?? l["actorUid"] ?? "System"} on ${l["targetCollection"] ?? "ledger"}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _formatAuditTimestamp(l['timestamp']),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
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

        // Active Student Directory & Cohort Registry
        ErpCard(
          title: 'Student Cohort Directory & Registry',
          subtitle:
              'Real-time enrolled student records across grades and sections',
          icon: Icons.people_alt_outlined,
          iconColor: AppColors.brandNavy,
          headerTrailing: SizedBox(
            width: 240,
            child: ErpSearchBar(
              hintText: 'Filter by student name...',
              onChanged: (val) => setState(() => _searchFilter = val),
            ),
          ),
          padding: EdgeInsets.zero,
          child: studentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.brandNavy)),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading directory: $err',
                  style: const TextStyle(color: AppColors.dangerRed)),
            ),
            data: (students) {
              final filtered = students.where((s) {
                if (_searchFilter.isEmpty) return true;
                return s.fullName
                        .toLowerCase()
                        .contains(_searchFilter.toLowerCase()) ||
                    s.admissionNumber
                        .toLowerCase()
                        .contains(_searchFilter.toLowerCase());
              }).toList();

              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No students match current search filter',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }

              return Column(
                children: [
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: const Row(
                      children: [
                        SizedBox(
                            width: 120,
                            child: Text('ADMISSION #',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary))),
                        Expanded(
                            child: Text('STUDENT NAME',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary))),
                        SizedBox(
                            width: 90,
                            child: Text('COHORT',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary))),
                        SizedBox(
                            width: 100,
                            child: Text('STATUS',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary))),
                        SizedBox(
                            width: 140,
                            child: Text('ACTIONS',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ...filtered.map((st) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: AppColors.borderLight, width: 1)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                st.admissionNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.brandNavy),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.brandNavy
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      st.fullName.isNotEmpty
                                          ? st.fullName[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandNavy),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(st.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                  'Class ${st.currentClassId}-${st.currentSectionId}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ),
                            SizedBox(
                              width: 100,
                              child: ErpStatusBadge.success(
                                  st.status.toUpperCase()),
                            ),
                            SizedBox(
                              width: 140,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.swap_horiz,
                                        size: 18, color: AppColors.brandNavy),
                                    tooltip: 'Transfer Cohort',
                                    onPressed: () => TransferStudentDialog.show(
                                        context,
                                        initialStudent: st),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.description_outlined,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                    tooltip: 'View Report Card',
                                    onPressed: () =>
                                        PrintPreviewDialog.showReportCard(
                                      context,
                                      student: st,
                                      examination: Examination(
                                        examId:
                                            'EXAM_${st.currentAcademicYearId}_RESULTS',
                                        title: 'Academic Progress Report',
                                        academicYearId:
                                            st.currentAcademicYearId,
                                        term: 'Annual Evaluation',
                                      ),
                                      marks: const [],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalsTab() {
    final sessionsAsync = ref.watch(allAttendanceSessionsStreamProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        const Text(
          'Pending Attendance Approvals',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        const Text(
          'Teachers submit draft attendance sessions. School Administrators review and trigger server-side approval and finalization.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 18),
        sessionsAsync.when(
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator())),
          error: (err, _) => ErpCard(
              child: Text('Error loading attendance sessions: $err',
                  style: const TextStyle(color: AppColors.dangerRed))),
          data: (sessions) {
            final unapproved = sessions.where((s) => !s.isApproved).toList();
            if (unapproved.isEmpty) {
              return const ErpCard(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 40, color: AppColors.successGreen),
                        SizedBox(height: 12),
                        Text('All Sessions Approved',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 6),
                        Text(
                            'No pending draft attendance sessions require administrative review.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: unapproved.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildApprovalItem(
                    s.sessionId,
                    'Class ${s.classId} - Section ${s.sectionId}',
                    s.date,
                    '${s.summary?.totalStudents ?? 0} Students (${s.summary?.presentCount ?? 0} Present)',
                    'Recorded by ${s.markedBy}',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showConfigureAyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: AppColors.brandNavy),
            SizedBox(width: 8),
            Text('Academic Year Configuration'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Academic Year: AY 2026-2027',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            SizedBox(height: 8),
            Text('Start Date: April 1, 2026',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('End Date: March 31, 2027',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('Active Term: Term 1 (Autumn Evaluation Cycle)',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('Enforced Curricula: Central Board Standards',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(String sessionId, String classTitle, String date,
      String count, String submitter) {
    return ErpCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.adminIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.adminIndigo, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text('$date • $count • $submitter',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ErpButton(
            label: 'Approve & Lock',
            isDense: true,
            color: AppColors.adminIndigo,
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Triggering server approval for $sessionId...')),
              );
              try {
                await ref
                    .read(attendanceRepositoryProvider)
                    .approveAttendanceSession(sessionId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Session successfully approved by Cloud Function.')),
                  );
                }
              } catch (e, stack) {
                debugPrint(
                    '[AdminDashboardScreen.approveAttendanceSession] Exception: $e\n$stack');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Attendance approval failed: ${e.toString()}')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesTab() {
    final noticesAsync = ref.watch(publishedNoticesProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'Official Notices & Broadcasts',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
            ErpButton(
              icon: Icons.add,
              label: 'Create Notice',
              color: AppColors.adminIndigo,
              isDense: true,
              onPressed: () => _showCreateNoticeDialog(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        noticesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading notices: $e')),
          data: (notices) {
            if (notices.isEmpty) {
              return const ErpCard(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 40, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('No Notices Published',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 6),
                        Text(
                            'No published institutional notices or broadcast circulars yet.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: notices.map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ErpCard(
                    title: n.title,
                    subtitle: 'Audience: ${n.targetAudience.toUpperCase()}',
                    icon: Icons.campaign,
                    iconColor: AppColors.adminIndigo,
                    headerTrailing: const ErpStatusBadge(
                      label: 'Published',
                      backgroundColor: AppColors.successBg,
                      textColor: AppColors.successGreen,
                      icon: Icons.check_circle,
                    ),
                    child: Text(n.content,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4)),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab() {
    final logsAsync = ref.watch(auditLogsStreamProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        const Text('Security & Financial Audit Trail',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3)),
        const SizedBox(height: 4),
        const Text(
          'Recent append-only server audit events from the actual audit log collection.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 18),
        logsAsync.when(
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator())),
          error: (error, _) =>
              ErpCard(child: Text('Unable to load audit events: $error')),
          data: (logs) {
            if (logs.isEmpty) {
              return const ErpCard(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: Text('No audit events have been recorded yet.',
                              style:
                                  TextStyle(color: AppColors.textSecondary)))));
            }
            return Column(
              children: [
                for (var index = 0; index < logs.length; index++) ...[
                  _buildAuditLogEntry(
                    (logs[index]['action'] ?? 'UNKNOWN').toString(),
                    (logs[index]['actorRole'] ??
                            logs[index]['actorUid'] ??
                            'System')
                        .toString(),
                    (logs[index]['targetCollection'] ?? '—').toString(),
                    (logs[index]['targetDocumentId'] ??
                            logs[index]['targetId'] ??
                            '—')
                        .toString(),
                    _formatAuditTimestamp(logs[index]['timestamp']),
                  ),
                  if (index < logs.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatAuditTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal().toString();
    if (value is DateTime) return value.toLocal().toString();
    return value?.toString() ?? 'Time unavailable';
  }

  Widget _buildAuditLogEntry(String action, String actor, String collection,
      String docId, String time) {
    return ErpCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.adminIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.adminIndigo.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.fingerprint,
                color: AppColors.adminIndigo, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Actor: $actor\nTarget: $collection / $docId',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3)),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showPublishExamDialog() {
    ConfirmActionDialog.show(
      context,
      title: 'Publish Term 1 Examination Results',
      message:
          'This triggers administrative publication of all verified examination scores. Published marks will become instantly viewable by authorized guardians.',
      confirmLabel: 'Publish Results',
      confirmColor: AppColors.adminIndigo,
      requireReason: true,
      onConfirm: (reason) async {
        await ref
            .read(examRepositoryProvider)
            .publishExamResults(examId: 'EXAM_TERM1_2026');
      },
    );
  }

  void _showCreateNoticeDialog() {
    CreateNoticeDialog.show(
      context,
      onNoticeCreated: (notice) async {
        await ref.read(noticeRepositoryProvider).createDraftNotice(
              noticeId: notice.noticeId,
              title: notice.title,
              content: notice.content,
              targetAudience: notice.targetAudience,
              authorUid: ref.read(currentUserProfileProvider).value?.uid ?? '',
            );
        await ref.read(noticeRepositoryProvider).publishNotice(notice.noticeId);
      },
    );
  }
}
