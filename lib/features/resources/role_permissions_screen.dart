import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class RolePermissionsScreen extends ConsumerWidget {
  const RolePermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;

    if (role != UserRoles.schoolAdmin) {
      return const ResponsiveScaffold(
        title: 'Access Restricted',
        currentRoute: AppRoutes.rolesPermissions,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_bad, size: 56, color: AppColors.dangerRed),
                SizedBox(height: 16),
                Text(
                  '403 Forbidden: Permission Control Restricted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Only School Administrators can inspect or configure the institutional Role-Based Access Control matrix.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ResponsiveScaffold(
      title: 'Institutional Roles & Access Boundaries',
      currentRoute: AppRoutes.rolesPermissions,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Role-Based Access Control Matrix (6 Isolated Roles)',
            subtitle:
                'Capabilities and security boundaries enforced at routing, repository, and Firebase rules layers',
            child: Column(
              children: [
                _buildRoleCard(
                  roleName: 'School Administrator (school_admin)',
                  color: AppColors.brandNavy,
                  description:
                      'Full institutional governance: student lifecycle, admissions decisions, staff roles, fee structures oversight, examination approval, and system settings.',
                  capabilities: [
                    'Manage Academic Years, Classes & Sections',
                    'Assign Teachers to Cohorts & Subjects',
                    'Finalize Examination Result Publication',
                    'Activate or Suspend Staff Accounts',
                    'Access Immutable Audit Logs & School Reports',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  roleName: 'Teaching Faculty (teacher)',
                  color: AppColors.teacherEmerald,
                  description:
                      'Pedagogical and cohort management: roll-call attendance, homework assignments, study materials, and draft marks entry strictly scoped to assigned classes.',
                  capabilities: [
                    'Mark Daily Roll Call for Assigned Classes',
                    'Create Homework & Track Submissions',
                    'Upload Subject Learning Materials',
                    'Enter Draft CA and Exam Marks (0-20, 0-60)',
                    'Restricted from Publishing Final Results or School Fees',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  roleName: 'Accountant & Bursar (accountant)',
                  color: AppColors.accountantAmber,
                  description:
                      'Bursary and fee operations: student fee structures, ledger tracking, invoice generation, offline payment collection, and monetary reconciliation with strict integer-paise arithmetic.',
                  capabilities: [
                    'Configure Approved Fee Structures',
                    'Generate Invoices with Integer Paise Precision',
                    'Record Cash / Offline Payment Receipts',
                    'Process and Authorize Refund Requests',
                    'Restricted from Academic Publishing & Staff Management',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  roleName: 'Admissions Officer (admissions_officer)',
                  color: AppColors.admissionsTeal,
                  description:
                      'Enrollment pipeline management: intake registry, application screening, statutory document verification, and approved applicant matriculation.',
                  capabilities: [
                    'Manage Admission Application Registry',
                    'Verify KYC & Academic Transfer Certificates',
                    'Record Admission Decisions (Approve/Reject/Waitlist)',
                    'Enroll Finalized Students with Admission Numbers',
                    'Restricted from Financial Mutations & General Staff Records',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  roleName: 'Librarian (librarian)',
                  color: AppColors.librarianViolet,
                  description:
                      'Central catalog & circulation desk: catalog inventory, physical copies tracking, barcode accession lookups, issue/return transactions, and overdue fine assessments.',
                  capabilities: [
                    'Manage Library Catalog Titles & Physical Volumes',
                    'Issue Books with Borrowing Limit Enforcement',
                    'Process Returns with Atomic Inventory Increment',
                    'Assess Overdue Fines at ₹2.00/day (200 paise)',
                    'Restricted from Student Demographics & General Tuition Fees',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  roleName: 'Parent / Guardian (parent_guardian)',
                  color: AppColors.parentBlue,
                  description:
                      'Family portal: attendance monitoring, timetable schedule, published report cards, online fee payments, leave applications, and transport routes strictly scoped to verified linked wards.',
                  capabilities: [
                    'Seamless Child Switching with Instant Cache Invalidation',
                    'View Verified Attendance & Academic Progress',
                    'Pay Term Invoices & Download Receipts',
                    'Submit Student Leave Applications & Support Grievances',
                    'Strictly Blocked from Accessing Any Unlinked Ward Records',
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const ErpCard(
            title: 'Zero-Trust Session Invalidation Architecture',
            subtitle:
                'Live security token versioning and immediate privilege revocation',
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Firestore Security Rules validate that the requesting user\'s `tokenVersion` matches the authoritative database value on every transaction.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. If a staff account is suspended or has its role updated, `tokenVersion` is automatically incremented, immediately terminating existing sessions without waiting for client token refresh.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. Relationship-Based Access Control (ReBAC) prevents parameter tampering on `/students/:studentId` and `/fees/invoices/:invoiceId` routes.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleName,
    required Color color,
    required String description,
    required List<String> capabilities,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(Icons.shield, color: color, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  roleName,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            const Text('Authorized Capabilities:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...capabilities.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.successGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(c,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
