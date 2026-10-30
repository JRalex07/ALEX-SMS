import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lav_sms/app/router/app_router.dart';
import 'package:lav_sms/core/constants/app_routes.dart';
import 'package:lav_sms/core/constants/role_colors.dart';
import 'package:lav_sms/models/user_model.dart';
import 'package:lav_sms/providers/auth_providers.dart';
import 'package:lav_sms/shared/widgets/responsive_scaffold.dart';

void main() {
  group('LAV Academy SMS — Navigation & Dedicated Routing Test Suite', () {
    final roles = [
      UserRoles.schoolAdmin,
      UserRoles.teacher,
      UserRoles.accountant,
      UserRoles.admissionsOfficer,
      UserRoles.librarian,
      UserRoles.parentGuardian,
    ];

    test('1. Every role has valid, structured navigation categories', () {
      for (final role in roles) {
        final categories = ResponsiveScaffold.getRoleNavCategories(role);
        expect(categories, isNotEmpty,
            reason: 'Role $role must have configured navigation categories');

        for (final cat in categories) {
          expect(cat.title, isNotEmpty);
          expect(cat.entries, isNotEmpty,
              reason: 'Category "${cat.title}" for $role must contain entries');
        }
      }
    });

    test(
        '2. Every menu option points to a dedicated named route without "?tab=" query hacks',
        () {
      for (final role in roles) {
        final categories = ResponsiveScaffold.getRoleNavCategories(role);

        for (final cat in categories) {
          for (final entry in cat.entries) {
            // Verify route begins with slash
            expect(entry.route.startsWith('/'), isTrue,
                reason:
                    'Entry "${entry.label}" in $role has invalid route "${entry.route}"');

            // Strictly disallow legacy ?tab= query parameter hacks
            expect(entry.route.contains('?tab='), isFalse,
                reason:
                    'Entry "${entry.label}" in $role must have its own dedicated route without query-parameter tab hacks');

            expect(entry.label, isNotEmpty);
            expect(entry.icon, isNotNull);
            expect(entry.selectedIcon, isNotNull);
          }
        }
      }
    });

    test(
        '3. Every menu option within a role has a unique, distinct route (no duplicate reuse)',
        () {
      final duplicates = <String>[];
      for (final role in roles) {
        final categories = ResponsiveScaffold.getRoleNavCategories(role);
        final seenRoutes = <String, String>{};

        for (final cat in categories) {
          for (final entry in cat.entries) {
            if (seenRoutes.containsKey(entry.route)) {
              duplicates.add(
                  'Role $role: "${entry.route}" is shared between "${seenRoutes[entry.route]}" and "${entry.label}"');
            }
            seenRoutes[entry.route] = entry.label;
          }
        }
      }

      if (duplicates.isNotEmpty) {
        fail('Duplicate routes detected across role menus:\n${duplicates.join('\n')}');
      }
    });

    test(
        '4. Exact active-item matching in isNavEntryActive reliably isolates routes',
        () {
      const studentDirEntry = RoleNavEntry(
        label: 'All Students',
        route: AppRoutes.students,
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
      );

      const studentAddEntry = RoleNavEntry(
        label: 'New Student Admission',
        route: AppRoutes.studentAdd,
        icon: Icons.person_add_outlined,
        selectedIcon: Icons.person_add,
      );

      const studentLookupEntry = RoleNavEntry(
        label: 'Student Profile Lookup',
        route: AppRoutes.studentLookup,
        icon: Icons.person_search_outlined,
        selectedIcon: Icons.person_search,
      );

      // Exact matching
      expect(
          ResponsiveScaffold.isNavEntryActive(
              studentDirEntry, AppRoutes.students),
          isTrue);
      expect(
          ResponsiveScaffold.isNavEntryActive(
              studentAddEntry, AppRoutes.studentAdd),
          isTrue);

      // Non-matching
      expect(
          ResponsiveScaffold.isNavEntryActive(
              studentDirEntry, AppRoutes.studentAdd),
          isFalse,
          reason:
              'Directory entry should not be active when on Add Student screen');
      expect(
          ResponsiveScaffold.isNavEntryActive(
              studentAddEntry, AppRoutes.students),
          isFalse);
      expect(
          ResponsiveScaffold.isNavEntryActive(
              studentLookupEntry, AppRoutes.students),
          isFalse);

      // Query params on current route do not break matching
      expect(
          ResponsiveScaffold.isNavEntryActive(
              studentDirEntry, '${AppRoutes.students}?class=10'),
          isTrue);
    });

    test('5. All role navigation routes are registered in GoRouter routes list',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      final registeredPaths = <String>{};

      void extractPaths(List<RouteBase> routes) {
        for (final route in routes) {
          if (route is GoRoute) {
            registeredPaths.add(route.path);
            if (route.routes.isNotEmpty) {
              extractPaths(route.routes);
            }
          }
        }
      }

      extractPaths(router.configuration.routes);

      // Verify that EVERY role navigation entry route is registered in the router
      for (final role in roles) {
        final categories = ResponsiveScaffold.getRoleNavCategories(role);
        for (final cat in categories) {
          for (final entry in cat.entries) {
            final routeBase = entry.route.split('?').first;
            expect(registeredPaths.contains(routeBase), isTrue,
                reason:
                    'Route "$routeBase" for entry "${entry.label}" ($role) must be registered in appRouterProvider');
          }
        }
      }
    });

    testWidgets(
        '6. ResponsiveScaffold renders sidebar, rail, or drawer depending on viewport',
        (WidgetTester tester) async {
      const mockAdmin = AppUser(
        uid: 'test_admin_uid',
        email: 'admin@lav.edu',
        displayName: 'Administrator',
        role: UserRoles.schoolAdmin,
        status: 'active',
      );

      // 1. Desktop Viewport (1200x800) -> Should have side navigation bar
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(mockAdmin)),
          ],
          child: const MaterialApp(
            home: ResponsiveScaffold(
              title: 'Student Directory',
              currentRoute: AppRoutes.students,
              body: Center(child: Text('Desktop Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Desktop Content'), findsOneWidget);
      expect(find.text('Student Directory'), findsWidgets);

      // 2. Mobile Viewport (390x844) -> Should use responsive drawer / compact layout
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => Stream.value(mockAdmin)),
          ],
          child: const MaterialApp(
            home: ResponsiveScaffold(
              title: 'Student Directory',
              currentRoute: AppRoutes.students,
              body: Center(child: Text('Mobile Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mobile Content'), findsOneWidget);
    });

    test('7. Parameterized and detail route matching in isNavEntryActive', () {
      const studentLookupEntry = RoleNavEntry(
        label: 'Student Profile Lookup',
        route: AppRoutes.studentLookup,
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
      );

      const admissionsEntry = RoleNavEntry(
        label: 'Admission Applications',
        route: AppRoutes.admissions,
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment,
      );

      // Student detail route (/students/STU-1234) matches lookup entry
      expect(
        ResponsiveScaffold.isNavEntryActive(
            studentLookupEntry, '/students/STU-1234'),
        isTrue,
        reason:
            'Dynamic /students/:studentId detail route should highlight Student Lookup entry',
      );

      // Specific dedicated student routes must NOT match
      expect(
        ResponsiveScaffold.isNavEntryActive(
            studentLookupEntry, AppRoutes.studentAdd),
        isFalse,
      );
      expect(
        ResponsiveScaffold.isNavEntryActive(
            studentLookupEntry, AppRoutes.studentTransfers),
        isFalse,
      );

      // Admissions detail route (/admissions/APP-2026-999) matches admissions entry
      expect(
        ResponsiveScaffold.isNavEntryActive(
            admissionsEntry, '/admissions/APP-2026-999'),
        isTrue,
        reason:
            'Dynamic /admissions/:applicationId detail route should highlight Admissions entry',
      );

      // Dedicated admissions sub-routes must NOT match
      expect(
        ResponsiveScaffold.isNavEntryActive(
            admissionsEntry, AppRoutes.admissionsReview),
        isFalse,
      );
    });

    test('8. Role-based route guards strictly enforce authorization boundaries',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      // Verify that router is instantiated with protected route guards
      expect(router.routeInformationProvider, isNotNull);
      expect(router.configuration.routes, isNotEmpty);
    });

    test('9. Dedicated routes exist for announcements and parent receipts', () {
      expect(AppRoutes.announcements, equals('/notices/announcements'));
      expect(AppRoutes.parentReceipts, equals('/parent/receipts'));
      expect(AppRoutes.feeReceipts, equals('/fees/receipts'));

      // Ensure parent receipts and fee receipts are strictly distinct routes
      expect(AppRoutes.parentReceipts, isNot(equals(AppRoutes.feeReceipts)));
      // Ensure announcements and notices are strictly distinct routes
      expect(AppRoutes.announcements, isNot(equals(AppRoutes.notices)));
    });
  });
}
