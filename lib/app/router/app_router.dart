import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/role_colors.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_selection_screen.dart';
import '../../features/auth/native_app_login_screen.dart';
import '../../features/auth/web_login_screen.dart';
import '../../features/dashboard/unified_dashboard_screen.dart';
import '../../features/resources/academics_resource_screen.dart';
import '../../features/resources/attendance_resource_screen.dart';
import '../../features/resources/fees_resource_screen.dart';
import '../../features/resources/library_resource_screen.dart';
import '../../features/resources/notices_resource_screen.dart';
import '../../features/resources/settings_screen.dart';
import '../../features/resources/students_resource_screen.dart';
import '../../features/resources/unauthorized_screen.dart';
import '../../providers/auth_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userProfile = ref.watch(currentUserProfileProvider).value;

  final isAuthenticated = authState.value != null;

  return GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final uriString = state.uri.toString();

      final isAuthFlow = path == '/login' ||
          path == '/login/parent' ||
          path == '/login/staff' ||
          path == '/forgot-password';

      // 1. Unauthenticated users cannot access protected routes
      if (!isAuthenticated) {
        if (isAuthFlow) {
          return null; // Allow unauthenticated user on login screens
        }

        // Preserve destination for safe return after authentication
        final safeTarget = Uri.encodeComponent(uriString);
        return '/login?redirect=$safeTarget';
      }

      // 2. Suspended account guard (fail closed)
      if (userProfile != null && !userProfile.isActive) {
        if (path == '/unauthorized') {
          return null;
        }
        return '/unauthorized?from=$path&reason=suspended';
      }

      // 3. Authenticated users attempting to visit login screens are redirected to /dashboard
      if (isAuthFlow) {
        final redirectParam = state.uri.queryParameters['redirect'];
        if (redirectParam != null &&
            redirectParam.isNotEmpty &&
            redirectParam.startsWith('/') &&
            !redirectParam.startsWith('/login')) {
          return redirectParam;
        }
        return '/dashboard';
      }

      // 4. Role-based resource guards
      final role = userProfile?.role;
      if (role != null) {
        // Fee Management route guard:
        if (path == '/fees') {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.accountant,
            UserRoles.parentGuardian,
          ];
          if (!allowed.contains(role)) {
            return '/unauthorized?from=$path';
          }
        }

        // Attendance route guard:
        if (path == '/attendance') {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.teacher,
            UserRoles.parentGuardian,
          ];
          if (!allowed.contains(role)) {
            return '/unauthorized?from=$path';
          }
        }

        // Academics route guard:
        if (path == '/academics') {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.teacher,
            UserRoles.parentGuardian,
          ];
          if (!allowed.contains(role)) {
            return '/unauthorized?from=$path';
          }
        }

        // Library route guard:
        if (path == '/library') {
          const allowed = [
            UserRoles.schoolAdmin,
            UserRoles.librarian,
            UserRoles.teacher,
            UserRoles.parentGuardian,
          ];
          if (!allowed.contains(role)) {
            return '/unauthorized?from=$path';
          }
        }

        // Parameter tampering guard for /students/:studentId:
        // Parents can ONLY access student IDs linked to their account (wardStudentIds)
        if (path.startsWith('/students/') && role == UserRoles.parentGuardian) {
          final studentId = state.pathParameters['studentId'];
          final wardIds = userProfile?.wardStudentIds ?? [];
          if (studentId != null && !wardIds.contains(studentId)) {
            return '/unauthorized?from=$uriString';
          }
        }
      }

      return null;
    },
    routes: [
      // Authentication Routes - Separate Web and Native App Login Experiences
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          if (kIsWeb) {
            return WebLoginScreen(
              initialTab:
                  roleParam == 'staff' ? WebLoginTab.staff : WebLoginTab.parent,
            );
          } else {
            return NativeAppLoginScreen(
              initialMode: roleParam == 'staff'
                  ? NativeLoginMode.staff
                  : NativeLoginMode.parent,
            );
          }
        },
      ),
      GoRoute(
        path: '/login/parent',
        builder: (context, state) {
          if (kIsWeb) {
            return const WebLoginScreen(initialTab: WebLoginTab.parent);
          } else {
            return const NativeAppLoginScreen(
                initialMode: NativeLoginMode.parent);
          }
        },
      ),
      GoRoute(
        path: '/login/staff',
        builder: (context, state) {
          if (kIsWeb) {
            return const WebLoginScreen(initialTab: WebLoginTab.staff);
          } else {
            return const NativeAppLoginScreen(
                initialMode: NativeLoginMode.staff);
          }
        },
      ),
      GoRoute(
        path: '/login/select',
        builder: (context, state) => const LoginSelectionScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Single Unified Dashboard for ALL Authenticated Roles
      // NO role-specific paths like /parents or /teacher or /admin
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const UnifiedDashboardScreen(),
      ),

      // Resource-Based Clean URLs
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceResourceScreen(),
      ),
      GoRoute(
        path: '/academics',
        builder: (context, state) => const AcademicsResourceScreen(),
      ),
      GoRoute(
        path: '/fees',
        builder: (context, state) => const FeesResourceScreen(),
      ),
      GoRoute(
        path: '/students',
        builder: (context, state) => const StudentsResourceScreen(),
        routes: [
          GoRoute(
            path: ':studentId',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId'] ?? '';
              return StudentDetailResourceScreen(studentId: studentId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryResourceScreen(),
      ),
      GoRoute(
        path: '/notices',
        builder: (context, state) => const NoticesResourceScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) {
          final fromRoute = state.uri.queryParameters['from'];
          return UnauthorizedScreen(attemptedRoute: fromRoute);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                '404 — Resource Not Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested URL "${state.uri}" does not exist in the school management system.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.dashboard, size: 16),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => context.go('/dashboard'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
