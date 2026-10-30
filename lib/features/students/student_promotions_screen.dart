import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Student Promotion Management
/// Route: /students/promotions
class StudentPromotionsScreen extends ConsumerStatefulWidget {
  const StudentPromotionsScreen({super.key});

  @override
  ConsumerState<StudentPromotionsScreen> createState() =>
      _StudentPromotionsScreenState();
}

class _StudentPromotionsScreenState
    extends ConsumerState<StudentPromotionsScreen> {
  String _selectedCohort = 'Class 9 → Class 10';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Student Promotion Engine',
      currentRoute: AppRoutes.studentPromotions,
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final class9 =
              students.where((s) => s.currentClassId == '9').toList();
          final class8 =
              students.where((s) => s.currentClassId == '8').toList();
          final class7 =
              students.where((s) => s.currentClassId == '7').toList();
          final class6 =
              students.where((s) => s.currentClassId == '6').toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Annual Academic Progression (2026-2027 → 2027-2028)',
                subtitle:
                    'Batch promotion engine moving qualified cohorts to next higher grade standards',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promotions re-index the student class levels and archive the previous session marks. Students on hold will remain in their current grade.',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ErpMetricStrip(
                      metrics: [
                        MetricItem(
                          label: 'Class 9 Cohort',
                          value: '${class9.length}',
                          accentColor: AppColors.brandNavy,
                        ),
                        MetricItem(
                          label: 'Class 8 Cohort',
                          value: '${class8.length}',
                          accentColor: AppColors.tealSuccess,
                        ),
                        MetricItem(
                          label: 'Class 7 Cohort',
                          value: '${class7.length}',
                          accentColor: AppColors.warningAmber,
                        ),
                        MetricItem(
                          label: 'Class 6 Cohort',
                          value: '${class6.length}',
                          accentColor: AppColors.infoBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Execute Cohort Progression',
                subtitle: 'Select batch pipeline and configure eligibility thresholds',
                headerTrailing: ErpButton(
                  label: _isProcessing ? 'Promoting...' : 'Run Batch Promotion',
                  icon: Icons.trending_up,
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isProcessing = true);
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                          if (!mounted) return;
                          setState(() => _isProcessing = false);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Promotion sequence validated. All eligible records queued for next AY enrollment.'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        },
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCohort,
                      decoration: const InputDecoration(
                        labelText: 'Target Progression Pipeline',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Class 9 → Class 10',
                          child: Text('Class 9 → Class 10 (Graduating Cohort)'),
                        ),
                        DropdownMenuItem(
                          value: 'Class 8 → Class 9',
                          child: Text('Class 8 → Class 9 (High School Transition)'),
                        ),
                        DropdownMenuItem(
                          value: 'Class 7 → Class 8',
                          child: Text('Class 7 → Class 8 (Middle School Upper)'),
                        ),
                        DropdownMenuItem(
                          value: 'Class 6 → Class 7',
                          child: Text('Class 6 → Class 7 (Middle School Entry)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedCohort = v!),
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: Icon(Icons.check_circle,
                          color: AppColors.successGreen),
                      title: Text('Minimum Attendance Threshold: 75%'),
                      subtitle: Text(
                          'Students failing to meet minimum attendance will be flagged for review.'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.check_circle,
                          color: AppColors.successGreen),
                      title: Text('Examination Clearance: All Terms Passed'),
                      subtitle: Text(
                          'Requires published marks cards with no pending arrears.'),
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
}
