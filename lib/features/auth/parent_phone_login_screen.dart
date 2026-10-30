import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';

class ParentPhoneLoginScreen extends ConsumerStatefulWidget {
  const ParentPhoneLoginScreen({super.key});

  @override
  ConsumerState<ParentPhoneLoginScreen> createState() =>
      _ParentPhoneLoginScreenState();
}

class _ParentPhoneLoginScreenState
    extends ConsumerState<ParentPhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldownTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fullPhone = '+91${_phoneController.text.trim()}';

    try {
      await ref.read(authRepositoryProvider).sendPhoneOtp(
            phoneNumber: fullPhone,
            onCodeSent: (verificationId) {
              if (mounted) {
                setState(() {
                  _verificationId = verificationId;
                  _isOtpSent = true;
                  _isLoading = false;
                });
                _startCooldownTimer();
              }
            },
            onError: (err) {
              debugPrint(
                  '[ParentPhoneLoginScreen._handleSendOtp] Error callback received: $err');
              if (mounted) {
                setState(() {
                  _errorMessage = err;
                  _isLoading = false;
                });
              }
            },
          );
    } catch (e, stack) {
      debugPrint(
          '[ParentPhoneLoginScreen._handleSendOtp] Exception: $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_verificationId == null) {
      setState(() =>
          _errorMessage = 'Please request an OTP verification code first.');
      return;
    }

    final fullPhone = '+91${_phoneController.text.trim()}';

    try {
      await ref.read(authRepositoryProvider).verifyOtpAndSignIn(
            verificationId: _verificationId!,
            smsCode: code,
            phoneNumber: fullPhone,
          );

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e, stack) {
      debugPrint(
          '[ParentPhoneLoginScreen._handleVerifyOtp] Exception: $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = AppBreakpoints.isCompact(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        title: Text(
          isCompact ? 'Parent Portal' : 'Academic  — Parent Portal',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: OutlinedButton.icon(
              key: const Key('admin_login_corner_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandNavy,
                side: const BorderSide(color: AppColors.brandNavy, width: 1.2),
                padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.admin_panel_settings, size: 18),
              label: Text(
                isCompact ? 'Staff Login' : 'Administrator Login',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () => context.go('/login/staff'),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 20 : 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.parentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.phonelink_lock,
                            size: 28,
                            color: AppColors.parentBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isOtpSent ? 'Verify OTP Code' : 'Mobile Number Login',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isOtpSent
                            ? 'Enter the 6-digit code sent to +91 ${_phoneController.text}'
                            : 'Enter your registered phone number to access your linked child profiles.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppColors.dangerRed.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 18, color: AppColors.dangerRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: AppColors.dangerRed, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (!_isOtpSent) ...[
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
                            hintText: '10-digit number',
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              child: Text(
                                '+91',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().length != 10) {
                              return 'Please enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _phoneController.text = '9708798088';
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.parentBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.parentBlue
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined,
                                    size: 16, color: AppColors.parentBlue),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Test: +91 9708798088',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.parentBlue,
                                        ),
                                      ),
                                      Text(
                                        'Tap to fill OTP test phone',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.parentBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.parentBlue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Fill',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.sms_outlined, size: 18),
                          label: Text(_isLoading
                              ? 'Sending SMS...'
                              : 'Send Verification OTP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.parentBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isLoading ? null : _handleSendOtp,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: '6-Digit OTP',
                            hintText: '• • • • • •',
                            prefixIcon: Icon(Icons.key),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.parentBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isLoading ? null : _handleVerifyOtp,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Verify & Enter Portal'),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                });
                              },
                              child: const Text('Change Mobile',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            TextButton(
                              onPressed:
                                  _secondsRemaining > 0 ? null : _handleSendOtp,
                              child: Text(
                                _secondsRemaining > 0
                                    ? 'Resend OTP (${_secondsRemaining}s)'
                                    : 'Resend OTP',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _secondsRemaining > 0
                                      ? AppColors.textMuted
                                      : AppColors.parentBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 36),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.brandNavy.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 16, color: AppColors.brandNavy),
                            const Text(
                              'Staff / Admin?',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                            ),
                            InkWell(
                              onTap: () => context.go('/login/staff'),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Text(
                                  'Administrator Login →',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandNavy,
                                  ),
                                ),
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
        ),
      ),
    );
  }
}
