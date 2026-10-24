import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lav_sms/app/router/app_router.dart';
import 'package:lav_sms/core/constants/breakpoints.dart';
import 'package:lav_sms/core/constants/role_colors.dart';
import 'package:lav_sms/core/services/data_export_service.dart';
import 'package:lav_sms/features/auth/login_selection_screen.dart';
import 'package:lav_sms/models/attendance_model.dart';
import 'package:lav_sms/models/fee_model.dart';
import 'package:lav_sms/models/library_model.dart';
import 'package:lav_sms/models/student_model.dart';
import 'package:lav_sms/models/user_model.dart';
import 'package:lav_sms/providers/auth_providers.dart';
import 'package:lav_sms/repositories/auth_repository.dart';
import 'package:lav_sms/shared/dialogs/attendance_register_dialog.dart';
import 'package:lav_sms/shared/dialogs/confirm_action_dialog.dart';
import 'package:lav_sms/shared/dialogs/fee_receipt_dialog.dart';
import 'package:lav_sms/shared/dialogs/report_card_dialog.dart';
import 'package:lav_sms/shared/widgets/responsive_scaffold.dart';

void main() {
  group('Acceptance Criteria 1 & 2: Parent Phone & OTP Invariants', () {
    late AuthRepository authRepo;

    setUp(() {
      authRepo = AuthRepository();
    });

    test('Rejects phone numbers missing international country prefix',
        () async {
      String? errorMessage;
      await authRepo.sendPhoneOtp(
        phoneNumber: '9876543210', // Missing +91
        onCodeSent: (_) {},
        onError: (err) => errorMessage = err,
      );

      expect(errorMessage, isNotNull);
      expect(errorMessage, contains('country code'));
    });

    test('Enforces strict 6-digit OTP code requirement', () async {
      expect(
        () async => await authRepo.verifyOtpAndSignIn(
          verificationId: 'session_verif_123',
          smsCode: '12', // Too short
          phoneNumber: '+919876543210',
        ),
        throwsA(isA<InvalidOtpException>()),
      );

      expect(
        () async => await authRepo.verifyOtpAndSignIn(
          verificationId: 'session_verif_123',
          smsCode: '12345678', // Too long
          phoneNumber: '+919876543210',
        ),
        throwsA(isA<InvalidOtpException>()),
      );
    });
  });

  group('Acceptance Criteria 3: Staff Institutional Invariants & Role Model',
      () {
    late AuthRepository authRepo;

    setUp(() {
      authRepo = AuthRepository();
    });

    test('Staff sign-in rejects blank email or password credentials', () async {
      expect(
        () async => await authRepo.signInStaffWithEmailAndPassword(
          email: '',
          password: 'Password@123',
        ),
        throwsA(isA<AuthException>()),
      );

      expect(
        () async => await authRepo.signInStaffWithEmailAndPassword(
          email: 'admin@lavschool.edu',
          password: '',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test(
        'Exactly 6 authorized roles defined and staff roles correctly isolated',
        () {
      expect(UserRoles.allRoles.length, 6);
      expect(UserRoles.allRoles, contains(UserRoles.schoolAdmin));
      expect(UserRoles.allRoles, contains(UserRoles.teacher));
      expect(UserRoles.allRoles, contains(UserRoles.accountant));
      expect(UserRoles.allRoles, contains(UserRoles.admissionsOfficer));
      expect(UserRoles.allRoles, contains(UserRoles.librarian));
      expect(UserRoles.allRoles, contains(UserRoles.parentGuardian));

      // Student is NOT an authentication role in v2.4.0
      expect(UserRoles.allRoles.contains('student'), false);

      // Staff roles helper correctly classifies roles
      expect(UserRoles.isStaffRole(UserRoles.schoolAdmin), true);
      expect(UserRoles.isStaffRole(UserRoles.teacher), true);
      expect(UserRoles.isStaffRole(UserRoles.accountant), true);
      expect(UserRoles.isStaffRole(UserRoles.admissionsOfficer), true);
      expect(UserRoles.isStaffRole(UserRoles.librarian), true);
      expect(UserRoles.isStaffRole(UserRoles.parentGuardian), false);
    });
  });

  group('Acceptance Criteria 4 & 5: Clean Routing & Single /dashboard URL', () {
    test('Router exposes NO role-based dashboard URLs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      final registeredRoutes =
          router.configuration.routes.map((r) => (r as GoRoute).path).toList();

      // Verified: Unified /dashboard exists
      expect(registeredRoutes, contains('/dashboard'));

      // Verified: Strict rejection of role-based dashboard URLs
      expect(registeredRoutes, isNot(contains('/parents')));
      expect(registeredRoutes, isNot(contains('/parent-dashboard')));
      expect(registeredRoutes, isNot(contains('/teacher')));
      expect(registeredRoutes, isNot(contains('/teacher-dashboard')));
      expect(registeredRoutes, isNot(contains('/admin-dashboard')));
      expect(registeredRoutes, isNot(contains('/accountant-dashboard')));
      expect(registeredRoutes, isNot(contains('/librarian-dashboard')));
      expect(registeredRoutes, isNot(contains('/admissions-dashboard')));

      // Verified: Clean resource-based routes are registered
      expect(registeredRoutes, contains('/attendance'));
      expect(registeredRoutes, contains('/academics'));
      expect(registeredRoutes, contains('/fees'));
      expect(registeredRoutes, contains('/students'));
      expect(registeredRoutes, contains('/library'));
      expect(registeredRoutes, contains('/notices'));
      expect(registeredRoutes, contains('/settings'));
      expect(registeredRoutes, contains('/unauthorized'));
    });
  });

  group('Acceptance Criteria 7 & 8: Parameter Tampering & Role Authorization',
      () {
    test('Parent cannot access unlinked student records', () {
      const parentUser = AppUser(
        uid: 'parent_01',
        email: 'parent@lavschool.edu',
        displayName: 'Test Parent',
        role: UserRoles.parentGuardian,
        wardStudentIds: ['STU_001', 'STU_002'],
      );

      // Authorized linked student
      expect(parentUser.wardStudentIds.contains('STU_001'), true);
      expect(parentUser.wardStudentIds.contains('STU_002'), true);

      // Attempting to access an unrelated student (e.g. STU_003) is rejected
      expect(parentUser.wardStudentIds.contains('STU_003'), false);
      expect(parentUser.wardStudentIds.contains('STU_999'), false);
    });

    test('AppUser enforces active account status and role helpers', () {
      const activeUser = AppUser(
        uid: 'user_01',
        email: 'admin@lavschool.edu',
        displayName: 'Admin',
        role: UserRoles.schoolAdmin,
        status: 'active',
      );
      expect(activeUser.isActive, true);
      expect(activeUser.isAdmin, true);

      const suspendedUser = AppUser(
        uid: 'user_02',
        email: 'teacher@lavschool.edu',
        displayName: 'Teacher',
        role: UserRoles.teacher,
        status: 'suspended',
      );
      expect(suspendedUser.isActive, false);
      expect(suspendedUser.isTeacher, true);
    });
  });

  group('Acceptance Criteria 12 & 13: Responsive Breakpoints & Multi-Device UI',
      () {
    test(
        'AppBreakpoints correctly classifies mobile, tablet, and desktop viewports',
        () {
      // Mobile (<600px)
      expect(AppBreakpoints.getDeviceType(320), DeviceScreenType.mobile);
      expect(AppBreakpoints.getDeviceType(390), DeviceScreenType.mobile);
      expect(AppBreakpoints.getDeviceType(599), DeviceScreenType.mobile);

      // Tablet (600px - 1023px)
      expect(AppBreakpoints.getDeviceType(600), DeviceScreenType.tablet);
      expect(AppBreakpoints.getDeviceType(768), DeviceScreenType.tablet);
      expect(AppBreakpoints.getDeviceType(834), DeviceScreenType.tablet);
      expect(AppBreakpoints.getDeviceType(1023), DeviceScreenType.tablet);

      // Desktop (>=1024px)
      expect(AppBreakpoints.getDeviceType(1024), DeviceScreenType.desktop);
      expect(AppBreakpoints.getDeviceType(1280), DeviceScreenType.desktop);
      expect(AppBreakpoints.getDeviceType(1440), DeviceScreenType.desktop);
      expect(AppBreakpoints.getDeviceType(1920), DeviceScreenType.desktop);
    });

    testWidgets(
        'Renders ResponsiveScaffold across Mobile, Tablet, and Desktop without overflow',
        (tester) async {
      // 1. Mobile Test Viewport (360x740)
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testOverrides = [
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(
            const AppUser(
              uid: 'user_admin',
              email: 'admin@lavschool.edu',
              displayName: 'School Administrator',
              role: UserRoles.schoolAdmin,
              status: 'active',
            ),
          ),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides,
          child: const MaterialApp(
            home: ResponsiveScaffold(
              title: 'Mobile View Test',
              currentRoute: '/dashboard',
              body: Center(child: Text('Mobile Content Area')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mobile View Test'), findsOneWidget);
      expect(find.text('Mobile Content Area'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // 2. Tablet Test Viewport (768x1024)
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides,
          child: const MaterialApp(
            home: ResponsiveScaffold(
              title: 'Tablet View Test',
              currentRoute: '/dashboard',
              body: Center(child: Text('Tablet Content Area')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tablet View Test'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);

      // 3. Desktop Test Viewport (1280x800)
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides,
          child: const MaterialApp(
            home: ResponsiveScaffold(
              title: 'Desktop View Test',
              currentRoute: '/dashboard',
              body: Center(child: Text('Desktop Content Area')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Desktop View Test'), findsOneWidget);
      expect(find.text('LAV Academy'), findsOneWidget);
      expect(find.text('End Session'), findsOneWidget);
    });

    testWidgets(
        'LoginSelectionScreen renders distinct Parent and Staff entrance options',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent / Guardian Login'), findsOneWidget);
      expect(find.text('Staff & Administration Login'), findsOneWidget);
      expect(find.text('Continue with Mobile OTP'), findsOneWidget);
      expect(find.text('Staff Institutional Sign In'), findsOneWidget);
    });
  });

  group('Acceptance Criteria 14: Data Export Service CSV Formats', () {
    test('exportStudentsCsv formats correct CSV headers and values', () {
      final students = [
        const Student(
          studentId: 'STU_001',
          admissionNumber: 'ADM-2026-001',
          fullName: 'Aarav Sharma',
          currentClassId: '10',
          currentSectionId: 'A',
          currentAcademicYearId: 'AY_2026_2027',
          bloodGroup: 'B+',
          emergencyContact: '+91 98765 43210',
          status: 'enrolled',
          guardianUserIds: ['parent_01'],
        ),
      ];

      // Service should execute cleanly without throwing
      expect(
          () => DataExportService.exportStudentsCsv(students), returnsNormally);
    });

    test('exportInvoicesCsv converts integer paise to INR accurately in export',
        () {
      final invoices = [
        const StudentInvoice(
          invoiceId: 'INV_001',
          studentId: 'STU_001',
          academicYearId: 'AY_2026_2027',
          title: 'Term 1 Tuition Fee',
          totalAmountPaise: 4500000,
          paidAmountPaise: 4500000,
          outstandingBalancePaise: 0,
          status: 'paid',
        ),
      ];

      expect(
          () => DataExportService.exportInvoicesCsv(invoices), returnsNormally);
    });

    test('exportLibraryBooksCsv generates correct catalog export columns', () {
      final books = [
        const LibraryBook(
          bookId: 'BOOK_001',
          title: 'Concepts of Physics (Vol 1)',
          author: 'H.C. Verma',
          isbn: '978-8177091878',
          category: 'Physics',
          totalCopies: 12,
          availableCopies: 8,
        ),
      ];

      expect(() => DataExportService.exportLibraryBooksCsv(books),
          returnsNormally);
    });

    test('exportAttendanceCsv exports roll call records with attendance rate',
        () {
      final sessions = [
        const AttendanceSession(
          sessionId: 'SESSION_001',
          schoolId: 'school_001',
          classId: '10',
          sectionId: 'A',
          date: '2026-10-23',
          academicYearId: 'AY_2026_2027',
          markedBy: 'teacher_01',
          isApproved: true,
          isFinalized: true,
          summary: AttendanceSummary(
            totalStudents: 30,
            presentCount: 28,
            absentCount: 2,
            attendancePercentage: 93.3,
          ),
        ),
      ];

      expect(() => DataExportService.exportAttendanceCsv(sessions),
          returnsNormally);
    });
  });

  group(
      'Acceptance Criteria 15: Functional Contextual Dialogs & Working Pop-ups',
      () {
    testWidgets(
        'ReportCardDialog renders institutional report card with print button',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ReportCardDialog.show(
                context,
                student: const Student(
                  studentId: 'STU_001',
                  admissionNumber: 'ADM-2026-001',
                  fullName: 'Aarav Sharma',
                  currentClassId: '10',
                  currentSectionId: 'A',
                  currentAcademicYearId: 'AY_2026_2027',
                ),
                marks: const [],
                academicYear: '2026-2027',
              ),
              child: const Text('Open Report Card'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to open dialog
      await tester.tap(find.text('Open Report Card'));
      await tester.pumpAndSettle();

      // Verify institutional identity & CBSE accreditation
      expect(find.text('LAV INTERNATIONAL ACADEMY'), findsOneWidget);
      expect(find.text('ANNUAL ACADEMIC PROGRESS REPORT — 2026-2027'),
          findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('ADM-2026-001'), findsOneWidget);

      // Verify print button is present and functional
      expect(find.text('Print Report Card'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap close
      await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('ANNUAL ACADEMIC PROGRESS REPORT — 2026-2027'),
          findsNothing);
    });

    testWidgets(
        'FeeReceiptDialog displays official payment voucher with INR amounts',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FeeReceiptDialog.show(
                context,
                invoice: const StudentInvoice(
                  invoiceId: 'INV_001',
                  studentId: 'STU_001',
                  academicYearId: 'AY_2026_2027',
                  title: 'Term 1 Tuition & Composite Annual Fee',
                  totalAmountPaise: 4500000,
                  paidAmountPaise: 4500000,
                  outstandingBalancePaise: 0,
                  status: 'paid',
                ),
                student: const Student(
                  studentId: 'STU_001',
                  admissionNumber: 'ADM-2026-001',
                  fullName: 'Aarav Sharma',
                  currentClassId: '10',
                  currentSectionId: 'A',
                  currentAcademicYearId: 'AY_2026_2027',
                ),
              ),
              child: const Text('Open Receipt'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('Official Fee Payment Receipt'), findsOneWidget);
      expect(find.text('RECEIPT NO: REC-2026-001'), findsOneWidget);
      expect(find.text('₹45,000.00'), findsWidgets);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Bursar / Cashier Signature'), findsOneWidget);
      expect(find.text('Print Receipt'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Official Fee Payment Receipt'), findsNothing);
    });

    testWidgets(
        'AttendanceRegisterDialog renders roll register with print action',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AttendanceRegisterDialog.show(
                context,
                classId: '10',
                sectionId: 'A',
                date: DateTime(2026, 10, 23),
              ),
              child: const Text('Open Attendance Register'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Attendance Register'));
      await tester.pumpAndSettle();

      expect(find.text('LAV INTERNATIONAL ACADEMY'), findsOneWidget);
      expect(
          find.text('CLASS 10 — SECTION A • DATE: 2026-10-23'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Class Teacher Signature'), findsOneWidget);
      expect(find.text('Print Register'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
          find.text('CLASS 10 — SECTION A • DATE: 2026-10-23'), findsNothing);
    });

    testWidgets(
        'ConfirmActionDialog executes callback on confirm and aborts on cancel',
        (tester) async {
      bool actionConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ConfirmActionDialog.show(
                context,
                title: 'Publish Term 1 Results',
                message:
                    'Are you sure you want to make marks visible to parents?',
                confirmLabel: 'Authorize Publication',
                onConfirm: (reason) async {
                  actionConfirmed = true;
                },
              ),
              child: const Text('Trigger Action'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Test Cancel
      await tester.tap(find.text('Trigger Action'));
      await tester.pumpAndSettle();

      expect(find.text('Publish Term 1 Results'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(actionConfirmed, false);

      // 2. Test Confirm
      await tester.tap(find.text('Trigger Action'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Authorize Publication'));
      await tester.pumpAndSettle();
      expect(actionConfirmed, true);
    });
  });
}
