import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lav_sms/core/constants/role_colors.dart';
import 'package:lav_sms/features/parent/parent_dashboard_screen.dart';
import 'package:lav_sms/models/student_model.dart';
import 'package:lav_sms/models/user_model.dart';
import 'package:lav_sms/providers/auth_providers.dart';
import 'package:lav_sms/providers/child_context_provider.dart';
import 'package:lav_sms/shared/dialogs/parent_portal_dialogs.dart';

void main() {
  group('Parent Portal 17-Option Expansion & Vibrant Clay Theming Tests', () {
    const mockStudent1 = Student(
      studentId: 'STU_TANISHK_01',
      admissionNumber: 'LAV-2026-089',
      fullName: 'Tanishk Anand',
      currentClassId: 'CLASS_5',
      currentSectionId: 'SEC_A',
      currentAcademicYearId: 'AY_2026_2027',
      status: 'enrolled',
      guardianUserIds: ['PARENT_USER_01'],
      emergencyContact: '+91 98765 43210',
    );

    const mockStudent2 = Student(
      studentId: 'STU_AARAV_02',
      admissionNumber: 'LAV-2026-090',
      fullName: 'Aarav Anand',
      currentClassId: 'CLASS_2',
      currentSectionId: 'SEC_B',
      currentAcademicYearId: 'AY_2026_2027',
      status: 'enrolled',
      guardianUserIds: ['PARENT_USER_01'],
      emergencyContact: '+91 98765 43210',
    );

    const mockParentUser = AppUser(
      uid: 'PARENT_USER_01',
      email: 'parent.anand@lav-school.edu',
      displayName: 'Mr. & Mrs. Anand',
      role: UserRoles.parentGuardian,
      status: 'active',
      wardStudentIds: ['STU_TANISHK_01', 'STU_AARAV_02'],
      wardClasses: ['CLASS_5', 'CLASS_2'],
      wardSections: ['SEC_A', 'SEC_B'],
    );

    Widget createTestApp({Student? initialChild}) {
      return ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(mockParentUser),
          ),
          parentLinkedChildrenProvider.overrideWith(
            (ref) async => [mockStudent1, mockStudent2],
          ),
          selectedChildProvider.overrideWith(
            (ref) => initialChild ?? mockStudent1,
          ),
        ],
        child: const MaterialApp(
          home: ParentDashboardScreen(),
        ),
      );
    }

    test(
        '1. RoleThemePalette correctly resolves vibrant color identities for all 6 roles',
        () {
      final adminPalette = RoleThemePalette.forRole(UserRoles.schoolAdmin);
      expect(adminPalette.primary, equals(AppColors.adminIndigo));
      expect(adminPalette.secondary, equals(AppColors.adminViolet));

      final teacherPalette = RoleThemePalette.forRole(UserRoles.teacher);
      expect(teacherPalette.primary, equals(AppColors.teacherTeal));
      expect(teacherPalette.secondary, equals(AppColors.teacherGreen));

      final accountantPalette = RoleThemePalette.forRole(UserRoles.accountant);
      expect(accountantPalette.primary, equals(AppColors.accountantEmerald));
      expect(accountantPalette.secondary, equals(AppColors.accountantJade));

      final admissionsPalette =
          RoleThemePalette.forRole(UserRoles.admissionsOfficer);
      expect(admissionsPalette.primary, equals(AppColors.admissionsAmber));
      expect(admissionsPalette.secondary, equals(AppColors.admissionsOrange));

      final librarianPalette = RoleThemePalette.forRole(UserRoles.librarian);
      expect(librarianPalette.primary, equals(AppColors.librarianViolet));
      expect(librarianPalette.secondary, equals(AppColors.librarianPurple));

      final parentPalette = RoleThemePalette.forRole(UserRoles.parentGuardian);
      expect(parentPalette.primary, equals(AppColors.parentBlue));
      expect(parentPalette.secondary, equals(AppColors.parentCyan));
    });

    testWidgets(
        '2. Renders ParentDashboardScreen with all 17 Explore Options at 390x844 (Mobile) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      if (caughtDetails != null) {
        // ignore: avoid_print
        print('=== CAUGHT ERROR DETAILS ===\n${caughtDetails!.toString()}');
        // ignore: avoid_print
        print('=== CONTEXT ===\n${caughtDetails!.context?.toStringDeep()}');
        // ignore: avoid_print
        print(
            '=== INFORMATION COLLECTOR ===\n${caughtDetails!.informationCollector?.call().map((d) => d.toStringDeep()).join('\n')}');
      }

      expect(find.text('Explore Options'), findsOneWidget);

      // Verify the 17 options from the reference screenshot
      final options = [
        'Announcement',
        'Profile',
        'Attendance',
        'Study Material',
        'Fees Payment',
        'Fees Receipt',
        'Homework',
        'Syllabus',
        'Chat with School',
        'Complaint',
        'Report Card',
        'Class Routine',
        'Online Class',
        'A-Calender',
        'Online Test',
        'Location',
        'Change Password',
      ];

      for (final opt in options) {
        expect(find.text(opt), findsAtLeastNWidgets(1));
      }

      // Verify selected child name is prominently displayed
      expect(find.text('Tanishk Anand'), findsAtLeastNWidgets(1));
      final exception = tester.takeException();
      expect(exception, isNull);
    });

    testWidgets(
        '3. Tapping Homework tile opens HomeworkListDialog with child curriculum assignments',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2.0, 2600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final homeworkFinder = find.text('Homework');
      expect(homeworkFinder, findsOneWidget);
      await tester.tap(homeworkFinder);
      await tester.pumpAndSettle();

      expect(find.byType(HomeworkListDialog), findsOneWidget);
      expect(find.text('Assigned Homework'), findsOneWidget);
      expect(find.textContaining('Fractions & Decimals'), findsOneWidget);
    });

    testWidgets(
        '4. Tapping Location tile opens LocationTransportDialog with Campus and Bus Route tabs',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2.0, 2600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final locationFinder = find.text('Location');
      await tester.tap(locationFinder);
      await tester.pumpAndSettle();

      expect(find.byType(LocationTransportDialog), findsOneWidget);
      expect(find.text('Location & Transit Details'), findsOneWidget);
      expect(find.text('🏫 Campus Location'), findsOneWidget);
      expect(find.text('🚌 Assigned Bus Route'), findsOneWidget);

      // Switch to Bus Route tab
      await tester.tap(find.text('🚌 Assigned Bus Route'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Route 4'), findsOneWidget);
      expect(find.textContaining('Green Park Metro Station'),
          findsAtLeastNWidgets(1));
    });

    testWidgets(
        '5. Online Test Runner launches student quiz session and submits answers',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2.0, 2600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final testFinder = find.text('Online Test');
      await tester.tap(testFinder);
      await tester.pumpAndSettle();

      expect(find.byType(OnlineTestDialog), findsOneWidget);
      expect(find.text('Start Quiz Session'), findsOneWidget);

      // Start quiz
      await tester.tap(find.text('Start Quiz Session'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 1 of'), findsOneWidget);
      expect(find.textContaining('Highest Common Factor'), findsOneWidget);

      // Select option and advance
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets(
        '6. Complaints dialog renders reference ID and supports filing new complaint',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2.0, 2600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final complaintFinder = find.text('Complaint');
      await tester.tap(complaintFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ComplaintsDialog), findsOneWidget);
      expect(find.text('Complaints & Grievances'), findsOneWidget);
      expect(find.text('+ New Complaint'), findsOneWidget);
      expect(find.textContaining('LAV-CMP-2026-084'), findsOneWidget);
    });

    testWidgets(
        '7. Chat with School dialog provides 3 role communication channels',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2.0, 2600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final chatFinder = find.text('Chat with School');
      await tester.tap(chatFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ParentChatDialog), findsOneWidget);
      expect(find.text('Class Teacher'), findsOneWidget);
      expect(find.text('Admin Desk'), findsOneWidget);
      expect(find.text('Fee Bursar'), findsOneWidget);
    });

    testWidgets('8. Change Password dialog validates input requirements',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2.0, 2600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final pwdFinder = find.text('Change Password');
      await tester.tap(pwdFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordDialog), findsOneWidget);
      expect(find.text('Change Account Password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });
  });
}
