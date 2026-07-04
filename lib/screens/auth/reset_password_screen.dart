import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../core/app_strings.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.controller,
    this.initialEmail,
  });

  final AppController controller;
  final String? initialEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final email = TextEditingController();
  final otp = TextEditingController();
  final password = TextEditingController();
  bool emailSent = false;
  bool busy = false;
  String? message;

  @override
  void initState() {
    super.initState();
    email.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final address = email.text.trim();
    if (address.isEmpty) {
      setState(
        () => message = AppStrings.of(
          widget.controller.language,
          'Enter your email address before sending a reset code.',
          'Entrez votre adresse e-mail avant d envoyer un code de reinitialisation.',
        ),
      );
      return;
    }

    setState(() {
      busy = true;
      message = null;
    });

    final error = await widget.controller.sendPasswordResetEmail(address);
    setState(() {
      busy = false;
      if (error != null) {
        message = error;
      } else {
        emailSent = true;
        message = AppStrings.of(
          widget.controller.language,
          'A reset code was sent to your email.',
          'Un code de reinitialisation a ete envoye a votre e-mail.',
        );
      }
    });
  }

  Future<void> _resetPassword() async {
    final address = email.text.trim();
    final code = otp.text.trim();
    final newPassword = password.text;

    if (address.isEmpty || code.length != 6 || newPassword.length < 6) {
      setState(
        () => message = AppStrings.of(
          widget.controller.language,
          'Please enter your email, 6-digit code, and a new password with at least 6 characters.',
          'Veuillez saisir votre e-mail, le code a 6 chiffres et un nouveau mot de passe d au moins 6 caracteres.',
        ),
      );
      return;
    }

    setState(() {
      busy = true;
      message = null;
    });

    final error = await widget.controller.resetPassword(
      address,
      code,
      newPassword,
    );
    if (!mounted) return;
    setState(() => busy = false);

    if (error != null) {
      setState(() => message = error);
      return;
    }

    if (!mounted) return;
    if (widget.controller.stage != null) {
      // no-op, just keep existing stage; reset does not require stage change.
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.of(
            widget.controller.language,
            'Password reset successfully. Please sign in with your new password.',
            'Mot de passe reinitialise avec succes. Veuillez vous connecter avec votre nouveau mot de passe.',
          ),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.controller.language;
    String t(String en, String fr) => AppStrings.of(language, en, fr);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.deepEmerald),
        title: Text(t('Reset Password', 'Reinitialiser le mot de passe')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(
                      'Reset your password with a verification code sent by email.',
                      'Reinitialisez votre mot de passe avec un code de verification envoye par e-mail.',
                    ),
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: t('Email Address', 'Adresse e-mail'),
                    icon: Icons.email_outlined,
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  AnimatedPrimaryButton(
                    label: emailSent
                        ? t(
                            'Send another reset code',
                            'Envoyer un autre code de reinitialisation',
                          )
                        : t(
                            'Send reset code',
                            'Envoyer le code de reinitialisation',
                          ),
                    icon: Icons.email,
                    busy: busy,
                    onPressed: _sendResetEmail,
                  ),
                  if (emailSent) ...[
                    const SizedBox(height: 18),
                    AppTextField(
                      label: t('Verification Code', 'Code de verification'),
                      icon: Icons.verified_user_outlined,
                      controller: otp,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: t('New Password', 'Nouveau mot de passe'),
                      icon: Icons.lock_outline,
                      controller: password,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    AnimatedPrimaryButton(
                      label: t(
                        'Reset Password',
                        'Reinitialiser le mot de passe',
                      ),
                      icon: Icons.lock_reset,
                      busy: busy,
                      onPressed: _resetPassword,
                    ),
                  ],
                  if (message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      message!,
                      style: TextStyle(
                        color:
                            message!.contains('success') ||
                                message!.contains('succès')
                            ? AppColors.leaf
                            : AppColors.coral,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
