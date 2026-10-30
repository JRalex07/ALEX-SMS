import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lav_sms/core/constants/breakpoints.dart';
import 'package:lav_sms/core/constants/role_colors.dart';
import 'package:lav_sms/shared/widgets/erp_components.dart';

void main() {
  group('1. Centralized Breakpoint & AppResponsive Unit Tests', () {
    test('Breakpoints classify all target viewport widths into correct tiers',
        () {
      // 320px narrow mobile
      expect(AppBreakpoints.getTier(320), equals(ResponsiveTier.compact));
      expect(
          AppBreakpoints.getDeviceType(320), equals(DeviceScreenType.mobile));

      // 360px compact Android phone
      expect(AppBreakpoints.getTier(360), equals(ResponsiveTier.compact));

      // 390-430px modern phones
      expect(AppBreakpoints.getTier(390), equals(ResponsiveTier.compact));
      expect(AppBreakpoints.getTier(430), equals(ResponsiveTier.compact));

      // 600-768px tablets
      expect(AppBreakpoints.getTier(600), equals(ResponsiveTier.medium));
      expect(AppBreakpoints.getTier(768), equals(ResponsiveTier.medium));
      expect(
          AppBreakpoints.getDeviceType(768), equals(DeviceScreenType.tablet));

      // 1024px compact desktop
      expect(AppBreakpoints.getTier(1024), equals(ResponsiveTier.wide));
      expect(
          AppBreakpoints.getDeviceType(1024), equals(DeviceScreenType.desktop));

      // 1280-1440px standard desktop
      expect(AppBreakpoints.getTier(1280), equals(ResponsiveTier.wide));
      expect(AppBreakpoints.getTier(1440), equals(ResponsiveTier.extraWide));

      // 1920px large desktop
      expect(AppBreakpoints.getTier(1920), equals(ResponsiveTier.extraWide));
    });

    test(
        'AppResponsive.contentWidth clamps within safe bounds and never exceeds available width',
        () {
      // At 280px, must not exceed 280px (never force overflow)
      expect(AppResponsive.contentWidth(280), equals(280.0));
      // At 500px, clamped to 500px
      expect(AppResponsive.contentWidth(500), equals(500.0));
      // At 1200px, clamped to 1200px
      expect(AppResponsive.contentWidth(1200), equals(1200.0));
      // At 2560px, clamped to maxContentWidth (1440px)
      expect(AppResponsive.contentWidth(2560), equals(1440.0));
    });

    test(
        'AppResponsive.gridColumns computes optimal columns based on tile width',
        () {
      // Narrow mobile
      expect(AppResponsive.gridColumns(320, minTileWidth: 240), equals(1));
      // Phablet / Tablet
      expect(AppResponsive.gridColumns(600, minTileWidth: 240), equals(2));
      // Desktop
      expect(AppResponsive.gridColumns(1000, minTileWidth: 240), equals(4));
    });

    test('AppResponsive.screenPadding adapts smoothly across tiers', () {
      final compactPadding = AppResponsive.screenPadding(360);
      expect(compactPadding.horizontal, equals(32.0)); // 16 * 2

      final tabletPadding = AppResponsive.screenPadding(768);
      expect(tabletPadding.horizontal, equals(40.0)); // 20 * 2

      final desktopPadding = AppResponsive.screenPadding(1280);
      expect(desktopPadding.horizontal, equals(48.0)); // 24 * 2
    });
  });

  group('2. AdaptiveFormRow Widget Tests', () {
    testWidgets('Lays out children as a Column on compact viewport (< 600px)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFormRow(
              children: [
                Container(key: const ValueKey('field1'), height: 48),
                Container(key: const ValueKey('field2'), height: 48),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstField =
          tester.getTopLeft(find.byKey(const ValueKey('field1')));
      final secondField =
          tester.getTopLeft(find.byKey(const ValueKey('field2')));

      // In a column, second field is below first field (higher Y coordinate)
      expect(secondField.dy, greaterThan(firstField.dy));
      // Both start at the same X coordinate
      expect(secondField.dx, equals(firstField.dx));
    });

    testWidgets('Lays out children as a Row on desktop viewport (>= 600px)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFormRow(
              children: [
                Container(key: const ValueKey('fieldA'), height: 48),
                Container(key: const ValueKey('fieldB'), height: 48),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstField =
          tester.getTopLeft(find.byKey(const ValueKey('fieldA')));
      final secondField =
          tester.getTopLeft(find.byKey(const ValueKey('fieldB')));

      // In a row, second field is to the right (higher X coordinate)
      expect(secondField.dx, greaterThan(firstField.dx));
      // Both align on the same Y coordinate
      expect(secondField.dy, equals(firstField.dy));
    });
  });

  group('3. ErpMetricStrip Responsive Resilience Tests', () {
    final testMetrics = [
      const ErpMetricItem(
        label: 'Enrolled',
        value: '1,420',
        subtitle: 'Active students',
        icon: Icons.people,
      ),
      const ErpMetricItem(
        label: 'Attendance',
        value: '94.2%',
        subtitle: 'Today rate',
        icon: Icons.check_circle,
        color: AppColors.successGreen,
      ),
      const ErpMetricItem(
        label: 'Revenue',
        value: '₹12.5L',
        subtitle: 'Collected',
        icon: Icons.currency_rupee,
        color: AppColors.accountantEmerald,
      ),
      const ErpMetricItem(
        label: 'Pending',
        value: '38',
        subtitle: 'Applications',
        icon: Icons.assignment_late,
        color: AppColors.warningAmber,
      ),
    ];

    testWidgets(
        'Does not overflow horizontally on 320px narrow mobile viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ErpMetricStrip(metrics: testMetrics),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ENROLLED'), findsOneWidget);
      expect(find.text('ATTENDANCE'), findsOneWidget);
    });

    testWidgets('Adapts smoothly on 600px tablet and 1280px desktop viewports',
        (tester) async {
      // Test 600px
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ErpMetricStrip(metrics: testMetrics),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Test 1280px
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ErpMetricStrip(metrics: testMetrics),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('4. ErpCard Header Wrapping Tests', () {
    testWidgets(
        'Wraps header trailing button safely without overflow on narrow width',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ErpCard(
                title: 'School Communication & Announcements',
                subtitle: 'Official institutional declarations',
                icon: Icons.campaign_outlined,
                headerTrailing: ErpButton(
                  label: 'View All Notices',
                  isDense: true,
                  isPrimary: false,
                  onPressed: () {},
                ),
                child: const Text('Card Content Body'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified no RenderFlex overflow exception thrown
      expect(tester.takeException(), isNull);
      expect(find.text('School Communication & Announcements'), findsOneWidget);
      expect(find.text('View All Notices'), findsOneWidget);
    });
  });
}
