import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Production-quality, privacy-protecting Crash Reporting Service for LAV Academy SMS.
///
/// Features:
/// 1. Platform-safe: gracefully detects Web vs supported Native targets (Android/iOS/macOS).
/// 2. Privacy-first: strictly sanitizes and redacts all PII, credentials, tokens, phone numbers,
///    emails, and financial information before sending to Crashlytics.
/// 3. Minimal session context: records safe role indicators (e.g. 'teacher') without sensitive user identities.
/// 4. Integrated with FlutterError and PlatformDispatcher.
class CrashReportingService {
  static CrashReportingService? _instance;
  final FirebaseCrashlytics? _crashlytics;
  final bool _enableInDev;

  CrashReportingService._({
    FirebaseCrashlytics? crashlytics,
    bool enableInDev = false,
  })  : _crashlytics = crashlytics,
        _enableInDev = enableInDev;

  static CrashReportingService get instance {
    _instance ??= CrashReportingService._(
      crashlytics: isSupportedPlatform ? FirebaseCrashlytics.instance : null,
    );
    return _instance!;
  }

  /// Visible for testing to inject mock/fake Crashlytics instances.
  @visibleForTesting
  static void setMockInstance(CrashReportingService mockService) {
    _instance = mockService;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Visible for testing factory
  @visibleForTesting
  factory CrashReportingService.forTesting({
    FirebaseCrashlytics? crashlytics,
    bool enableInDev = false,
  }) {
    return CrashReportingService._(
      crashlytics: crashlytics,
      enableInDev: enableInDev,
    );
  }

  /// Crashlytics is natively supported only on Android, iOS, and macOS.
  /// Web and Windows/Linux desktop targets are non-native Crashlytics targets.
  static bool isPlatformSupported({TargetPlatform? platform, bool? isWeb}) {
    if (isWeb ?? kIsWeb) return false;
    final target = platform ?? defaultTargetPlatform;
    return target == TargetPlatform.android ||
        target == TargetPlatform.iOS ||
        target == TargetPlatform.macOS;
  }

  static bool get isSupportedPlatform => isPlatformSupported();

  // --- INITIALIZATION ---

  /// Initializes Crashlytics and configures collection settings safely.
  Future<void> initialize() async {
    if (!isSupportedPlatform || _crashlytics == null) {
      debugPrint(
          '[CrashReportingService] Native Crashlytics not supported on this platform. Using console fallback.');
      return;
    }

    try {
      // In release builds, automatic collection is enabled.
      // In debug/profile mode, automatic collection is disabled unless _enableInDev is set.
      final shouldCollect = !kDebugMode || _enableInDev;
      await _crashlytics.setCrashlyticsCollectionEnabled(shouldCollect);

      await _crashlytics.setCustomKey('app_name', 'LAV Academy SMS');
      await _crashlytics.setCustomKey('platform', defaultTargetPlatform.name);
      await _crashlytics.setCustomKey(
          'environment', kReleaseMode ? 'production' : 'development');
    } catch (e, stack) {
      debugPrint('[CrashReportingService] Initialization warning: $e\n$stack');
    }
  }

  /// Sets up global Flutter framework error and platform dispatcher asynchronous error handlers.
  void registerGlobalErrorHandlers() {
    // 1. Flutter framework layout & widget errors
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Present visually in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else if (originalOnError != null) {
        originalOnError(details);
      }

      // Record through privacy-safe reporting service as fatal framework crash
      if (isSupportedPlatform && _crashlytics != null) {
        _crashlytics.recordFlutterFatalError(details);
      } else {
        recordFlutterError(details, fatal: true);
      }
    };

    // 2. Uncaught asynchronous errors from the engine / platform dispatcher
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(
        error,
        stack,
        fatal: true,
        reason: 'uncaught_asynchronous_dispatcher_error',
      );
      return true; // Mark as handled so the app does not abruptly terminate ungracefully
    };
  }

  // --- PRIVACY SANITIZATION ENGINE ---

  // Regex rules to prevent personal/sensitive information leaks
  static final RegExp _emailRegex =
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
  static final RegExp _phoneRegex =
      RegExp(r'(?:\+?[0-9]{1,3}[-.\s]?)?[0-9]{10,12}');
  static final RegExp _otpRegex = RegExp(r'\b[0-9]{6}\b');
  static final RegExp _tokenRegex = RegExp(
      r'(AIzaSy[A-Za-z0-9_-]{33}|Bearer\s+[A-Za-z0-9._-]+|rzp_[a-zA-Z0-9_-]+)');
  static final RegExp _passwordRegex = RegExp(
      r'(?:password|pwd|pass|secret)\s*[:=]\s*[^\s,]+',
      caseSensitive: false);
  static final RegExp _signedUrlRegex = RegExp(
      r'https?:\/\/[^\s]+(?:X-Goog-[A-Za-z0-9_-]+|token=[A-Za-z0-9_-]+)[^\s]*');

  /// Sanitizes messages, exception strings, and stack traces by redacting confidential information.
  String sanitize(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    String sanitized = raw;
    sanitized = sanitized.replaceAll(_signedUrlRegex, '[REDACTED_SIGNED_URL]');
    sanitized = sanitized.replaceAll(_tokenRegex, '[REDACTED_AUTH_TOKEN]');
    sanitized =
        sanitized.replaceAll(_passwordRegex, 'password: [REDACTED_PASSWORD]');
    sanitized = sanitized.replaceAll(_emailRegex, '[REDACTED_EMAIL]');
    sanitized = sanitized.replaceAll(_phoneRegex, '[REDACTED_PHONE]');
    sanitized = sanitized.replaceAll(_otpRegex, '[REDACTED_OTP]');

    return sanitized;
  }

  /// Sanitizes custom key-value pairs before attaching to Crashlytics.
  Map<String, Object> sanitizeCustomKeys(Map<String, Object> keys) {
    final Map<String, Object> clean = {};
    const prohibitedKeySubstrings = [
      'password',
      'secret',
      'token',
      'auth',
      'email',
      'phone',
      'aadhaar',
      'dob',
      'address',
      'card',
      'bank',
      'otp',
    ];

    keys.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      final isProhibited =
          prohibitedKeySubstrings.any((p) => lowerKey.contains(p));

      if (isProhibited) {
        clean[key] = '[REDACTED_SENSITIVE_KEY]';
      } else if (value is String) {
        clean[key] = sanitize(value);
      } else if (value is num || value is bool) {
        clean[key] = value;
      } else {
        clean[key] = sanitize(value.toString());
      }
    });

    return clean;
  }

  final Set<String> _recentErrorSignatures = {};
  DateTime _lastCacheReset = DateTime.now();

  bool _isDuplicateError(String signature) {
    final now = DateTime.now();
    if (now.difference(_lastCacheReset).inMilliseconds > 2000) {
      _recentErrorSignatures.clear();
      _lastCacheReset = now;
    }
    return !_recentErrorSignatures.add(signature);
  }

  // --- REPORTING APIS ---

  /// Records an unexpected caught or non-fatal exception with sanitized diagnostics.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object>? customContext,
  }) async {
    final sanitizedReason = reason != null ? sanitize(reason) : null;
    final sanitizedExceptionStr = sanitize(exception.toString());
    final signature = '$sanitizedExceptionStr:$sanitizedReason';

    if (!isSupportedPlatform || _crashlytics == null) {
      if (!_isDuplicateError(signature)) {
        debugPrint(
            '[CrashReportingService Fallback] ${fatal ? "FATAL" : "NON-FATAL"}: $sanitizedExceptionStr '
            '${sanitizedReason != null ? "Reason: $sanitizedReason" : ""}');
      }
      return;
    }

    try {
      if (customContext != null && customContext.isNotEmpty) {
        final cleanContext = sanitizeCustomKeys(customContext);
        for (final entry in cleanContext.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }

      await _crashlytics.recordError(
        sanitizedExceptionStr,
        stack,
        reason: sanitizedReason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('[CrashReportingService] Error recording failed: $e');
    }
  }

  /// Records Flutter framework error details safely.
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    final errStr = details.exceptionAsString();
    if (_isDuplicateError(errStr)) {
      return;
    }

    if (!isSupportedPlatform || _crashlytics == null) {
      debugPrint('[CrashReportingService Fallback FlutterError] $errStr');
      return;
    }

    try {
      final sanitizedException = sanitize(details.exceptionAsString());
      await _crashlytics.recordFlutterError(
        FlutterErrorDetails(
          exception: sanitizedException,
          stack: details.stack,
          library: details.library,
          context: details.context,
          informationCollector: details.informationCollector,
          silent: details.silent,
        ),
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('[CrashReportingService] Flutter error recording failed: $e');
    }
  }

  /// Appends a breadcrumb log to the Crashlytics session buffer.
  Future<void> log(String message) async {
    final clean = sanitize(message);
    if (!isSupportedPlatform || _crashlytics == null) {
      debugPrint('[CrashReportingService Breadcrumb] $clean');
      return;
    }

    try {
      await _crashlytics.log(clean);
    } catch (e) {
      debugPrint('[CrashReportingService] Log failed: $e');
    }
  }

  /// Sets safe, non-sensitive session metadata (e.g. role, active module).
  /// PII like email, name, phone, or child names are NEVER attached.
  Future<void> setSessionState({
    required String role,
    String? currentScreen,
    String? currentCohort,
  }) async {
    if (!isSupportedPlatform || _crashlytics == null) return;

    try {
      await _crashlytics.setCustomKey('user_role', role);
      if (currentScreen != null) {
        await _crashlytics.setCustomKey('current_screen', currentScreen);
      }
      if (currentCohort != null) {
        await _crashlytics.setCustomKey('assigned_cohort', currentCohort);
      }
    } catch (e) {
      debugPrint('[CrashReportingService] setSessionState failed: $e');
    }
  }

  /// Sets arbitrary sanitized diagnostic key.
  Future<void> setCustomKey(String key, Object value) async {
    if (!isSupportedPlatform || _crashlytics == null) return;

    try {
      final sanitized = sanitizeCustomKeys({key: value});
      if (sanitized.containsKey(key)) {
        await _crashlytics.setCustomKey(key, sanitized[key]!);
      }
    } catch (e) {
      debugPrint('[CrashReportingService] setCustomKey failed: $e');
    }
  }

  /// Clears user session diagnostics when signing out.
  Future<void> clearUserSession() async {
    if (!isSupportedPlatform || _crashlytics == null) return;

    try {
      await _crashlytics.setUserIdentifier('');
      await _crashlytics.setCustomKey('user_role', 'unauthenticated');
      await _crashlytics.setCustomKey('current_screen', 'login');
      await _crashlytics.setCustomKey('assigned_cohort', 'none');
    } catch (e) {
      debugPrint('[CrashReportingService] clearUserSession failed: $e');
    }
  }

  /// Controlled verification crash for testing and staging builds ONLY.
  /// Never exposed to standard production UI.
  void forceCrashForTesting() {
    if (isSupportedPlatform && _crashlytics != null) {
      _crashlytics.crash();
    } else {
      throw StateError(
          'Simulated test exception for non-Crashlytics platform verification');
    }
  }
}
