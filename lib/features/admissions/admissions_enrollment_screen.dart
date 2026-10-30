import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/student_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Enrollment Register
/// Route: /admissions/enrollment
class AdmissionsEnrollmentScreen extends ConsumerStatefulWidget {
  const AdmissionsEnrollmentScreen({super.key});

  @override
  ConsumerState<AdmissionsEnrollmentScreen> createState() =>
      _AdmissionsEnrollmentScreenState();
}

class _AdmissionsEnrollmentScreenState
    extends ConsumerState<AdmissionsEnrollmentScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _enrollApplicant(Map<String, dynamic> app) async {
    try {
      final newStudentId = 'STU_${DateTime.now().millisecondsSinceEpoch}';
      final admissionNumber =
          'LAV-2026-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, "0")}';

      final student = Student(
        studentId: newStudentId,
        schoolId: 'SCH_001',
        admissionNumber: admissionNumber,
        fullName: app['applicantName'] ?? 'Enrolled Student',
        currentClassId: (app['targetClass'] ?? '10').toString(),
        currentSectionId: 'A',
        currentAcademicYearId: 'AY_2026_2027',
        status: 'enrolled',
        guardianUserIds: const [],
        emergencyContact: app['phone'],
      );

      await ref.read(studentRepositoryProvider).enrollStudent(student);
      await ref.read(admissionRepositoryProvider).updateApplicationStatus(
            applicationId: app['id'],
            status: 'enrolled',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Applicant ${student.fullName} officially enrolled with Admission #$admissionNumber!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enrollment failed: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);

    return ResponsiveScaffold(
      title: 'Enrollment Register',
      currentRoute: AppRoutes.admissionsEnrollment,
      body: enquiriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.admissionsTeal),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (enquiries) {
          final approvedApplicants =
              enquiries.where((e) => e['status'] == 'approved').toList();

          final enrolledApplicants =
              enquiries.where((e) => e['status'] == 'enrolled').toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Official School Roll Register',
                subtitle:
                    'Generate student admission numbers, section placements, and create institutional records',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Ready for Roll No',
                      value: '${approvedApplicants.length}',
                      accentColor: AppColors.admissionsTeal,
                    ),
                    MetricItem(
                      label: 'Enrolled in 2026',
                      value: '${enrolledApplicants.length}',
                      accentColor: AppColors.successGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Approved Candidates Pending Roll Assignment (${approvedApplicants.length})',
                child: approvedApplicants.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No approved applicants waiting for roll assignment.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: approvedApplicants.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final app = approvedApplicants[idx];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.admissionsTeal,
                              child: Icon(Icons.badge,
                                  color: Colors.white, size: 20),
                            ),
                            title: Text(
                              app['applicantName'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                                'Admitted to: Class ${app['targetClass']} • Contact: ${app['phone']}'),
                            trailing: ErpButton(
                              label: 'Assign Roll & Enroll',
                              icon: Icons.check_circle_outline,
                              isDense: true,
                              onPressed: () => _enrollApplicant(app),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

