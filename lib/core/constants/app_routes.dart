/// Centralized Route Constants for LAV Academy School Management System.
/// Strictly enforces unique, dedicated named routes for every functional workflow.
/// NO query parameters or generic dashboard fallbacks for separate operations.
class AppRoutes {
  AppRoutes._();

  // Authentication & Session
  static const String login = '/login';
  static const String loginParent = '/login/parent';
  static const String loginStaff = '/login/staff';
  static const String loginSelect = '/login/select';
  static const String forgotPassword = '/forgot-password';
  static const String unauthorized = '/unauthorized';

  // Role Dashboards (Single Unified Destination)
  static const String dashboard = '/dashboard';

  // 1. Student Management Module (Each action has its own dedicated route)
  static const String students = '/students';
  static const String studentDetail = '/students/:studentId';
  static const String studentAdd = '/students/add';
  static const String studentLookup = '/students/lookup';
  static const String studentTransfers = '/students/transfers';
  static const String studentPromotions = '/students/promotions';
  static const String studentArchives = '/students/archives';
  static const String studentGuardians = '/students/guardians';
  static const String studentLinkGuardians = '/students/link-guardians';

  // 2. Admissions Module
  static const String admissions = '/admissions';
  static const String admissionsApply = '/admissions/apply';
  static const String admissionsDetail = '/admissions/:applicationId';
  static const String admissionsNew = '/admissions/apply';
  static const String admissionsReview = '/admissions/review';
  static const String admissionsVerification = '/admissions/verification';
  static const String admissionsDecisions = '/admissions/decisions';
  static const String admissionsEnrollment = '/admissions/enrollment';
  static const String admissionsReports = '/admissions/reports';

  // 3. Academic Management Module
  static const String academics = '/academics';
  static const String academicsYears = '/academics/years';
  static const String academicsClasses = '/academics/classes';
  static const String academicsSections = '/academics/sections';
  static const String academicsSubjects = '/academics/subjects';
  static const String academicsTimetable = '/academics/timetable';
  static const String academicsCalendar = '/academics/calendar';
  static const String academicsHolidays = '/academics/holidays';
  static const String academicsHomework = '/academics/homework';
  static const String academicsHomeworkCreate = '/academics/homework/create';
  static const String academicsHomeworkSubmissions = '/academics/homework/submissions';
  static const String academicsMaterials = '/academics/materials';
  static const String academicsMaterialsUpload = '/academics/materials/upload';

  // 4. Examinations & Marks Module
  static const String examinations = '/examinations';
  static const String examinationsSchedule = '/examinations/schedule';
  static const String examinationsMarks = '/examinations/marks';
  static const String examinationsDrafts = '/examinations/drafts';
  static const String examinationsPublication = '/examinations/publication';
  static const String examinationsReportCards = '/examinations/report-cards';

  // 5. Staff and Access Module
  static const String staff = '/staff';
  static const String staffDetail = '/staff/:staffId';
  static const String staffAdd = '/staff/add';
  static const String staffRoles = '/staff/roles';
  static const String staffWorkload = '/staff/workload';
  static const String staffActivation = '/staff/activation';

  // 6. Attendance Module
  static const String attendance = '/attendance';
  static const String attendanceRegister = '/attendance/register';
  static const String attendanceClasswise = '/attendance/classwise';
  static const String attendanceExceptions = '/attendance/exceptions';
  static const String attendanceCorrections = '/attendance/corrections';
  static const String attendanceReports = '/attendance/reports';

  // 7. Fee Management Module
  static const String fees = '/fees';
  static const String feeInvoiceDetail = '/fees/invoices/:invoiceId';
  static const String feeStructures = '/fees/structures';
  static const String feePlans = '/fees/plans';
  static const String feeAccounts = '/fees/accounts';
  static const String feeInvoices = '/fees/invoices';
  static const String feeInvoicesGenerate = '/fees/invoices/generate';
  static const String feePayments = '/fees/payments';
  static const String feePaymentsOffline = '/fees/payments/offline';
  static const String feeReceipts = '/fees/receipts';
  static const String feeRefunds = '/fees/refunds';
  static const String feeDues = '/fees/dues';
  static const String feeReports = '/fees/reports';

  // 8. Library Circulation & Catalog Module
  static const String library = '/library';
  static const String libraryAdd = '/library/add';
  static const String libraryIssue = '/library/issue';
  static const String libraryReturn = '/library/return';
  static const String libraryLoans = '/library/loans';
  static const String libraryOverdue = '/library/overdue';
  static const String libraryMembers = '/library/members';
  static const String libraryReports = '/library/reports';

  // 9. Parent / Guardian Dedicated Workspaces
  static const String parentChildren = '/parent/children';
  static const String parentTimetable = '/parent/timetable';
  static const String parentAttendance = '/parent/attendance';
  static const String parentHomework = '/parent/homework';
  static const String parentMaterials = '/parent/materials';
  static const String parentExams = '/parent/exams';
  static const String parentResults = '/parent/results';
  static const String parentFees = '/parent/fees';
  static const String parentReceipts = '/parent/receipts';
  static const String parentRequests = '/parent/requests';
  static const String requests = parentRequests;
  static const String parentLeave = '/parent/leave';
  static const String parentSupport = '/parent/support';

  // 10. Communication & Notices
  static const String notices = '/notices';
  static const String announcements = '/notices/announcements';

  // 11. Security, Audit, and Institutional Settings
  static const String auditLogs = '/audit-logs';
  static const String rolesPermissions = '/roles-permissions';
  static const String settings = '/settings';
  static const String transport = '/transport';

  // 12. Credential Management
  static const String changePhone = '/account/change-phone';
  static const String changePassword = '/account/change-password';
  static const String adminUserCredentials = '/admin/user-credentials';
}
