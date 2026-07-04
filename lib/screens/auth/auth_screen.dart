import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../core/app_strings.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/floating_badge.dart';
import '../../widgets/glass_panel.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final result = await widget.controller.signIn(
      email: email.text.trim(),
      password: password.text,
      fullName: name.text.trim(),
    );
    if (mounted) setState(() => error = result);
  }

  Future<void> googleSubmit() async {
    final result = await widget.controller.signInWithGoogle();
    if (mounted) setState(() => error = result);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    String t(String en, String fr) =>
        AppStrings.of(controller.language, en, fr);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 38, 22, 28),
          children: [
            const FloatingBadge(icon: Icons.church_outlined, size: 82),
            const SizedBox(height: 18),
            const Text(
              'ReviveSpring',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              t(
                'Sign in to unlock your AI prayer companion.',
                'Connectez-vous pour acceder a votre compagnon de priere IA.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            GlassPanel(
              child: Column(
                children: [
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(t('Sign In', 'Connexion')),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(t('Sign Up', 'Inscription')),
                      ),
                    ],
                    selected: {controller.signingUp},
                    onSelectionChanged: (value) =>
                        controller.setAuthMode(value.first),
                  ),
                  const SizedBox(height: 20),
                  if (error != null) ...[
                    Text(
                      error!,
                      style: const TextStyle(color: AppColors.coral),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Column(
                      key: ValueKey(controller.signingUp),
                      children: [
                        if (controller.signingUp) ...[
                          AppTextField(
                            label: t('Full Name', 'Nom complet'),
                            icon: Icons.person_outline,
                            controller: name,
                          ),
                          const SizedBox(height: 14),
                        ],
                        AppTextField(
                          label: t('Email Address', 'Adresse e-mail'),
                          icon: Icons.email_outlined,
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: t('Password', 'Mot de passe'),
                          icon: Icons.lock_outline,
                          controller: password,
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        if (!controller.signingUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: controller.busy
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ResetPasswordScreen(
                                            controller: controller,
                                            initialEmail: email.text.trim(),
                                          ),
                                        ),
                                      );
                                    },
                              child: Text(
                                t('Forgot password?', 'Mot de passe oublie ?'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        AnimatedPrimaryButton(
                          label: controller.signingUp
                              ? t('Create Account', 'Creer un compte')
                              : t('Sign In', 'Connexion'),
                          icon: controller.signingUp
                              ? Icons.person_add_alt_1
                              : Icons.login,
                          busy: controller.busy,
                          onPressed: submit,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: controller.busy ? null : googleSubmit,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: Text(
                            t('Continue with Google', 'Continuer avec Google'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
