import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Switch Ward / Child Context
/// Route: /parent/children
class SwitchChildScreen extends ConsumerWidget {
  const SwitchChildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(parentLinkedChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);

    return ResponsiveScaffold(
      title: 'Switch Child / Ward Context',
      currentRoute: AppRoutes.parentChildren,
      body: childrenAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.parentBlue),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (children) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Linked Student Profiles',
                subtitle:
                    'Select an active child profile to switch academic dashboard, grades, and fee records',
                child: children.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No student profiles linked to this parent account.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: children.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final child = children[idx];
                          final isSelected =
                              selectedChild?.studentId == child.studentId;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? AppColors.parentBlue
                                  : AppColors.surfaceMuted,
                              child: Icon(
                                Icons.child_care,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            title: Text(child.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.parentBlue
                                      : null,
                                )),
                            subtitle: Text(
                                'Adm #${child.admissionNumber} • Standard: Class ${child.currentClassId}-${child.currentSectionId} • AY: ${child.currentAcademicYearId}'),
                            trailing: isSelected
                                ? const Chip(
                                    label: Text('ACTIVE CONTEXT',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                    backgroundColor: AppColors.parentBlue,
                                  )
                                : OutlinedButton(
                                    onPressed: () {
                                      ref
                                          .read(selectedChildIdProvider.notifier)
                                          .state = child.studentId;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Active child switched to ${child.fullName}'),
                                          backgroundColor: AppColors.successGreen,
                                        ),
                                      );
                                      context.go(AppRoutes.dashboard);
                                    },
                                    child: const Text('Switch Context'),
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
