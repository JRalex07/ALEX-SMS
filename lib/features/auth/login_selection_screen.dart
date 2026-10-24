import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/role_colors.dart';
import '../../core/constants/breakpoints.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // School Crest & Header
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.brandNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.brandNavy.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 36,
                      color: AppColors.brandNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'LAV School Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dedicated Single-Institution Portal • Academic Year 2026-2027',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 36),

                  // Two Distinct Authentication Cards
                  if (isMobile)
                    Column(
                      children: [
                        _buildParentPortalCard(context),
                        const SizedBox(height: 20),
                        _buildStaffPortalCard(context),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildParentPortalCard(context)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildStaffPortalCard(context)),
                      ],
                    ),

                  const SizedBox(height: 32),
                  const Text(
                    'Protected by Zero-Trust Client Boundary and Verified Institutional Access Control',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentPortalCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.parentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.family_restroom,
                  size: 28, color: AppColors.parentBlue),
            ),
            const SizedBox(height: 16),
            const Text(
              'Parent / Guardian Login',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fast and secure login using your registered mobile number and one-time password (OTP).',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildFeatureBullet(
                Icons.check_circle_outline,
                'Child attendance logs & daily roll call',
                AppColors.parentBlue),
            _buildFeatureBullet(Icons.check_circle_outline,
                'Published term marks & report cards', AppColors.parentBlue),
            _buildFeatureBullet(
                Icons.check_circle_outline,
                'Online fee payment with integer paise ledger',
                AppColors.parentBlue),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_android, size: 18),
                label: const Text('Continue with Mobile OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.parentBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push('/login/parent'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffPortalCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  size: 28, color: AppColors.brandNavy),
            ),
            const SizedBox(height: 16),
            const Text(
              'Staff & Administration Login',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'For teachers, administrators, accountants, librarians, and admissions officers.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildFeatureBullet(Icons.verified_user_outlined,
                'Attendance approvals & marks moderation', AppColors.brandNavy),
            _buildFeatureBullet(
                Icons.verified_user_outlined,
                'Institutional fee collections & reconciliation',
                AppColors.brandNavy),
            _buildFeatureBullet(
                Icons.verified_user_outlined,
                'Student records, enrollment, and library loans',
                AppColors.brandNavy),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Staff Institutional Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push('/login/staff'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
