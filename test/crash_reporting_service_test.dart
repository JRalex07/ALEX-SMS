import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lav_sms/core/services/crash_reporting_service.dart';

void main() {
  late CrashReportingService reportingService;

  setUp(() {
    reportingService = CrashReportingService.forTesting(
      crashlytics: null, // Simulated unsupported platform / fallback
      enableInDev: true,
    );
    CrashReportingService.setMockInstance(reportingService);
  });

  tearDown(() {
    CrashReportingService.resetInstance();
  });

  group('1. Platform Detection & Startup Safety', () {
    test('isPlatformSupported returns false on web or desktop targets', () {
      expect(CrashReportingService.isPlatformSupported(isWeb: true), isFalse);
      expect(
          CrashReportingService.isPlatformSupported(
              platform: TargetPlatform.windows),
          isFalse);
      expect(
          CrashReportingService.isPlatformSupported(
              platform: TargetPlatform.linux),
          isFalse);
      expect(
          CrashReportingService.isPlatformSupported(
              platform: TargetPlatform.fuchsia),
          isFalse);
    });

    test('isPlatformSupported returns true on mobile and macOS', () {
      expect(
          CrashReportingService.isPlatformSupported(
              platform: TargetPlatform.android),
          isTrue);
      expect(
          CrashReportingService.isPlatformSupported(
              platform: TargetPlatform.iOS),
          isTrue);
      expect(
          CrashReportingService.isPlatformSupported(
              platform: TargetPlatform.macOS),
          isTrue);
    });

    test('initialize runs without throwing on unsupported platform', () async {
      await expectLater(reportingService.initialize(), completes);
    });
  });

  group('2. Privacy Sanitization Engine (PII & Secret Protection)', () {
    test('Redacts email addresses from error messages', () {
      const raw =
          'Failed to send invoice notification to parent.john@example.com for student';
      final clean = reportingService.sanitize(raw);

      expect(clean, contains('[REDACTED_EMAIL]'));
      expect(clean.contains('parent.john@example.com'), isFalse);
    });

    test('Redacts international and 10-digit phone numbers', () {
      const raw1 = 'SMS delivery error for +919876543210: provider timeout';
      final clean1 = reportingService.sanitize(raw1);
      expect(clean1, contains('[REDACTED_PHONE]'));
      expect(clean1.contains('+919876543210'), isFalse);

      const raw2 = 'Parent contact number 9876543210 missing country prefix';
      final clean2 = reportingService.sanitize(raw2);
      expect(clean2, contains('[REDACTED_PHONE]'));
      expect(clean2.contains('9876543210'), isFalse);
    });

    test('Redacts 6-digit OTP codes', () {
      const raw = 'Invalid OTP submission: code 849201 expired';
      final clean = reportingService.sanitize(raw);

      expect(clean, contains('[REDACTED_OTP]'));
      expect(clean.contains('849201'), isFalse);
    });

    test('Redacts auth tokens and API keys', () {
      const rawToken =
          'Authorization failure with Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9 and key AIzaSyAR60C9elZEe5U88CAJa31xgpWPUpPEK6U';
      final clean = reportingService.sanitize(rawToken);

      expect(clean, contains('[REDACTED_AUTH_TOKEN]'));
      expect(
          clean.contains('AIzaSyAR60C9elZEe5U88CAJa31xgpWPUpPEK6U'), isFalse);
    });

    test('Redacts passwords in key-value strings', () {
      const raw =
          'Auth payload: user=admin, password: SuperSecretPassword!123, grant=admin';
      final clean = reportingService.sanitize(raw);

      expect(clean, contains('[REDACTED_PASSWORD]'));
      expect(clean.contains('SuperSecretPassword!123'), isFalse);
    });

    test('Redacts Google Storage signed URLs with access signatures', () {
      const raw =
          'Download failed at https://storage.googleapis.com/bucket/report.pdf?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=admin';
      final clean = reportingService.sanitize(raw);

      expect(clean, contains('[REDACTED_SIGNED_URL]'));
      expect(clean.contains('X-Goog-Algorithm'), isFalse);
    });

    test('sanitizeCustomKeys redacts prohibited key substrings', () {
      final input = <String, Object>{
        'safe_module': 'attendance',
        'app_version': '1.0.0',
        'user_password': 'plain_password',
        'auth_token': 'secret_token_val',
        'student_aadhaar': '1234-5678-9012',
        'guardian_email': 'guardian@domain.com',
        'parent_phone': '+919999988888',
        'user_dob': '2010-01-01',
      };

      final sanitized = reportingService.sanitizeCustomKeys(input);

      expect(sanitized['safe_module'], 'attendance');
      expect(sanitized['app_version'], '1.0.0');
      expect(sanitized['user_password'], '[REDACTED_SENSITIVE_KEY]');
      expect(sanitized['auth_token'], '[REDACTED_SENSITIVE_KEY]');
      expect(sanitized['student_aadhaar'], '[REDACTED_SENSITIVE_KEY]');
      expect(sanitized['guardian_email'], '[REDACTED_SENSITIVE_KEY]');
      expect(sanitized['parent_phone'], '[REDACTED_SENSITIVE_KEY]');
      expect(sanitized['user_dob'], '[REDACTED_SENSITIVE_KEY]');
    });
  });

  group('3. Safe Diagnostic Reporting APIs', () {
    test('recordError completes safely on fallback platform', () async {
      await expectLater(
        reportingService.recordError(
          Exception('Simulated test exception for user test@example.com'),
          StackTrace.current,
          reason: 'test_operation_verification',
          fatal: false,
          customContext: {'operation': 'fee_collection', 'amount': 500},
        ),
        completes,
      );
    });

    test('recordFlutterError handles framework error details safely', () async {
      final details = FlutterErrorDetails(
        exception: StateError('RenderFlex overflow on phone +919876543210'),
        stack: StackTrace.current,
        library: 'widgets library',
      );

      await expectLater(
        reportingService.recordFlutterError(details, fatal: false),
        completes,
      );
    });

    test('log breadcrumb completes safely', () async {
      await expectLater(
        reportingService.log('Navigated to /dashboard as teacher'),
        completes,
      );
    });

    test('setSessionState and clearUserSession complete safely', () async {
      await expectLater(
        reportingService.setSessionState(
          role: 'teacher',
          currentScreen: 'attendance_register',
          currentCohort: '10-A',
        ),
        completes,
      );

      await expectLater(
        reportingService.clearUserSession(),
        completes,
      );
    });

    test(
        'registerGlobalErrorHandlers binds to FlutterError and PlatformDispatcher',
        () {
      final oldFlutterOnError = FlutterError.onError;
      final oldPlatformOnError = PlatformDispatcher.instance.onError;

      reportingService.registerGlobalErrorHandlers();

      expect(FlutterError.onError, isNotNull);
      expect(PlatformDispatcher.instance.onError, isNotNull);

      // Restore handlers after test
      FlutterError.onError = oldFlutterOnError;
      PlatformDispatcher.instance.onError = oldPlatformOnError;
    });
  });
}
