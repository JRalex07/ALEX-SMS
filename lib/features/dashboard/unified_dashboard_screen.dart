import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../accountant/accountant_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admissions/admissions_dashboard_screen.dart';
import '../librarian/librarian_dashboard_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';

/// Unified Entry Dashboard Screen for ALL authenticated roles.
/// Replaces role-specific URLs (/parents, /teacher, /admin) with a single /dashboard route.
/// GoRouter resolves the verified user role from trusted state and renders
/// the permitted role dashboard view.
class UnifiedDashboardScreen extends ConsumerWidget {
  const UnifiedDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.brandNavy),
              SizedBox(height: 16),
              Text(
                'Verifying Institutional Session...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.dangerRed),
                const SizedBox(height: 16),
                const Text(
                  'Authorization Verification Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (user) {
        final role = user?.role ?? UserRoles.parentGuardian;

        switch (role) {
          case UserRoles.schoolAdmin:
            return const AdminDashboardScreen();
          case UserRoles.teacher:
            return const TeacherDashboardScreen();
          case UserRoles.accountant:
            return const AccountantDashboardScreen();
          case UserRoles.admissionsOfficer:
            return const AdmissionsDashboardScreen();
          case UserRoles.librarian:
            return const LibrarianDashboardScreen();
          case UserRoles.parentGuardian:
          default:
            return const ParentDashboardScreen();
        }
      },
    );
  }
}
