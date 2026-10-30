import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../models/student_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/erp_components.dart';
import '../../core/theme/apple_design_system.dart';

class AdmissionsDashboardScreen extends ConsumerStatefulWidget {
  const AdmissionsDashboardScreen({super.key});

  @override
  ConsumerState<AdmissionsDashboardScreen> createState() =>
      _AdmissionsDashboardScreenState();
}

class _AdmissionsDashboardScreenState
    extends ConsumerState<AdmissionsDashboardScreen> {
  int _currentNavIndex = 0;

  // Controllers for student enrollment and linking
  final TextEditingController _guardianStudentIdCtrl = TextEditingController();
  final TextEditingController _guardianUidCtrl = TextEditingController();
  final TextEditingController _guardianRelationCtrl = TextEditingController();
  final TextEditingController _newStudentNameCtrl = TextEditingController();
  final TextEditingController _admissionNumberCtrl = TextEditingController();
  final TextEditingController _newClassCtrl = TextEditingController();
  final TextEditingController _newSectionCtrl = TextEditingController();
  final TextEditingController _emergencyContactCtrl = TextEditingController();
  final TextEditingController _bloodGroupCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _guardianStudentIdCtrl.dispose();
    _guardianUidCtrl.dispose();
    _guardianRelationCtrl.dispose();
    _newStudentNameCtrl.dispose();
    _admissionNumberCtrl.dispose();
    _newClassCtrl.dispose();
    _newSectionCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Admissions Officer Workspace',
      selectedNavIndex: _currentNavIndex,
      onNavIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
      navDestinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
        NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Review Queue'),
        NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Verification'),
        NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'Approved'),
        NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students'),
        NavigationDestination(
            icon: Icon(Icons.person_add_outlined),
            selectedIcon: Icon(Icons.person_add),
            label: 'New Admission'),
        NavigationDestination(
            icon: Icon(Icons.link_outlined),
            selectedIcon: Icon(Icons.link),
            label: 'Link Guardian'),
      ],
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildMainAdmissionsDashboard(),
          _buildFilteredQueueView('review'),
          _buildFilteredQueueView('verification'),
          _buildFilteredQueueView('approved'),
          _buildStudentsListTab(),
          _buildNewAdmissionTab(),
          _buildLinkGuardianTab(),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 1: MAIN ADMISSIONS DASHBOARD
  // ==========================================================================
  Widget _buildMainAdmissionsDashboard() {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    final officerName =
        userProfileAsync.valueOrNull?.displayName ?? 'Admissions Officer';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Role-specific Welcome Header
        _buildAdmissionsWelcomeHeader(officerName),
        const SizedBox(height: 20),

        // 2. 7 Compact Real-Data Metric Widgets
        _buildAdmissionsMetrics(enquiriesAsync, studentsAsync),
        const SizedBox(height: 20),

        // 3. Primary Quick Actions
        _buildPrimaryQuickActions(enquiriesAsync, studentsAsync),
        const SizedBox(height: 24),

        // 4. Operational Tables & Queues (Sections 1 through 6)
        // 4.1 Application Review Queue
        _buildApplicationReviewQueue(enquiriesAsync),
        const SizedBox(height: 24),

        // 4.2 Document Verification Queue
        _buildDocumentVerificationQueue(enquiriesAsync),
        const SizedBox(height: 24),

        // 4.3 Admission Pipeline Stage Bar
        _buildAdmissionPipelineStageBar(enquiriesAsync, studentsAsync),
        const SizedBox(height: 24),

        // 4.4 Approved but Not Enrolled
        _buildApprovedAwaitingEnrollment(enquiriesAsync),
        const SizedBox(height: 24),

        // 4.5 Recent Applications
        _buildRecentApplications(enquiriesAsync),
        const SizedBox(height: 24),

        // 4.6 Intake Summary (Capacity & Enrollment by Class)
        _buildIntakeCapacitySummary(studentsAsync, enquiriesAsync),
        const SizedBox(height: 32),
      ],
    );
  }

  // 1. Welcome Header
  Widget _buildAdmissionsWelcomeHeader(String officerName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.admissionsOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: AppColors.admissionsOrange,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      officerName,
                      style: AppleTypography.title2(color: AppColors.textPrimary),
                    ),
                    const ErpStatusBadge(
                      label: 'Admissions Officer',
                      backgroundColor: Color(0xFFFFF7ED),
                      textColor: AppColors.admissionsOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Enrolment & Candidate Management • Active Cycle: AY 2026-2027 Admissions Open',
                  style: AppleTypography.subheadline(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const ErpStatusBadge(
            label: 'AY 2026-2027',
            backgroundColor: Color(0xFFF1F5F9),
            textColor: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  // 2. Compact Real-Data Metric Widgets (7 metrics)
  Widget _buildAdmissionsMetrics(
    AsyncValue<List<Map<String, dynamic>>> enquiriesAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return enquiriesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.admissionsOrange),
        ),
      ),
      error: (err, _) => ErpCard(
        title: 'Admissions Data Metrics Unavailable',
        subtitle: 'Error fetching admissions enquiries from Firestore',
        icon: Icons.error_outline,
        iconColor: AppColors.dangerRed,
        child: Text('Unable to query admissions stream: $err'),
      ),
      data: (enquiries) {
        final totalEnrolledStudents = studentsAsync.maybeWhen(
          data: (s) => s.where((stu) => stu.status == 'enrolled').length,
          orElse: () => 0,
        );

        final newApplications = enquiries.where((e) {
          final s = (e['status'] ?? '').toString();
          return s == 'enquiry' || s == 'applied';
        }).length;

        final awaitingReview = enquiries.where((e) {
          final s = (e['status'] ?? '').toString();
          return s == 'applied' || s == 'under_review';
        }).length;

        final awaitingVerification = enquiries.where((e) {
          final s = (e['status'] ?? '').toString();
          return s == 'applied' || s == 'under_review' || s == 'documents_pending';
        }).length;

        final incompleteOrBlocked = enquiries.where((e) {
          final s = (e['status'] ?? '').toString();
          return s == 'incomplete' || s == 'blocked';
        }).length;

        final approvedAwaitingEnroll = enquiries.where((e) {
          final s = (e['status'] ?? '').toString();
          return s == 'approved';
        }).length;

        final completedEnrollments = totalEnrolledStudents +
            enquiries.where((e) => (e['status'] ?? '').toString() == 'enrolled').length;

        final rejectedOrWithdrawn = enquiries.where((e) {
          final s = (e['status'] ?? '').toString();
          return s == 'rejected' || s == 'withdrawn';
        }).length;

        return ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'New Received',
              value: '$newApplications',
              subtitle: 'Enquiry / Applied',
              icon: Icons.mark_email_unread_outlined,
              color: AppColors.admissionsOrange,
              trend: 'Intake cycle',
            ),
            ErpMetricItem(
              label: 'Awaiting Review',
              value: '$awaitingReview',
              subtitle: 'In review queue',
              icon: Icons.pending_actions_outlined,
              color: AppColors.warningAmber,
              trend: 'Action required',
            ),
            ErpMetricItem(
              label: 'Doc Verification',
              value: '$awaitingVerification',
              subtitle: 'Pending docs check',
              icon: Icons.rule_folder_outlined,
              color: AppColors.infoSky,
              trend: 'Verification',
            ),
            ErpMetricItem(
              label: 'Incomplete / Blocked',
              value: '$incompleteOrBlocked',
              subtitle: 'Missing requirements',
              icon: Icons.error_outline,
              color: AppColors.dangerRed,
              trend: 'Deficient files',
            ),
            ErpMetricItem(
              label: 'Approved (Pending)',
              value: '$approvedAwaitingEnroll',
              subtitle: 'Ready to enroll',
              icon: Icons.verified_outlined,
              color: AppColors.accountantEmerald,
              trend: 'Awaiting student ID',
            ),
            ErpMetricItem(
              label: 'Completed Enrollments',
              value: '$completedEnrollments',
              subtitle: 'Institutional registry',
              icon: Icons.how_to_reg_outlined,
              color: AppColors.brandNavy,
              trend: 'Enrolled students',
            ),
            ErpMetricItem(
              label: 'Rejected / Withdrawn',
              value: '$rejectedOrWithdrawn',
              subtitle: 'Closed dossiers',
              icon: Icons.cancel_outlined,
              color: AppColors.textMuted,
              trend: 'Archived',
            ),
          ],
        );
      },
    );
  }

  // 3. Primary Quick Actions
  Widget _buildPrimaryQuickActions(
    AsyncValue<List<Map<String, dynamic>>> enquiriesAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return ErpCard(
      title: 'Admissions Operational Actions',
      subtitle:
          'Authoritative candidate intake, document certification, and cohort enrollment operations',
      icon: Icons.flash_on_outlined,
      iconColor: AppColors.admissionsOrange,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ErpButton(
            icon: Icons.person_add_alt_1,
            label: 'Create Application',
            color: AppColors.admissionsOrange,
            onPressed: () => _showCreateApplicationDialog(context),
          ),
          ErpButton(
            icon: Icons.rate_review_outlined,
            label: 'Review Queue',
            isPrimary: false,
            color: AppColors.warningAmber,
            onPressed: () => setState(() => _currentNavIndex = 1),
          ),
          ErpButton(
            icon: Icons.verified_user_outlined,
            label: 'Verify Documents',
            isPrimary: false,
            color: AppColors.infoSky,
            onPressed: () => setState(() => _currentNavIndex = 2),
          ),
          ErpButton(
            icon: Icons.gavel_outlined,
            label: 'Record Decision',
            isPrimary: false,
            color: AppColors.admissionsOrange,
            onPressed: () {
              final enquiries = enquiriesAsync.valueOrNull ?? [];
              final pending = enquiries.where((e) {
                final s = (e['status'] ?? '').toString();
                return s == 'applied' || s == 'under_review' || s == 'documents_verified';
              }).toList();
              if (pending.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No applications currently awaiting decision.')),
                );
              } else {
                _showRecordDecisionDialog(context, pending.first);
              }
            },
          ),
          ErpButton(
            icon: Icons.how_to_reg,
            label: 'Enroll Approved Applicant',
            isPrimary: false,
            color: AppColors.accountantEmerald,
            onPressed: () => setState(() => _currentNavIndex = 3),
          ),
          studentsAsync.maybeWhen(
            data: (students) => ErpButton(
              icon: Icons.file_download_outlined,
              label: 'Export Registry CSV',
              isPrimary: false,
              color: AppColors.textSecondary,
              onPressed: () => DataExportService.exportStudentsCsv(students),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.1: APPLICATION REVIEW QUEUE
  // ==========================================================================
  Widget _buildApplicationReviewQueue(
      AsyncValue<List<Map<String, dynamic>>> enquiriesAsync) {
    return ErpCard(
      title: 'Application Review Queue',
      subtitle:
          'Primary operational queue • candidate dossiers awaiting stage progression or evaluation',
      icon: Icons.rate_review_outlined,
      iconColor: AppColors.admissionsOrange,
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ErpButton(
            icon: Icons.add,
            label: 'New Candidate',
            isDense: true,
            color: AppColors.admissionsOrange,
            onPressed: () => _showCreateApplicationDialog(context),
          ),
        ],
      ),
      child: enquiriesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading applications: $err',
              style: const TextStyle(color: AppColors.dangerRed)),
        ),
        data: (enquiries) {
          final reviewItems = enquiries.where((e) {
            final s = (e['status'] ?? '').toString();
            return s == 'applied' || s == 'under_review' || s == 'enquiry';
          }).toList();

          if (reviewItems.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 36, color: AppColors.accountantEmerald),
                    SizedBox(height: 10),
                    Text(
                      'Review Queue Up To Date',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No pending applications are currently awaiting reviewer assessment.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ErpDataView<Map<String, dynamic>>(
            items: reviewItems,
            columns: [
              ErpColumn<Map<String, dynamic>>(
                title: 'Application ID',
                flex: 2,
                cellBuilder: (e) => Text(
                  e['id']?.toString().substring(0, 8) ?? 'APP-001',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
              ErpColumn<Map<String, dynamic>>(
                title: 'Applicant Name',
                flex: 3,
                cellBuilder: (e) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['applicantName'] ?? 'Unnamed Candidate',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'Guardian: ${e['guardianName'] ?? '—'} • ${e['phone'] ?? '—'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ErpColumn<Map<String, dynamic>>(
                title: 'Target Class',
                flex: 2,
                cellBuilder: (e) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    'Class ${e['targetClass'] ?? '—'}',
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              ErpColumn<Map<String, dynamic>>(
                title: 'Submission Status',
                flex: 2,
                cellBuilder: (e) => _buildStatusPill(e['status']?.toString()),
              ),
              ErpColumn<Map<String, dynamic>>(
                title: 'Assigned Reviewer',
                flex: 2,
                cellBuilder: (e) => const Text(
                  'Admissions Desk',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              ErpColumn<Map<String, dynamic>>(
                title: 'Action',
                flex: 2.5,
                textAlign: TextAlign.right,
                cellBuilder: (e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ErpButton(
                      label: 'Review',
                      isDense: true,
                      color: AppColors.admissionsOrange,
                      onPressed: () => _showRecordDecisionDialog(context, e),
                    ),
                    const SizedBox(width: 6),
                    ErpButton(
                      label: 'Verify Docs',
                      isDense: true,
                      isPrimary: false,
                      color: AppColors.infoSky,
                      onPressed: () =>
                          _showDocumentVerificationDialog(context, e),
                    ),
                  ],
                ),
              ),
            ],
            mobileCardBuilder: (context, e) => _buildApplicationMobileCard(e),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.2: DOCUMENT VERIFICATION QUEUE
  // ==========================================================================
  Widget _buildDocumentVerificationQueue(
      AsyncValue<List<Map<String, dynamic>>> enquiriesAsync) {
    return ErpCard(
      title: 'Document Verification Queue',
      subtitle:
          'Examine mandatory compliance certificates (Birth Cert, Transfer Cert, Immunization, Address Proof)',
      icon: Icons.verified_user_outlined,
      iconColor: AppColors.infoSky,
      child: enquiriesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $err'),
        ),
        data: (enquiries) {
          final pendingDocs = enquiries.where((e) {
            final s = (e['status'] ?? '').toString();
            return s == 'applied' || s == 'under_review' || s == 'documents_pending';
          }).toList();

          if (pendingDocs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No applications currently require document certification.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return Column(
            children: [
              for (final app in pendingDocs.take(4))
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.infoSky.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.file_present_outlined,
                            size: 20, color: AppColors.infoSky),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  app['applicantName'] ?? 'Candidate',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Text(
                                    'Class ${app['targetClass'] ?? '—'}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Pending: Birth Certificate • Previous Report Card • Transfer Certificate (TC)',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ErpButton(
                            label: 'Certify Docs',
                            isDense: true,
                            color: AppColors.accountantEmerald,
                            onPressed: () =>
                                _showDocumentVerificationDialog(context, app),
                          ),
                          ErpButton(
                            label: 'Mark Incomplete',
                            isDense: true,
                            isPrimary: false,
                            color: AppColors.dangerRed,
                            onPressed: () => _updateStatusWithConfirm(
                                context, app['id'], 'incomplete',
                                'Mark this application incomplete due to missing compliance files?'),
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
  // SECTION 4.3: ADMISSION PIPELINE STAGE BAR
  // ==========================================================================
  Widget _buildAdmissionPipelineStageBar(
    AsyncValue<List<Map<String, dynamic>>> enquiriesAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return ErpCard(
      title: 'Institutional Admission Pipeline',
      subtitle:
          'End-to-end stage progression from primary inquiry to verified classroom matriculation',
      icon: Icons.linear_scale,
      iconColor: AppColors.admissionsOrange,
      child: enquiriesAsync.when(
        loading: () => const SizedBox(
            height: 80, child: Center(child: CircularProgressIndicator())),
        error: (err, _) => Text('Error: $err'),
        data: (enquiries) {
          final totalInquiries = enquiries.where((e) => (e['status'] ?? '') == 'enquiry').length;
          final totalApplied = enquiries.where((e) => (e['status'] ?? '') == 'applied').length;
          final totalUnderReview = enquiries.where((e) => (e['status'] ?? '') == 'under_review').length;
          final totalDocsVerified = enquiries.where((e) => (e['status'] ?? '') == 'documents_verified').length;
          final totalApproved = enquiries.where((e) => (e['status'] ?? '') == 'approved').length;
          final totalEnrolled = studentsAsync.maybeWhen(
            data: (s) => s.length,
            orElse: () => enquiries.where((e) => (e['status'] ?? '') == 'enrolled').length,
          );

          final stages = [
            {'label': '1. Inquiries', 'count': totalInquiries, 'color': AppColors.textSecondary},
            {'label': '2. Applied', 'count': totalApplied, 'color': AppColors.admissionsOrange},
            {'label': '3. Review', 'count': totalUnderReview, 'color': AppColors.warningAmber},
            {'label': '4. Verified', 'count': totalDocsVerified, 'color': AppColors.infoSky},
            {'label': '5. Approved', 'count': totalApproved, 'color': AppColors.accountantEmerald},
            {'label': '6. Enrolled', 'count': totalEnrolled, 'color': AppColors.brandNavy},
          ];

          return Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < stages.length; i++) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: (stages[i]['color'] as Color)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (stages[i]['color'] as Color)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${stages[i]['count']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: stages[i]['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stages[i]['label'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < stages.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_ios,
                            size: 12, color: AppColors.borderLight),
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
  // SECTION 4.4: APPROVED BUT NOT ENROLLED
  // ==========================================================================
  Widget _buildApprovedAwaitingEnrollment(
      AsyncValue<List<Map<String, dynamic>>> enquiriesAsync) {
    return ErpCard(
      title: 'Approved Applications Awaiting Enrollment',
      subtitle:
          'Candidates with cleared admission decisions awaiting authoritative generation of institutional student record',
      icon: Icons.how_to_reg_outlined,
      iconColor: AppColors.accountantEmerald,
      child: enquiriesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        data: (enquiries) {
          final approvedList = enquiries.where((e) {
            final s = (e['status'] ?? '').toString();
            return s == 'approved';
          }).toList();

          if (approvedList.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No cleared candidates are currently pending formal cohort matriculation.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return Column(
            children: [
              for (final app in approvedList)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.accountantEmerald.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFECFDF5),
                        child: Icon(Icons.check,
                            size: 18, color: AppColors.accountantEmerald),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app['applicantName'] ?? 'Approved Student',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            Text(
                              'Target: Class ${app['targetClass'] ?? '10'} • Guardian: ${app['guardianName'] ?? '—'} (${app['phone'] ?? '—'})',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (app['reviewerNotes'] != null &&
                                app['reviewerNotes'].toString().isNotEmpty)
                              Text(
                                'Cleared: ${app['reviewerNotes']}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.accountantEmerald),
                              ),
                          ],
                        ),
                      ),
                      ErpButton(
                        icon: Icons.person_add,
                        label: 'Enroll to Class',
                        color: AppColors.accountantEmerald,
                        onPressed: () =>
                            _showDirectEnrollModal(context, app),
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
  // SECTION 4.5: RECENT APPLICATIONS
  // ==========================================================================
  Widget _buildRecentApplications(
      AsyncValue<List<Map<String, dynamic>>> enquiriesAsync) {
    return ErpCard(
      title: 'Recent Applications & Enquiries',
      subtitle:
          'Chronological log of intake submissions with demographic notes and candidate contact info',
      icon: Icons.history,
      iconColor: AppColors.brandNavy,
      child: enquiriesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        data: (enquiries) {
          if (enquiries.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No recent applications registered in the database.'),
              ),
            );
          }

          final recent = enquiries.take(6).toList();

          return Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.admissionsOrange.withValues(alpha: 0.12),
                      child: Text(
                        (recent[i]['applicantName'] ?? 'C').toString()[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.admissionsOrange),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recent[i]['applicantName'] ?? 'Candidate',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            'Class ${recent[i]['targetClass'] ?? '—'} • Tel: ${recent[i]['phone'] ?? '—'} • ${recent[i]['notes'] ?? 'No special notes'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(recent[i]['status']?.toString()),
                  ],
                ),
                if (i < recent.length - 1)
                  const Divider(height: 18, color: AppColors.borderLight),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.6: INTAKE SUMMARY (Capacity by Class)
  // ==========================================================================
  Widget _buildIntakeCapacitySummary(
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Map<String, dynamic>>> enquiriesAsync,
  ) {
    return ErpCard(
      title: 'Institutional Intake & Seat Capacity Summary',
      subtitle:
          'Authorized class quotas, current enrollment count, active pipeline, and remaining capacity',
      icon: Icons.pie_chart_outline,
      iconColor: AppColors.brandNavy,
      child: studentsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        data: (students) {
          final enquiries = enquiriesAsync.valueOrNull ?? [];

          // Standard class quotas for LAV Academy
          final quotas = [
            {'class': 'Class 9', 'classId': '9', 'quota': 80},
            {'class': 'Class 10', 'classId': '10', 'quota': 80},
            {'class': 'Class 11-Science', 'classId': '11', 'quota': 60},
            {'class': 'Class 12-Science', 'classId': '12', 'quota': 60},
          ];

          return Column(
            children: [
              for (final q in quotas) ...[
                Builder(builder: (context) {
                  final cid = q['classId'] as String;
                  final quota = q['quota'] as int;
                  final enrolled = students
                      .where((s) => s.currentClassId.contains(cid))
                      .length;
                  final pipeline = enquiries
                      .where((e) => (e['targetClass'] ?? '').toString().contains(cid))
                      .length;
                  final remaining = (quota - enrolled).clamp(0, quota);
                  final fillPct = (enrolled / quota).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              q['class'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              'Enrolled: $enrolled / $quota • Pipeline: $pipeline • Left: $remaining',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fillPct,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              fillPct > 0.9
                                  ? AppColors.dangerRed
                                  : (fillPct > 0.7
                                      ? AppColors.warningAmber
                                      : AppColors.admissionsOrange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // FILTERED QUEUES VIEW (For Navigation Destinations 1, 2, 3)
  // ==========================================================================
  Widget _buildFilteredQueueView(String mode) {
    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);

    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (mode) {
      case 'verification':
        title = 'Document Verification Queue';
        subtitle = 'Compliance and verification of prospective candidate files';
        icon = Icons.verified_user_outlined;
        color = AppColors.infoSky;
        break;
      case 'approved':
        title = 'Approved Applications Awaiting Cohort Enrollment';
        subtitle = 'Authorized candidates cleared for formal student registration';
        icon = Icons.how_to_reg_outlined;
        color = AppColors.accountantEmerald;
        break;
      case 'review':
      default:
        title = 'Application Review & Decision Queue';
        subtitle = 'All pending applications under active institutional evaluation';
        icon = Icons.rate_review_outlined;
        color = AppColors.admissionsOrange;
        break;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        ErpCard(
          title: title,
          subtitle: subtitle,
          icon: icon,
          iconColor: color,
          headerTrailing: ErpButton(
            icon: Icons.arrow_back,
            label: 'Back to Dashboard',
            isDense: true,
            isPrimary: false,
            color: AppColors.textSecondary,
            onPressed: () => setState(() => _currentNavIndex = 0),
          ),
          child: mode == 'verification'
              ? _buildDocumentVerificationQueue(enquiriesAsync)
              : (mode == 'approved'
                  ? _buildApprovedAwaitingEnrollment(enquiriesAsync)
                  : _buildApplicationReviewQueue(enquiriesAsync)),
        ),
      ],
    );
  }

  // ==========================================================================
  // HELPER WORKFLOWS: DIALOGS & ACTIONS
  // ==========================================================================
  void _showCreateApplicationDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final guardianCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String targetClass = '10';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.admissionsOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person_add_alt_1,
                    size: 20, color: AppColors.admissionsOrange),
              ),
              const SizedBox(width: 12),
              const Text(
                'Register New Candidate Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registers a prospective student in the admissions intake pipeline with AY 2026-2027 credentials.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Applicant Full Name*',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: targetClass,
                          decoration: const InputDecoration(
                            labelText: 'Applying For Class*',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: '9', child: Text('Class 9')),
                            DropdownMenuItem(value: '10', child: Text('Class 10')),
                            DropdownMenuItem(value: '11', child: Text('Class 11')),
                            DropdownMenuItem(value: '12', child: Text('Class 12')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => targetClass = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: guardianCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Guardian Name*',
                            prefixIcon: Icon(Icons.family_restroom),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (+91)*',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Demographic Notes & Prior School',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ErpButton(
              label: 'Submit Application',
              color: AppColors.admissionsOrange,
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    phoneCtrl.text.trim().isEmpty ||
                    guardianCtrl.text.trim().isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Applicant name, guardian name, and phone are mandatory.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(studentRepositoryProvider).createEnquiry(
                        applicantName: nameCtrl.text.trim(),
                        targetClass: targetClass,
                        guardianName: guardianCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.admissionsOrange,
                        content: Text(
                            'Application recorded for ${nameCtrl.text.trim()}!'),
                      ),
                    );
                  }
                } catch (err) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error registering candidate: $err')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      guardianCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  void _showRecordDecisionDialog(
      BuildContext context, Map<String, dynamic> app) {
    final messenger = ScaffoldMessenger.of(context);
    final notesCtrl = TextEditingController();
    String decision = 'approved';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            'Record Decision: ${app['applicantName']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class ${app['targetClass']} • Guardian: ${app['guardianName']}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: decision,
                decoration: const InputDecoration(
                  labelText: 'Admission Decision*',
                  prefixIcon: Icon(Icons.gavel_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'approved', child: Text('Approve for Enrollment')),
                  DropdownMenuItem(
                      value: 'under_review',
                      child: Text('Under Active Committee Review')),
                  DropdownMenuItem(
                      value: 'incomplete',
                      child: Text('Incomplete - Require Information')),
                  DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Reject Application')),
                  DropdownMenuItem(
                      value: 'withdrawn', child: Text('Withdrawn by Parent')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => decision = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Decision Justification / Reviewer Notes',
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ErpButton(
              label: 'Save Decision',
              color: AppColors.admissionsOrange,
              onPressed: () async {
                final notes = notesCtrl.text.trim();
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(studentRepositoryProvider)
                      .updateApplicationStatus(
                        enquiryId: app['id'],
                        newStatus: decision,
                        reviewerNotes: notes.isEmpty ? null : notes,
                      );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.accountantEmerald,
                        content: Text(
                            'Decision "$decision" committed for ${app['applicantName']}'),
                      ),
                    );
                  }
                } catch (err) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update decision: $err')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() => notesCtrl.dispose());
  }

  void _showDocumentVerificationDialog(
      BuildContext context, Map<String, dynamic> app) {
    final messenger = ScaffoldMessenger.of(context);
    bool birthCert = true;
    bool tcCert = true;
    bool reportCard = true;
    bool addressProof = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            'Verify Documents: ${app['applicantName']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify certified copies of statutory candidate admission documents:',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: birthCert,
                title: const Text('Birth Certificate (Municipal/Govt)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onChanged: (val) => setModalState(() => birthCert = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: tcCert,
                title: const Text('Transfer Certificate (Prior School TC)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onChanged: (val) => setModalState(() => tcCert = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: reportCard,
                title: const Text('Previous Academic Year Report Card',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onChanged: (val) =>
                    setModalState(() => reportCard = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: addressProof,
                title: const Text('Residential Address Verification Document',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onChanged: (val) =>
                    setModalState(() => addressProof = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ErpButton(
              label: 'Certify All Documents',
              color: AppColors.accountantEmerald,
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(studentRepositoryProvider)
                      .updateApplicationStatus(
                        enquiryId: app['id'],
                        newStatus: 'documents_verified',
                        reviewerNotes: 'All mandatory compliance files verified.',
                      );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.accountantEmerald,
                        content: Text(
                            'Documents verified for ${app['applicantName']}'),
                      ),
                    );
                  }
                } catch (err) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error updating status: $err')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectEnrollModal(BuildContext context, Map<String, dynamic> app) {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl =
        TextEditingController(text: app['applicantName']?.toString() ?? '');
    final admNoCtrl = TextEditingController(
        text: 'LAV-${DateTime.now().year}-${DateTime.now().millisecond}');
    final classCtrl =
        TextEditingController(text: app['targetClass']?.toString() ?? '10');
    final secCtrl = TextEditingController(text: 'A');
    final contactCtrl =
        TextEditingController(text: app['phone']?.toString() ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Enroll Approved Student: ${app['applicantName']}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Creates an institutional Student record with strict empty guardianUserIds array and marks application as enrolled.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Student Full Name*'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: admNoCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Admission Number*'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: classCtrl,
                      decoration: const InputDecoration(labelText: 'Class ID*'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: secCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Section ID*'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Emergency Contact*'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ErpButton(
            label: 'Complete Matriculation',
            color: AppColors.accountantEmerald,
            onPressed: () async {
              final studentId = 'STU_${DateTime.now().millisecondsSinceEpoch}';
              Navigator.pop(ctx);
              try {
                await ref.read(studentRepositoryProvider).enrollStudent(
                      Student(
                        studentId: studentId,
                        admissionNumber: admNoCtrl.text.trim(),
                        fullName: nameCtrl.text.trim(),
                        currentClassId: classCtrl.text.trim(),
                        currentSectionId: secCtrl.text.trim(),
                        currentAcademicYearId: 'AY_2026_2027',
                        emergencyContact: contactCtrl.text.trim(),
                      ),
                    );

                await ref.read(studentRepositoryProvider).updateApplicationStatus(
                      enquiryId: app['id'],
                      newStatus: 'enrolled',
                      reviewerNotes: 'Enrolled under Student ID $studentId',
                    );

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.accountantEmerald,
                      content: Text(
                          'Student enrolled with Institutional ID $studentId!'),
                    ),
                  );
                }
              } catch (err) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Enrollment failed: $err')),
                  );
                }
              }
            },
          ),
        ],
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      admNoCtrl.dispose();
      classCtrl.dispose();
      secCtrl.dispose();
      contactCtrl.dispose();
    });
  }

  void _updateStatusWithConfirm(
      BuildContext context, String enquiryId, String newStatus, String message) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Confirm Status Change',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ErpButton(
            label: 'Confirm',
            color: AppColors.admissionsOrange,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(studentRepositoryProvider)
                    .updateApplicationStatus(
                      enquiryId: enquiryId,
                      newStatus: newStatus,
                    );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Status updated to $newStatus')),
                  );
                }
              } catch (err) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Status update error: $err')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String? status) {
    final s = status ?? 'enquiry';
    Color bg;
    Color fg;
    String label;

    switch (s) {
      case 'approved':
        bg = const Color(0xFFECFDF5);
        fg = AppColors.accountantEmerald;
        label = 'Approved';
        break;
      case 'enrolled':
        bg = const Color(0xFFEFF6FF);
        fg = AppColors.brandNavy;
        label = 'Enrolled';
        break;
      case 'documents_verified':
        bg = const Color(0xFFF0FDF4);
        fg = AppColors.successGreen;
        label = 'Docs Verified';
        break;
      case 'under_review':
        bg = const Color(0xFFFEF3C7);
        fg = AppColors.warningAmber;
        label = 'Under Review';
        break;
      case 'incomplete':
      case 'blocked':
        bg = const Color(0xFFFEF2F2);
        fg = AppColors.dangerRed;
        label = 'Incomplete';
        break;
      case 'rejected':
      case 'withdrawn':
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.textSecondary;
        label = s[0].toUpperCase() + s.substring(1);
        break;
      case 'applied':
      case 'enquiry':
      default:
        bg = const Color(0xFFFFF7ED);
        fg = AppColors.admissionsOrange;
        label = 'Applied';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildApplicationMobileCard(Map<String, dynamic> e) {
    return ErpCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  e['applicantName'] ?? 'Candidate',
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(e['status']?.toString()),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Applying For: Class ${e['targetClass']} • Guardian: ${e['guardianName']} (${e['phone']})',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ErpButton(
                label: 'Review',
                isDense: true,
                color: AppColors.admissionsOrange,
                onPressed: () => _showRecordDecisionDialog(context, e),
              ),
              const SizedBox(width: 8),
              ErpButton(
                label: 'Verify Docs',
                isDense: true,
                isPrimary: false,
                color: AppColors.infoSky,
                onPressed: () => _showDocumentVerificationDialog(context, e),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 5: ENROLLED STUDENTS REGISTRY (Full institutional directory)
  // ==========================================================================
  Widget _buildStudentsListTab() {
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        ErpCard(
          title: 'Institutional Enrolled Students Registry',
          subtitle:
              'Official database of matriculated students with class, blood group, and guardian associations',
          icon: Icons.people_outline,
          iconColor: AppColors.admissionsOrange,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ErpButton(
                icon: Icons.person_add_alt_1,
                label: 'New Enrollment',
                isDense: true,
                color: AppColors.admissionsOrange,
                onPressed: () => setState(() => _currentNavIndex = 5),
              ),
              const SizedBox(width: 8),
              studentsAsync.maybeWhen(
                data: (students) => ErpButton(
                  icon: Icons.download,
                  label: 'Export CSV',
                  isPrimary: false,
                  isDense: true,
                  color: AppColors.textSecondary,
                  onPressed: () =>
                      DataExportService.exportStudentsCsv(students),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          child: studentsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading student records: $err',
                style: const TextStyle(color: AppColors.dangerRed),
              ),
            ),
            data: (students) {
              if (students.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 44, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No Enrolled Students Found',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'The institutional student registry is currently empty.',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ErpDataView<Student>(
                items: students,
                columns: [
                  ErpColumn<Student>(
                    title: 'Adm No',
                    flex: 2,
                    cellBuilder: (s) => Text(
                      s.admissionNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ErpColumn<Student>(
                    title: 'Student Name',
                    flex: 3,
                    cellBuilder: (s) => Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.admissionsOrange
                              .withValues(alpha: 0.15),
                          child: Text(
                            s.fullName.isNotEmpty
                                ? s.fullName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.admissionsOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ErpColumn<Student>(
                    title: 'Class & Section',
                    flex: 2,
                    cellBuilder: (s) =>
                        Text('${s.currentClassId}-${s.currentSectionId}'),
                  ),
                  ErpColumn<Student>(
                    title: 'Blood Group',
                    flex: 2,
                    cellBuilder: (s) => Text(s.bloodGroup ?? '—'),
                  ),
                  ErpColumn<Student>(
                    title: 'Guardian Status',
                    flex: 3,
                    cellBuilder: (s) => Text(
                      s.guardianUserIds.isNotEmpty
                          ? 'Linked (${s.guardianUserIds.length})'
                          : 'Unlinked',
                      style: TextStyle(
                        color: s.guardianUserIds.isNotEmpty
                            ? AppColors.successGreen
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ErpColumn<Student>(
                    title: 'Action',
                    flex: 1.5,
                    textAlign: TextAlign.right,
                    cellBuilder: (s) => Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.edit_note,
                            color: AppColors.admissionsOrange),
                        tooltip: 'Edit Demographics Allowlist',
                        onPressed: () => _showEditDemographicsDialog(s),
                      ),
                    ),
                  ),
                ],
                mobileCardBuilder: (context, student) => ErpCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.admissionsOrange
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    student.fullName.isNotEmpty
                                        ? student.fullName[0].toUpperCase()
                                        : 'S',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.admissionsOrange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Adm: ${student.admissionNumber}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note,
                                color: AppColors.admissionsOrange),
                            tooltip: 'Edit Demographics Allowlist',
                            onPressed: () =>
                                _showEditDemographicsDialog(student),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.borderLight, width: 1),
                            ),
                            child: Text(
                              'Class: ${student.currentClassId}-${student.currentSectionId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.borderLight, width: 1),
                            ),
                            child: Text(
                              'Blood: ${student.bloodGroup ?? '—'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.borderLight, width: 1),
                            ),
                            child: Text(
                              student.guardianUserIds.isNotEmpty
                                  ? '${student.guardianUserIds.length} Linked'
                                  : 'No Guardians',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // SECTION 6: NEW ADMISSION FORM (Dedicated Tab)
  // ==========================================================================
  Widget _buildNewAdmissionTab() {
    final nameCtrl = _newStudentNameCtrl;
    final admNoCtrl = _admissionNumberCtrl;
    final classCtrl = _newClassCtrl;
    final secCtrl = _newSectionCtrl;
    final contactCtrl = _emergencyContactCtrl;
    final bgCtrl = _bloodGroupCtrl;
    final addressCtrl = _addressCtrl;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Direct Institutional Student Enrollment',
          subtitle:
              'Security Rule Constraint: Direct client creation strictly enforces guardianUserIds: []. Guardians are linked exclusively via the privileged Cloud Function.',
          icon: Icons.person_add_alt_1,
          iconColor: AppColors.admissionsOrange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Full Name*',
                  hintText: 'e.g. Diya Nair',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: admNoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Admission Number*',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: bgCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        prefixIcon: Icon(Icons.bloodtype_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: classCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Class ID (e.g. 10)*',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: secCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Section ID (e.g. A)*',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone*',
                  hintText: '+91 98765 43210',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Residential Address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ErpButton(
                label: 'Complete Institutional Enrollment',
                icon: Icons.person_add,
                color: AppColors.admissionsOrange,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      admNoCtrl.text.trim().isEmpty ||
                      classCtrl.text.trim().isEmpty ||
                      secCtrl.text.trim().isEmpty ||
                      contactCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Enter student name, admission number, class, section and phone.')),
                    );
                    return;
                  }
                  final sId =
                      'STU_${DateTime.now().millisecondsSinceEpoch}';
                  try {
                    await ref.read(studentRepositoryProvider).enrollStudent(
                          Student(
                            studentId: sId,
                            admissionNumber: admNoCtrl.text.trim(),
                            fullName: nameCtrl.text.trim(),
                            currentClassId: classCtrl.text.trim(),
                            currentSectionId: secCtrl.text.trim(),
                            currentAcademicYearId: 'AY_2026_2027',
                            emergencyContact: contactCtrl.text.trim(),
                            bloodGroup: bgCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                          ),
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.accountantEmerald,
                          content: Text(
                              'Student ${nameCtrl.text} enrolled successfully with ID $sId!'),
                        ),
                      );
                      nameCtrl.clear();
                      admNoCtrl.clear();
                      classCtrl.clear();
                      secCtrl.clear();
                      contactCtrl.clear();
                      bgCtrl.clear();
                      addressCtrl.clear();
                      setState(() => _currentNavIndex = 4);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Enrollment failed: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // SECTION 7: LINK GUARDIAN (Dedicated Tab)
  // ==========================================================================
  Widget _buildLinkGuardianTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Link Guardian Account to Student Record',
          subtitle:
              'Authoritative Cloud Function: links parent account UID to student.guardianUserIds, syncs Firebase Auth custom claims, and increments tokenVersion for instant revocation on unlinking.',
          icon: Icons.link,
          iconColor: AppColors.admissionsOrange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _guardianStudentIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Record ID (e.g. STU_1710000000)*',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guardianUidCtrl,
                decoration: const InputDecoration(
                  labelText: 'Parent/Guardian User Account UID*',
                  prefixIcon: Icon(Icons.account_circle_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guardianRelationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Relationship (Father, Mother, Legal Guardian)*',
                  prefixIcon: Icon(Icons.family_restroom),
                ),
              ),
              const SizedBox(height: 24),
              ErpButton(
                label: 'Authorize & Link Guardian Account',
                icon: Icons.link,
                color: AppColors.admissionsOrange,
                onPressed: () async {
                  if (_guardianStudentIdCtrl.text.trim().isEmpty ||
                      _guardianUidCtrl.text.trim().isEmpty ||
                      _guardianRelationCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Enter student ID, guardian account UID and relationship.')),
                    );
                    return;
                  }
                  try {
                    await ref.read(studentRepositoryProvider).linkGuardian(
                          studentId: _guardianStudentIdCtrl.text.trim(),
                          guardianUid: _guardianUidCtrl.text.trim(),
                          relationship: _guardianRelationCtrl.text.trim(),
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.accountantEmerald,
                          content: Text(
                              'Guardian linked successfully! Claims and tokenVersion updated.'),
                        ),
                      );
                      _guardianStudentIdCtrl.clear();
                      _guardianUidCtrl.clear();
                      _guardianRelationCtrl.clear();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Guardian linking failed: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDemographicsDialog(Student student) {
    final messenger = ScaffoldMessenger.of(context);
    final contactCtrl =
        TextEditingController(text: student.emergencyContact ?? '');
    final bgCtrl = TextEditingController(text: student.bloodGroup ?? '');
    final notesCtrl = TextEditingController(text: student.medicalNotes ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Edit Demographics: ${student.fullName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Only demographic fields are updated here. Student identity, class, section and guardian links remain managed by dedicated workflows.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Emergency Contact',
                      prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 12),
              TextFormField(
                  controller: bgCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon: Icon(Icons.bloodtype_outlined))),
              const SizedBox(height: 12),
              TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Medical Notes',
                      prefixIcon: Icon(Icons.medical_services_outlined))),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ErpButton(
            label: 'Save Demographics',
            color: AppColors.admissionsOrange,
            onPressed: () async {
              final emergencyContact = contactCtrl.text.trim();
              final bloodGroup = bgCtrl.text.trim();
              final medicalNotes = notesCtrl.text.trim();
              Navigator.pop(ctx);
              try {
                await ref
                    .read(studentRepositoryProvider)
                    .updateStudentDemographics(
                      studentId: student.studentId,
                      emergencyContact: emergencyContact,
                      bloodGroup: bloodGroup,
                      medicalNotes: medicalNotes,
                    );
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.accountantEmerald,
                      content: Text('Demographics updated successfully.'),
                    ),
                  );
                }
              } catch (error) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Demographics update failed: $error')),
                  );
                }
              }
            },
          ),
        ],
      ),
    ).whenComplete(() {
      contactCtrl.dispose();
      bgCtrl.dispose();
      notesCtrl.dispose();
    });
  }
}
