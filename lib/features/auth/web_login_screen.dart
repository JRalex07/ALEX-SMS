import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../shared/clay/clay.dart';

enum WebLoginTab {
  staff,
  parent,
}

/// Dedicated Desktop/Web Portal Login Experience.
///
/// Designed exclusively for Flutter Web running in browser viewports.
/// Features a two-column desktop workspace layout with an institutional
/// branding panel on the left and a focused tactile clay authentication workspace on the right.
/// Adapts cleanly into a single-column web portal header + card on narrower browser windows.
class WebLoginScreen extends ConsumerStatefulWidget {
  final WebLoginTab initialTab;

  const WebLoginScreen({
    super.key,
    this.initialTab = WebLoginTab.staff,
  });

  @override
  ConsumerState<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends ConsumerState<WebLoginScreen> {
  late WebLoginTab _activeTab;

  // Staff Form Controllers
  final _staffFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Parent Form Controllers
  final _parentFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // State Management
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _verificationId;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  Future<void> _handleStaffLogin() async {
    if (!_staffFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInStaff(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      _navigateToDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.replaceAll(' ', '').trim();
    if (rawPhone.isEmpty) {
      setState(
          () => _errorMessage = 'Please enter your registered mobile number.');
      return;
    }

    final formattedPhone = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPhoneOtp(
        phoneNumber: formattedPhone,
        onCodeSent: (verifId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verifId;
            _statusMessage = 'Verification code sent to $formattedPhone';
            _isLoading = false;
          });
          _startCountdown();
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _errorMessage = err;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP.');
      return;
    }

    if (_verificationId == null) {
      setState(
          () => _errorMessage = 'Session expired. Please request a new code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final rawPhone = _phoneController.text.replaceAll(' ', '').trim();
      final formattedPhone =
          rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';

      await authRepo.verifyOtpAndSignIn(
        verificationId: _verificationId!,
        smsCode: code,
        phoneNumber: formattedPhone,
      );

      if (!mounted) return;
      _navigateToDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    final uri = GoRouterState.of(context).uri;
    final redirect = uri.queryParameters['redirect'];
    if (redirect != null &&
        redirect.isNotEmpty &&
        redirect.startsWith('/') &&
        !redirect.startsWith('/login')) {
      context.go(redirect);
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWidth = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: ClayTheme.clayCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktopWidth ? 48 : 24,
              vertical: isDesktopWidth ? 40 : 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: isDesktopWidth
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Institutional Introduction & Branding Panel
                        Expanded(
                          flex: 5,
                          child: _buildInstitutionalPanel(),
                        ),
                        const SizedBox(width: 48),
                        // Right: Interactive Clay Authentication Workspace
                        Expanded(
                          flex: 6,
                          child: _buildWorkspaceCard(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildInstitutionalHeaderBanner(),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: _buildWorkspaceCard(),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Wide Desktop Institutional Overview Panel
  Widget _buildInstitutionalPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Crest and Brand Name
        Row(
          children: [
            ClayContainer(
              depth: ClayDepth.medium,
              borderRadius: ClayTheme.radiusMd,
              surfaceColor: Colors.white,
              borderColor: AppColors.brandNavy.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.school_rounded,
                size: 32,
                color: AppColors.brandNavy,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAV ACADEMY',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'School Management System • Web Portal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        const Text(
          'Unified Institutional Workspace',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Official administrative, financial, academic, and parent portal for LAV Academy. Secure single-institution infrastructure protecting academic records, attendance logs, and fee transactions.',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),

        // Institutional Pillars (Tactile feature cards)
        _buildPillarTile(
          icon: Icons.security_rounded,
          iconColor: AppColors.adminIndigo,
          title: 'Authoritative Role-Based Access',
          description:
              'Strict ReBAC matrix across Administrator, Teacher, Accountant, Admissions, Librarian, and Parent.',
        ),
        const SizedBox(height: 14),
        _buildPillarTile(
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.accountantEmerald,
          title: 'Audited Financial Ledgers',
          description:
              'Exact integer-paise calculations, automated invoice reconciliation, and official printable vouchers.',
        ),
        const SizedBox(height: 14),
        _buildPillarTile(
          icon: Icons.verified_user_rounded,
          iconColor: AppColors.parentBlue,
          title: 'Verified Guardian Safeguards',
          description:
              'Multi-factor phone authentication mapped directly to student records with zero mock fallbacks.',
        ),
        const SizedBox(height: 32),

        // Session Information
        const ClayContainer(
          depth: ClayDepth.low,
          borderRadius: ClayTheme.radiusSm,
          surfaceColor: Color(0xFFF8FAFC),
          borderColor: AppColors.borderLight,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.brandNavy),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Academic Session: 2026 – 2027 • Production Environment',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Compact Institutional Banner for Narrower Browser Windows
  Widget _buildInstitutionalHeaderBanner() {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClayContainer(
              depth: ClayDepth.medium,
              borderRadius: ClayTheme.radiusSm,
              surfaceColor: Colors.white,
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.school_rounded,
                size: 26,
                color: AppColors.brandNavy,
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LAV ACADEMY',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Web Portal • Academic Year 2026-2027',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillarTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return ClayContainer(
      depth: ClayDepth.low,
      borderRadius: ClayTheme.radiusMd,
      surfaceColor: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Authentication Workspace Card with Segmented Controls
  Widget _buildWorkspaceCard() {
    return ClayCard(
      depth: ClayDepth.medium,
      borderRadius: ClayTheme.radiusLg,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Portal Sign In',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select your institutional role to continue to your authorized dashboard.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Portal Segmented Selector
          ClaySegmentedControl(
            selectedIndex: _activeTab == WebLoginTab.staff ? 0 : 1,
            onSelectedIndexChanged: (index) {
              setState(() {
                _activeTab =
                    index == 0 ? WebLoginTab.staff : WebLoginTab.parent;
                _errorMessage = null;
                _statusMessage = null;
              });
            },
            items: const [
              ClaySegmentItem(
                label: 'Staff & Faculty',
                icon: Icons.badge_rounded,
              ),
              ClaySegmentItem(
                label: 'Parent / Guardian',
                icon: Icons.family_restroom_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Error & Status Banners
          if (_errorMessage != null) ...[
            ClayContainer(
              depth: ClayDepth.low,
              borderRadius: ClayTheme.radiusSm,
              surfaceColor: AppColors.dangerBg,
              borderColor: AppColors.dangerRed.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 20, color: AppColors.dangerRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dangerRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          if (_statusMessage != null) ...[
            ClayContainer(
              depth: ClayDepth.low,
              borderRadius: ClayTheme.radiusSm,
              surfaceColor: AppColors.successBg,
              borderColor: AppColors.successGreen.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 20, color: AppColors.successGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Active Tab Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _activeTab == WebLoginTab.staff
                ? _buildStaffForm()
                : _buildParentForm(),
          ),
        ],
      ),
    );
  }

  /// Staff & Faculty Sign-in Form
  Widget _buildStaffForm() {
    return Form(
      key: _staffFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClayTextField(
            controller: _emailController,
            label: 'Institutional Email Address',
            hintText: 'e.g. admin@lavsms.edu or faculty@lavsms.edu',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your registered email address';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Enter a valid institutional email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          ClayTextField(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Enter your secure password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your password';
              }
              return null;
            },
            onSubmitted: (_) => _handleStaffLogin(),
          ),
          const SizedBox(height: 12),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          ClayButton(
            label: 'Sign In to Staff Portal',
            icon: Icons.login_rounded,
            isLoading: _isLoading,
            isFullWidth: true,
            onPressed: _handleStaffLogin,
          ),
          const SizedBox(height: 20),

          const Text(
            'Authorized personnel only. Access privileges are strictly validated against Firestore user roles and audited for compliance.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Parent / Guardian Phone & OTP Form
  Widget _buildParentForm() {
    return Form(
      key: _parentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClayTextField(
            controller: _phoneController,
            label: 'Registered Mobile Number',
            hintText: '9876543210 (10 digits)',
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            enabled: _verificationId == null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your registered phone number';
              }
              final clean = value.replaceAll(' ', '').replaceAll('-', '');
              if (clean.length < 10) {
                return 'Enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          if (_verificationId == null) ...[
            ClayButton(
              label: 'Send Verification Code (OTP)',
              icon: Icons.send_rounded,
              isLoading: _isLoading,
              isFullWidth: true,
              onPressed: _handleSendOtp,
            ),
          ] else ...[
            ClayTextField(
              controller: _otpController,
              label: 'Enter 6-Digit OTP',
              hintText: '• • • • • •',
              prefixIcon: Icons.lock_clock_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().length != 6) {
                  return 'Enter the complete 6-digit code';
                }
                return null;
              },
              onSubmitted: (_) => _handleVerifyOtp(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _verificationId = null;
                      _otpController.clear();
                      _statusMessage = null;
                      _errorMessage = null;
                    });
                  },
                  child: const Text('Change Number',
                      style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: _resendCountdown == 0 ? _handleSendOtp : null,
                  child: Text(
                    _resendCountdown == 0
                        ? 'Resend OTP'
                        : 'Resend in ${_resendCountdown}s',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _resendCountdown == 0
                          ? AppColors.brandNavy
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClayButton(
              label: 'Verify & Sign In',
              icon: Icons.verified_rounded,
              isLoading: _isLoading,
              isFullWidth: true,
              onPressed: _handleVerifyOtp,
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Parent access requires an active guardianship link verified by the administration. OTP delivery utilizes Firebase Phone Authentication.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
