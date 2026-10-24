import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lav_sms/core/constants/breakpoints.dart';
import 'package:lav_sms/core/constants/role_colors.dart';
import 'package:lav_sms/features/auth/native_app_login_screen.dart';
import 'package:lav_sms/features/auth/web_login_screen.dart';
import 'package:lav_sms/models/user_model.dart';
import 'package:lav_sms/providers/auth_providers.dart';
import 'package:lav_sms/shared/clay/clay.dart';
import 'package:lav_sms/shared/widgets/responsive_scaffold.dart';

void main() {
  const testAdminUser = AppUser(
    uid: 'admin_test_001',
    email: 'admin@lavacademy.edu',
    displayName: 'System Administrator',
    role: UserRoles.schoolAdmin,
    status: 'active',
  );

  const testParentUser = AppUser(
    uid: 'parent_test_001',
    email: 'parent@gmail.com',
    displayName: 'Aditi Sharma',
    role: UserRoles.parentGuardian,
    status: 'active',
    wardStudentIds: ['STU_001'],
    wardClasses: ['10-A'],
  );

  final adminOverrides = [
    currentUserProfileProvider.overrideWith(
      (ref) => Stream.value(testAdminUser),
    ),
  ];

  final parentOverrides = [
    currentUserProfileProvider.overrideWith(
      (ref) => Stream.value(testParentUser),
    ),
  ];

  group('Requirement 9: Multi-Viewport Responsive Tests (All 8 Viewports)', () {
    const viewports = <String, Size>{
      '360x800 (Compact Phone)': Size(360, 800),
      '390x844 (Typical Phone)': Size(390, 844),
      '600x960 (Compact Tablet Boundary)': Size(600, 960),
      '768x1024 (Tablet)': Size(768, 1024),
      '1024x768 (Small Desktop / Landscape Tablet)': Size(1024, 768),
      '1280x800 (Laptop)': Size(1280, 800),
      '1440x900 (Desktop)': Size(1440, 900),
      '1920x1080 (Wide Desktop)': Size(1920, 1080),
    };

    for (final entry in viewports.entries) {
      testWidgets(
          'Renders ResponsiveScaffold at ${entry.key} with zero overflow',
          (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: adminOverrides,
            child: MaterialApp(
              theme: ThemeData(
                scaffoldBackgroundColor: ClayTheme.clayCanvas,
              ),
              home: ResponsiveScaffold(
                title: 'Test Portal',
                currentRoute: '/dashboard',
                body: AdaptiveContainer(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const ClayCard(
                        title: 'Operational Header',
                        subtitle: 'Multi-device verified clay card',
                        icon: Icons.dashboard_outlined,
                        child: Text('Content inside clay card'),
                      ),
                      const SizedBox(height: 16),
                      ResponsiveBuilder(
                        compact: (ctx) => const Column(
                          children: [
                            ClayStatCard(
                              title: 'Metric 1',
                              value: '142',
                              subtitle: 'Active records',
                              icon: Icons.analytics_outlined,
                            ),
                            SizedBox(height: 12),
                            ClayStatCard(
                              title: 'Metric 2',
                              value: '₹84,000',
                              subtitle: 'Collected fees',
                              icon: Icons.payments_outlined,
                            ),
                          ],
                        ),
                        wide: (ctx) => const Row(
                          children: [
                            Expanded(
                              child: ClayStatCard(
                                title: 'Metric 1',
                                value: '142',
                                subtitle: 'Active records',
                                icon: Icons.analytics_outlined,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ClayStatCard(
                                title: 'Metric 2',
                                value: '₹84,000',
                                subtitle: 'Collected fees',
                                icon: Icons.payments_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify no exception was thrown and titles rendered
        expect(find.text('Test Portal'), findsOneWidget);
        expect(find.text('Operational Header'), findsOneWidget);
        expect(find.text('Metric 1'), findsOneWidget);

        final width = entry.value.width;
        if (width < 600) {
          // Compact phone: NavigationBar or Drawer is used
          expect(find.byType(NavigationBar), findsOneWidget);
        } else if (width < 1024) {
          // Medium tablet: NavigationRail is used
          expect(find.byType(NavigationRail), findsOneWidget);
        } else {
          // Wide / Extra-wide desktop: Persistent Sidebar with LAV Academy branding
          expect(find.text('LAV Academy'), findsOneWidget);
          expect(find.text('End Session'), findsOneWidget);
        }
      });
    }

    testWidgets('Renders accessible UI with increased text scaling (1.5x)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: parentOverrides,
          child: MaterialApp(
            theme: ThemeData(
              scaffoldBackgroundColor: ClayTheme.clayCanvas,
            ),
            home: const MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(1.5),
                size: Size(390, 844),
              ),
              child: ResponsiveScaffold(
                title: 'Parent Portal',
                currentRoute: '/dashboard',
                body: ClayCard(
                  title: 'Accessible Card',
                  subtitle: 'Checking scale tolerance',
                  icon: Icons.accessibility_new,
                  child: Text('Card with 1.5x scaled typography'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent Portal'), findsOneWidget);
      expect(find.text('Accessible Card'), findsOneWidget);
      expect(find.text('Card with 1.5x scaled typography'), findsOneWidget);
    });
  });

  group('Claymorphism Reusable Component Suite Verification', () {
    testWidgets('ClayButton renders tactile states and triggers callback',
        (tester) async {
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClayButton(
                label: 'Save Changes',
                icon: Icons.check,
                onPressed: () => clicked = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
    });

    testWidgets('ClayTextField renders recessed styling and accepts input',
        (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: ClayTextField(
                controller: controller,
                label: 'Student Name',
                hintText: 'Enter full name',
                prefixIcon: Icons.person_outline,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Name'), findsOneWidget);
      expect(find.text('Enter full name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Eleanor Vance');
      await tester.pumpAndSettle();

      expect(controller.text, 'Eleanor Vance');
    });

    testWidgets('ClaySegmentedControl switches active segment', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: ClaySegmentedControl(
                    selectedIndex: activeIndex,
                    onSelectedIndexChanged: (idx) =>
                        setState(() => activeIndex = idx),
                    items: const [
                      ClaySegmentItem(
                          label: 'Weekly', icon: Icons.calendar_view_week),
                      ClaySegmentItem(
                          label: 'Monthly', icon: Icons.calendar_month),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      expect(activeIndex, 1);
    });

    testWidgets('AdaptiveDataView renders cards on mobile and table on desktop',
        (tester) async {
      final sampleItems = ['Alice Smith', 'Bob Johnson'];

      // Mobile check (<768px): Expects mobile cards
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveDataView<String>(
              items: sampleItems,
              columns: [
                AdaptiveColumn<String>(
                  title: 'Name',
                  cellBuilder: (item) => Text(item),
                ),
              ],
              mobileCardBuilder: (ctx, item) => ClayCard(
                depth: ClayDepth.low,
                child: Text('Mobile: $item'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mobile: Alice Smith'), findsOneWidget);
      expect(find.text('Mobile: Bob Johnson'), findsOneWidget);

      // Desktop check (1280px): Expects table rows and headers
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveDataView<String>(
              items: sampleItems,
              columns: [
                AdaptiveColumn<String>(
                  title: 'Student Full Name',
                  cellBuilder: (item) => Text('Row: $item'),
                ),
              ],
              mobileCardBuilder: (ctx, item) => ClayCard(
                depth: ClayDepth.low,
                child: Text('Mobile: $item'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STUDENT FULL NAME'), findsOneWidget);
      expect(find.text('Row: Alice Smith'), findsOneWidget);
      expect(find.text('Row: Bob Johnson'), findsOneWidget);
    });
  });

  group('Platform-Separated Login Experiences Suite', () {
    testWidgets(
        'WebLoginScreen renders 2-column wide layout on desktop (1440x900) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WebLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('LAV ACADEMY'), findsWidgets);
      expect(find.text('Unified Institutional Workspace'), findsOneWidget);
      expect(find.text('Portal Sign In'), findsOneWidget);
      expect(find.text('Staff & Faculty'), findsOneWidget);
      expect(find.text('Parent / Guardian'), findsOneWidget);
    });

    testWidgets(
        'WebLoginScreen reorganizes into single-column layout on mobile browser (390x844) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WebLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Web Portal • Academic Year 2026-2027'), findsOneWidget);
      expect(find.text('Portal Sign In'), findsOneWidget);
    });

    testWidgets(
        'NativeAppLoginScreen renders compact one-handed layout at 360x800 with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NativeAppLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('LAV ACADEMY'), findsOneWidget);
      expect(find.text('Parent Portal'), findsOneWidget);
      expect(find.text('Staff Portal'), findsOneWidget);
      expect(find.text('Parent / Guardian Sign In'), findsOneWidget);

      // Switch to staff mode
      await tester.tap(find.text('Staff Portal'));
      await tester.pumpAndSettle();

      expect(find.text('Staff & Faculty Sign In'), findsOneWidget);
      expect(find.text('Institutional Email'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ClayTexturePainter Material Verification Suite', () {
    testWidgets(
        'ClayContainer renders with ClayTexturePainter and toggles microtexture',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClayContainer(
              depth: ClayDepth.medium,
              child: Text('Tactile Molded Clay'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tactile Molded Clay'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify toggle respects ClayTheme.enableMicrotexture
      ClayTheme.enableMicrotexture = false;
      await tester.pump();
      expect(find.text('Tactile Molded Clay'), findsOneWidget);
      ClayTheme.enableMicrotexture = true; // reset
    });
  });
}
