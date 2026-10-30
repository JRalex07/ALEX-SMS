import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Staff Directory
/// Route: /staff
class StaffDirectoryScreen extends ConsumerStatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  ConsumerState<StaffDirectoryScreen> createState() =>
      _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends ConsumerState<StaffDirectoryScreen> {
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';

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

  Future<void> _toggleAccountStatus(AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final newStatus = !user.isActive;
    try {
      await ref.read(authRepositoryProvider).setUserActiveStatus(
            uid: user.uid,
            isActive: newStatus,
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              '${user.displayName} is now ${newStatus ? "Active" : "Suspended"}'),
          backgroundColor:
              newStatus ? AppColors.successGreen : AppColors.dangerRed,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffMembersStreamProvider);

    return ResponsiveScaffold(
      title: 'Staff Directory',
      currentRoute: AppRoutes.staff,
      actions: [
        ErpButton(
          label: 'Add Staff Account',
          icon: Icons.person_add_alt_1_outlined,
          isDense: true,
          onPressed: () => context.go(AppRoutes.staffAdd),
        ),
      ],
      body: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (staff) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = staff.where((u) {
            final matchesQuery = query.isEmpty ||
                u.displayName.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query);
            final matchesRole =
                _selectedRoleFilter == 'All' || u.role == _selectedRoleFilter;
            return matchesQuery && matchesRole;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Staff Directory Filter & Search',
                subtitle:
                    'Audit institutional user access by name, email, or institutional role',
                child: Row(
                  children: [
                    Expanded(
                      child: ErpSearchBar(
                        controller: _searchController,
                        hintText: 'Search staff by name or email...',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedRoleFilter,
                      items: const [
                        DropdownMenuItem(
                            value: 'All', child: Text('All Roles')),
                        DropdownMenuItem(
                            value: UserRoles.schoolAdmin,
                            child: Text('School Admin')),
                        DropdownMenuItem(
                            value: UserRoles.teacher, child: Text('Teacher')),
                        DropdownMenuItem(
                            value: UserRoles.accountant,
                            child: Text('Accountant')),
                        DropdownMenuItem(
                            value: UserRoles.admissionsOfficer,
                            child: Text('Admissions Officer')),
                        DropdownMenuItem(
                            value: UserRoles.librarian,
                            child: Text('Librarian')),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedRoleFilter = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Staff Roster (${filtered.length} Staff Accounts)',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                              'No staff members found matching criteria.',
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
                              child: Icon(Icons.person, color: roleColor),
                            ),
                            title: Text(
                              member.displayName.isNotEmpty
                                  ? member.displayName
                                  : 'Staff Member',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                                '${member.email} • Status: ${member.isActive ? "Active" : "Suspended"}\n'
                                'Assigned Scope: ${member.assignedClasses.isEmpty ? "All School / Campus" : member.assignedClasses.join(", ")}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    UserRoles.getRoleDisplayName(member.role),
                                    style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (val) {
                                    if (val == 'role') {
                                      _showRoleUpdateDialog(member);
                                    } else if (val == 'scope') {
                                      AssignTeacherDialog.show(context);
                                    } else if (val == 'toggle') {
                                      _toggleAccountStatus(member);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'role',
                                        child:
                                            Text('Change Institutional Role')),
                                    if (member.role == UserRoles.teacher)
                                      const PopupMenuItem(
                                          value: 'scope',
                                          child:
                                              Text('Assign Classes / Scope')),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(member.isActive
                                          ? 'Suspend Account'
                                          : 'Activate Account'),
                                    ),
                                  ],
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
