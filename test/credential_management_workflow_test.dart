import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lav_sms/features/auth/change_phone_screen.dart';
import 'package:lav_sms/features/auth/change_password_screen.dart';
import 'package:lav_sms/features/admin/admin_user_credentials_screen.dart';
import 'package:lav_sms/features/resources/settings_screen.dart';
import 'package:lav_sms/models/user_model.dart';
import 'package:lav_sms/providers/auth_providers.dart';
import 'package:lav_sms/providers/feature_providers.dart';

void main() {
  group('LAV Academy Role-Based Credential Management Test Suite', () {
    testWidgets(
        '1. SettingsScreen renders Change Phone Number for Parent and no email-edit field',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const parentUser = AppUser(
        uid: 'parent_uid_001',
        email: 'parent@example.com',
        phoneNumber: '+919876543210',
        displayName: 'Aarav Guardian',
        role: 'parent_guardian',
        status: 'active',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(parentUser)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that parent sees Change Phone Number
      expect(find.text('Change Registered Phone Number'), findsOneWidget);
      // Verify that parent does NOT see admin email management
      expect(find.text('Manage User Credentials & Emails'), findsNothing);
    });

    testWidgets(
        '2. SettingsScreen renders Change Password for Staff and no email-edit field',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const teacherUser = AppUser(
        uid: 'teacher_uid_001',
        email: 'teacher.meena@lavacademy.edu',
        displayName: 'Meena Iyer',
        role: 'teacher',
        status: 'active',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(teacherUser)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that staff sees Change Password
      expect(find.text('Change Password'), findsOneWidget);
      // Verify that staff does NOT see admin email management or phone change
      expect(find.text('Manage User Credentials & Emails'), findsNothing);
      expect(find.text('Change Registered Phone Number'), findsNothing);
    });

    testWidgets(
        '3. SettingsScreen renders both Change Password and Manage User Credentials for School Admin',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const adminUser = AppUser(
        uid: 'admin_uid_001',
        email: 'admin.principal@lavacademy.edu',
        displayName: 'Dr. Anita Roy',
        role: 'school_admin',
        status: 'active',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(adminUser)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Manage User Credentials & Emails'), findsOneWidget);
    });

    testWidgets(
        '4. ChangePhoneScreen displays masked phone, OTP flow, and preserves parent account context',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const parentUser = AppUser(
        uid: 'parent_uid_001',
        email: 'parent@example.com',
        phoneNumber: '+919876543210',
        displayName: 'Aarav Guardian',
        role: 'parent_guardian',
        status: 'active',
        wardStudentIds: ['STU_001'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(parentUser)),
          ],
          child: const MaterialApp(
            home: ChangePhoneScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Registered Phone Number'), findsOneWidget);
      expect(find.text('Current Registered Phone'), findsOneWidget);
      // Masked check: last 4 digits visible
      expect(find.textContaining('3210'), findsOneWidget);
      expect(find.text('Send Verification OTP'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
    });

    testWidgets(
        '5. ChangePasswordScreen displays current/new password inputs, locked email indicator, and zero email edits',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const accountantUser = AppUser(
        uid: 'accountant_uid_001',
        email: 'accountant@lavacademy.edu',
        displayName: 'Bursar Rajesh',
        role: 'accountant',
        status: 'active',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(accountantUser)),
          ],
          child: const MaterialApp(
            home: ChangePasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Account Password'), findsOneWidget);
      expect(find.text('Official Institutional Email (Read-Only)'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Save New Password'), findsOneWidget);
    });

    testWidgets(
        '6. AdminUserCredentialsScreen renders searchable directory and authorized email initiation',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const adminUser = AppUser(
        uid: 'admin_uid_001',
        email: 'admin.principal@lavacademy.edu',
        displayName: 'Dr. Anita Roy',
        role: 'school_admin',
        status: 'active',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(adminUser)),
            allStaffUsersStreamProvider
                .overrideWith((ref) => Stream.value([adminUser])),
          ],
          child: const MaterialApp(
            home: AdminUserCredentialsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Administrative Credential & Email Management'), findsOneWidget);
      expect(find.text('Principal & School Administrator Authority'), findsOneWidget);
      expect(find.text('Select Institutional Account'), findsOneWidget);
      expect(find.text('User Credential Detail'), findsOneWidget);
    });

    testWidgets(
        '7. ChangePhoneScreen rejects identical phone number and displays feedback dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const parentUser = AppUser(
        uid: 'parent_uid_001',
        email: 'parent@example.com',
        phoneNumber: '+919876543210',
        displayName: 'Aarav Guardian',
        role: 'parent_guardian',
        status: 'active',
        wardStudentIds: ['STU_001'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(parentUser)),
          ],
          child: const MaterialApp(
            home: ChangePhoneScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter the exact same 10-digit number
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, '9876543210');
      await tester.pumpAndSettle();

      // Verify inline error warning appears
      expect(
          find.textContaining(
              'This is already your registered phone number'),
          findsAtLeastNWidgets(1));

      // Attempt to tap Send Verification OTP
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      // Verify Number Unchanged modal dialog appears
      expect(find.text('Number Unchanged'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Number Unchanged'), findsNothing);
    });

    testWidgets(
        '8. ChangePasswordScreen triggers validation and feedback dialog on missing fields',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const teacherUser = AppUser(
        uid: 'teacher_uid_001',
        email: 'teacher@lavacademy.edu',
        displayName: 'Meena Iyer',
        role: 'teacher',
        status: 'active',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(teacherUser)),
          ],
          child: const MaterialApp(
            home: ChangePasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save New Password with empty fields
      await tester.tap(find.text('Save New Password'));
      await tester.pumpAndSettle();

      // Verify feedback dialog appears
      expect(find.text('Input Required'), findsOneWidget);
      expect(
          find.textContaining('Please enter your current password.'),
          findsAtLeastNWidgets(1));

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Input Required'), findsNothing);
    });

    testWidgets(
        '9. Desktop viewport 1276x670 renders ResponsiveScaffold with zero RenderBox layout assertions',
        (tester) async {
      tester.view.physicalSize = const Size(1276, 670);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const parentUser = AppUser(
        uid: 'parent_uid_001',
        email: 'parent@example.com',
        phoneNumber: '+919876543210',
        displayName: 'Aarav Guardian',
        role: 'parent_guardian',
        status: 'active',
        wardStudentIds: ['STU_001'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(parentUser)),
          ],
          child: const MaterialApp(
            home: ChangePhoneScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect screen content rendered and hit-testable
      expect(find.text('Change Registered Phone Number'), findsOneWidget);
      expect(find.text('Send Verification OTP'), findsOneWidget);

      // Tap is possible without RenderBox was not laid out exception
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();
    });
  });
}
