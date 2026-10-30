import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Student Homework Submissions Roster
/// Route: /academics/homework/submissions
class StudentSubmissionsScreen extends ConsumerStatefulWidget {
  const StudentSubmissionsScreen({super.key});

  @override
  ConsumerState<StudentSubmissionsScreen> createState() =>
      _StudentSubmissionsScreenState();
}

class _StudentSubmissionsScreenState
    extends ConsumerState<StudentSubmissionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Student Homework Submissions',
      currentRoute: AppRoutes.academicsHomeworkSubmissions,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('All Homework'),
          onPressed: () => context.go(AppRoutes.academicsHomework),
        ),
      ],
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = students.where((s) {
            return query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.admissionNumber.toLowerCase().contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Submission Audit Roster — Quadratic Equations Ex 4.2',
                subtitle:
                    'Class 10-A • Due Date: 28 Oct 2026 • Teacher: Tarun Sharma',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search pupil to evaluate submission dossier...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Student Submission Records (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No student records found.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final s = filtered[idx];
                          final isSubmitted = idx % 3 != 0;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSubmitted
                                  ? AppColors.successGreen.withValues(alpha: 0.12)
                                  : AppColors.dangerRed.withValues(alpha: 0.12),
                              child: Icon(
                                isSubmitted
                                    ? Icons.task_alt
                                    : Icons.warning_amber_outlined,
                                color: isSubmitted
                                    ? AppColors.successGreen
                                    : AppColors.dangerRed,
                              ),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Adm #${s.admissionNumber} • Standard: Class ${s.currentClassId}-${s.currentSectionId} • '
                                '${isSubmitted ? "Turned In (PDF 1.4 MB)" : "Missing / Overdue"}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusBadge(
                                  label: isSubmitted ? 'EVALUATED' : 'PENDING',
                                  type: isSubmitted
                                      ? StatusType.success
                                      : StatusType.warning,
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Reviewing submission for ${s.fullName}')),
                                    );
                                  },
                                  child: const Text('Review Work'),
                                ),
                              ],
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
