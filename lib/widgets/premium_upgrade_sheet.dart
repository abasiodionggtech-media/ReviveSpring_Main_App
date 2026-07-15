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
  State<_PremiumUpgradeSheetBody> createState() => _PremiumUpgradeSheetBodyState();
}

class _PremiumUpgradeSheetBodyState extends State<_PremiumUpgradeSheetBody> {
  bool _busy = false;
  String _selectedTier = 'premium';

  @override
  void initState() {
    super.initState();
    // Default the picker to whichever plan the user doesn't already have,
    // preferring premium as the natural upsell target.
    final currentPlan = widget.controller.user?.plan;
    if (currentPlan == 'premium') _selectedTier = 'standard';
  }

  Future<void> _runPurchase(String language, String Function(String, String) t) async {
    setState(() => _busy = true);
    final result = await widget.controller.activateGooglePlayBilling(tier: _selectedTier);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ?? t('Subscription activated successfully.', 'Abonnement active avec succes.'),
        ),
      ),
    );
    if (result == null && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _runRestore(String language, String Function(String, String) t) async {
    setState(() => _busy = true);
    final result = await widget.controller.restoreGooglePlayBilling(tier: _selectedTier);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ?? t('Subscription restored successfully.', 'Abonnement restaure avec succes.'),
        ),
      ),
    );
    if (result == null && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.controller.language;
    String t(String en, String fr) => AppStrings.of(language, en, fr);
    final user = widget.controller.user;
    final alreadyPaid = user?.isPaidPlan == true || user?.isAdmin == true;
    final plans = widget.controller.subscriptionPlans;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        decoration: const BoxDecoration(
          color: AppColors.iconCream,
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
            Text(
              t('Choose your plan', 'Choisissez votre forfait'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              t(
                'Your first payment covers 3 months, with a discount applied automatically.',
                'Votre premier paiement couvre 3 mois, avec une remise appliquee automatiquement.',
              ),
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            if (alreadyPaid)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.deepEmerald),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user?.isAdmin == true
                            ? t('Admin accounts are already premium.', 'Les comptes admin sont deja premium.')
                            : t(
                                'You already have an active subscription. Thank you for supporting ReviveSpring!',
                                'Vous avez deja un abonnement actif. Merci de soutenir ReviveSpring !',
                              ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              for (final plan in plans) ...[
                _PlanCard(
                  plan: plan,
                  language: language,
                  selected: _selectedTier == plan['tier'],
                  onTap: () => setState(() => _selectedTier = plan['tier'].toString()),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.iconCream.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  t(
                    'Billing works only when this Android app is installed from Google Play testing or production.',
                    'La facturation fonctionne seulement quand cette application Android est installee depuis Google Play en test ou en production.',
                  ),
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedPrimaryButton(
                label: _busy
                    ? t('Starting billing...', 'Ouverture de la facturation...')
                    : t('Subscribe with Google Play', 'S\'abonner avec Google Play'),
                icon: Icons.lock_open_outlined,
                busy: _busy,
                onPressed: _busy ? null : () => _runPurchase(language, t),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : () => _runRestore(language, t),
                child: Text(
                  _busy
                      ? t('Checking purchase...', 'Verification de l achat...')
                      : t('Restore a previous purchase', 'Restaurer un achat precedent'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> plan;
  final String language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String t(String en, String fr) => AppStrings.of(language, en, fr);
    final tier = plan['tier']?.toString() ?? 'standard';
    final isPremiumTier = tier == 'premium';
    final monthly = (plan['monthlyPriceUsd'] as num?)?.toDouble() ?? 0;
    final months = (plan['termMonths'] as num?)?.toInt() ?? 3;
    final fullTerm = (plan['fullTermPriceUsd'] as num?)?.toDouble() ?? 0;
    final firstTerm = (plan['firstTermPriceUsd'] as num?)?.toDouble() ?? 0;
    final discount = (plan['firstTermDiscountPercent'] as num?)?.toDouble() ?? 0;

    final features = isPremiumTier
        ? [
            t('Everything in Standard', 'Tout ce qui est dans Standard'),
            t('Unlimited AI Prayer Companion', 'Assistant IA de priere illimite'),
            t('Full Mental Wellness library', 'Bibliotheque bien-etre mental complete'),
          ]
        : [
            t('No ads across the app', 'Aucune pub dans l application'),
            t('Daily prayer & declarations', 'Priere et declarations quotidiennes'),
            t('AI without the ad unlock limit', 'IA sans limite publicitaire'),
          ];

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.leaf.withValues(alpha: .12) : AppColors.iconCream.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.deepEmerald : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremiumTier ? Icons.workspace_premium : Icons.spa_outlined,
                  color: AppColors.deepEmerald,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremiumTier ? t('Premium', 'Premium') : t('Standard', 'Standard'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Radio<bool>(
                  value: true,
                  groupValue: selected ? true : null,
                  onChanged: (_) => onTap(),
                  activeColor: AppColors.deepEmerald,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '\$${monthly.toStringAsFixed(2)} ${t('/ month', '/ mois')}',
              style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (discount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t('${discount.toStringAsFixed(0)}% off first payment', '${discount.toStringAsFixed(0)}% de remise'),
                      style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${fullTerm.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '\$${firstTerm.toStringAsFixed(2)} ${t('for the first $months months', 'pour les premiers $months mois')}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.leaf, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
