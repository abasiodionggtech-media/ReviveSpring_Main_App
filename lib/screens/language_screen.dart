import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_controller.dart';
import '../core/app_strings.dart';
import '../widgets/floating_badge.dart';
import '../widgets/glass_panel.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final title = AppStrings.of(
      controller.language,
      'Choose Your Language',
      'Choisissez votre langue',
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FloatingBadge(icon: Icons.language, size: 76),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(AppStrings.of(controller.language, 'Choisissez votre langue', 'Choose your language'), style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: _LanguageCard(title: 'English', subtitle: 'Continue in English', icon: Icons.chat_bubble_outline, onTap: () => controller.chooseLanguage('en'))),
                    const SizedBox(width: 14),
                    Expanded(child: _LanguageCard(title: 'Francais', subtitle: 'Continuer en francais', icon: Icons.translate, onTap: () => controller.chooseLanguage('fr'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: GlassPanel(
        child: Column(
          children: [
            Icon(icon, color: AppColors.deepEmerald, size: 32),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 5),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
