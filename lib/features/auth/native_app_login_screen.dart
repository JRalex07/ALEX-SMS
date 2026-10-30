import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';

enum NativeLoginMode {
  staff,
  parent,
}

/// Dedicated Native Mobile Application Login Experience (Android & iOS).
///
/// Designed with a streamlined, phone-first ergonomic interface:
/// - Defaults directly to the Parent / Guardian OTP login workflow.
/// - Prominent Administrator / Staff quick-login button positioned in the top corner.
/// - No middle slider/tabs — clicking the top corner Administrator button seamlessly
///   transitions between Parent and Staff / Administrator login with a smooth animation.
/// - Tactile touch targets (>= 48px), clean modern inputs, and robust error/status handling.
/// - Zero-overflow responsive layout across all phone screen sizes.
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

  // Parent Form Controllers
  final _parentFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // Staff Form Controllers
  final _staffFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Async & Feedback State
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

  void _switchToStaffMode() {
    setState(() {
      _activeMode = NativeLoginMode.staff;
      _errorMessage = null;
      _statusMessage = null;
      if (_emailController.text.isEmpty) {
        _emailController.text = 'admin@lavsms.edu';
      }
    });
  }

  void _switchToParentMode() {
    setState(() {
      _activeMode = NativeLoginMode.parent;
      _errorMessage = null;
      _statusMessage = null;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                    // Top Section: Header + Corner Administrator Button + Card
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInstitutionalHeader(),
                        const SizedBox(height: 20),
                        if (_errorMessage != null) ...[
                          _buildFeedbackBanner(
                            message: _errorMessage!,
                            isError: true,
                            onDismiss: () =>
                                setState(() => _errorMessage = null),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (_statusMessage != null) ...[
                          _buildFeedbackBanner(
                            message: _statusMessage!,
                            isError: false,
                            onDismiss: () =>
                                setState(() => _statusMessage = null),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _buildAnimatedCardContainer(),
                      ],
                    ),

                    // Bottom Section: Institutional Trust & Support Footer
                    _buildSecurityFooter(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Institutional Header with School Crest, Typography, and Top Corner Administrator Action
  Widget _buildInstitutionalHeader() {
    final isStaff = _activeMode == NativeLoginMode.staff;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: School Crest + Name + Academic Year Subtitle
        Expanded(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x251E3A8A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LAV ACADEMY',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Academic Year 2026-2027 • Mobile Portal',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Top Corner Action: Administrator / Staff Login or Switch Back to Parents
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isStaff ? _switchToParentMode : _switchToStaffMode,
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isStaff ? const Color(0xFF1E3A8A) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isStaff
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFF2563EB).withValues(alpha: 0.4),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isStaff
                        ? const Color(0x331E3A8A)
                        : const Color(0x0C0F172A),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isStaff
                        ? Icons.family_restroom_rounded
                        : Icons.admin_panel_settings_rounded,
                    size: 16,
                    color: isStaff ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isStaff ? 'Parent Portal' : 'Administrator',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isStaff ? Colors.white : const Color(0xFF1E3A8A),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Animated Switcher with Smooth Slide and Fade Transition
  Widget _buildAnimatedCardContainer() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isStaffChild = child.key == const ValueKey(NativeLoginMode.staff);
        // Staff slides in from left (-0.35, 0); Parent slides in from right (0.35, 0)
        final inOffset =
            isStaffChild ? const Offset(-0.35, 0.0) : const Offset(0.35, 0.0);
        final isCurrent = child.key == ValueKey(_activeMode);

        final slideTween = isCurrent
            ? Tween<Offset>(begin: inOffset, end: Offset.zero)
            : Tween<Offset>(begin: Offset.zero, end: inOffset);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideTween.animate(animation),
            child: child,
          ),
        );
      },
      child: _activeMode == NativeLoginMode.staff
          ? _buildStaffCard(key: const ValueKey(NativeLoginMode.staff))
          : _buildParentCard(key: const ValueKey(NativeLoginMode.parent)),
    );
  }

  /// Staff & Administrator Sign In Card
  Widget _buildStaffCard({required Key key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _staffFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Admin Shield Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 22,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff & Faculty Sign In',
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Authorized access for school staff & administrators.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Role Scope Information Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: Color(0xFF1E3A8A)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Roles: School Admin • Teachers • Accountants • Admissions • Librarians',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Institutional Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              decoration: _buildInputDecoration(
                label: 'Institutional Email',
                hintText: 'name@lavsms.edu',
                prefixIcon: Icons.email_rounded,
              ),
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

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              decoration: _buildInputDecoration(
                label: 'Password',
                hintText: 'Enter password',
                prefixIcon: Icons.lock_rounded,
                suffixWidget: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter password';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleStaffLogin(),
            ),
            const SizedBox(height: 8),

            // Forgot Password Navigation
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleStaffLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In to Staff Portal',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick return link back to parent portal
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: TextButton.icon(
                  onPressed: _switchToParentMode,
                  icon: const Icon(Icons.arrow_back_rounded, size: 15),
                  label: const Text(
                    'Return to Parent / Guardian Sign In',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Parent / Guardian Sign In Card (Default Mobile Mode)
  Widget _buildParentCard({required Key key}) {
    final isOtpSent = _verificationId != null;

    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _parentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    size: 22,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parent / Guardian Sign In',
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Enter your registered mobile number to receive a secure OTP code.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Ward Access Features Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Access: Real-Time Attendance • Grades • Fee Receipts • Leaves',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Phone Number Input
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !isOtpSent,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: 0.5,
              ),
              decoration: _buildInputDecoration(
                label: 'Mobile Number',
                hintText: '9876543210 (10 digits)',
                prefixIcon: Icons.phone_android_rounded,
                prefixWidget: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter phone number';
                }
                final clean = value.replaceAll(' ', '').replaceAll('-', '');
                if (clean.length < 10) {
                  return 'Enter valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Step 1: Send OTP Action
            if (!isOtpSent) ...[
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Send OTP Code',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Staff Helper text pointing to top corner Administrator button
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Text(
                      'School staff or faculty? ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    InkWell(
                      onTap: _switchToStaffMode,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Administrator Sign In',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Step 2: 6-Digit OTP Field
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                  color: Color(0xFF0F172A),
                ),
                decoration: _buildInputDecoration(
                  label: '6-Digit OTP',
                  hintText: '• • • • • •',
                  prefixIcon: Icons.lock_clock_rounded,
                ).copyWith(
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().length != 6) {
                    return 'Enter complete 6-digit OTP';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleVerifyOtp(),
              ),
              const SizedBox(height: 10),

              // Actions: Change Number / Resend Timer
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _verificationId = null;
                        _otpController.clear();
                        _statusMessage = null;
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text(
                      'Change Number',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                    ),
                  ),
                  TextButton(
                    onPressed: _resendCountdown == 0 ? _handleSendOtp : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                    ),
                    child: Text(
                      _resendCountdown == 0
                          ? 'Resend OTP'
                          : 'Resend in ${_resendCountdown}s',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _resendCountdown == 0
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Step 2 Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle_rounded, size: 18),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Modern Input Decoration Builder for Form Fields
  InputDecoration _buildInputDecoration({
    required String label,
    required String hintText,
    required IconData prefixIcon,
    Widget? prefixWidget,
    Widget? suffixWidget,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
      hintStyle: const TextStyle(
        fontSize: 13.5,
        color: Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: prefixWidget != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 14),
                Icon(prefixIcon, size: 20, color: const Color(0xFF64748B)),
                const SizedBox(width: 10),
                prefixWidget,
              ],
            )
          : Icon(prefixIcon, size: 20, color: const Color(0xFF64748B)),
      suffixIcon: suffixWidget,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
      ),
    );
  }

  /// Feedback Banner for Error or Status Messages
  Widget _buildFeedbackBanner({
    required String message,
    required bool isError,
    required VoidCallback onDismiss,
  }) {
    final bgColor = isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor =
        isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final textColor =
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final iconData = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 16, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Institutional Security Trust and Help Center Footer
  Widget _buildSecurityFooter() {
    return const Padding(
      padding: EdgeInsets.only(top: 20, bottom: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded,
                  size: 14, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Single-Institution Verified Authentication • 256-Bit TLS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'School Support: helpdesk@lavacademy.edu • +91 80 1234 5678',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
