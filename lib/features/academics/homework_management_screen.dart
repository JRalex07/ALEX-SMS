import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/parent_services_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Homework & Assignments Management
/// Route: /academics/homework
class HomeworkManagementScreen extends ConsumerStatefulWidget {
  const HomeworkManagementScreen({super.key});

  @override
  ConsumerState<HomeworkManagementScreen> createState() =>
      _HomeworkManagementScreenState();
}

class _HomeworkManagementScreenState
    extends ConsumerState<HomeworkManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeworkAsync = ref.watch(childHomeworkProvider);
    final user = ref.watch(currentUserProfileProvider).value;
    final isTeacher =
        user?.role == UserRoles.teacher || user?.role == UserRoles.schoolAdmin;

    return ResponsiveScaffold(
      title: 'Homework & Assignments',
      currentRoute: AppRoutes.academicsHomework,
      actions: [
        if (isTeacher)
          ErpButton(
            label: 'Create Homework',
            icon: Icons.add_task,
            isDense: true,
            onPressed: () => context.go(AppRoutes.academicsHomeworkCreate),
          ),
      ],
      body: homeworkAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = items.where((i) {
            final matchesQuery = query.isEmpty ||
                i.title.toLowerCase().contains(query) ||
                i.subjectName.toLowerCase().contains(query);
            return matchesQuery;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Homework & Curriculum Tasks',
                subtitle:
                    'Assigned coursework, research topics, exercises, and submission deadlines',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search assignments by title or subject...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Active Assignments (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No homework assignments found.',
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
                          final item = filtered[idx];
                          final isSubmitted =
                              item.submissionStatus.toLowerCase() ==
                                  'submitted';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSubmitted
                                  ? AppColors.successGreen
                                      .withValues(alpha: 0.12)
                                  : AppColors.warningAmber
                                      .withValues(alpha: 0.15),
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
                                'Instructions: ${item.instructions}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    item.submissionStatus.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (isTeacher) ...[
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => context.go(
                                        AppRoutes.academicsHomeworkSubmissions),
                                    child: const Text('Submissions'),
                                  ),
                                ],
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
