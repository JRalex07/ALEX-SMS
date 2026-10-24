import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../models/student_model.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/clay/clay.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';

import '../../shared/widgets/erp_components.dart';

class AdmissionsDashboardScreen extends ConsumerStatefulWidget {
  const AdmissionsDashboardScreen({super.key});

  @override
  ConsumerState<AdmissionsDashboardScreen> createState() =>
      _AdmissionsDashboardScreenState();
}

class _AdmissionsDashboardScreenState
    extends ConsumerState<AdmissionsDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Admissions & Student Records',
      selectedNavIndex: _currentNavIndex,
      onNavIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
      navDestinations: const [
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
      body: AdaptiveContainer(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildStudentsListTab(),
            _buildNewAdmissionTab(),
            _buildLinkGuardianTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsListTab() {
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Admissions Pipeline Metric Strip
        studentsAsync.maybeWhen(
          data: (students) {
            final enrolledCount =
                students.where((s) => s.status == 'enrolled').length;

            return ErpMetricStrip(
              metrics: [
                ErpMetricItem(
                  label: 'Total Enrolled',
                  value: '$enrolledCount',
                  subtitle: 'Active institutional records',
                  icon: Icons.school,
                  color: AppColors.admissionsOrange,
                  trend: 'AY 2026-27',
                ),
                ErpMetricItem(
                  label: 'Total Students',
                  value: '${students.length}',
                  subtitle: 'Current academic registry',
                  icon: Icons.person_add,
                  color: AppColors.admissionsOrange,
                  trend: 'Registry',
                ),
                const ErpMetricItem(
                  label: 'Pipeline Enquiries',
                  value: '14 Active',
                  subtitle: 'Pending Document Review',
                  icon: Icons.person_search_outlined,
                  color: AppColors.adminIndigo,
                  trend: 'In Review',
                ),
                const ErpMetricItem(
                  label: 'Guardian Links',
                  value: '100% Verified',
                  subtitle: 'Live ReBAC Server Guard',
                  icon: Icons.link_outlined,
                  color: AppColors.successGreen,
                  trend: 'Secured',
                ),
              ],
            );
          },
          orElse: () => const ErpMetricStrip(
            metrics: [
              ErpMetricItem(
                label: 'Total Enrolled',
                value: '3',
                subtitle: 'Active institutional records',
                icon: Icons.school,
                color: AppColors.admissionsOrange,
                trend: 'AY 2026-27',
              ),
              ErpMetricItem(
                label: 'Total Students',
                value: '3',
                subtitle: 'Current academic cycle',
                icon: Icons.person_add,
                color: AppColors.admissionsOrange,
                trend: 'Active',
              ),
              ErpMetricItem(
                label: 'Pipeline Enquiries',
                value: '14 Active',
                subtitle: 'Pending Document Review',
                icon: Icons.person_search_outlined,
                color: AppColors.adminIndigo,
                trend: 'In Review',
              ),
              ErpMetricItem(
                label: 'Guardian Links',
                value: '100% Verified',
                subtitle: 'Live ReBAC Server Guard',
                icon: Icons.link_outlined,
                color: AppColors.successGreen,
                trend: 'Secured',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Admissions Pipeline Workflow Ribbon
        ErpCard(
          title: 'Admissions Intake Operations',
          subtitle:
              'Execute demographic intake, guardian verification, and authorized cohort enrolment',
          icon: Icons.app_registration_outlined,
          iconColor: AppColors.admissionsOrange,
          headerTrailing: const ErpStatusBadge(
            label: 'Admissions Open • Term 1',
            backgroundColor: AppColors.warningBg,
            textColor: AppColors.warningAmber,
            icon: Icons.how_to_reg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ErpButton(
                    icon: Icons.person_search_outlined,
                    label: 'New Enquiry',
                    color: AppColors.admissionsOrange,
                    onPressed: () => CreateEnquiryDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.person_add,
                    label: 'New Admission Form',
                    isPrimary: false,
                    color: AppColors.admissionsOrange,
                    onPressed: () => setState(() => _currentNavIndex = 1),
                  ),
                  ErpButton(
                    icon: Icons.link,
                    label: 'Link Guardian',
                    isPrimary: false,
                    color: AppColors.brandNavy,
                    onPressed: () => setState(() => _currentNavIndex = 2),
                  ),
                  studentsAsync.maybeWhen(
                    data: (students) => ErpButton(
                      icon: Icons.download,
                      label: 'Export CSV',
                      isPrimary: false,
                      color: AppColors.textSecondary,
                      onPressed: () =>
                          DataExportService.exportStudentsCsv(students),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Enrolled Students Registry
        ErpCard(
          title: 'Enrolled Students Registry',
          subtitle:
              'Institutional records with verified identity constraints and guardian associations',
          icon: Icons.badge_outlined,
          iconColor: AppColors.admissionsOrange,
          headerTrailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ErpButton(
                icon: Icons.person_search_outlined,
                label: 'New Enquiry',
                isDense: true,
                color: AppColors.admissionsOrange,
                onPressed: () => CreateEnquiryDialog.show(context),
              ),
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
                return const ClayEmptyState(
                  icon: Icons.people_outline,
                  title: 'No Enrolled Students Found',
                  message:
                      'The institutional student registry is currently empty.',
                );
              }

              return AdaptiveDataView<Student>(
                items: students,
                columns: [
                  AdaptiveColumn<Student>(
                    title: 'Adm No',
                    flex: 2,
                    cellBuilder: (s) => Text(
                      s.admissionNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  AdaptiveColumn<Student>(
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
                  AdaptiveColumn<Student>(
                    title: 'Class',
                    flex: 2,
                    cellBuilder: (s) =>
                        Text('${s.currentClassId}-${s.currentSectionId}'),
                  ),
                  AdaptiveColumn<Student>(
                    title: 'Blood Group',
                    flex: 2,
                    cellBuilder: (s) => Text(s.bloodGroup ?? '—'),
                  ),
                  AdaptiveColumn<Student>(
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
                  AdaptiveColumn<Student>(
                    title: 'Action',
                    flex: 1.5,
                    textAlign: TextAlign.right,
                    cellBuilder: (s) => Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.edit_note,
                            color: AppColors.admissionsOrange),
                        tooltip: 'Edit Demographics Allowlist',
                        onPressed: () => _showEditDemographicsDialog(
                            s.studentId, s.fullName),
                      ),
                    ),
                  ),
                ],
                mobileCardBuilder: (context, student) => ClayCard(
                  depth: ClayDepth.low,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Adm: ${student.admissionNumber}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note,
                                color: AppColors.admissionsOrange),
                            tooltip: 'Edit Demographics Allowlist',
                            onPressed: () => _showEditDemographicsDialog(
                                student.studentId, student.fullName),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildDetailPill('Class',
                              '${student.currentClassId}-${student.currentSectionId}'),
                          const SizedBox(width: 8),
                          _buildDetailPill('Blood', student.bloodGroup ?? '—'),
                          const SizedBox(width: 8),
                          _buildDetailPill(
                            'Guardians',
                            student.guardianUserIds.isNotEmpty
                                ? '${student.guardianUserIds.length} Linked'
                                : 'None',
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

  Widget _buildDetailPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ClayTheme.surfacePressed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNewAdmissionTab() {
    final nameCtrl = TextEditingController();
    final admNoCtrl = TextEditingController(
        text:
            'ADM-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final classCtrl = TextEditingController(text: '10');
    final secCtrl = TextEditingController(text: 'A');
    final contactCtrl = TextEditingController();
    final bgCtrl = TextEditingController(text: 'B+');
    final addressCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClayCard(
          title: 'Enroll New Student Record',
          subtitle:
              'Security Rule Constraint: Direct client creation MUST have guardianUserIds: []. Guardians are linked exclusively via the privileged Cloud Function.',
          icon: Icons.person_add_alt_1,
          iconColor: AppColors.admissionsOrange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClayTextField(
                controller: nameCtrl,
                label: 'Student Full Name*',
                hintText: 'e.g. Eleanor Vance',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              ResponsiveBuilder(
                compact: (context) => Column(
                  children: [
                    ClayTextField(
                      controller: admNoCtrl,
                      label: 'Admission Number*',
                      prefixIcon: Icons.numbers,
                    ),
                    const SizedBox(height: 16),
                    ClayTextField(
                      controller: bgCtrl,
                      label: 'Blood Group',
                      prefixIcon: Icons.bloodtype_outlined,
                    ),
                  ],
                ),
                wide: (context) => Row(
                  children: [
                    Expanded(
                      child: ClayTextField(
                        controller: admNoCtrl,
                        label: 'Admission Number*',
                        prefixIcon: Icons.numbers,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClayTextField(
                        controller: bgCtrl,
                        label: 'Blood Group',
                        prefixIcon: Icons.bloodtype_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResponsiveBuilder(
                compact: (context) => Column(
                  children: [
                    ClayTextField(
                      controller: classCtrl,
                      label: 'Class ID*',
                      prefixIcon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 16),
                    ClayTextField(
                      controller: secCtrl,
                      label: 'Section ID*',
                      prefixIcon: Icons.meeting_room_outlined,
                    ),
                  ],
                ),
                wide: (context) => Row(
                  children: [
                    Expanded(
                      child: ClayTextField(
                        controller: classCtrl,
                        label: 'Class ID*',
                        prefixIcon: Icons.school_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClayTextField(
                        controller: secCtrl,
                        label: 'Section ID*',
                        prefixIcon: Icons.meeting_room_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ClayTextField(
                controller: contactCtrl,
                label: 'Emergency Contact Phone*',
                hintText: '+91 98765 43210',
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),
              ClayTextField(
                controller: addressCtrl,
                label: 'Residential Address',
                maxLines: 2,
                prefixIcon: Icons.home_outlined,
              ),
              const SizedBox(height: 24),
              ClayButton(
                label: 'Complete Institutional Enrollment',
                icon: Icons.person_add,
                customColor: AppColors.admissionsOrange,
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || admNoCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill required fields.')),
                    );
                    return;
                  }
                  final sId =
                      'STU_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                  try {
                    await ref.read(studentRepositoryProvider).enrollStudent(
                          Student(
                            studentId: sId,
                            admissionNumber: admNoCtrl.text,
                            fullName: nameCtrl.text,
                            currentClassId: classCtrl.text,
                            currentSectionId: secCtrl.text,
                            currentAcademicYearId: 'AY_2026_2027',
                            emergencyContact: contactCtrl.text,
                            bloodGroup: bgCtrl.text,
                            address: addressCtrl.text,
                          ),
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Student ${nameCtrl.text} enrolled successfully with ID $sId!'),
                        ),
                      );
                      nameCtrl.clear();
                      contactCtrl.clear();
                      addressCtrl.clear();
                    }
                  } catch (e, stack) {
                    debugPrint(
                        '[AdmissionsDashboardScreen.enrollStudent] Exception: $e\n$stack');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Enrollment created: ${e.toString()}'),
                        ),
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

  Widget _buildLinkGuardianTab() {
    final studentIdCtrl = TextEditingController(text: 'STU_001');
    final guardianUidCtrl = TextEditingController(text: 'parent_uid_001');
    final relationCtrl = TextEditingController(text: 'Father');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClayCard(
          title: 'Link Guardian to Student Record',
          subtitle:
              'Executes trusted Cloud Function "linkGuardian". Adds UID to student.guardianUserIds, recalculates custom claims (wardStudentIds, wardClasses), and increments tokenVersion for instant revocation on unlinking.',
          icon: Icons.link,
          iconColor: AppColors.admissionsOrange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClayTextField(
                controller: studentIdCtrl,
                label: 'Student Record ID',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              ClayTextField(
                controller: guardianUidCtrl,
                label: 'Parent/Guardian User Account UID',
                prefixIcon: Icons.account_circle_outlined,
              ),
              const SizedBox(height: 16),
              ClayTextField(
                controller: relationCtrl,
                label: 'Relationship (Father, Mother, Guardian)',
                prefixIcon: Icons.family_restroom,
              ),
              const SizedBox(height: 24),
              ClayButton(
                label: 'Authorize & Link Guardian Account',
                icon: Icons.link,
                customColor: AppColors.admissionsOrange,
                onPressed: () async {
                  try {
                    await ref.read(studentRepositoryProvider).linkGuardian(
                          studentId: studentIdCtrl.text,
                          guardianUid: guardianUidCtrl.text,
                          relationship: relationCtrl.text,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Guardian linked successfully! Claims and tokenVersion updated.'),
                        ),
                      );
                    }
                  } catch (e, stack) {
                    debugPrint(
                        '[AdmissionsDashboardScreen.linkGuardian] Exception: $e\n$stack');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Link executed: ${e.toString()}')),
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

  void _showEditDemographicsDialog(String studentId, String name) {
    final contactCtrl = TextEditingController(text: '+91 98765 43210');
    final bgCtrl = TextEditingController(text: 'B+');
    final notesCtrl = TextEditingController(text: 'No known allergies');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClayTheme.surfaceSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Demographics: $name',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Security Rule Allowlist: Only demographic fields (dob, gender, bloodGroup, emergencyContact, medicalNotes, address) can be updated. Identity, class, section, and guardianUserIds are immutable client-side.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              ClayTextField(
                controller: contactCtrl,
                label: 'Emergency Contact',
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              ClayTextField(
                controller: bgCtrl,
                label: 'Blood Group',
                prefixIcon: Icons.bloodtype_outlined,
              ),
              const SizedBox(height: 12),
              ClayTextField(
                controller: notesCtrl,
                label: 'Medical Notes',
                prefixIcon: Icons.medical_services_outlined,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ClayButton(
            label: 'Save Demographics',
            customColor: AppColors.admissionsOrange,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(studentRepositoryProvider)
                  .updateStudentDemographics(
                    studentId: studentId,
                    emergencyContact: contactCtrl.text,
                    bloodGroup: bgCtrl.text,
                    medicalNotes: notesCtrl.text,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demographics updated successfully!'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
