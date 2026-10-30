import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/admission_application_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/confirm_action_dialog.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class AdmissionDetailScreen extends ConsumerStatefulWidget {
  final String applicationId;

  const AdmissionDetailScreen({super.key, required this.applicationId});

  @override
  ConsumerState<AdmissionDetailScreen> createState() =>
      _AdmissionDetailScreenState();
}

class _AdmissionDetailScreenState extends ConsumerState<AdmissionDetailScreen> {
  final _reviewerNotesCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _reviewerNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(
      AdmissionApplication app, String decision) async {
    final user = ref.read(currentUserProfileProvider).value;
    final reviewerName = user?.displayName ?? 'Admissions Officer';
    final reviewerUid = user?.uid ?? 'AUTH_OFFICER';

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Confirm Admission Decision: ${decision.toUpperCase()}',
      message:
          'Are you sure you want to mark application ${app.id} for ${app.fullName} as ${decision.toUpperCase()}?',
      confirmLabel: 'Confirm $decision',
      confirmColor: decision == 'approved'
          ? AppColors.successGreen
          : (decision == 'rejected'
              ? AppColors.dangerRed
              : AppColors.brandNavy),
      isDestructive: decision == 'rejected',
      requireReason: decision == 'rejected',
      onConfirm: (reason) async {
        final repo = ref.read(admissionRepositoryProvider);
        await repo.recordDecision(
          applicationId: app.id,
          decision: decision,
          reviewerUid: reviewerUid,
          reviewerName: reviewerName,
          notes: _reviewerNotesCtrl.text.trim(),
          reason: reason,
        );
      },
    );

    if (confirmed == true && mounted) {
      ref.invalidate(admissionApplicationByIdProvider(app.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: decision == 'approved'
              ? AppColors.successGreen
              : (decision == 'rejected'
                  ? AppColors.dangerRed
                  : AppColors.brandNavy),
          content: Text('Application ${app.id} marked as $decision!'),
        ),
      );
    }
  }

  Future<void> _handleEnrollment(AdmissionApplication app) async {
    final assignedClassCtrl = TextEditingController(text: app.targetClass);
    final assignedSectionCtrl = TextEditingController(text: app.targetSection);
    final year = DateTime.now().year;
    final randomAdm = (DateTime.now().millisecondsSinceEpoch % 1000)
        .toString()
        .padLeft(3, '0');
    final admNumberCtrl = TextEditingController(text: 'ADM-$year-$randomAdm');

    final enrolled = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.how_to_reg, color: AppColors.successGreen, size: 26),
            SizedBox(width: 10),
            Text('Enroll Applicant as Student'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrolling ${app.fullName} will create an active Student record in the institutional database and generate an admission register entry.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: admNumberCtrl,
              decoration: const InputDecoration(
                  labelText: 'Permanent Admission Number *'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: assignedClassCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Enrolled Class *'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: assignedSectionCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Assigned Section *'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.successGreen),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Enrollment'),
          ),
        ],
      ),
    );

    if (enrolled == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        final repo = ref.read(admissionRepositoryProvider);
        final user = ref.read(currentUserProfileProvider).value;
        final student = await repo.enrollApplicant(
          application: app,
          assignedClass: assignedClassCtrl.text.trim(),
          assignedSection: assignedSectionCtrl.text.trim(),
          admissionNumber: admNumberCtrl.text.trim(),
          enrollerName: user?.displayName ?? 'Admissions Officer',
        );

        ref.invalidate(admissionApplicationByIdProvider(app.id));
        ref.invalidate(allStudentsStreamProvider);

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.successGreen, size: 28),
                  SizedBox(width: 10),
                  Text('Enrollment Complete'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.fullName} is now enrolled as an official student in Class ${student.currentClassId}-${student.currentSectionId}.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Admission Number: ${student.admissionNumber}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandNavy)),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: AppColors.dangerRed,
                content: Text('Enrollment failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAsync =
        ref.watch(admissionApplicationByIdProvider(widget.applicationId));
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return ResponsiveScaffold(
      title: 'Application Review & Decision',
      currentRoute: AppRoutes.admissions,
      actions: [
        appAsync.when(
          data: (app) {
            if (app == null) return const SizedBox.shrink();
            return Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print Application'),
                  onPressed: () {
                    PrintPreviewDialog.showAdmissionApplication(context,
                        application: app);
                  },
                ),
                const SizedBox(width: 8),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
      body: appAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Error loading application record: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
        ),
        data: (app) {
          if (app == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Application record not found.'),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : 16,
              vertical: 24,
            ),
            children: [
              _buildStatusBar(app),
              const SizedBox(height: 20),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildApplicantCard(app)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildDecisionPanel(app)),
                  ],
                )
              else ...[
                _buildApplicantCard(app),
                const SizedBox(height: 20),
                _buildDecisionPanel(app),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBar(AdmissionApplication app) {
    Color bg = AppColors.brandNavy;
    if (app.isApproved) bg = AppColors.successGreen;
    if (app.isEnrolled) bg = AppColors.brandNavyDark;
    if (app.isRejected) bg = AppColors.dangerRed;
    if (app.isUnderReview) bg = AppColors.warningAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  app.status.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Application Ref: ${app.id}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          Text(
            'Target: Class ${app.targetClass} (${app.academicYearId})',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.brandNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(AdmissionApplication app) {
    return Column(
      children: [
        ErpCard(
          title: 'Student Legal Profile',
          subtitle: 'Demographic and identification record',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Full Legal Name', app.fullName),
              _detailRow('Date of Birth',
                  app.dateOfBirth.toLocal().toString().split(' ').first),
              _detailRow(
                  'Gender / Blood Group', '${app.gender} • ${app.bloodGroup}'),
              _detailRow('Nationality / Mother Tongue',
                  '${app.nationality} • ${app.motherTongue}'),
              if (app.studentAadhaarNumber != null &&
                  app.studentAadhaarNumber!.isNotEmpty)
                _detailRow('Aadhaar / National ID', app.studentAadhaarNumber!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ErpCard(
          title: 'Guardian & Residential Contacts',
          subtitle: 'Official family correspondence coordinates',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(
                  'Father\'s Name', '${app.fatherName} (${app.fatherPhone})'),
              _detailRow(
                  'Mother\'s Name', '${app.motherName} (${app.motherPhone})'),
              _detailRow('Primary Guardian', app.primaryGuardian),
              _detailRow('Emergency Contact',
                  '${app.emergencyContactName} (${app.emergencyContactPhone})'),
              _detailRow('Residential Address', app.formattedCurrentAddress),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ErpCard(
          title: 'Academic Background',
          subtitle: 'Prior schooling and transfer documents',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(
                  'Previous School',
                  app.previousSchoolName.isEmpty
                      ? 'First Admission / Fresher'
                      : app.previousSchoolName),
              _detailRow('Last Class / Grade',
                  app.previousClass.isEmpty ? 'N/A' : app.previousClass),
              _detailRow(
                  'Result Aggregate',
                  app.previousResultPercentage.isEmpty
                      ? 'N/A'
                      : '${app.previousResultPercentage}%'),
              if (app.transferCertificateNumber.isNotEmpty)
                _detailRow('TC Number', app.transferCertificateNumber),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ErpCard(
          title: 'Submitted Document Scans (${app.documents.length})',
          subtitle: 'Verified files stored in Firebase Storage',
          child: app.documents.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No documents uploaded for this application.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: app.documents.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final doc = app.documents[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        doc.isVerified ? Icons.verified : Icons.attachment,
                        color: doc.isVerified
                            ? AppColors.successGreen
                            : AppColors.brandNavy,
                      ),
                      title: Text(
                        doc.documentType.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${doc.fileName} • ${(doc.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!doc.isVerified) ...[
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: AppColors.successGreen, size: 20),
                              tooltip: 'Verify Document',
                              onPressed: () async {
                                final repo =
                                    ref.read(admissionRepositoryProvider);
                                await repo.updateDocumentVerification(
                                  applicationId: app.id,
                                  documentType: doc.documentType,
                                  verificationStatus: 'verified',
                                );
                                ref.invalidate(
                                    admissionApplicationByIdProvider(app.id));
                              },
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: doc.isVerified
                                  ? AppColors.successGreen
                                      .withValues(alpha: 0.15)
                                  : AppColors.warningAmber
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              doc.verificationStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: doc.isVerified
                                    ? AppColors.successGreen
                                    : AppColors.warningAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDecisionPanel(AdmissionApplication app) {
    return Column(
      children: [
        ErpCard(
          title: 'Admissions Decision Workspace',
          subtitle: 'Official approval, waitlist, rejection & enrollment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _reviewerNotesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Officer Review Notes',
                  hintText:
                      'Record interview scores, document remarks or enrollment conditions...',
                ),
              ),
              const SizedBox(height: 16),
              if (app.status == 'submitted' ||
                  app.status == 'under_review') ...[
                FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Approve Admission'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _handleDecision(app, 'approved'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.hourglass_empty, size: 16),
                  label: const Text('Place on Waitlist'),
                  onPressed: () => _handleDecision(app, 'waitlisted'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Reject Application'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerRed,
                  ),
                  onPressed: () => _handleDecision(app, 'rejected'),
                ),
              ] else if (app.status == 'approved') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.successGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.successGreen, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Approved for Enrollment. Proceed to assign permanent student admission record.',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.how_to_reg, size: 16),
                  label: const Text('Enroll into Register'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed:
                      _isProcessing ? null : () => _handleEnrollment(app),
                ),
              ] else if (app.isEnrolled) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified,
                              color: AppColors.brandNavy, size: 20),
                          SizedBox(width: 8),
                          Text('STUDENT ENROLLED',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandNavy)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Enrolled Student ID: ${app.enrolledStudentId ?? "N/A"}'),
                      Text(
                          'Admission Number: ${app.enrolledAdmissionNumber ?? "N/A"}'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.badge, size: 16),
                        label: const Text('View Student Profile'),
                        onPressed: () {
                          if (app.enrolledStudentId != null) {
                            context.go(
                                '${AppRoutes.students}?studentId=${app.enrolledStudentId}');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}