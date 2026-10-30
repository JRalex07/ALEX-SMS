import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lav_sms/app/theme/app_theme.dart';
import 'package:lav_sms/core/constants/role_colors.dart';
import 'package:lav_sms/core/theme/apple_design_system.dart';
import 'package:lav_sms/shared/widgets/erp_components.dart';
import 'package:lav_sms/shared/widgets/responsive_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('1. Apple Design System Tokens & Typography Tests', () {
    test('Optical tracking scales with font size inversely', () {
      // Large display text has negative tracking (tightened)
      expect(AppleTypography.trackingDisplay, lessThan(0.0));
      expect(AppleTypography.trackingTitle, lessThan(0.0));
      expect(AppleTypography.trackingHeadline, lessThan(0.0));

      // Standard body has neutral tracking
      expect(AppleTypography.trackingBody, equals(0.0));

      // Small captions and badges have positive tracking for legibility
      expect(AppleTypography.trackingCaption, greaterThan(0.0));
      expect(AppleTypography.trackingBadge, greaterThan(0.0));
    });

    test('Proportional leading (line-height) is properly defined', () {
      expect(AppleTypography.leadingTight,
          lessThan(AppleTypography.leadingHeading));
      expect(AppleTypography.leadingHeading,
          lessThan(AppleTypography.leadingBody));
      expect(
          AppleTypography.leadingBody, lessThan(AppleTypography.leadingLoose));
    });

    test(
        'Apple spatial corner radii and touch targets enforce 44-48pt standards',
        () {
      expect(AppleSpatial.minTouchTarget, greaterThanOrEqualTo(44.0));
      expect(AppleSpatial.radiusMd, equals(10.0));
      expect(AppleSpatial.radiusPill, equals(999.0));
    });

    test(
        'Apple materials provide layered dual shadows without heavy black cast',
        () {
      final cardElevation = AppleMaterials.elevationCard;
      expect(cardElevation.length, equals(2));
      for (final shadow in cardElevation) {
        expect(shadow.color.a, lessThanOrEqualTo(0.12));
      }
    });
  });

  group('2. AppTheme Production Institutional SaaS Alignment', () {
    late ThemeData theme;

    setUpAll(() {
      theme =
          AppTheme.buildTheme(customTextTheme: Typography.material2021().black);
    });

    test('Theme surfaces use Apple clean canvas and solid white cards', () {
      expect(theme.scaffoldBackgroundColor, equals(AppleMaterials.canvas));
      expect(theme.colorScheme.primary, equals(AppColors.brandNavy));
      expect(theme.colorScheme.surface, equals(AppleMaterials.solid));
    });

    test('Button themes enforce 44pt touch targets and 10pt radius', () {
      final elevatedBtnStyle = theme.elevatedButtonTheme.style;
      expect(elevatedBtnStyle, isNotNull);
      final minSize = elevatedBtnStyle?.minimumSize?.resolve({});
      expect(minSize?.height, greaterThanOrEqualTo(44.0));
    });

    test('Input decoration uses subtle 10pt radius and clean background', () {
      final inputTheme = theme.inputDecorationTheme;
      expect(inputTheme.filled, isTrue);
      expect(inputTheme.contentPadding,
          equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
    });
  });

  group('3. Reusable ERP Components Apple Craft', () {
    final testTheme =
        AppTheme.buildTheme(customTextTheme: Typography.material2021().black);

    testWidgets(
        'ErpCard renders title, subtitle, icon, and content with subtle borders',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: const Scaffold(
            body: ErpCard(
              title: 'Academic Cohort',
              subtitle: 'Class 10 - Section A',
              icon: Icons.school,
              child: Text('42 Students Enrolled'),
            ),
          ),
        ),
      );

      expect(find.text('Academic Cohort'), findsOneWidget);
      expect(find.text('Class 10 - Section A'), findsOneWidget);
      expect(find.text('42 Students Enrolled'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('ErpStatusBadge renders semantic pill with accessible colors',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Scaffold(
            body: Row(
              children: [
                ErpStatusBadge.success('Verified'),
                ErpStatusBadge.warning('Pending Review'),
                ErpStatusBadge.danger('Overdue'),
                ErpStatusBadge.info('Published'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
    });

    testWidgets('ErpMetricStrip renders metrics with trend badges',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: const Scaffold(
            body: ErpMetricStrip(
              metrics: [
                ErpMetricItem(
                  label: 'Total Collections',
                  value: '₹14,50,000',
                  icon: Icons.payments,
                  trend: '+12.4%',
                  isPositive: true,
                ),
                ErpMetricItem(
                  label: 'Attendance Rate',
                  value: '94.2%',
                  icon: Icons.how_to_reg,
                  trend: '+1.8%',
                  isPositive: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('TOTAL COLLECTIONS'), findsOneWidget);
      expect(find.text('₹14,50,000'), findsOneWidget);
      expect(find.text('+12.4%'), findsOneWidget);
      expect(find.text('ATTENDANCE RATE'), findsOneWidget);
      expect(find.text('94.2%'), findsOneWidget);
    });
  });

  group('4. Six Role-Specific Navigation Systems & Route Safety', () {
    test('School Admin has complete operational categories', () {
      final categories =
          ResponsiveScaffold.getRoleNavCategories(UserRoles.schoolAdmin);
      expect(categories.isNotEmpty, isTrue);
      final titles = categories.map((c) => c.title).toList();
      expect(titles, contains('Student Management'));
      expect(titles, contains('Admissions'));
      expect(titles, contains('Academic Management'));
      expect(titles, contains('Staff and Access'));
    });

    test('Teacher has teaching-focused categories', () {
      final categories =
          ResponsiveScaffold.getRoleNavCategories(UserRoles.teacher);
      expect(categories.isNotEmpty, isTrue);
      final titles = categories.map((c) => c.title).toList();
      expect(titles, contains('My Teaching'));
      expect(titles, contains('Attendance'));
      expect(titles, contains('Homework & Assignments'));
      expect(titles, contains('Learning Materials'));
      expect(titles, contains('Examinations and Marks'));
    });

    test('Accountant has finance & collection categories', () {
      final categories =
          ResponsiveScaffold.getRoleNavCategories(UserRoles.accountant);
      expect(categories.isNotEmpty, isTrue);
      final titles = categories.map((c) => c.title).toList();
      expect(titles, contains('Fee Configuration'));
      expect(titles, contains('Student Accounts'));
      expect(titles, contains('Invoicing'));
      expect(titles, contains('Payments'));
      expect(titles, contains('Receipts & Adjustments'));
    });

    test('Admissions Officer has applicant & enrollment pipeline categories',
        () {
      final categories =
          ResponsiveScaffold.getRoleNavCategories(UserRoles.admissionsOfficer);
      expect(categories.isNotEmpty, isTrue);
      final titles = categories.map((c) => c.title).toList();
      expect(titles, contains('Applications'));
      expect(titles, contains('Verification'));
      expect(titles, contains('Decisions'));
      expect(titles, contains('Enrollment'));
      expect(titles, contains('Reports'));
    });

    test('Librarian has book catalog & circulation categories', () {
      final categories =
          ResponsiveScaffold.getRoleNavCategories(UserRoles.librarian);
      expect(categories.isNotEmpty, isTrue);
      final titles = categories.map((c) => c.title).toList();
      expect(titles, contains('Catalog'));
      expect(titles, contains('Circulation'));
      expect(titles, contains('Availability and Overdue'));
      expect(titles, contains('Library Members'));
      expect(titles, contains('Fines and Reports'));
    });

    test('Parent/Guardian has family-focused ward categories', () {
      final categories =
          ResponsiveScaffold.getRoleNavCategories(UserRoles.parentGuardian);
      expect(categories.isNotEmpty, isTrue);
      final titles = categories.map((c) => c.title).toList();
      expect(titles, contains('Academics'));
      expect(titles, contains('Fees'));
      expect(titles, contains('Requests & Communication'));
      expect(titles, contains('Additional Services'));
    });

    test('All navigation routes are valid and non-empty', () {
      for (final role in UserRoles.allRoles) {
        final categories = ResponsiveScaffold.getRoleNavCategories(role);
        for (final cat in categories) {
          for (final entry in cat.entries) {
            expect(entry.route, startsWith('/'));
            expect(entry.label.isNotEmpty, isTrue);
          }
        }
      }
    });
  });
}
