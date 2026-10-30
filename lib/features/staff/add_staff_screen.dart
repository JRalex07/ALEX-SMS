import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Add Staff Account
/// Route: /staff/add
class AddStaffScreen extends ConsumerStatefulWidget {
  const AddStaffScreen({super.key});

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = UserRoles.teacher;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createStaffAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isCreating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Staff account created for ${_nameController.text.trim()} (${UserRoles.getRoleDisplayName(_selectedRole)})!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
    context.go(AppRoutes.staff);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Add Staff Account',
      currentRoute: AppRoutes.staffAdd,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ErpCard(
              title: 'Institutional Staff Account Enrollment',
              subtitle:
                  'Provision an authenticated faculty or administrative user profile',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please provide staff full name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Institutional Email Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null ||
                              !val.contains('@') ||
                              val.trim().isEmpty
                          ? 'Valid school email required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Verified Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Institutional Access Role *',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: UserRoles.teacher,
                            child: Text('Teacher / Faculty')),
                        DropdownMenuItem(
                            value: UserRoles.accountant,
                            child: Text('Accountant / Finance Officer')),
                        DropdownMenuItem(
                            value: UserRoles.admissionsOfficer,
                            child: Text('Admissions Officer')),
                        DropdownMenuItem(
                            value: UserRoles.librarian,
                            child: Text('Librarian')),
                        DropdownMenuItem(
                            value: UserRoles.schoolAdmin,
                            child: Text('School Administrator')),
                      ],
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.staff),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ErpButton(
                          label: _isCreating
                              ? 'Creating Profile...'
                              : 'Create & Provision Account',
                          icon: Icons.check_circle_outline,
                          onPressed: _isCreating ? null : _createStaffAccount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
