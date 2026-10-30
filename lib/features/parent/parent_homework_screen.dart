import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/parent_services_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Parent Homework Portal
/// Route: /parent/homework
class ParentHomeworkScreen extends ConsumerWidget {
  const ParentHomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final homeworkAsync = ref.watch(childHomeworkProvider);

    return ResponsiveScaffold(
      title: "Child's Homework & Coursework",
      currentRoute: AppRoutes.parentHomework,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          if (selectedChild == null)
            const Center(child: Text('No student selected.'))
          else
            homeworkAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.parentBlue)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (items) {
                return ErpCard(
                  title: 'Active Coursework Tasks (${items.length})',
                  subtitle:
                      'Assignments assigned to ${selectedChild.fullName} (Class ${selectedChild.currentClassId}-${selectedChild.currentSectionId})',
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No pending homework tasks.',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: AppColors.borderLight),
                          itemBuilder: (ctx, idx) {
                            final item = items[idx];
                            final isSubmitted =
                                item.submissionStatus.toLowerCase() ==
                                    'submitted';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSubmitted
                                    ? AppColors.successGreen.withValues(alpha: 0.12)
                                    : AppColors.warningAmber.withValues(alpha: 0.15),
                                child: Icon(
                                  isSubmitted
                                      ? Icons.task_alt
                                      : Icons.assignment_late_outlined,
                                  color: isSubmitted
                                      ? AppColors.successGreen
                                      : AppColors.warningAmber,
                                ),
                              ),
                              title: Text(item.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                  'Subject: ${item.subjectName} • Due: ${item.dueDate.toLocal().toString().split(" ").first}\n'
                                  'Teacher Guidance: ${item.instructions}'),
                              isThreeLine: true,
                              trailing: Chip(
                                label: Text(
                                  item.submissionStatus.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}
