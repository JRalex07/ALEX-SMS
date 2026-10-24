import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final roleDisplayName = UserRoles.getRoleDisplayName(role);
    final roleColor = AppColors.getRoleColor(role);

    return ResponsiveScaffold(
      title: 'Account & System Settings',
      currentRoute: '/settings',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verified Institutional Identity',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.1),
                      child: Icon(Icons.person, color: roleColor),
                    ),
                    title: Text(
                      user?.displayName ?? 'Authenticated User',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      user?.email ?? 'Registered Institutional Account',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        roleDisplayName,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: roleColor),
                      ),
                    ),
                  ),
                  const Divider(height: 24, color: AppColors.borderLight),
                  const Text(
                    'Session Security & Tokens',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Account Status: ${user?.status.toUpperCase() ?? "ACTIVE"} • Token Version: ${user?.tokenVersion ?? 1} • Boundary: Zero-Trust Live Security Check',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.lock_reset, size: 16),
                    label: const Text('Change Password / Credentials'),
                    onPressed: () {
                      context.push('/forgot-password');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderLight),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Institutional Application Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 12),
                  Text(
                    'LAV School Management System (SMS)\n'
                    'Single-Tenant Dedicated School Architecture\n'
                    'Flutter Web / Mobile • Firebase Asia-South1 (Mumbai)\n'
                    'Zero-Loss Integer Paise Financial Ledger\n'
                    'CBSE Academic Year 2026-2027',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
