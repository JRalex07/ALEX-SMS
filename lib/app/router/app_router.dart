import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_selection_screen.dart';
import '../../features/auth/native_app_login_screen.dart';
import '../../features/auth/web_login_screen.dart';
import '../../features/dashboard/unified_dashboard_screen.dart';

// 1. Students Module
import '../../features/students/student_directory_screen.dart';
import '../../features/students/student_registration_screen.dart';
import '../../features/students/student_lookup_screen.dart';
import '../../features/students/student_transfers_screen.dart';
import '../../features/students/student_promotions_screen.dart';
import '../../features/students/student_archives_screen.dart';
import '../../features/students/guardian_directory_screen.dart';
import '../../features/students/link_guardians_screen.dart';

// 2. Admissions Module
import '../../features/admissions/admissions_overview_screen.dart';
import '../../features/admissions/admissions_review_queue_screen.dart';
import '../../features/admissions/admissions_document_verification_screen.dart';
import '../../features/admissions/admissions_decisions_screen.dart';
import '../../features/admissions/admissions_enrollment_screen.dart';
import '../../features/admissions/admissions_reports_screen.dart';
import '../../features/admissions/admission_application_screen.dart';
import '../../features/admissions/admission_detail_screen.dart';

// 3. Academics Module
import '../../features/academics/academic_years_screen.dart';
import '../../features/academics/classes_management_screen.dart';
import '../../features/academics/sections_management_screen.dart';
import '../../features/academics/subjects_management_screen.dart';
import '../../features/academics/timetable_management_screen.dart';
import '../../features/academics/school_calendar_screen.dart';
import '../../features/academics/holidays_management_screen.dart';
import '../../features/academics/homework_management_screen.dart';
import '../../features/academics/create_homework_screen.dart';
import '../../features/academics/student_submissions_screen.dart';
import '../../features/academics/study_materials_screen.dart';
import '../../features/academics/upload_material_screen.dart';

// 4. Examinations Module
import '../../features/examinations/examinations_catalog_screen.dart';
import '../../features/examinations/examination_schedule_screen.dart';
import '../../features/examinations/marks_entry_screen.dart';
import '../../features/examinations/draft_marks_screen.dart';
import '../../features/examinations/result_publication_screen.dart';
import '../../features/examinations/report_cards_screen.dart';

// 5. Staff Module
import '../../features/staff/staff_directory_screen.dart';
import '../../features/staff/add_staff_screen.dart';
import '../../features/staff/staff_roles_screen.dart';
import '../../features/staff/teacher_workload_screen.dart';
import '../../features/staff/staff_activation_screen.dart';

// 6. Attendance Module
import '../../features/attendance/attendance_overview_screen.dart';
import '../../features/attendance/attendance_register_screen.dart';
import '../../features/attendance/classwise_attendance_screen.dart';
import '../../features/attendance/attendance_exceptions_screen.dart';
import '../../features/attendance/attendance_corrections_screen.dart';
import '../../features/attendance/attendance_reports_screen.dart';

// 7. Finance Module
import '../../features/finance/fee_structures_screen.dart';
import '../../features/finance/fee_plans_screen.dart';
import '../../features/finance/fee_accounts_screen.dart';
import '../../features/finance/invoice_registry_screen.dart';
import '../../features/finance/generate_invoice_screen.dart';
import '../../features/finance/payment_transactions_screen.dart';
import '../../features/finance/offline_payments_screen.dart';
import '../../features/finance/receipt_registry_screen.dart';
import '../../features/finance/refund_management_screen.dart';
import '../../features/finance/outstanding_dues_screen.dart';
import '../../features/finance/financial_reports_screen.dart';

// 8. Library Module
import '../../features/library/library_catalog_screen.dart';
import '../../features/library/add_book_screen.dart';
import '../../features/library/issue_book_screen.dart';
import '../../features/library/return_book_screen.dart';
import '../../features/library/active_loans_screen.dart';
import '../../features/library/overdue_loans_screen.dart';
import '../../features/library/library_members_screen.dart';
import '../../features/library/library_reports_screen.dart';

// 9. Parent Module
import '../../features/parent/switch_child_screen.dart';
import '../../features/parent/parent_timetable_screen.dart';
import '../../features/parent/parent_attendance_screen.dart';
import '../../features/parent/parent_homework_screen.dart';
import '../../features/parent/parent_materials_screen.dart';
import '../../features/parent/parent_exams_screen.dart';
import '../../features/parent/parent_results_screen.dart';
import '../../features/parent/parent_fees_screen.dart';
import '../../features/parent/parent_receipts_screen.dart';
import '../../features/parent/parent_requests_screen.dart';
import '../../features/parent/parent_leave_screen.dart';
import '../../features/parent/parent_support_screen.dart';

// Resources & Settings
import '../../features/resources/announcements_screen.dart';
import '../../features/resources/audit_logs_screen.dart';
import '../../features/resources/notices_resource_screen.dart';
import '../../features/resources/role_permissions_screen.dart';
import '../../features/resources/settings_screen.dart';
import '../../features/resources/students_resource_screen.dart';
import '../../features/resources/transport_screen.dart';
import '../../features/resources/unauthorized_screen.dart';

// Credential Management
import '../../features/auth/change_phone_screen.dart';
import '../../features/auth/change_password_screen.dart';
import '../../features/admin/admin_user_credentials_screen.dart';
import '../../providers/auth_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userProfile = ref.watch(currentUserProfileProvider).value;

  final isAuthenticated = authState.value != null;

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final uriString = state.uri.toString();

      final isAuthFlow = path == AppRoutes.login ||
          path == AppRoutes.loginParent ||
          path == AppRoutes.loginStaff ||
          path == AppRoutes.loginSelect ||
          path == AppRoutes.forgotPassword;

      // 1. Unauthenticated users cannot access protected routes
      if (!isAuthenticated) {
        if (isAuthFlow) {
          return null; // Allow unauthenticated user on login screens
        }

        // Preserve destination for safe return after authentication
        final safeTarget = Uri.encodeComponent(uriString);
        return '${AppRoutes.login}?redirect=$safeTarget';
      }

      // 2. Suspended account guard (fail closed)
      if (userProfile != null && !userProfile.isActive) {
        if (path == AppRoutes.unauthorized) {
          return null;
        }
        return '${AppRoutes.unauthorized}?from=$path&reason=suspended';
      }

      // 3. Authenticated users attempting to visit login screens are redirected to /dashboard
      if (isAuthFlow) {
        final redirectParam = state.uri.queryParameters['redirect'];
        if (redirectParam != null &&
            redirectParam.isNotEmpty &&
            redirectParam.startsWith('/') &&
            !redirectParam.startsWith('/login')) {
          return redirectParam;
        }
        return AppRoutes.dashboard;
      }

      // 4. Role-based resource guards
      final role = userProfile?.role;
      if (role != null) {
        // Admissions route guard:
        if (path.startsWith(AppRoutes.admissions)) {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.admissionsOfficer,
          ];
          if (!allowed.contains(role)) {
            return '${AppRoutes.unauthorized}?from=$path';
          }
        }

        // Staff & Security route guards:
        if (path.startsWith(AppRoutes.staff) ||
            path.startsWith(AppRoutes.auditLogs) ||
            path.startsWith(AppRoutes.rolesPermissions)) {
          const allowed = [UserRoles.schoolAdmin];
          if (!allowed.contains(role)) {
            return '${AppRoutes.unauthorized}?from=$path';
          }
        }

        // Fee Management route guard:
        if (path.startsWith(AppRoutes.fees)) {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.accountant,
            UserRoles.parentGuardian,
          ];
          if (!allowed.contains(role)) {
            return '${AppRoutes.unauthorized}?from=$path';
          }
        }

        // Attendance route guard:
        if (path.startsWith(AppRoutes.attendance)) {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.teacher,
            UserRoles.parentGuardian,
          ];
          if (!allowed.contains(role)) {
            return '${AppRoutes.unauthorized}?from=$path';
          }
        }

        // Academics & Examinations route guard:
        if (path.startsWith(AppRoutes.academics) ||
            path.startsWith(AppRoutes.examinations)) {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.teacher,
            UserRoles.parentGuardian,
          ];
          if (!allowed.contains(role)) {
            return '${AppRoutes.unauthorized}?from=$path';
          }
        }

        // Library route guard:
        if (path.startsWith(AppRoutes.library)) {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.librarian,
            UserRoles.teacher,
            UserRoles.parentGuardian,
          ];
          if (!allowed.contains(role)) {
            return '${AppRoutes.unauthorized}?from=$path';
          }
        }

        // Parent Dedicated Workspaces route guard:
        if (path.startsWith('/parent/') ||
            path.startsWith(AppRoutes.parentRequests) ||
            path.startsWith(AppRoutes.transport)) {
          const allowed = [
            UserRoles.parentGuardian,
            UserRoles.schoolAdmin,
          ];
          if (!allowed.contains(role)) {
            return '${AppRoutes.unauthorized}?from=$path';
          }
        }

        // Credential Management route guards:
        if (path == AppRoutes.changePassword) {
          if (role == UserRoles.parentGuardian) {
            return AppRoutes.changePhone;
          }
        }
        if (path == AppRoutes.changePhone) {
          if (role != UserRoles.parentGuardian && role != UserRoles.schoolAdmin) {
            return AppRoutes.changePassword;
          }
        }
        if (path == AppRoutes.adminUserCredentials) {
          if (role != UserRoles.schoolAdmin) {
            return '${AppRoutes.unauthorized}?from=$path';
          }
        }

        // Parameter tampering guard for /students/:studentId:
        if (path.startsWith('/students/') && role == UserRoles.parentGuardian) {
          final studentId = state.pathParameters['studentId'];
          final wardIds = userProfile?.wardStudentIds ?? [];
          if (studentId != null && !wardIds.contains(studentId)) {
            return '${AppRoutes.unauthorized}?from=$uriString';
          }
        }
      }

      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          final isStaff = roleParam == 'staff';
          if (kIsWeb) {
            return NoTransitionPage(
              key: const ValueKey('auth_web_login_page'),
              child: WebLoginScreen(
                key: const ValueKey('web_login_screen_widget'),
                initialTab: isStaff ? WebLoginTab.staff : WebLoginTab.parent,
              ),
            );
          } else {
            return MaterialPage(
              key: state.pageKey,
              child: NativeAppLoginScreen(
                initialMode:
                    isStaff ? NativeLoginMode.staff : NativeLoginMode.parent,
              ),
            );
          }
        },
      ),
      GoRoute(
        path: AppRoutes.loginParent,
        pageBuilder: (context, state) {
          if (kIsWeb) {
            return const NoTransitionPage(
              key: ValueKey('auth_web_login_page'),
              child: WebLoginScreen(
                key: ValueKey('web_login_screen_widget'),
                initialTab: WebLoginTab.parent,
              ),
            );
          } else {
            return MaterialPage(
              key: state.pageKey,
              child: const NativeAppLoginScreen(
                  initialMode: NativeLoginMode.parent),
            );
          }
        },
      ),
      GoRoute(
        path: AppRoutes.loginStaff,
        pageBuilder: (context, state) {
          if (kIsWeb) {
            return const NoTransitionPage(
              key: ValueKey('auth_web_login_page'),
              child: WebLoginScreen(
                key: ValueKey('web_login_screen_widget'),
                initialTab: WebLoginTab.staff,
              ),
            );
          } else {
            return MaterialPage(
              key: state.pageKey,
              child: const NativeAppLoginScreen(
                  initialMode: NativeLoginMode.staff),
            );
          }
        },
      ),
      GoRoute(
        path: AppRoutes.loginSelect,
        builder: (context, state) => const LoginSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Single Unified Dashboard for All Authenticated Roles
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const UnifiedDashboardScreen(),
      ),

      // 1. Student Management Dedicated Routes
      GoRoute(
        path: AppRoutes.students,
        builder: (context, state) => const StudentDirectoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentAdd,
        builder: (context, state) => const StudentRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentLookup,
        builder: (context, state) => const StudentLookupScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentTransfers,
        builder: (context, state) => const StudentTransfersScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentPromotions,
        builder: (context, state) => const StudentPromotionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentArchives,
        builder: (context, state) => const StudentArchivesScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentGuardians,
        builder: (context, state) => const GuardianDirectoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentLinkGuardians,
        builder: (context, state) => const LinkGuardiansScreen(),
      ),
      GoRoute(
        path: '/students/:studentId',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId'] ?? '';
          return StudentDetailResourceScreen(studentId: studentId);
        },
      ),

      // 2. Admissions Dedicated Routes
      GoRoute(
        path: AppRoutes.admissions,
        builder: (context, state) => const AdmissionsOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.admissionsReview,
        builder: (context, state) => const AdmissionsReviewQueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.admissionsVerification,
        builder: (context, state) =>
            const AdmissionsDocumentVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.admissionsDecisions,
        builder: (context, state) => const AdmissionsDecisionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admissionsEnrollment,
        builder: (context, state) => const AdmissionsEnrollmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.admissionsReports,
        builder: (context, state) => const AdmissionsReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admissionsApply,
        builder: (context, state) {
          final appId = state.uri.queryParameters['draftId'];
          return AdmissionApplicationScreen(applicationId: appId);
        },
      ),
      GoRoute(
        path: '/admissions/:applicationId',
        builder: (context, state) {
          final appId = state.pathParameters['applicationId'] ?? '';
          return AdmissionDetailScreen(applicationId: appId);
        },
      ),

      // 3. Academic Management Dedicated Routes
      GoRoute(
        path: AppRoutes.academics,
        builder: (context, state) => const AcademicYearsScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsYears,
        builder: (context, state) => const AcademicYearsScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsClasses,
        builder: (context, state) => const ClassesManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsSections,
        builder: (context, state) => const SectionsManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsSubjects,
        builder: (context, state) => const SubjectsManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsTimetable,
        builder: (context, state) => const TimetableManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsCalendar,
        builder: (context, state) => const SchoolCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsHolidays,
        builder: (context, state) => const HolidaysManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsHomework,
        builder: (context, state) => const HomeworkManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsHomeworkCreate,
        builder: (context, state) => const CreateHomeworkScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsHomeworkSubmissions,
        builder: (context, state) => const StudentSubmissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsMaterials,
        builder: (context, state) => const StudyMaterialsScreen(),
      ),
      GoRoute(
        path: AppRoutes.academicsMaterialsUpload,
        builder: (context, state) => const UploadMaterialScreen(),
      ),

      // 4. Examinations Dedicated Routes
      GoRoute(
        path: AppRoutes.examinations,
        builder: (context, state) => const ExaminationsCatalogScreen(),
      ),
      GoRoute(
        path: AppRoutes.examinationsSchedule,
        builder: (context, state) => const ExaminationScheduleScreen(),
      ),
      GoRoute(
        path: AppRoutes.examinationsMarks,
        builder: (context, state) => const MarksEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.examinationsDrafts,
        builder: (context, state) => const DraftMarksScreen(),
      ),
      GoRoute(
        path: AppRoutes.examinationsPublication,
        builder: (context, state) => const ResultPublicationScreen(),
      ),
      GoRoute(
        path: AppRoutes.examinationsReportCards,
        builder: (context, state) => const ReportCardsScreen(),
      ),

      // 5. Staff and Access Dedicated Routes
      GoRoute(
        path: AppRoutes.staff,
        builder: (context, state) => const StaffDirectoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffAdd,
        builder: (context, state) => const AddStaffScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffRoles,
        builder: (context, state) => const StaffRolesScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffWorkload,
        builder: (context, state) => const TeacherWorkloadScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffActivation,
        builder: (context, state) => const StaffActivationScreen(),
      ),

      // 6. Attendance Dedicated Routes
      GoRoute(
        path: AppRoutes.attendance,
        builder: (context, state) => const AttendanceOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendanceRegister,
        builder: (context, state) => const AttendanceRegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendanceClasswise,
        builder: (context, state) => const ClasswiseAttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendanceExceptions,
        builder: (context, state) => const AttendanceExceptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendanceCorrections,
        builder: (context, state) => const AttendanceCorrectionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendanceReports,
        builder: (context, state) => const AttendanceReportsScreen(),
      ),

      // 7. Finance and Fees Dedicated Routes
      GoRoute(
        path: AppRoutes.fees,
        builder: (context, state) => const InvoiceRegistryScreen(),
      ),
      GoRoute(
        path: AppRoutes.feeStructures,
        builder: (context, state) => const FeeStructuresScreen(),
      ),
      GoRoute(
        path: AppRoutes.feePlans,
        builder: (context, state) => const FeePlansScreen(),
      ),
      GoRoute(
        path: AppRoutes.feeAccounts,
        builder: (context, state) => const FeeAccountsScreen(),
      ),
      GoRoute(
        path: AppRoutes.feeInvoices,
        builder: (context, state) => const InvoiceRegistryScreen(),
      ),
      GoRoute(
        path: AppRoutes.feeInvoicesGenerate,
        builder: (context, state) => const GenerateInvoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.feePayments,
        builder: (context, state) => const PaymentTransactionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.feePaymentsOffline,
        builder: (context, state) => const OfflinePaymentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.feeReceipts,
        builder: (context, state) => const ReceiptRegistryScreen(),
      ),
      GoRoute(
        path: AppRoutes.feeRefunds,
        builder: (context, state) => const RefundManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.feeDues,
        builder: (context, state) => const OutstandingDuesScreen(),
      ),
      GoRoute(
        path: AppRoutes.feeReports,
        builder: (context, state) => const FinancialReportsScreen(),
      ),

      // 8. Library Circulation & Catalog Dedicated Routes
      GoRoute(
        path: AppRoutes.library,
        builder: (context, state) => const LibraryCatalogScreen(),
      ),
      GoRoute(
        path: AppRoutes.libraryAdd,
        builder: (context, state) => const AddBookScreen(),
      ),
      GoRoute(
        path: AppRoutes.libraryIssue,
        builder: (context, state) => const IssueBookScreen(),
      ),
      GoRoute(
        path: AppRoutes.libraryReturn,
        builder: (context, state) => const ReturnBookScreen(),
      ),
      GoRoute(
        path: AppRoutes.libraryLoans,
        builder: (context, state) => const ActiveLoansScreen(),
      ),
      GoRoute(
        path: AppRoutes.libraryOverdue,
        builder: (context, state) => const OverdueLoansScreen(),
      ),
      GoRoute(
        path: AppRoutes.libraryMembers,
        builder: (context, state) => const LibraryMembersScreen(),
      ),
      GoRoute(
        path: AppRoutes.libraryReports,
        builder: (context, state) => const LibraryReportsScreen(),
      ),

      // 9. Parent / Guardian Dedicated Workspaces
      GoRoute(
        path: AppRoutes.parentChildren,
        builder: (context, state) => const SwitchChildScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentTimetable,
        builder: (context, state) => const ParentTimetableScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentAttendance,
        builder: (context, state) => const ParentAttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentHomework,
        builder: (context, state) => const ParentHomeworkScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentMaterials,
        builder: (context, state) => const ParentMaterialsScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentExams,
        builder: (context, state) => const ParentExamsScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentResults,
        builder: (context, state) => const ParentResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentFees,
        builder: (context, state) => const ParentFeesScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentReceipts,
        builder: (context, state) => const ParentReceiptsScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentRequests,
        builder: (context, state) => const ParentRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentLeave,
        builder: (context, state) => const ParentLeaveScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentSupport,
        builder: (context, state) => const ParentSupportScreen(),
      ),

      // 10. Communication & Announcements
      GoRoute(
        path: AppRoutes.notices,
        builder: (context, state) => const NoticesResourceScreen(),
      ),
      GoRoute(
        path: AppRoutes.announcements,
        builder: (context, state) => const AnnouncementsScreen(),
      ),

      // 11. Security, Audit, and Institutional Settings
      GoRoute(
        path: AppRoutes.auditLogs,
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.rolesPermissions,
        builder: (context, state) => const RolePermissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.transport,
        builder: (context, state) => const TransportResourceScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      // 12. Credential Management Routes
      GoRoute(
        path: AppRoutes.changePhone,
        builder: (context, state) => const ChangePhoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUserCredentials,
        builder: (context, state) => const AdminUserCredentialsScreen(),
      ),
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (context, state) {
          final fromRoute = state.uri.queryParameters['from'];
          return UnauthorizedScreen(attemptedRoute: fromRoute);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                '404 — Resource Not Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested URL "${state.uri}" does not exist in the school management system.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.dashboard, size: 16),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => context.go(AppRoutes.dashboard),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
