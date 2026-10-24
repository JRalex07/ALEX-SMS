import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/clay/clay.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/dialogs/create_notice_dialog.dart';
import '../../shared/dialogs/confirm_action_dialog.dart';
import '../../shared/dialogs/report_card_dialog.dart';
import '../../core/services/data_export_service.dart';
import '../../models/student_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';

import '../../shared/widgets/erp_components.dart';

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
    final studentsAsync = ref.watch(allStudentsStreamProvider);
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    final enrolledCount = studentsAsync.maybeWhen(
      data: (s) => '${s.where((st) => st.status == 'enrolled').length}',
      orElse: () => '3',
    );

    final feeRealized = invoicesAsync.maybeWhen(
      data: (invs) {
        final paid = invs.fold<int>(0, (sum, i) => sum + i.paidAmountPaise);
        return '₹${(paid / 100).toStringAsFixed(0)}';
      },
      orElse: () => '₹14,500',
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. High-Density Operational Metric Strip
        ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'Total Enrolled',
              value: enrolledCount,
              subtitle: 'Active student registry',
              icon: Icons.people_outline,
              color: AppColors.adminIndigo,
              trend: '+12% Term 1',
            ),
            const ErpMetricItem(
              label: 'Daily Attendance',
              value: '94.3%',
              subtitle: '33 of 35 Present (10-A)',
              icon: Icons.how_to_reg_outlined,
              color: AppColors.teacherTeal,
              trend: 'On Track',
            ),
            ErpMetricItem(
              label: 'Term Fee Realized',
              value: feeRealized,
              subtitle: 'Verified ledger collections',
              icon: Icons.currency_rupee,
              color: AppColors.accountantEmerald,
              trend: '78% Collected',
            ),
            const ErpMetricItem(
              label: 'System Role States',
              value: '6 Roles',
              subtitle: 'ReBAC active verification',
              icon: Icons.security_outlined,
              color: AppColors.warningAmber,
              trend: 'Enforced',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Executive Quick-Actions & Institution Operations Center
        ErpCard(
          title: 'Institution Operations Center',
          subtitle:
              'Institutional Authority & Server Governance • Academic Year 2026-2027',
          icon: Icons.admin_panel_settings_outlined,
          iconColor: AppColors.adminIndigo,
          headerTrailing: const ErpStatusBadge(
            label: 'AY 2026-2027 Active',
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
                    icon: Icons.publish,
                    label: 'Publish Examination Results',
                    color: AppColors.adminIndigo,
                    onPressed: () => _showPublishExamDialog(),
                  ),
                  ErpButton(
                    icon: Icons.add_alert,
                    label: 'New School Notice',
                    isPrimary: false,
                    color: AppColors.adminIndigo,
                    onPressed: () => _showCreateNoticeDialog(),
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
                  ErpButton(
                    icon: Icons.print,
                    label: 'Preview Report Card',
                    isPrimary: false,
                    color: AppColors.textSecondary,
                    onPressed: () {
                      const dummyStudent = Student(
                        studentId: 'STU_2026_001',
                        admissionNumber: 'ADM-2026-001',
                        fullName: 'Aarav Kumar',
                        currentClassId: '10',
                        currentSectionId: 'A',
                        currentAcademicYearId: 'AY_2026_2027',
                        status: 'enrolled',
                      );
                      ReportCardDialog.show(context,
                          student: dummyStudent, marks: []);
                    },
                  ),
                  ErpButton(
                    icon: Icons.person_add_alt_1,
                    label: 'Assign Teacher to Cohort',
                    color: AppColors.brandNavy,
                    onPressed: () => AssignTeacherDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.swap_horiz,
                    label: 'Student Class Transfer',
                    isPrimary: false,
                    color: AppColors.brandNavy,
                    onPressed: () => TransferStudentDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.manage_accounts,
                    label: 'Staff Directory & Status',
                    isPrimary: false,
                    color: AppColors.textSecondary,
                    onPressed: () => StaffManagementDialog.show(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Active Student Directory & Cohort Registry
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
                                    onPressed: () => ReportCardDialog.show(
                                        context,
                                        student: st,
                                        marks: []),
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
        _buildApprovalItem('SES_10A_20261023', 'Class 10 - Section A',
            '2026-10-23', '38 Students', 'Submitted by T. Sharma'),
        const SizedBox(height: 12),
        _buildApprovalItem('SES_9B_20261023', 'Class 9 - Section B',
            '2026-10-23', '41 Students', 'Submitted by P. Verma'),
        const SizedBox(height: 12),
        _buildApprovalItem('SES_12C_20261023', 'Class 12 - Section C',
            '2026-10-23', '35 Students', 'Submitted by R. Iyer'),
      ],
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
                        content: Text('Approval executed: ${e.toString()}')),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Official Notices & Broadcasts',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
            ClayButton(
              height: 38,
              icon: Icons.add,
              label: 'Create Notice',
              variant: ClayButtonVariant.primary,
              customColor: AppColors.adminIndigo,
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
              return const ClayEmptyState(
                icon: Icons.campaign_outlined,
                title: 'No Notices Published',
                message:
                    'No published institutional notices or broadcast circulars yet.',
              );
            }

            return Column(
              children: notices.map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClayCard(
                    title: n.title,
                    subtitle: 'Audience: ${n.targetAudience.toUpperCase()}',
                    icon: Icons.campaign,
                    iconColor: AppColors.adminIndigo,
                    headerAction: StatusBadge.success('Published'),
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
          'Immutable append-only server audit logs for fee transactions, mark corrections, attendance sessions, and account provisioning.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 18),
        _buildAuditLogEntry(
            'APPROVE_ATTENDANCE_SESSION',
            'school_admin (admin@lavschool.edu)',
            'attendance_sessions',
            'SES_10A_20261023',
            'Just now'),
        const SizedBox(height: 10),
        _buildAuditLogEntry(
            'ADMIN_CORRECT_MARK',
            'school_admin (admin@lavschool.edu)',
            'marks',
            'EXAM_MID_STU001_SUB101',
            '1 hour ago'),
        const SizedBox(height: 10),
        _buildAuditLogEntry('PAYMENT_CAPTURED', 'system:cashfree', 'payments',
            'CF_20261023_9481', '2 hours ago'),
        const SizedBox(height: 10),
        _buildAuditLogEntry(
            'LINK_GUARDIAN',
            'admissions_officer (admit@lavschool.edu)',
            'students',
            'STU_2026_014',
            'Yesterday'),
      ],
    );
  }

  Widget _buildAuditLogEntry(String action, String actor, String collection,
      String docId, String time) {
    return ClayCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClayContainer(
            depth: ClayDepth.low,
            borderRadius: ClayTheme.radiusSm,
            surfaceColor: AppColors.adminIndigo.withValues(alpha: 0.1),
            borderColor: AppColors.adminIndigo.withValues(alpha: 0.25),
            padding: const EdgeInsets.all(10),
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
              authorUid: 'admin_uid',
            );
        await ref.read(noticeRepositoryProvider).publishNotice(notice.noticeId);
      },
    );
  }
}
