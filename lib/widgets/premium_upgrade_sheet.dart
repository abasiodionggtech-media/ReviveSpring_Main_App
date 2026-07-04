import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_controller.dart';
import '../core/app_strings.dart';
import 'app_buttons.dart';

class PremiumUpgradeSheet {
  static Future<void> show(
    BuildContext context,
    AppController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PremiumUpgradeSheetBody(controller: controller),
    );
  }
}

class _PremiumUpgradeSheetBody extends StatefulWidget {
  const _PremiumUpgradeSheetBody({required this.controller});

  final AppController controller;

  @override
  State<_PremiumUpgradeSheetBody> createState() =>
      _PremiumUpgradeSheetBodyState();
}

class _PremiumUpgradeSheetBodyState extends State<_PremiumUpgradeSheetBody> {
  bool _busy = false;

  String _buttonLabel(String language, {required bool activate}) {
    final name = AppStrings.of(
      language,
      'Activate Google Play Billing',
      'Activer Google Play Billing',
    );
    final restore = AppStrings.of(
      language,
      'Restore Google Play Purchase',
      'Restaurer un achat Google Play',
    );
    final starting = AppStrings.of(
      language,
      'Starting billing...',
      'Ouverture de la facturation...',
    );
    final checking = AppStrings.of(
      language,
      'Checking purchase...',
      'Verification de l achat...',
    );

    if (!_busy) {
      return activate ? name : restore;
    }
    return activate ? starting : checking;
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.controller.language;
    String t(String en, String fr) => AppStrings.of(language, en, fr);
    final user = widget.controller.user;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.deepEmerald.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.leaf.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.deepEmerald,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('ReviveSpring Premium', 'ReviveSpring Premium'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.controller.subscriptionPriceLabel,
                        style: const TextStyle(
                          color: AppColors.deepEmerald,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              user?.isAdmin == true
                  ? t(
                      'Admin accounts are already premium.',
                      'Les comptes admin sont deja premium.',
                    )
                  : user?.isPremium == true
                  ? t(
                      'Your account is already premium. Ads stay off and premium features remain unlocked.',
                      'Votre compte est deja premium. Les pubs restent desactivees et les fonctions premium restent debloquees.',
                    )
                  : t(
                      'Upgrade through Google Play Billing to remove ads, unlock premium features, and keep AI usage open without the ad gate.',
                      'Passez premium via Google Play Billing pour retirer les pubs, debloquer les fonctions premium et utiliser l IA sans verrou publicitaire.',
                    ),
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            ...[
              t('No ads across the app', 'Aucune pub dans l application'),
              t(
                'Premium features stay unlocked',
                'Les fonctions premium restent debloquees',
              ),
              t('AI without ad unlock limits', 'IA sans limite publicitaire'),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.leaf,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
            if (user?.isPremium != true && user?.isAdmin != true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.iconCream.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t('Google Play product', 'Produit Google Play')}: ${widget.controller.subscriptionProductId}',
                      style: const TextStyle(
                        color: AppColors.deepEmerald,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t(
                        'Billing works only when this Android app is installed from Google Play testing or production.',
                        'La facturation fonctionne seulement quand cette application Android est installee depuis Google Play en test ou en production.',
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (user?.isPremium != true && user?.isAdmin != true) ...[
              AnimatedPrimaryButton(
                label: _buttonLabel(language, activate: false),
                icon: Icons.restore,
                busy: _busy,
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() {
                          _busy = true;
                        });
                        final result = await widget.controller
                            .restoreGooglePlayBilling();
                        if (!mounted) return;
                        setState(() {
                          _busy = false;
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result ??
                                  t(
                                    'Premium activated successfully.',
                                    'Premium active avec succes.',
                                  ),
                            ),
                          ),
                        );
                        if (result == null && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
              ),
              const SizedBox(height: 10),
              AnimatedPrimaryButton(
                label: _buttonLabel(language, activate: true),
                icon: Icons.lock_open_outlined,
                busy: _busy,
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() {
                          _busy = true;
                        });
                        final result = await widget.controller
                            .activateGooglePlayBilling();
                        if (!mounted) return;
                        setState(() {
                          _busy = false;
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result ??
                                  t(
                                    'Premium activated successfully.',
                                    'Premium active avec succes.',
                                  ),
                            ),
                          ),
                        );
                        if (result == null && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
              ),
            ],
            if (user?.isPremium == true || user?.isAdmin == true)
              AnimatedPrimaryButton(
                label: t('Premium is active', 'Premium est actif'),
                icon: Icons.verified,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}
