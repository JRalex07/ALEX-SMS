import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';

enum WebLoginTab {
  staff,
  parent,
}

/// Dedicated Desktop/Web Portal Login Experience.
///
/// Designed with an institutional School ERP presentation matching modern school portal designs:
/// - Left side: Rich deep-blue gradient with organic ambient curves, high-impact typography
///   "Everything your school needs, in one place.", feature pills, and institutional branding.
/// - Top right corner: Dedicated floating Administrator Login quick-access button.
/// - Right side: Clean, floating card with school crest, "Welcome back 👋", role switcher,
///   modern input fields with icons, prominent "Sign In to Dashboard →" button, and security trust badge.
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
  bool _isAdminMode = false;

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
  void didUpdateWidget(covariant WebLoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        _activeTab != widget.initialTab) {
      setState(() {
        _activeTab = widget.initialTab;
        _errorMessage = null;
        _statusMessage = null;
      });
    }
  }

  void _navigateToTab(WebLoginTab tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _isAdminMode = false;
      _errorMessage = null;
      _statusMessage = null;
    });
    try {
      if (tab == WebLoginTab.staff) {
        context.go('/login/staff');
      } else {
        context.go('/login');
      }
    } catch (_) {
      // In standalone widget tests without GoRouter, state update is still applied
    }
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

  void _activateAdministratorMode() {
    setState(() {
      _isAdminMode = true;
      _activeTab = WebLoginTab.staff;
      _errorMessage = null;
      _statusMessage =
          'Administrator mode active. Sign in with institutional credentials.';
      if (_emailController.text.isEmpty) {
        _emailController.text = 'admin@lavsms.edu';
      }
    });
  }

  void _toggleAdministratorMode() {
    setState(() {
      if (_isAdminMode) {
        _isAdminMode = false;
        _statusMessage = null;
      } else {
        _activateAdministratorMode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWidth = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body:
          isDesktopWidth ? _buildDesktopLayout() : _buildMobileOrTabletLayout(),
    );
  }

  /// Desktop Full-Bleed 2-Column ERP Portal Layout with Smooth Slide Transition
  /// - When Staff Login is active: Staff Login workspace slides to the LEFT, Hero Banner slides to the RIGHT.
  /// - When Parent Login is active: Hero Banner slides to the LEFT, Parent Login workspace slides to the RIGHT.
  Widget _buildDesktopLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStaff = _activeTab == WebLoginTab.staff;
        final totalWidth = constraints.maxWidth;
        final heroWidth = totalWidth * (11.0 / 20.0);
        final formWidth = totalWidth * (9.0 / 20.0);
        const animDuration = Duration(milliseconds: 650);
        const animCurve = Curves.easeInOutCubicEmphasized;

        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Foundation canvas background
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFF1F5F9),
                ),
              ),

              // Sliding Hero Branding Panel (Blue gradient canvas)
              AnimatedPositioned(
                duration: animDuration,
                curve: animCurve,
                top: 0,
                bottom: 0,
                left: isStaff ? formWidth : 0,
                width: heroWidth,
                child: _buildHeroPanel(),
              ),

              // Sliding Authentication Workspace Panel (Light grey canvas with floating card)
              AnimatedPositioned(
                duration: animDuration,
                curve: animCurve,
                top: 0,
                bottom: 0,
                left: isStaff ? 0 : heroWidth,
                width: formWidth,
                child: _buildAuthWorkspace(),
              ),

              // Dedicated Floating Navigation at the Corner of Screen
              Positioned(
                top: 24,
                right: 32,
                child: _buildCornerButton(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Left/Right Hero Branding Panel with rich blue gradient, layered organic curves, and feature chips
  Widget _buildHeroPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F265C),
            Color(0xFF143B8B),
            Color(0xFF1A47A8),
            Color(0xFF1E52C4),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layered Organic Ambient Waves
          CustomPaint(
            painter: _SchoolHeroBackgroundPainter(),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // School Header Crest & Title
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 28,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAV ACADEMY',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Smart School Management System',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFBFDBFE),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(flex: 2),

                // Digital School Management Pill matching reference image
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Color(0xFFFDE047), size: 14),
                      SizedBox(width: 8),
                      Text(
                        'DIGITAL SCHOOL MANAGEMENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unified Institutional Workspace',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF93C5FD),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 24),

                // Hero Main Heading
                const Text(
                  'Everything your\nschool needs, in one\nplace.',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 18),

                // Subtitle
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: const Text(
                    'Manage students, attendance, fees, examinations, communication and daily school operations from a single powerful ERP platform.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFE2E8F0),
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Functional Feature Badges (Matching reference design)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildHeroPill(
                        Icons.person_outline_rounded, 'Student Management'),
                    _buildHeroPill(Icons.account_balance_wallet_outlined,
                        'Fees & Accounts'),
                    _buildHeroPill(Icons.calendar_today_outlined, 'Attendance'),
                    _buildHeroPill(Icons.school_outlined, 'Exams & Results'),
                    _buildHeroPill(
                        Icons.notifications_none_rounded, 'Notifications'),
                    _buildHeroPill(
                        Icons.people_outline_rounded, 'Parent Communication'),
                  ],
                ),

                const Spacer(flex: 3),

                // Bottom Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '© 2026 LAV Academy ERP • Secure & Reliable School Management',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'School ERP Solution',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Floating Authentication Workspace Container with Centered Card
  Widget _buildAuthWorkspace() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _buildFloatingAuthCard(),
          ),
        ),
      ),
    );
  }

  /// Narrow/Mobile Browser Layout with Responsive Adaptation
  Widget _buildMobileOrTabletLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row with School Branding and Corner Admin Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.school_rounded,
                                size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LAV ACADEMY',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Web Portal • Academic Year 2026-2027',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCornerButton(isDense: true),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFloatingAuthCard(isCompact: true),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    '© 2026 Raman Kumar Sharma • Secure & Verified Portal',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Feature Pill Chip matching the reference visual style
  Widget _buildHeroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF93C5FD), size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Dedicated Floating Navigation Button located at the Corner of Screen
  Widget _buildCornerButton({bool isDense = false}) {
    final isStaff = _activeTab == WebLoginTab.staff;

    return Tooltip(
      message: isStaff
          ? 'Switch to Parent & Guardian Portal (/login)'
          : 'Switch to Staff & Faculty Institutional Login (/login/staff)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isStaff) {
              _navigateToTab(WebLoginTab.parent);
            } else {
              _navigateToTab(WebLoginTab.staff);
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isDense ? 12 : 16,
              vertical: isDense ? 7 : 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isStaff ? Icons.family_restroom_rounded : Icons.badge_rounded,
                  size: isDense ? 15 : 18,
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 6),
                Text(
                  isStaff
                      ? (isDense ? 'Parents' : 'Parent / Guardian')
                      : (isDense ? 'Staff' : 'Staff & Faculty'),
                  style: TextStyle(
                    fontSize: isDense ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Floating Authentication Workspace Card (Design matching user-provided reference)
  Widget _buildFloatingAuthCard({bool isCompact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 20 : 32, vertical: isCompact ? 24 : 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Top Badge & School Info
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAV ACADEMY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'SCHOOL MANAGEMENT PORTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Header matching active portal (/login for Parent, /login/staff for Staff)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _isAdminMode
                      ? 'Administrative Login'
                      : (_activeTab == WebLoginTab.staff
                          ? 'Staff & Faculty'
                          : 'Welcome back'),
                  style: TextStyle(
                    fontSize: isCompact ? 22 : 26,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isAdminMode ? '🔐' : '👋',
                style: TextStyle(fontSize: isCompact ? 20 : 24),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isAdminMode
                ? 'Sign in with institutional administrative credentials.'
                : (_activeTab == WebLoginTab.staff
                    ? 'Sign in to continue to your staff dashboard.'
                    : 'Sign in to continue to your parent portal.'),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Portal Sign In Sub-header Badge (No segmented slider!)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _activeTab == WebLoginTab.staff
                          ? Icons.badge_rounded
                          : Icons.family_restroom_rounded,
                      size: 15,
                      color: const Color(0xFF1E3A8A),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _activeTab == WebLoginTab.staff
                            ? 'Staff Portal'
                            : 'Parent Portal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'Portal Sign In',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feedback Status Banners
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 18, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_statusMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Active Mode Form with smooth reveal slide & fade transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _activeTab == WebLoginTab.staff
                ? KeyedSubtree(
                    key: const ValueKey('staff_form'),
                    child: _buildStaffForm(),
                  )
                : KeyedSubtree(
                    key: const ValueKey('parent_form'),
                    child: _buildParentForm(),
                  ),
          ),

          const SizedBox(height: 16),

          // Bottom Portal Switcher (Clean navigation between /login and /login/staff)
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                Icon(
                  _activeTab == WebLoginTab.staff
                      ? Icons.family_restroom_rounded
                      : Icons.badge_outlined,
                  size: 14,
                  color: const Color(0xFF2563EB),
                ),
                Text(
                  _activeTab == WebLoginTab.staff
                      ? 'Parent / Guardian? '
                      : 'Staff or Faculty? ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                InkWell(
                  onTap: () => _navigateToTab(
                    _activeTab == WebLoginTab.staff
                        ? WebLoginTab.parent
                        : WebLoginTab.staff,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      _activeTab == WebLoginTab.staff
                          ? 'Parent Portal Sign In →'
                          : 'Staff & Faculty Sign In →',
                      style: const TextStyle(
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

          const SizedBox(height: 20),

          // Security Trust Badge (Matching reference design)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 14, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Your information is protected with secure authentication',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sub-footer
          const Center(
            child: Text(
              'Powered by Raman Kumar Sharma',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Staff & Faculty Sign-in Form with Clean Modern Inputs and Arrow CTA
  Widget _buildStaffForm() {
    return Form(
      key: _staffFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User Id / Email
          Text(
            _isAdminMode ? 'Administrator ID' : 'User Id',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: _isAdminMode
                  ? 'Enter Administrator ID or email'
                  : 'Enter User Id or Institutional Email',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  size: 20, color: Color(0xFF64748B)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your registered email address or user ID';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Enter a valid institutional email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 20, color: Color(0xFF64748B)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your password';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleStaffLogin(),
          ),
          const SizedBox(height: 8),

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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Modern Gradient Primary CTA Button matching reference image
          ElevatedButton(
            onPressed: _isLoading ? null : _handleStaffLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _isAdminMode
                              ? 'Sign In to Admin Console'
                              : 'Sign In to Dashboard',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _toggleAdministratorMode,
              icon: Icon(
                _isAdminMode
                    ? Icons.badge_outlined
                    : Icons.admin_panel_settings_outlined,
                size: 16,
                color: const Color(0xFF2563EB),
              ),
              label: Text(
                _isAdminMode ? 'Standard Staff Login' : 'Administrator Login',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
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
          const Text(
            'Registered Mobile Number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: _verificationId == null,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: '9876543210 (10 digits)',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.phone_android_rounded,
                  size: 20, color: Color(0xFF64748B)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
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
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Send Verification Code (OTP)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ] else ...[
            const Text(
              'Enter 6-Digit OTP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: '• • • • • •',
                hintStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 4,
                ),
                prefixIcon: const Icon(Icons.lock_clock_rounded,
                    size: 20, color: Color(0xFF64748B)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().length != 6) {
                  return 'Enter the complete 6-digit code';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleVerifyOtp(),
            ),
            const SizedBox(height: 10),
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
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Verify & Sign In',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle_outline, size: 18),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom Background Painter for Left Hero Section to render subtle organic glowing curve waves
class _SchoolHeroBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft organic glow wave 1
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(w * 0.4, 0)
      ..cubicTo(w * 0.65, h * 0.15, w * 0.85, h * 0.45, w, h * 0.5)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(path1, paint1);

    // Soft organic glow wave 2
    final paint2 = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, h * 0.6)
      ..cubicTo(w * 0.35, h * 0.7, w * 0.7, h * 0.85, w * 0.9, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path2, paint2);

    // Subtle curved stroke outline
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final strokePath = Path()
      ..moveTo(w * 0.3, 0)
      ..cubicTo(w * 0.55, h * 0.25, w * 0.8, h * 0.45, w, h * 0.6);
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
