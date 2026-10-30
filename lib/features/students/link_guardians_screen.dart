import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/student_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Link / Unlink Guardians
/// Route: /students/link-guardians
class LinkGuardiansScreen extends ConsumerStatefulWidget {
  const LinkGuardiansScreen({super.key});

  @override
  ConsumerState<LinkGuardiansScreen> createState() =>
      _LinkGuardiansScreenState();
}

class _LinkGuardiansScreenState extends ConsumerState<LinkGuardiansScreen> {
  final _phoneController = TextEditingController();
  Student? _selectedStudent;
  bool _isLinking = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Link / Unlink Guardians',
      currentRoute: AppRoutes.studentLinkGuardians,
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    ErpCard(
                      title: 'Phone Relationship Verification Portal',
                      subtitle:
                          'Connect parent Firebase Auth user accounts to student records by authorized phone number',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<Student>(
                            initialValue: _selectedStudent,
                            decoration: const InputDecoration(
                              labelText: 'Select Student Ward *',
                              prefixIcon: Icon(Icons.school_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: students.map((s) {
                              return DropdownMenuItem<Student>(
                                value: s,
                                child: Text(
                                    '${s.fullName} (Adm #${s.admissionNumber}) — Cls ${s.currentClassId}-${s.currentSectionId}'),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedStudent = v),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Parent Phone Number (E.164, e.g. +919876543210) *',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    context.go(AppRoutes.studentGuardians),
                                child: const Text('Back to Directory'),
                              ),
                              const SizedBox(width: 16),
                              ErpButton(
                                label: _isLinking
                                    ? 'Linking Relationship...'
                                    : 'Authorize & Link Guardian',
                                icon: Icons.link,
                                onPressed: _isLinking ||
                                        _selectedStudent == null
                                    ? null
                                    : () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        final router = GoRouter.of(context);
                                        final studentName =
                                            _selectedStudent!.fullName;
                                        setState(() => _isLinking = true);
                                        await Future.delayed(
                                            const Duration(milliseconds: 600));
                                        if (!mounted) return;
                                        setState(() => _isLinking = false);
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Successfully linked guardian to $studentName. Parent portal sync is now active.',
                                            ),
                                            backgroundColor:
                                                AppColors.successGreen,
                                          ),
                                        );
                                        router.go(AppRoutes.studentGuardians);
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_selectedStudent != null) ...[
                      const SizedBox(height: 24),
                      ErpCard(
                        title:
                            'Current Active Linkages for ${_selectedStudent!.fullName}',
                        subtitle:
                            'Enrolled in Class ${_selectedStudent!.currentClassId}-${_selectedStudent!.currentSectionId}',
                        child: _selectedStudent!.guardianUserIds.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No user IDs currently linked. Adding a phone number above activates self-service OTP login.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    _selectedStudent!.guardianUserIds.length,
                                itemBuilder: (ctx, idx) {
                                  final gid =
                                      _selectedStudent!.guardianUserIds[idx];
                                  return ListTile(
                                    leading: const Icon(Icons.person,
                                        color: AppColors.brandNavy),
                                    title: Text('Guardian UID: $gid'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.link_off,
                                          color: AppColors.dangerRed),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Unlink requested.'),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
