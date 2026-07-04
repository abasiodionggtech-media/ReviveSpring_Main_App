import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../core/app_strings.dart';
import '../../widgets/floating_badge.dart';
import '../../widgets/glass_panel.dart';

enum _VerificationState { idle, verifying, success, error }

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final otp = TextEditingController();
  _VerificationState status = _VerificationState.idle;
  String? message;

  @override
  void dispose() {
    otp.dispose();
    super.dispose();
  }

  Future<void> submit(String code) async {
    if (code.length != 6 || status == _VerificationState.verifying) return;

    setState(() {
      status = _VerificationState.verifying;
      message = null;
    });

    final result = await widget.controller.verifyOtp(code, transition: false);
    if (!mounted) return;

    if (result == null) {
      setState(() => status = _VerificationState.success);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) widget.controller.completeOtpVerification();
      return;
    }

    setState(() {
      status = _VerificationState.error;
      message = result;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    otp.clear();
    setState(() {});
  }

  Future<void> resend() async {
    final result = await widget.controller.resendOtp();
    if (!mounted) return;
    setState(() {
      status = result == null ? _VerificationState.idle : _VerificationState.error;
      message = result ??
          AppStrings.of(
            widget.controller.language,
            'A fresh verification code has been sent.',
            'Un nouveau code de verification a ete envoye.',
          );
      otp.clear();
    });
  }

  Color get borderColor => switch (status) {
        _VerificationState.success => AppColors.leaf,
        _VerificationState.error => AppColors.coral,
        _VerificationState.verifying => AppColors.sky,
        _VerificationState.idle => AppColors.deepEmerald,
      };

  @override
  Widget build(BuildContext context) {
    final email = widget.controller.pendingVerifyEmail ?? 'your email';
    String t(String en, String fr) =>
        AppStrings.of(widget.controller.language, en, fr);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(22),
            children: [
              const FloatingBadge(icon: Icons.mark_email_read_outlined, size: 82, color: AppColors.sky),
              const SizedBox(height: 18),
              Text(t('Verify Your Email', 'Verifiez votre e-mail'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(t('Enter the 6-digit code sent to $email', 'Entrez le code a 6 chiffres envoye a $email'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 24),
              GlassPanel(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: otp,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 12),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (value) {
                          if (status == _VerificationState.error) {
                            setState(() {
                              status = _VerificationState.idle;
                              message = null;
                            });
                          }
                          if (value.length == 6) submit(value);
                        },
                        decoration: InputDecoration(
                          hintText: '000000',
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.iconCream.withValues(alpha: .55),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (status == _VerificationState.verifying)
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text(t('Checking your code...', 'Verification du code...')),
                          ],
                        )
                    else if (status == _VerificationState.success)
                      Text(t('Email verified successfully.', 'E-mail verifie avec succes.'), style: const TextStyle(color: AppColors.leaf, fontWeight: FontWeight.w800))
                    else if (message != null)
                      Text(message!, textAlign: TextAlign.center, style: TextStyle(color: status == _VerificationState.error ? AppColors.coral : AppColors.leaf)),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: widget.controller.busy ? null : resend,
                      child: Text(t('Send a new code', 'Envoyer un nouveau code')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
