import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Account Activation & Deactivation
/// Route: /staff/activation
class StaffActivationScreen extends ConsumerStatefulWidget {
  const StaffActivationScreen({super.key});

  @override
  ConsumerState<StaffActivationScreen> createState() =>
      _StaffActivationScreenState();
}

class _StaffActivationScreenState extends ConsumerState<StaffActivationScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(AppUser user) async {
    final newStatus = !user.isActive;
    try {
      await ref.read(authRepositoryProvider).setUserActiveStatus(
            uid: user.uid,
            isActive: newStatus,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${user.displayName} is now ${newStatus ? "Active" : "Suspended"}'),
            backgroundColor:
                newStatus ? AppColors.successGreen : AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffMembersStreamProvider);

    return ResponsiveScaffold(
      title: 'Account Activation & Deactivation',
      currentRoute: AppRoutes.staffActivation,
      body: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (staff) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = staff.where((u) {
            return query.isEmpty ||
                u.displayName.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Security Access Control & Suspension Desk',
                subtitle:
                    'Immediately suspend terminated or inactive employee accounts from accessing student PII',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search staff by name or email...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Account Access Status (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No staff accounts found.',
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
                          final member = filtered[idx];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: member.isActive
                                  ? AppColors.successGreen.withValues(alpha: 0.12)
                                  : AppColors.dangerRed.withValues(alpha: 0.12),
                              child: Icon(
                                member.isActive
                                    ? Icons.check_circle
                                    : Icons.block,
                                color: member.isActive
                                    ? AppColors.successGreen
                                    : AppColors.dangerRed,
                              ),
                            ),
                            title: Text(member.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${member.email} • Role: ${UserRoles.getRoleDisplayName(member.role)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusBadge(
                                  label: member.isActive ? 'ACTIVE' : 'SUSPENDED',
                                  type: member.isActive
                                      ? StatusType.success
                                      : StatusType.danger,
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: member.isActive
                                        ? AppColors.dangerRed
                                        : AppColors.successGreen,
                                  ),
                                  onPressed: () => _toggleStatus(member),
                                  child: Text(member.isActive
                                      ? 'Suspend Access'
                                      : 'Activate Account'),
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
