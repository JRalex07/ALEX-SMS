import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../shared/clay/clay.dart';

enum NativeLoginMode {
  parent,
  staff,
}

/// Dedicated Native Mobile Application Login Experience (Android & iOS).
///
/// Designed exclusively for native mobile execution on smartphones.
/// Features a focused, mobile-first one-handed layout with compact LAV Academy branding,
/// large tactile touch targets (>= 48px), ergonomic thumb reach, seamless segmented mode switching,
/// recessed inputs, and resilient keyboard adaptation.
class NativeAppLoginScreen extends ConsumerStatefulWidget {
  final NativeLoginMode initialMode;

  const NativeAppLoginScreen({
    super.key,
    this.initialMode = NativeLoginMode.parent,
  });

  @override
  ConsumerState<NativeAppLoginScreen> createState() =>
      _NativeAppLoginScreenState();
}

class _NativeAppLoginScreenState extends ConsumerState<NativeAppLoginScreen> {
  late NativeLoginMode _activeMode;

  // Parent Controllers
  final _parentFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // Staff Controllers
  final _staffFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _verificationId;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _activeMode = widget.initialMode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.replaceAll(' ', '').trim();
    if (rawPhone.isEmpty) {
      setState(() => _errorMessage = 'Enter your 10-digit mobile number.');
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
            _statusMessage = 'OTP code sent to $formattedPhone';
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
      setState(() => _errorMessage = 'Enter the complete 6-digit OTP code.');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Session expired. Request a new OTP.');
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      backgroundColor: ClayTheme.clayCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                  maxWidth: 440,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Section: Header & Mode Switcher
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isKeyboardOpen) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: ClayContainer(
                              depth: ClayDepth.medium,
                              borderRadius: ClayTheme.radiusMd,
                              surfaceColor: Colors.white,
                              borderColor:
                                  AppColors.brandNavy.withValues(alpha: 0.12),
                              padding: const EdgeInsets.all(14),
                              child: const Icon(
                                Icons.school_rounded,
                                size: 34,
                                color: AppColors.brandNavy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Center(
                            child: Text(
                              'LAV ACADEMY',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandNavy,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Center(
                            child: Text(
                              'Mobile Portal • Academic Year 2026-2027',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          const SizedBox(height: 8),
                        ],

                        // Mode Segmented Control
                        ClaySegmentedControl(
                          selectedIndex:
                              _activeMode == NativeLoginMode.parent ? 0 : 1,
                          onSelectedIndexChanged: (index) {
                            setState(() {
                              _activeMode = index == 0
                                  ? NativeLoginMode.parent
                                  : NativeLoginMode.staff;
                              _errorMessage = null;
                              _statusMessage = null;
                            });
                          },
                          items: const [
                            ClaySegmentItem(
                              label: 'Parent Portal',
                              icon: Icons.family_restroom_rounded,
                            ),
                            ClaySegmentItem(
                              label: 'Staff Portal',
                              icon: Icons.badge_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          ClayContainer(
                            depth: ClayDepth.low,
                            borderRadius: ClayTheme.radiusSm,
                            surfaceColor: AppColors.dangerBg,
                            borderColor:
                                AppColors.dangerRed.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 18, color: AppColors.dangerRed),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dangerRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Status Banner
                        if (_statusMessage != null) ...[
                          ClayContainer(
                            depth: ClayDepth.low,
                            borderRadius: ClayTheme.radiusSm,
                            surfaceColor: AppColors.successBg,
                            borderColor:
                                AppColors.successGreen.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 18, color: AppColors.successGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _statusMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.successGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Main Tactile Authentication Card
                        ClayCard(
                          depth: ClayDepth.medium,
                          borderRadius: ClayTheme.radiusLg,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 24),
                          child: _activeMode == NativeLoginMode.parent
                              ? _buildParentMobileForm()
                              : _buildStaffMobileForm(),
                        ),
                      ],
                    ),

                    // Bottom Section: Support & Helplines
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 8),
                      child: Column(
                        children: [
                          const Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.verified_user_rounded,
                                  size: 14, color: AppColors.textMuted),
                              SizedBox(width: 6),
                              Text(
                                'Single-Institution Verified Authentication',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Administrative Support: office@lavacademy.edu',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Parent Phone & OTP Form for Native Mobile
  Widget _buildParentMobileForm() {
    return Form(
      key: _parentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Parent / Guardian Sign In',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your registered mobile number to receive a secure OTP code.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ClayTextField(
            controller: _phoneController,
            label: 'Mobile Number',
            hintText: '9876543210',
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            enabled: _verificationId == null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter phone number';
              }
              final clean = value.replaceAll(' ', '').replaceAll('-', '');
              if (clean.length < 10) {
                return 'Enter 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          if (_verificationId == null) ...[
            ClayButton(
              label: 'Get Verification Code',
              icon: Icons.sms_rounded,
              isLoading: _isLoading,
              isFullWidth: true,
              height: 50,
              onPressed: _handleSendOtp,
            ),
          ] else ...[
            ClayTextField(
              controller: _otpController,
              label: 'Verification Code',
              hintText: '6-digit OTP',
              prefixIcon: Icons.lock_clock_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().length != 6) {
                  return 'Enter 6-digit code';
                }
                return null;
              },
              onSubmitted: (_) => _handleVerifyOtp(),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
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
            const SizedBox(height: 16),
            ClayButton(
              label: 'Verify & Continue',
              icon: Icons.verified_user_rounded,
              isLoading: _isLoading,
              isFullWidth: true,
              height: 50,
              onPressed: _handleVerifyOtp,
            ),
          ],
        ],
      ),
    );
  }

  /// Staff Email/Password Form for Native Mobile
  Widget _buildStaffMobileForm() {
    return Form(
      key: _staffFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Staff & Faculty Sign In',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in using your authorized institutional credentials.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ClayTextField(
            controller: _emailController,
            label: 'Institutional Email',
            hintText: 'name@lavsms.edu',
            prefixIcon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter institutional email';
              }
              if (!value.contains('@')) {
                return 'Enter valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ClayTextField(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Enter password',
            prefixIcon: Icons.lock_rounded,
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
                return 'Enter password';
              }
              return null;
            },
            onSubmitted: (_) => _handleStaffLogin(),
          ),
          const SizedBox(height: 8),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClayButton(
            label: 'Sign In to Portal',
            icon: Icons.login_rounded,
            isLoading: _isLoading,
            isFullWidth: true,
            height: 50,
            onPressed: _handleStaffLogin,
          ),
        ],
      ),
    );
  }
}
