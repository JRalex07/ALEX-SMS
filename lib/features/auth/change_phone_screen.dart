import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Parent Change Phone Number with Firebase OTP Verification
/// Route: /account/change-phone
class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  static const String _kFixedCountryCode = '+91';

  bool _codeSent = false;
  String _verificationId = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  String _normalizeToE164(String raw) {
    var digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.startsWith('91') && digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(2);
    }
    return '$_kFixedCountryCode$digitsOnly';
  }

  void _showFeedbackDialog({
    required bool isSuccess,
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? AppColors.successGreen : AppColors.dangerRed,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSuccess ? AppColors.successGreen : AppColors.brandNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    final rawNumber = _phoneController.text.trim();
    if (rawNumber.isEmpty) {
      setState(
          () => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    final digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) {
      setState(() => _errorMessage =
          'Please enter exactly 10 digits for the mobile number.');
      return;
    }

    final fullProposedPhone = _normalizeToE164(rawNumber);

    // Retrieve authenticated user's current phone number
    final user = ref.read(currentUserProfileProvider).value;
    final currentPhoneRaw = (user?.phoneNumber.isNotEmpty == true)
        ? user!.phoneNumber
        : ref.read(authRepositoryProvider).currentFirebaseUser?.phoneNumber ??
            '';

    final currentNormalized = _normalizeToE164(currentPhoneRaw);

    if (fullProposedPhone == currentNormalized) {
      const errorMsg =
          'This is already your registered phone number. Please enter a different number.';
      setState(() => _errorMessage = errorMsg);
      _showFeedbackDialog(
        isSuccess: false,
        title: 'Number Unchanged',
        message: errorMsg,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    await repo.sendUpdatePhoneOtp(
      newPhoneNumber: fullProposedPhone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _verificationId = verificationId;
          _isLoading = false;
          _errorMessage = null;
          _successMessage = 'OTP has been dispatched to $fullProposedPhone.';
        });
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.parentBlue,
            content: Text('OTP successfully sent to $fullProposedPhone'),
          ),
        );
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
        _showFeedbackDialog(
          isSuccess: false,
          title: 'OTP Dispatch Failed',
          message: error,
        );
      },
    );
  }

  Future<void> _handleVerifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      setState(
          () => _errorMessage = 'Verification code must be exactly 6 digits.');
      return;
    }

    final fullProposedPhone = _normalizeToE164(_phoneController.text.trim());

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyOtpAndUpdatePhone(
        verificationId: _verificationId,
        smsCode: smsCode,
        newPhoneNumber: fullProposedPhone,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage =
            'Phone number updated successfully to $fullProposedPhone.';
        _codeSent = false;
        _phoneController.clear();
        _otpController.clear();
      });

      _showFeedbackDialog(
        isSuccess: true,
        title: 'Phone Number Updated Successfully',
        message:
            'Your registered mobile number has been changed to $fullProposedPhone successfully. All student linkages, records, and access permissions remain fully preserved.',
      );
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString().replaceAll('Exception:', '').trim();
      setState(() {
        _isLoading = false;
        _errorMessage = errorText;
      });
      _showFeedbackDialog(
        isSuccess: false,
        title: 'Phone Number Update Failed',
        message: errorText,
      );
    }
  }

  String _formatMaskedPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'No phone registered';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 4) return phone;
    final lastFour = digits.substring(digits.length - 4);
    return '+91 ••••• •$lastFour';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final currentPhone = user?.phoneNumber.isNotEmpty == true
        ? user!.phoneNumber
        : ref.watch(authRepositoryProvider).currentFirebaseUser?.phoneNumber;

    return ResponsiveScaffold(
      title: 'Change Registered Phone Number',
      currentRoute: AppRoutes.changePhone,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner explaining security requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.parentBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.parentBlue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          color: AppColors.parentBlue, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parent Identity Verification',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.parentBlue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Updating your registered phone number requires SMS OTP verification. Your parent account UID, student links, and fee ledgers will be seamlessly preserved.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Current Registered Phone (Read-Only & Masked)
                ErpCard(
                  title: 'Current Registered Phone',
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatMaskedPhone(currentPhone),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VERIFIED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Update Phone Workflow Card
                ErpCard(
                  title: _codeSent
                      ? 'Step 2: Enter 6-Digit OTP'
                      : 'Step 1: Enter New Mobile Number',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppColors.dangerRed.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.dangerRed, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.dangerRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_successMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.successGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.successGreen
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: AppColors.successGreen, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_codeSent) ...[
                        const Text(
                          'New Mobile Number (India Only)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Static +91 country badge (NO DROPDOWN, NO SELECTOR)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                border:
                                    Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '🇮🇳 +91',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'Enter 10-digit mobile number',
                                  prefixIcon: const Icon(Icons.phone_outlined,
                                      size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val.length == 10 &&
                                        _normalizeToE164(val) ==
                                            _normalizeToE164(
                                                currentPhone ?? '')) {
                                      _errorMessage =
                                          'This is already your registered phone number. Please enter a different number.';
                                    } else {
                                      _errorMessage = null;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ErpButton(
                          label: _isLoading
                              ? 'Sending OTP...'
                              : 'Send Verification OTP',
                          icon: Icons.send_outlined,
                          color: AppColors.parentBlue,
                          onPressed: _isLoading ? null : _handleSendOtp,
                        ),
                      ] else ...[
                        Text(
                          'A 6-digit OTP was sent to $_kFixedCountryCode${_phoneController.text.trim()}.',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '000000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ErpButton(
                                label: _isLoading
                                    ? 'Verifying...'
                                    : 'Verify OTP & Update Phone',
                                icon: Icons.verified_user_outlined,
                                color: AppColors.successGreen,
                                onPressed: _isLoading ? null : _handleVerifyOtp,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: (_resendCooldown > 0 || _isLoading)
                                  ? null
                                  : _handleSendOtp,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                              child: Text(_resendCooldown > 0
                                  ? 'Resend (${_resendCooldown}s)'
                                  : 'Resend OTP'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() {
                            _codeSent = false;
                            _otpController.clear();
                          }),
                          child: const Text('Change Phone Number'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
