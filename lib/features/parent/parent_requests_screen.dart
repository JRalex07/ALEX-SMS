import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Parent Requests & Applications Hub
/// Route: /parent/requests
class ParentRequestsScreen extends ConsumerWidget {
  const ParentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    return ResponsiveScaffold(
      title: 'Parent Requests & Grievances',
      currentRoute: AppRoutes.parentRequests,
      actions: [
        ErpButton(
          label: 'Submit Leave Request',
          icon: Icons.event_busy,
          isDense: true,
          onPressed: () => context.go(AppRoutes.parentLeave),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          ErpCard(
            title: 'Parent Service Desk Hub',
            subtitle:
                'Self-service portal for leave permissions, administrative inquiries, and support tickets',
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.surfaceMuted,
                      child: Icon(Icons.event_busy, color: AppColors.parentBlue),
                    ),
                    title: const Text('Leave Requests',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Apply for student leave and medical exemptions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.parentLeave),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.surfaceMuted,
                      child: Icon(Icons.contact_support_outlined,
                          color: AppColors.parentBlue),
                    ),
                    title: const Text('Support & Grievances',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Reach school administration or teachers'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.parentSupport),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Recent Request History',
            subtitle: selectedChild != null
                ? 'Filed requests for ${selectedChild.fullName}'
                : 'All requests',
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ListTile(
                  leading: Icon(Icons.check_circle,
                      color: AppColors.successGreen),
                  title: Text('Medical Leave (3 Days) — Approved'),
                  subtitle: Text(
                      'Ref: LV_2026_01 • Dates: 03 Nov – 05 Nov 2026 • Reason: Viral fever recovery'),
                  trailing: StatusBadge(
                      label: 'APPROVED', type: StatusType.success),
                ),
                Divider(height: 1, color: AppColors.borderLight),
                ListTile(
                  leading: Icon(Icons.pending_actions,
                      color: AppColors.warningAmber),
                  title: Text('Family Leave (2 Days) — Under Review'),
                  subtitle: Text(
                      'Ref: LV_2026_02 • Dates: 14 Nov – 15 Nov 2026 • Reason: Out of city event'),
                  trailing: StatusBadge(
                      label: 'PENDING', type: StatusType.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
