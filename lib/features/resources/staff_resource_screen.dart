import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/confirm_action_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class StaffResourceScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  final String? staffId;

  const StaffResourceScreen({
    super.key,
    this.initialTab,
    this.staffId,
  });

  @override
  ConsumerState<StaffResourceScreen> createState() =>
      _StaffResourceScreenState();
}

class _StaffResourceScreenState extends ConsumerState<StaffResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';

  final List<String> _tabs = [
    'Staff Directory',
    'Assign Roles',
    'Teacher Workload',
    'Account Status',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'roles':
          initialIndex = 1;
          break;
        case 'workload':
          initialIndex = 2;
          break;
        case 'activation':
          initialIndex = 3;
          break;
        default:
          initialIndex = 0;
      }
    }
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void didUpdateWidget(covariant StaffResourceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      int targetIndex = 0;
      switch (widget.initialTab) {
        case 'roles':
          targetIndex = 1;
          break;
        case 'workload':
          targetIndex = 2;
          break;
        case 'activation':
          targetIndex = 3;
          break;
        default:
          targetIndex = 0;
      }
      if (_tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;

    if (role != UserRoles.schoolAdmin) {
      return const ResponsiveScaffold(
        title: 'Access Restricted',
        currentRoute: AppRoutes.staff,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_bad, size: 56, color: AppColors.dangerRed),
                SizedBox(height: 16),
                Text(
                  '403 Forbidden: Staff Management Restricted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Only School Administrators are authorized to view and manage institutional staff accounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final staffAsync = ref.watch(allStaffUsersStreamProvider);

    return ResponsiveScaffold(
      title: 'Staff & Personnel Directory',
      currentRoute: AppRoutes.staff,
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Add Staff Account'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandNavy,
            foregroundColor: Colors.white,
          ),
          onPressed: () => StaffManagementDialog.show(context),
        ),
        const SizedBox(width: 8),
      ],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.brandNavy,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.brandNavy,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading staff accounts: $err',
                      style: const TextStyle(color: AppColors.dangerRed)),
                ),
              ),
              data: (staffMembers) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDirectoryTab(staffMembers),
                    _buildRolesTab(staffMembers),
                    _buildWorkloadTab(staffMembers),
                    _buildActivationTab(staffMembers),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryTab(List<AppUser> staff) {
    final filtered = staff.where((u) {
      final name = u.displayName.toLowerCase();
      final email = u.email.toLowerCase();
      final q = _searchController.text.toLowerCase();
      final matchesSearch = name.contains(q) || email.contains(q);
      final matchesRole =
          _selectedRoleFilter == 'All' || u.role == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSearchFilterHeader(),
        const SizedBox(height: 16),
        ErpCard(
          title: 'Institutional Staff Roster (${filtered.length})',
          subtitle: 'Active faculty, bursars, admissions, and library staff',
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No staff members found matching search.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final member = filtered[idx];
                    final roleColor = AppColors.getRoleColor(member.role);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor: roleColor.withValues(alpha: 0.1),
                        child: Icon(Icons.person, color: roleColor),
                      ),
                      title: Text(
                        member.displayName.isNotEmpty
                            ? member.displayName
                            : 'Staff Member',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                          '${member.email} • Assigned Classes: ${member.assignedClasses.isEmpty ? "None" : member.assignedClasses.join(", ")}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
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
                                  child: Text('Change Institutional Role')),
                              if (member.role == UserRoles.teacher)
                                const PopupMenuItem(
                                    value: 'scope',
                                    child: Text('Assign Classes / Scope')),
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
  }

  Widget _buildRolesTab(List<AppUser> staff) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Role Assignment & Privilege Delegation',
          subtitle:
              'Modify institutional access tier. Only authorized school admins can grant privileges.',
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: staff.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.borderLight),
            itemBuilder: (ctx, idx) {
              final member = staff[idx];
              final roleColor = AppColors.getRoleColor(member.role);
              return ListTile(
                title: Text(member.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${member.email} • Current Role: ${UserRoles.getRoleDisplayName(member.role)}'),
                trailing: OutlinedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings, size: 16),
                  label: const Text('Update Role'),
                  style: OutlinedButton.styleFrom(foregroundColor: roleColor),
                  onPressed: () => _showRoleUpdateDialog(member),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadTab(List<AppUser> staff) {
    final teachers =
        staff.where((u) => u.role == UserRoles.teacher).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Teacher Workload & Cohort Allocations (${teachers.length})',
          subtitle: 'Active teacher assignments across classes and sections',
          child: teachers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No teaching faculty registered.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teachers.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final t = teachers[idx];
                    return ListTile(
                      title: Text(t.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        'Classes: ${t.assignedClasses.isEmpty ? "None" : t.assignedClasses.map((c) => "Class $c").join(", ")} • '
                        'Sections: ${t.assignedSections.isEmpty ? "None" : t.assignedSections.join(", ")}',
                      ),
                      trailing: FilledButton.icon(
                        icon: const Icon(Icons.edit_calendar, size: 14),
                        label: const Text('Reassign Cohort'),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teacherEmerald),
                        onPressed: () => AssignTeacherDialog.show(context),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivationTab(List<AppUser> staff) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Account Activation & Deactivation Control',
          subtitle:
              'Deactivating an account immediately revokes access via zero-trust session checks',
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: staff.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.borderLight),
            itemBuilder: (ctx, idx) {
              final member = staff[idx];
              final isActive = member.isActive;
              return SwitchListTile(
                title: Text(member.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${member.email} • Status: ${isActive ? "ACTIVE" : "SUSPENDED"}'),
                value: isActive,
                activeThumbColor: AppColors.successGreen,
                inactiveThumbColor: AppColors.dangerRed,
                onChanged: (val) => _toggleAccountStatus(member),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilterHeader() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search staff by name or institutional email...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedRoleFilter,
              items: [
                const DropdownMenuItem(value: 'All', child: Text('All Roles')),
                ...UserRoles.allRoles
                    .where((r) => r != UserRoles.parentGuardian)
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(UserRoles.getRoleDisplayName(r)),
                        )),
              ],
              onChanged: (v) => setState(() => _selectedRoleFilter = v!),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoleUpdateDialog(AppUser member) async {
    String selectedRole = member.role;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Role: ${member.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select new institutional role. This immediately adjusts system routing and module permissions.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              items: UserRoles.allRoles
                  .where((r) => r != UserRoles.parentGuardian)
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(UserRoles.getRoleDisplayName(r)),
                      ))
                  .toList(),
              onChanged: (v) => selectedRole = v ?? selectedRole,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.brandNavy),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Role Update'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.updateStaffRole(
          uid: member.uid,
          newRole: selectedRole,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated ${member.displayName} to $selectedRole!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update role: $e'),
              backgroundColor: AppColors.dangerRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAccountStatus(AppUser member) async {
    final nextStatus = member.isActive ? 'suspended' : 'active';
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: '${member.isActive ? "Suspend" : "Activate"} Account',
      message:
          'Are you sure you want to change account status for ${member.displayName} to $nextStatus?',
      confirmLabel: member.isActive ? 'Suspend' : 'Activate',
      isDestructive: member.isActive,
      onConfirm: (_) async {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.updateStaffStatus(
          uid: member.uid,
          status: nextStatus,
        );
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Account for ${member.displayName} marked as $nextStatus!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }
}

