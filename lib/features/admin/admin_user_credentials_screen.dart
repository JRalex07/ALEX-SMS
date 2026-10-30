import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Administrative User Credential & Email Management
/// Strictly restricted to School Administrators / Principal.
/// Route: /admin/user-credentials
class AdminUserCredentialsScreen extends ConsumerStatefulWidget {
  const AdminUserCredentialsScreen({super.key});

  @override
  ConsumerState<AdminUserCredentialsScreen> createState() =>
      _AdminUserCredentialsScreenState();
}

class _AdminUserCredentialsScreenState
    extends ConsumerState<AdminUserCredentialsScreen> {
  final _searchController = TextEditingController();
  String _selectedRole = 'all';

  AppUser? _selectedUser;
  final _newEmailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleInitiateEmailChange() async {
    if (_selectedUser == null) return;

    final newEmail = _newEmailController.text.trim();
    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid new email address.');
      return;
    }

    if (newEmail.toLowerCase() == _selectedUser!.email.toLowerCase()) {
      setState(() => _errorMessage =
          'Proposed email cannot be identical to current registered email.');
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Authorized Email Change'),
        content: Text(
          'Are you sure you want to initiate an official email change for ${_selectedUser!.displayName} (${_selectedUser!.role}) from ${_selectedUser!.email} to $newEmail?\n\n'
          'A secure verification process will be initiated in accordance with institutional policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Authorize & Initiate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.initiateAdminEmailChange(
        targetUid: _selectedUser!.uid,
        newEmail: newEmail,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage = result['message'] ??
            'Email change initiated for $newEmail. Verification link generated and audit record created.';
        _newEmailController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffListAsync = ref.watch(allStaffUsersStreamProvider);

    return ResponsiveScaffold(
      title: 'Administrative Credential & Email Management',
      currentRoute: AppRoutes.adminUserCredentials,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Institutional Governance Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.adminIndigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.adminIndigo.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined,
                    color: AppColors.adminIndigo, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Principal & School Administrator Authority',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.adminIndigo,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Staff and parent users cannot modify their own email addresses. Authorized email updates require school administrative clearance, verification of the new address, and an immutable audit trail.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: User Directory & Filters
                  SizedBox(
                    width: isWide ? 420 : double.infinity,
                    child: ErpCard(
                      title: 'Select Institutional Account',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Search & Role Filter
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name or email...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildRoleChip('all', 'All Roles'),
                                const SizedBox(width: 6),
                                _buildRoleChip('teacher', 'Teachers'),
                                const SizedBox(width: 6),
                                _buildRoleChip('accountant', 'Accountants'),
                                const SizedBox(width: 6),
                                _buildRoleChip(
                                    'admissions_officer', 'Admissions'),
                                const SizedBox(width: 6),
                                _buildRoleChip('librarian', 'Librarians'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Staff List
                          staffListAsync.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, _) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error loading directory: $err',
                                  style: const TextStyle(
                                      color: AppColors.dangerRed)),
                            ),
                            data: (users) {
                              final query =
                                  _searchController.text.trim().toLowerCase();
                              final filtered = users.where((u) {
                                final matchesRole = _selectedRole == 'all' ||
                                    u.role == _selectedRole;
                                final matchesQuery = query.isEmpty ||
                                    u.displayName
                                        .toLowerCase()
                                        .contains(query) ||
                                    u.email.toLowerCase().contains(query);
                                return matchesRole && matchesQuery;
                              }).toList();

                              if (filtered.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text('No users match criteria.'),
                                  ),
                                );
                              }

                              return ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 380),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final u = filtered[index];
                                    final isSelected =
                                        _selectedUser?.uid == u.uid;
                                    final roleColor =
                                        AppColors.getRoleColor(u.role);

                                    return Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        selected: isSelected,
                                        selectedTileColor: AppColors.adminIndigo
                                            .withValues(alpha: 0.08),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              roleColor.withValues(alpha: 0.1),
                                          child: Icon(Icons.person,
                                              color: roleColor, size: 20),
                                        ),
                                        title: Text(
                                          u.displayName,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${u.email} • ${u.role}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedUser = u;
                                            _errorMessage = null;
                                            _successMessage = null;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isWide)
                    const SizedBox(width: 24)
                  else
                    const SizedBox(height: 24),

                  // Right Column: Target User Details & Email Update Initiation
                  isWide
                      ? Expanded(child: _buildRightColumn())
                      : _buildRightColumn(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn() {
    return _selectedUser == null
        ? const ErpCard(
            title: 'User Credential Detail',
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Select a user from the directory on the left to review credentials or initiate an email change.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        : ErpCard(
            title: 'Authorized Email Management',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slateGray.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.dangerRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: AppColors.dangerRed)),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.successGreen.withValues(alpha: 0.3)),
                    ),
                    child: Text(_successMessage!,
                        style: const TextStyle(color: AppColors.successGreen)),
                  ),
                  const SizedBox(height: 16),
                ],
                // User Details Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedUser!.displayName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UID: ${_selectedUser!.uid} • Role: ${_selectedUser!.role}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Current Email: ',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _selectedUser!.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Proposed New Email
                const Text(
                  'Proposed New Email Address',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'e.g. staff.member@lavacademy.edu',
                    prefixIcon: const Icon(Icons.alternate_email, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                ErpButton(
                  label: _isLoading
                      ? 'Initiating...'
                      : 'Initiate Email Change & Send Verification',
                  icon: Icons.mark_email_read_outlined,
                  color: AppColors.adminIndigo,
                  onPressed: _isLoading ? null : _handleInitiateEmailChange,
                ),
              ],
            ),
          );
  }

  Widget _buildRoleChip(String role, String label) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _selectedRole = role),
    );
  }
}
