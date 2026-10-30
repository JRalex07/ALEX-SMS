import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Assign Staff Roles
/// Route: /staff/roles
class StaffRolesScreen extends ConsumerStatefulWidget {
  const StaffRolesScreen({super.key});

  @override
  ConsumerState<StaffRolesScreen> createState() => _StaffRolesScreenState();
}

class _StaffRolesScreenState extends ConsumerState<StaffRolesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRoleUpdateDialog(AppUser user) {
    String selectedRole = user.role;
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Role: ${user.displayName}'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedRole,
            decoration: const InputDecoration(labelText: 'Institutional Role'),
            items: const [
              DropdownMenuItem(
                  value: UserRoles.teacher, child: Text('Teacher / Faculty')),
              DropdownMenuItem(
                  value: UserRoles.accountant, child: Text('Accountant')),
              DropdownMenuItem(
                  value: UserRoles.admissionsOfficer,
                  child: Text('Admissions Officer')),
              DropdownMenuItem(
                  value: UserRoles.librarian, child: Text('Librarian')),
              DropdownMenuItem(
                  value: UserRoles.schoolAdmin, child: Text('School Admin')),
            ],
            onChanged: (val) => setDialogState(() => selectedRole = val!),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(authRepositoryProvider).updateUserRole(
                        uid: user.uid,
                        newRole: selectedRole,
                      );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          'Updated role for ${user.displayName} to ${UserRoles.getRoleDisplayName(selectedRole)}'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update role: $e'),
                      backgroundColor: AppColors.dangerRed,
                    ),
                  );
                }
              },
              child: const Text('Save Role'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffMembersStreamProvider);

    return ResponsiveScaffold(
      title: 'Assign Staff Roles',
      currentRoute: AppRoutes.staffRoles,
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
                title: 'RBAC Role Delegation Authority',
                subtitle:
                    'Audit institutional access tiers, administrative rights, and custom claim tokens',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search staff member to modify security role...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Staff Role Registry (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No staff found matching query.',
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
                          final roleColor = AppColors.getRoleColor(member.role);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  roleColor.withValues(alpha: 0.12),
                              child: Icon(Icons.security, color: roleColor),
                            ),
                            title: Text(member.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${member.email} • Current Tier: ${UserRoles.getRoleDisplayName(member.role)}'),
                            trailing: OutlinedButton.icon(
                              icon: const Icon(Icons.admin_panel_settings,
                                  size: 16),
                              label: const Text('Change Role'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: roleColor),
                              onPressed: () => _showRoleUpdateDialog(member),
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
