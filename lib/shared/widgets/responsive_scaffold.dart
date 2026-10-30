import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final List<String> allowedRoles;

  const NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.allowedRoles,
  });
}

class RoleNavCategory {
  final String title;
  final List<RoleNavEntry> entries;

  const RoleNavCategory({
    required this.title,
    required this.entries,
  });
}

class RoleNavEntry {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final String? badge;

  const RoleNavEntry({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.badge,
  });
}

class ResponsiveScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String currentRoute;
  final int selectedNavIndex;
  final ValueChanged<int>? onNavIndexChanged;
  final List<NavigationDestination>? navDestinations;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.currentRoute = '/dashboard',
    this.selectedNavIndex = 0,
    this.onNavIndexChanged,
    this.navDestinations,
  });

  static const List<NavItem> _allNavItems = [
    NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: '/dashboard',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.accountant,
        UserRoles.admissionsOfficer,
        UserRoles.librarian,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Attendance',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
      route: '/attendance',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Academics',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      route: '/academics',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Fee Management',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      route: '/fees',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.accountant,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Students',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/students',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.admissionsOfficer,
        UserRoles.teacher,
        UserRoles.librarian,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Library',
      icon: Icons.local_library_outlined,
      selectedIcon: Icons.local_library,
      route: '/library',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.librarian,
        UserRoles.teacher,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Notices',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
      route: '/notices',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.accountant,
        UserRoles.admissionsOfficer,
        UserRoles.librarian,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: '/settings',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.accountant,
        UserRoles.admissionsOfficer,
        UserRoles.librarian,
        UserRoles.parentGuardian,
      ],
    ),
  ];

  static List<RoleNavCategory> getRoleNavCategories(String role) {
    switch (role) {
      case UserRoles.schoolAdmin:
        return const [
          RoleNavCategory(
            title: 'Overview',
            entries: [
              RoleNavEntry(
                  label: 'Institutional Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  route: AppRoutes.dashboard),
              RoleNavEntry(
                  label: 'School Calendar',
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today,
                  route: AppRoutes.academicsCalendar),
            ],
          ),
          RoleNavCategory(
            title: 'Student Management',
            entries: [
              RoleNavEntry(
                  label: 'All Students',
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  route: AppRoutes.students),
              RoleNavEntry(
                  label: 'Add New Student',
                  icon: Icons.person_add_outlined,
                  selectedIcon: Icons.person_add,
                  route: AppRoutes.studentAdd),
              RoleNavEntry(
                  label: 'Student Profile Lookup',
                  icon: Icons.badge_outlined,
                  selectedIcon: Icons.badge,
                  route: AppRoutes.studentLookup),
              RoleNavEntry(
                  label: 'Class & Section Transfers',
                  icon: Icons.swap_horiz,
                  selectedIcon: Icons.swap_horizontal_circle,
                  route: AppRoutes.studentTransfers),
              RoleNavEntry(
                  label: 'Student Cohort Promotion',
                  icon: Icons.trending_up,
                  selectedIcon: Icons.trending_up,
                  route: AppRoutes.studentPromotions),
              RoleNavEntry(
                  label: 'Student Status & Archives',
                  icon: Icons.archive_outlined,
                  selectedIcon: Icons.archive,
                  route: AppRoutes.studentArchives),
              RoleNavEntry(
                  label: 'Parent / Guardian Directory',
                  icon: Icons.family_restroom_outlined,
                  selectedIcon: Icons.family_restroom,
                  route: AppRoutes.studentGuardians),
              RoleNavEntry(
                  label: 'Link / Unlink Guardians',
                  icon: Icons.link_outlined,
                  selectedIcon: Icons.link,
                  route: AppRoutes.studentLinkGuardians),
            ],
          ),
          RoleNavCategory(
            title: 'Admissions',
            entries: [
              RoleNavEntry(
                  label: 'Admission Applications',
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment,
                  route: AppRoutes.admissions),
              RoleNavEntry(
                  label: 'Review Queue',
                  icon: Icons.rate_review_outlined,
                  selectedIcon: Icons.rate_review,
                  route: AppRoutes.admissionsReview),
              RoleNavEntry(
                  label: 'Document Verification',
                  icon: Icons.verified_user_outlined,
                  selectedIcon: Icons.verified_user,
                  route: AppRoutes.admissionsVerification),
              RoleNavEntry(
                  label: 'Admissions Decisions',
                  icon: Icons.gavel_outlined,
                  selectedIcon: Icons.gavel,
                  route: AppRoutes.admissionsDecisions),
              RoleNavEntry(
                  label: 'Enrollment Register',
                  icon: Icons.how_to_reg_outlined,
                  selectedIcon: Icons.how_to_reg,
                  route: AppRoutes.admissionsEnrollment),
              RoleNavEntry(
                  label: 'Admission Reports',
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics,
                  route: AppRoutes.admissionsReports),
            ],
          ),
          RoleNavCategory(
            title: 'Academic Management',
            entries: [
              RoleNavEntry(
                  label: 'Academic Years & Terms',
                  icon: Icons.date_range_outlined,
                  selectedIcon: Icons.date_range,
                  route: AppRoutes.academicsYears),
              RoleNavEntry(
                  label: 'Classes Management',
                  icon: Icons.class_,
                  selectedIcon: Icons.class_,
                  route: AppRoutes.academicsClasses),
              RoleNavEntry(
                  label: 'Sections Management',
                  icon: Icons.view_module_outlined,
                  selectedIcon: Icons.view_module,
                  route: AppRoutes.academicsSections),
              RoleNavEntry(
                  label: 'Subjects Catalog',
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book,
                  route: AppRoutes.academicsSubjects),
              RoleNavEntry(
                  label: 'Master Timetable',
                  icon: Icons.schedule_outlined,
                  selectedIcon: Icons.schedule,
                  route: AppRoutes.academicsTimetable),
              RoleNavEntry(
                  label: 'Holidays Calendar',
                  icon: Icons.beach_access_outlined,
                  selectedIcon: Icons.beach_access,
                  route: AppRoutes.academicsHolidays),
              RoleNavEntry(
                  label: 'Homework & Assignments',
                  icon: Icons.assignment_turned_in_outlined,
                  selectedIcon: Icons.assignment_turned_in,
                  route: AppRoutes.academicsHomework),
              RoleNavEntry(
                  label: 'Create Homework',
                  icon: Icons.note_add_outlined,
                  selectedIcon: Icons.note_add,
                  route: AppRoutes.academicsHomeworkCreate),
              RoleNavEntry(
                  label: 'Homework Submissions',
                  icon: Icons.upload_file_outlined,
                  selectedIcon: Icons.upload_file,
                  route: AppRoutes.academicsHomeworkSubmissions),
              RoleNavEntry(
                  label: 'Study Materials Repository',
                  icon: Icons.folder_shared_outlined,
                  selectedIcon: Icons.folder_shared,
                  route: AppRoutes.academicsMaterials),
              RoleNavEntry(
                  label: 'Upload Study Material',
                  icon: Icons.cloud_upload_outlined,
                  selectedIcon: Icons.cloud_upload,
                  route: AppRoutes.academicsMaterialsUpload),
            ],
          ),
          RoleNavCategory(
            title: 'Examinations',
            entries: [
              RoleNavEntry(
                  label: 'Examinations Catalog',
                  icon: Icons.fact_check_outlined,
                  selectedIcon: Icons.fact_check,
                  route: AppRoutes.examinations),
              RoleNavEntry(
                  label: 'Examination Schedule',
                  icon: Icons.event_note_outlined,
                  selectedIcon: Icons.event_note,
                  route: AppRoutes.examinationsSchedule),
              RoleNavEntry(
                  label: 'Marks Entry',
                  icon: Icons.edit_calendar_outlined,
                  selectedIcon: Icons.edit_calendar,
                  route: AppRoutes.examinationsMarks),
              RoleNavEntry(
                  label: 'Draft Marks Registry',
                  icon: Icons.edit_note_outlined,
                  selectedIcon: Icons.edit_note,
                  route: AppRoutes.examinationsDrafts),
              RoleNavEntry(
                  label: 'Result Publication',
                  icon: Icons.publish_outlined,
                  selectedIcon: Icons.publish,
                  route: AppRoutes.examinationsPublication),
              RoleNavEntry(
                  label: 'Official Report Cards',
                  icon: Icons.badge_outlined,
                  selectedIcon: Icons.badge,
                  route: AppRoutes.examinationsReportCards),
            ],
          ),
          RoleNavCategory(
            title: 'Staff and Access',
            entries: [
              RoleNavEntry(
                  label: 'Staff Directory',
                  icon: Icons.badge_outlined,
                  selectedIcon: Icons.badge,
                  route: AppRoutes.staff),
              RoleNavEntry(
                  label: 'Add Staff Member',
                  icon: Icons.person_add_alt_outlined,
                  selectedIcon: Icons.person_add_alt,
                  route: AppRoutes.staffAdd),
              RoleNavEntry(
                  label: 'Staff Roles & Permissions',
                  icon: Icons.admin_panel_settings_outlined,
                  selectedIcon: Icons.admin_panel_settings,
                  route: AppRoutes.staffRoles),
              RoleNavEntry(
                  label: 'Teacher Workload & Assignments',
                  icon: Icons.assignment_ind_outlined,
                  selectedIcon: Icons.assignment_ind,
                  route: AppRoutes.staffWorkload),
              RoleNavEntry(
                  label: 'Staff Account Activation',
                  icon: Icons.manage_accounts_outlined,
                  selectedIcon: Icons.manage_accounts,
                  route: AppRoutes.staffActivation),
            ],
          ),
          RoleNavCategory(
            title: 'Attendance',
            entries: [
              RoleNavEntry(
                  label: 'Attendance Overview',
                  icon: Icons.co_present_outlined,
                  selectedIcon: Icons.co_present,
                  route: AppRoutes.attendance),
              RoleNavEntry(
                  label: 'Daily Attendance Register',
                  icon: Icons.how_to_reg_outlined,
                  selectedIcon: Icons.how_to_reg,
                  route: AppRoutes.attendanceRegister),
              RoleNavEntry(
                  label: 'Class-wise Attendance',
                  icon: Icons.group_outlined,
                  selectedIcon: Icons.group,
                  route: AppRoutes.attendanceClasswise),
              RoleNavEntry(
                  label: 'Absence Exceptions',
                  icon: Icons.event_busy_outlined,
                  selectedIcon: Icons.event_busy,
                  route: AppRoutes.attendanceExceptions),
              RoleNavEntry(
                  label: 'Attendance Corrections',
                  icon: Icons.published_with_changes_outlined,
                  selectedIcon: Icons.published_with_changes,
                  route: AppRoutes.attendanceCorrections),
              RoleNavEntry(
                  label: 'Attendance Reports',
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights,
                  route: AppRoutes.attendanceReports),
            ],
          ),
          RoleNavCategory(
            title: 'Finance & Accounts',
            entries: [
              RoleNavEntry(
                  label: 'Fee Structures',
                  icon: Icons.account_tree_outlined,
                  selectedIcon: Icons.account_tree,
                  route: AppRoutes.feeStructures),
              RoleNavEntry(
                  label: 'Fee Plans',
                  icon: Icons.payments_outlined,
                  selectedIcon: Icons.payments,
                  route: AppRoutes.feePlans),
              RoleNavEntry(
                  label: 'Student Fee Accounts',
                  icon: Icons.account_box_outlined,
                  selectedIcon: Icons.account_box,
                  route: AppRoutes.feeAccounts),
              RoleNavEntry(
                  label: 'Invoices Registry',
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  route: AppRoutes.feeInvoices),
              RoleNavEntry(
                  label: 'Generate New Invoice',
                  icon: Icons.post_add_outlined,
                  selectedIcon: Icons.post_add,
                  route: AppRoutes.feeInvoicesGenerate),
              RoleNavEntry(
                  label: 'Payment Transactions',
                  icon: Icons.paid_outlined,
                  selectedIcon: Icons.paid,
                  route: AppRoutes.feePayments),
              RoleNavEntry(
                  label: 'Offline Payments Entry',
                  icon: Icons.point_of_sale_outlined,
                  selectedIcon: Icons.point_of_sale,
                  route: AppRoutes.feePaymentsOffline),
              RoleNavEntry(
                  label: 'Receipts Registry',
                  icon: Icons.receipt_outlined,
                  selectedIcon: Icons.receipt,
                  route: AppRoutes.feeReceipts),
              RoleNavEntry(
                  label: 'Refund Management',
                  icon: Icons.currency_exchange_outlined,
                  selectedIcon: Icons.currency_exchange,
                  route: AppRoutes.feeRefunds),
              RoleNavEntry(
                  label: 'Outstanding Dues',
                  icon: Icons.pending_actions_outlined,
                  selectedIcon: Icons.pending_actions,
                  route: AppRoutes.feeDues),
              RoleNavEntry(
                  label: 'Financial Reports',
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  route: AppRoutes.feeReports),
            ],
          ),
          RoleNavCategory(
            title: 'Library',
            entries: [
              RoleNavEntry(
                  label: 'Library Catalog',
                  icon: Icons.local_library_outlined,
                  selectedIcon: Icons.local_library,
                  route: AppRoutes.library),
              RoleNavEntry(
                  label: 'Add New Book',
                  icon: Icons.library_add_outlined,
                  selectedIcon: Icons.library_add,
                  route: AppRoutes.libraryAdd),
              RoleNavEntry(
                  label: 'Issue Book',
                  icon: Icons.outbox_outlined,
                  selectedIcon: Icons.outbox,
                  route: AppRoutes.libraryIssue),
              RoleNavEntry(
                  label: 'Return Book',
                  icon: Icons.move_to_inbox_outlined,
                  selectedIcon: Icons.move_to_inbox,
                  route: AppRoutes.libraryReturn),
              RoleNavEntry(
                  label: 'Active Book Loans',
                  icon: Icons.auto_stories_outlined,
                  selectedIcon: Icons.auto_stories,
                  route: AppRoutes.libraryLoans),
              RoleNavEntry(
                  label: 'Overdue Loans',
                  icon: Icons.alarm_outlined,
                  selectedIcon: Icons.alarm,
                  route: AppRoutes.libraryOverdue),
              RoleNavEntry(
                  label: 'Library Members',
                  icon: Icons.card_membership_outlined,
                  selectedIcon: Icons.card_membership,
                  route: AppRoutes.libraryMembers),
              RoleNavEntry(
                  label: 'Library Reports',
                  icon: Icons.pie_chart_outline,
                  selectedIcon: Icons.pie_chart,
                  route: AppRoutes.libraryReports),
            ],
          ),
          RoleNavCategory(
            title: 'Institutional & Security',
            entries: [
              RoleNavEntry(
                  label: 'Institutional Notices',
                  icon: Icons.notifications_none,
                  selectedIcon: Icons.notifications,
                  route: AppRoutes.notices),
              RoleNavEntry(
                  label: 'Announcements Board',
                  icon: Icons.campaign_outlined,
                  selectedIcon: Icons.campaign,
                  route: AppRoutes.announcements),
              RoleNavEntry(
                  label: 'Transport Fleet',
                  icon: Icons.directions_bus_outlined,
                  selectedIcon: Icons.directions_bus,
                  route: AppRoutes.transport),
              RoleNavEntry(
                  label: 'Security Audit Logs',
                  icon: Icons.security_outlined,
                  selectedIcon: Icons.security,
                  route: AppRoutes.auditLogs),
              RoleNavEntry(
                  label: 'System Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  route: AppRoutes.settings),
            ],
          ),
        ];

      case UserRoles.teacher:
        return const [
          RoleNavCategory(
            title: 'My Teaching',
            entries: [
              RoleNavEntry(
                  label: 'Teacher Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  route: AppRoutes.dashboard),
              RoleNavEntry(
                  label: 'School Calendar',
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today,
                  route: AppRoutes.academicsCalendar),
              RoleNavEntry(
                  label: 'My Timetable',
                  icon: Icons.schedule_outlined,
                  selectedIcon: Icons.schedule,
                  route: AppRoutes.academicsTimetable),
              RoleNavEntry(
                  label: 'My Class Students',
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  route: AppRoutes.students),
              RoleNavEntry(
                  label: 'Student Profile Lookup',
                  icon: Icons.badge_outlined,
                  selectedIcon: Icons.badge,
                  route: AppRoutes.studentLookup),
            ],
          ),
          RoleNavCategory(
            title: 'Attendance',
            entries: [
              RoleNavEntry(
                  label: 'Daily Attendance Register',
                  icon: Icons.how_to_reg_outlined,
                  selectedIcon: Icons.how_to_reg,
                  route: AppRoutes.attendanceRegister),
              RoleNavEntry(
                  label: 'Attendance Corrections',
                  icon: Icons.published_with_changes_outlined,
                  selectedIcon: Icons.published_with_changes,
                  route: AppRoutes.attendanceCorrections),
            ],
          ),
          RoleNavCategory(
            title: 'Homework & Assignments',
            entries: [
              RoleNavEntry(
                  label: 'Homework & Assignments',
                  icon: Icons.assignment_turned_in_outlined,
                  selectedIcon: Icons.assignment_turned_in,
                  route: AppRoutes.academicsHomework),
              RoleNavEntry(
                  label: 'Create Homework',
                  icon: Icons.note_add_outlined,
                  selectedIcon: Icons.note_add,
                  route: AppRoutes.academicsHomeworkCreate),
              RoleNavEntry(
                  label: 'Review Submissions',
                  icon: Icons.upload_file_outlined,
                  selectedIcon: Icons.upload_file,
                  route: AppRoutes.academicsHomeworkSubmissions),
            ],
          ),
          RoleNavCategory(
            title: 'Learning Materials',
            entries: [
              RoleNavEntry(
                  label: 'Study Materials Repository',
                  icon: Icons.folder_shared_outlined,
                  selectedIcon: Icons.folder_shared,
                  route: AppRoutes.academicsMaterials),
              RoleNavEntry(
                  label: 'Upload Study Material',
                  icon: Icons.cloud_upload_outlined,
                  selectedIcon: Icons.cloud_upload,
                  route: AppRoutes.academicsMaterialsUpload),
            ],
          ),
          RoleNavCategory(
            title: 'Examinations and Marks',
            entries: [
              RoleNavEntry(
                  label: 'Examination Schedule',
                  icon: Icons.event_note_outlined,
                  selectedIcon: Icons.event_note,
                  route: AppRoutes.examinationsSchedule),
              RoleNavEntry(
                  label: 'Enter Student Marks',
                  icon: Icons.edit_calendar_outlined,
                  selectedIcon: Icons.edit_calendar,
                  route: AppRoutes.examinationsMarks),
              RoleNavEntry(
                  label: 'Draft Marks Registry',
                  icon: Icons.edit_note_outlined,
                  selectedIcon: Icons.edit_note,
                  route: AppRoutes.examinationsDrafts),
              RoleNavEntry(
                  label: 'Student Report Cards',
                  icon: Icons.badge_outlined,
                  selectedIcon: Icons.badge,
                  route: AppRoutes.examinationsReportCards),
            ],
          ),
          RoleNavCategory(
            title: 'Communication & Tools',
            entries: [
              RoleNavEntry(
                  label: 'School Notices',
                  icon: Icons.notifications_none,
                  selectedIcon: Icons.notifications,
                  route: AppRoutes.notices),
              RoleNavEntry(
                  label: 'Announcements',
                  icon: Icons.campaign_outlined,
                  selectedIcon: Icons.campaign,
                  route: AppRoutes.announcements),
              RoleNavEntry(
                  label: 'Library Catalog',
                  icon: Icons.local_library_outlined,
                  selectedIcon: Icons.local_library,
                  route: AppRoutes.library),
              RoleNavEntry(
                  label: 'My Profile & Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  route: AppRoutes.settings),
            ],
          ),
        ];

      case UserRoles.accountant:
        return const [
          RoleNavCategory(
            title: 'Overview',
            entries: [
              RoleNavEntry(
                  label: 'Finance Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  route: AppRoutes.dashboard),
              RoleNavEntry(
                  label: 'Financial Reports',
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  route: AppRoutes.feeReports),
            ],
          ),
          RoleNavCategory(
            title: 'Fee Configuration',
            entries: [
              RoleNavEntry(
                  label: 'Fee Structures & Heads',
                  icon: Icons.account_tree_outlined,
                  selectedIcon: Icons.account_tree,
                  route: AppRoutes.feeStructures),
              RoleNavEntry(
                  label: 'Fee Plans & Installments',
                  icon: Icons.payments_outlined,
                  selectedIcon: Icons.payments,
                  route: AppRoutes.feePlans),
            ],
          ),
          RoleNavCategory(
            title: 'Student Accounts',
            entries: [
              RoleNavEntry(
                  label: 'Student Fee Accounts',
                  icon: Icons.account_box_outlined,
                  selectedIcon: Icons.account_box,
                  route: AppRoutes.feeAccounts),
              RoleNavEntry(
                  label: 'Student Directory',
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  route: AppRoutes.students),
              RoleNavEntry(
                  label: 'Outstanding Dues',
                  icon: Icons.pending_actions_outlined,
                  selectedIcon: Icons.pending_actions,
                  route: AppRoutes.feeDues),
            ],
          ),
          RoleNavCategory(
            title: 'Invoicing',
            entries: [
              RoleNavEntry(
                  label: 'All Invoices',
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  route: AppRoutes.feeInvoices),
              RoleNavEntry(
                  label: 'Generate Invoice',
                  icon: Icons.post_add_outlined,
                  selectedIcon: Icons.post_add,
                  route: AppRoutes.feeInvoicesGenerate),
            ],
          ),
          RoleNavCategory(
            title: 'Payments',
            entries: [
              RoleNavEntry(
                  label: 'Payment Transactions',
                  icon: Icons.paid_outlined,
                  selectedIcon: Icons.paid,
                  route: AppRoutes.feePayments),
              RoleNavEntry(
                  label: 'Record Offline Payment',
                  icon: Icons.point_of_sale_outlined,
                  selectedIcon: Icons.point_of_sale,
                  route: AppRoutes.feePaymentsOffline),
            ],
          ),
          RoleNavCategory(
            title: 'Receipts & Adjustments',
            entries: [
              RoleNavEntry(
                  label: 'Fee Receipts Registry',
                  icon: Icons.receipt_outlined,
                  selectedIcon: Icons.receipt,
                  route: AppRoutes.feeReceipts),
              RoleNavEntry(
                  label: 'Refund Processing',
                  icon: Icons.currency_exchange_outlined,
                  selectedIcon: Icons.currency_exchange,
                  route: AppRoutes.feeRefunds),
            ],
          ),
          RoleNavCategory(
            title: 'Institutional',
            entries: [
              RoleNavEntry(
                  label: 'School Notices',
                  icon: Icons.notifications_none,
                  selectedIcon: Icons.notifications,
                  route: AppRoutes.notices),
              RoleNavEntry(
                  label: 'Accountant Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  route: AppRoutes.settings),
            ],
          ),
        ];

      case UserRoles.admissionsOfficer:
        return const [
          RoleNavCategory(
            title: 'Overview',
            entries: [
              RoleNavEntry(
                  label: 'Admissions Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  route: AppRoutes.dashboard),
            ],
          ),
          RoleNavCategory(
            title: 'Applications',
            entries: [
              RoleNavEntry(
                  label: 'All Applications',
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment,
                  route: AppRoutes.admissions),
              RoleNavEntry(
                  label: 'Review Queue',
                  icon: Icons.rate_review_outlined,
                  selectedIcon: Icons.rate_review,
                  route: AppRoutes.admissionsReview),
            ],
          ),
          RoleNavCategory(
            title: 'Verification',
            entries: [
              RoleNavEntry(
                  label: 'Document Verification',
                  icon: Icons.verified_user_outlined,
                  selectedIcon: Icons.verified_user,
                  route: AppRoutes.admissionsVerification),
            ],
          ),
          RoleNavCategory(
            title: 'Decisions',
            entries: [
              RoleNavEntry(
                  label: 'Admissions Decisions',
                  icon: Icons.gavel_outlined,
                  selectedIcon: Icons.gavel,
                  route: AppRoutes.admissionsDecisions),
            ],
          ),
          RoleNavCategory(
            title: 'Enrollment',
            entries: [
              RoleNavEntry(
                  label: 'Official Enrollment',
                  icon: Icons.how_to_reg_outlined,
                  selectedIcon: Icons.how_to_reg,
                  route: AppRoutes.admissionsEnrollment),
              RoleNavEntry(
                  label: 'Enrolled Students Directory',
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  route: AppRoutes.students),
              RoleNavEntry(
                  label: 'Student Registration Form',
                  icon: Icons.person_add_outlined,
                  selectedIcon: Icons.person_add,
                  route: AppRoutes.studentAdd),
              RoleNavEntry(
                  label: 'Parent & Guardian Directory',
                  icon: Icons.family_restroom_outlined,
                  selectedIcon: Icons.family_restroom,
                  route: AppRoutes.studentGuardians),
            ],
          ),
          RoleNavCategory(
            title: 'Reports',
            entries: [
              RoleNavEntry(
                  label: 'Admission Reports',
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics,
                  route: AppRoutes.admissionsReports),
            ],
          ),
          RoleNavCategory(
            title: 'Institutional',
            entries: [
              RoleNavEntry(
                  label: 'School Calendar',
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today,
                  route: AppRoutes.academicsCalendar),
              RoleNavEntry(
                  label: 'Notices & Circulars',
                  icon: Icons.notifications_none,
                  selectedIcon: Icons.notifications,
                  route: AppRoutes.notices),
              RoleNavEntry(
                  label: 'Officer Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  route: AppRoutes.settings),
            ],
          ),
        ];

      case UserRoles.librarian:
        return const [
          RoleNavCategory(
            title: 'Overview',
            entries: [
              RoleNavEntry(
                  label: 'Library Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  route: AppRoutes.dashboard),
            ],
          ),
          RoleNavCategory(
            title: 'Catalog',
            entries: [
              RoleNavEntry(
                  label: 'Library Catalog',
                  icon: Icons.local_library_outlined,
                  selectedIcon: Icons.local_library,
                  route: AppRoutes.library),
              RoleNavEntry(
                  label: 'Add New Book',
                  icon: Icons.library_add_outlined,
                  selectedIcon: Icons.library_add,
                  route: AppRoutes.libraryAdd),
            ],
          ),
          RoleNavCategory(
            title: 'Circulation',
            entries: [
              RoleNavEntry(
                  label: 'Issue Book',
                  icon: Icons.outbox_outlined,
                  selectedIcon: Icons.outbox,
                  route: AppRoutes.libraryIssue),
              RoleNavEntry(
                  label: 'Return Book',
                  icon: Icons.move_to_inbox_outlined,
                  selectedIcon: Icons.move_to_inbox,
                  route: AppRoutes.libraryReturn),
              RoleNavEntry(
                  label: 'Active Outstanding Loans',
                  icon: Icons.auto_stories_outlined,
                  selectedIcon: Icons.auto_stories,
                  route: AppRoutes.libraryLoans),
            ],
          ),
          RoleNavCategory(
            title: 'Availability and Overdue',
            entries: [
              RoleNavEntry(
                  label: 'Overdue Loans & Fines',
                  icon: Icons.alarm_outlined,
                  selectedIcon: Icons.alarm,
                  route: AppRoutes.libraryOverdue),
            ],
          ),
          RoleNavCategory(
            title: 'Library Members',
            entries: [
              RoleNavEntry(
                  label: 'Library Members',
                  icon: Icons.card_membership_outlined,
                  selectedIcon: Icons.card_membership,
                  route: AppRoutes.libraryMembers),
              RoleNavEntry(
                  label: 'Student Directory',
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  route: AppRoutes.students),
            ],
          ),
          RoleNavCategory(
            title: 'Fines and Reports',
            entries: [
              RoleNavEntry(
                  label: 'Circulation & Inventory Reports',
                  icon: Icons.pie_chart_outline,
                  selectedIcon: Icons.pie_chart,
                  route: AppRoutes.libraryReports),
            ],
          ),
          RoleNavCategory(
            title: 'Institutional',
            entries: [
              RoleNavEntry(
                  label: 'School Notices',
                  icon: Icons.notifications_none,
                  selectedIcon: Icons.notifications,
                  route: AppRoutes.notices),
              RoleNavEntry(
                  label: 'Librarian Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  route: AppRoutes.settings),
            ],
          ),
        ];

      case UserRoles.parentGuardian:
      default:
        return const [
          RoleNavCategory(
            title: 'Academics',
            entries: [
              RoleNavEntry(
                  label: 'Parent Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  route: AppRoutes.dashboard),
              RoleNavEntry(
                  label: 'Switch Child',
                  icon: Icons.switch_account_outlined,
                  selectedIcon: Icons.switch_account,
                  route: AppRoutes.parentChildren),
              RoleNavEntry(
                  label: 'Child Timetable',
                  icon: Icons.schedule_outlined,
                  selectedIcon: Icons.schedule,
                  route: AppRoutes.parentTimetable),
              RoleNavEntry(
                  label: 'Attendance Record',
                  icon: Icons.co_present_outlined,
                  selectedIcon: Icons.co_present,
                  route: AppRoutes.parentAttendance),
              RoleNavEntry(
                  label: 'Homework & Submissions',
                  icon: Icons.assignment_turned_in_outlined,
                  selectedIcon: Icons.assignment_turned_in,
                  route: AppRoutes.parentHomework),
              RoleNavEntry(
                  label: 'Curriculum Study Materials',
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book,
                  route: AppRoutes.parentMaterials),
              RoleNavEntry(
                  label: 'Upcoming Examinations',
                  icon: Icons.event_note_outlined,
                  selectedIcon: Icons.event_note,
                  route: AppRoutes.parentExams),
              RoleNavEntry(
                  label: 'Examination Results',
                  icon: Icons.fact_check_outlined,
                  selectedIcon: Icons.fact_check,
                  route: AppRoutes.parentResults),
            ],
          ),
          RoleNavCategory(
            title: 'Fees',
            entries: [
              RoleNavEntry(
                  label: 'Fee Summary & Invoices',
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  route: AppRoutes.parentFees),
              RoleNavEntry(
                  label: 'Official Fee Receipts',
                  icon: Icons.receipt_outlined,
                  selectedIcon: Icons.receipt,
                  route: AppRoutes.parentReceipts),
            ],
          ),
          RoleNavCategory(
            title: 'Requests & Communication',
            entries: [
              RoleNavEntry(
                  label: 'School Notices',
                  icon: Icons.notifications_none,
                  selectedIcon: Icons.notifications,
                  route: AppRoutes.notices),
              RoleNavEntry(
                  label: 'Official Announcements',
                  icon: Icons.campaign_outlined,
                  selectedIcon: Icons.campaign,
                  route: AppRoutes.announcements),
              RoleNavEntry(
                  label: 'Requests & Applications',
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment,
                  route: AppRoutes.parentRequests),
              RoleNavEntry(
                  label: 'Apply for Leave',
                  icon: Icons.time_to_leave_outlined,
                  selectedIcon: Icons.time_to_leave,
                  route: AppRoutes.parentLeave),
              RoleNavEntry(
                  label: 'School Helpdesk & Support',
                  icon: Icons.support_agent_outlined,
                  selectedIcon: Icons.support_agent,
                  route: AppRoutes.parentSupport),
            ],
          ),
          RoleNavCategory(
            title: 'Additional Services',
            entries: [
              RoleNavEntry(
                  label: 'Parent Profile',
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  route: AppRoutes.settings),
            ],
          ),
        ];
    }
  }

  static bool isNavEntryActive(RoleNavEntry entry, String currentRoute) {
    final cleanCurrent = currentRoute.split('?').first;
    final cleanEntry = entry.route.split('?').first;

    if (cleanEntry == cleanCurrent) {
      return true;
    }

    // Handle student detail routes such as /students/:studentId
    if (cleanEntry == AppRoutes.studentLookup &&
        cleanCurrent.startsWith('/students/') &&
        !cleanCurrent.endsWith('/add') &&
        !cleanCurrent.endsWith('/transfers') &&
        !cleanCurrent.endsWith('/promotions') &&
        !cleanCurrent.endsWith('/archives') &&
        !cleanCurrent.endsWith('/guardians') &&
        !cleanCurrent.endsWith('/link-guardians')) {
      return true;
    }

    // Handle admissions detail routes such as /admissions/:applicationId
    if (cleanEntry == AppRoutes.admissions &&
        cleanCurrent.startsWith('/admissions/') &&
        !cleanCurrent.endsWith('/apply') &&
        !cleanCurrent.endsWith('/review') &&
        !cleanCurrent.endsWith('/verification') &&
        !cleanCurrent.endsWith('/decisions') &&
        !cleanCurrent.endsWith('/enrollment') &&
        !cleanCurrent.endsWith('/reports')) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final roleColor = AppColors.getRoleColor(role);
    final roleDisplayName = UserRoles.getRoleDisplayName(role);
    final isMobile = AppBreakpoints.isMobile(context);
    final isTablet = AppBreakpoints.isTablet(context);

    // Filter permitted navigation destinations for current user role
    final permittedItems =
        _allNavItems.where((item) => item.allowedRoles.contains(role)).toList();

    int selectedRouteIndex =
        permittedItems.indexWhere((item) => item.route == currentRoute);
    if (selectedRouteIndex < 0) selectedRouteIndex = 0;

    if (isMobile) {
      return !kIsWeb
          ? _buildNativeMobileLayout(
              context: context,
              ref: ref,
              role: role,
              roleColor: roleColor,
              roleDisplayName: roleDisplayName,
              userEmail: user?.email ?? user?.displayName ?? 'Verified User',
              permittedItems: permittedItems,
              selectedRouteIndex: selectedRouteIndex,
            )
          : _buildWebMobileLayout(
              context: context,
              ref: ref,
              role: role,
              roleColor: roleColor,
              roleDisplayName: roleDisplayName,
              userEmail: user?.email ?? user?.displayName ?? 'Verified User',
              permittedItems: permittedItems,
              selectedRouteIndex: selectedRouteIndex,
            );
    } else if (isTablet) {
      return !kIsWeb
          ? _buildNativeTabletLayout(
              context: context,
              ref: ref,
              role: role,
              roleColor: roleColor,
              roleDisplayName: roleDisplayName,
              userEmail: user?.email ?? user?.displayName ?? 'Verified User',
              permittedItems: permittedItems,
              selectedRouteIndex: selectedRouteIndex,
            )
          : _buildWebTabletLayout(
              context: context,
              ref: ref,
              role: role,
              roleColor: roleColor,
              roleDisplayName: roleDisplayName,
              userEmail: user?.email ?? user?.displayName ?? 'Verified User',
              permittedItems: permittedItems,
              selectedRouteIndex: selectedRouteIndex,
            );
    } else {
      // Desktop Viewports (>= 1024): Enterprise Desktop ERP Layout
      return _buildWebDesktopLayout(
        context: context,
        ref: ref,
        role: role,
        roleColor: roleColor,
        roleDisplayName: roleDisplayName,
        userEmail: user?.email ?? user?.displayName ?? 'Verified User',
        permittedItems: permittedItems,
        selectedRouteIndex: selectedRouteIndex,
      );
    }
  }

  // --- 1. NATIVE MOBILE PRESENTATION (<600px on Android/iOS) ---
  Widget _buildNativeMobileLayout({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
  }) {
    return _buildMobileScaffold(
      context: context,
      ref: ref,
      role: role,
      roleColor: roleColor,
      roleDisplayName: roleDisplayName,
      userEmail: userEmail,
      permittedItems: permittedItems,
      selectedRouteIndex: selectedRouteIndex,
      isWeb: false,
    );
  }

  // --- 2. WEB MOBILE PRESENTATION (<600px on Web Browser) ---
  Widget _buildWebMobileLayout({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
  }) {
    return _buildMobileScaffold(
      context: context,
      ref: ref,
      role: role,
      roleColor: roleColor,
      roleDisplayName: roleDisplayName,
      userEmail: userEmail,
      permittedItems: permittedItems,
      selectedRouteIndex: selectedRouteIndex,
      isWeb: true,
    );
  }

  Widget _buildMobileScaffold({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
    required bool isWeb,
  }) {
    final hasSubTabs = navDestinations != null && navDestinations!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: isWeb
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandNavy,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:
                        const Icon(Icons.school, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: roleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          roleDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildRoleDrawer(
        context: context,
        ref: ref,
        role: role,
        roleColor: roleColor,
        userEmail: userEmail,
        isWeb: isWeb,
      ),
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: isWeb
          ? null
          : (hasSubTabs
              ? NavigationBar(
                  selectedIndex: selectedNavIndex,
                  onDestinationSelected: onNavIndexChanged,
                  destinations: navDestinations!,
                  backgroundColor: Colors.white,
                  indicatorColor: roleColor.withValues(alpha: 0.14),
                  elevation: 4,
                )
              : (permittedItems.length > 1
                  ? NavigationBar(
                      selectedIndex:
                          selectedRouteIndex < permittedItems.take(4).length
                              ? selectedRouteIndex
                              : 0,
                      onDestinationSelected: (idx) {
                        final target = permittedItems.take(4).toList()[idx];
                        if (target.route != currentRoute) {
                          context.go(target.route);
                        }
                      },
                      destinations: permittedItems
                          .take(4)
                          .map((item) => NavigationDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.selectedIcon),
                                label: item.label,
                              ))
                          .toList(),
                      backgroundColor: Colors.white,
                      indicatorColor: roleColor.withValues(alpha: 0.14),
                      elevation: 4,
                    )
                  : null)),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildRoleDrawer({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String userEmail,
    required bool isWeb,
  }) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.brandNavy,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandNavy,
                  AppColors.brandNavyDark,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child:
                      const Icon(Icons.school, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  isWeb ? 'LAV Academy • Web Portal' : 'LAV Academy SMS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...getRoleNavCategories(role).expand((category) => [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    category.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                ...category.entries.map((item) {
                  final isSelected = isNavEntryActive(item, currentRoute);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    child: Material(
                      color: isSelected
                          ? roleColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: isSelected
                                ? roleColor.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        leading: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: isSelected
                              ? roleColor
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? roleColor
                                : AppColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (item.route != currentRoute) {
                            context.go(item.route);
                          }
                        },
                      ),
                    ),
                  );
                }),
              ]),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.dangerRed),
            title: const Text('Sign Out',
                style: TextStyle(
                    color: AppColors.dangerRed, fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(context);
              _confirmSignOut(context, ref);
            },
          ),
        ],
      ),
    );
  }

  // --- 3. NATIVE TABLET PRESENTATION (Any Tablet on Android/iOS) ---
  Widget _buildNativeTabletLayout({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
  }) {
    return _buildTabletScaffold(
      context: context,
      ref: ref,
      role: role,
      roleColor: roleColor,
      roleDisplayName: roleDisplayName,
      userEmail: userEmail,
      permittedItems: permittedItems,
      selectedRouteIndex: selectedRouteIndex,
      isWeb: false,
    );
  }

  // --- 4. WEB TABLET PRESENTATION (600px - 1023px on Web Browser) ---
  Widget _buildWebTabletLayout({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
  }) {
    return _buildTabletScaffold(
      context: context,
      ref: ref,
      role: role,
      roleColor: roleColor,
      roleDisplayName: roleDisplayName,
      userEmail: userEmail,
      permittedItems: permittedItems,
      selectedRouteIndex: selectedRouteIndex,
      isWeb: true,
    );
  }

  Widget _buildTabletScaffold({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
    required bool isWeb,
  }) {
    final hasSubTabs = navDestinations != null && navDestinations!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  roleDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: roleColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: _buildRoleDrawer(
        context: context,
        ref: ref,
        role: role,
        roleColor: roleColor,
        userEmail: userEmail,
        isWeb: isWeb,
      ),
      body: Row(
        children: [
          // Tactile NavigationRail for Tablet
          NavigationRail(
            selectedIndex: selectedRouteIndex,
            onDestinationSelected: (idx) {
              final target = permittedItems[idx];
              if (target.route != currentRoute) {
                context.go(target.route);
              }
            },
            labelType: NavigationRailLabelType.selected,
            backgroundColor: Colors.white,
            indicatorColor: roleColor.withValues(alpha: 0.16),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandNavy,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A1E3A8A),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.school, size: 22, color: Colors.white),
              ),
            ),
            destinations: permittedItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon, color: roleColor),
                      label: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const VerticalDivider(
              width: 1, thickness: 1, color: AppColors.borderLight),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  if (hasSubTabs)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      color: Colors.white,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              List.generate(navDestinations!.length, (idx) {
                            final dest = navDestinations![idx];
                            final isSel = idx == selectedNavIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(dest.label),
                                selected: isSel,
                                selectedColor:
                                    roleColor.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  fontWeight:
                                      isSel ? FontWeight.w800 : FontWeight.w600,
                                  color:
                                      isSel ? roleColor : AppColors.textPrimary,
                                ),
                                onSelected: (_) => onNavIndexChanged?.call(idx),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  // --- 5. WEB DESKTOP PRESENTATION (>=1024px on Web Browser) ---
  Widget _buildWebDesktopLayout({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
    bool isWeb = false,
  }) {
    final hasSubTabs = navDestinations != null && navDestinations!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 260px Modern School ERP Enterprise Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: AppColors.borderLight, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x060F172A),
                  offset: Offset(1, 0),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Institutional Branding Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.brandNavy,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A1E3A8A),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LAV Academy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              isWeb ? 'SMS • Web Portal' : 'SMS • AY 2026-27',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Authenticated Identity Profile Box
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                roleDisplayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AY 2026-27',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'INSTITUTIONAL MODULES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Grouped Navigation Items List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: getRoleNavCategories(role)
                        .expand((category) => [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 14, 10, 4),
                                child: Text(
                                  category.title.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              ...category.entries.map((item) {
                                final isSelected =
                                    isNavEntryActive(item, currentRoute);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Material(
                                    color: isSelected
                                        ? roleColor.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        if (item.route != currentRoute) {
                                          context.go(item.route);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 7),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected
                                                  ? item.selectedIcon
                                                  : item.icon,
                                              size: 16,
                                              color: isSelected
                                                  ? roleColor
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item.label,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? roleColor
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                width: 3,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: roleColor,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ])
                        .toList(),
                  ),
                ),

                // Bottom End Session Action
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('End Session'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () => _confirmSignOut(context, ref),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Desktop Main Workspace Area
          Expanded(
            child: Column(
              children: [
                // Desktop Header Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom:
                          BorderSide(color: AppColors.borderLight, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'LAV Academy / $roleDisplayName',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (hasSubTabs) ...[
                        const SizedBox(width: 24),
                        Row(
                          children:
                              List.generate(navDestinations!.length, (idx) {
                            final dest = navDestinations![idx];
                            final isSel = idx == selectedNavIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => onNavIndexChanged?.call(idx),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? roleColor.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSel
                                          ? roleColor.withValues(alpha: 0.35)
                                          : Colors.transparent,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    dest.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSel
                                          ? roleColor
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                      const Spacer(),
                      ...?actions,
                    ],
                  ),
                ),

                // Desktop Content Area
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    width: double.infinity,
                    height: double.infinity,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.maxContentWidth,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: body,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Session Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your authenticated session will be terminated and cached sensitive records cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
