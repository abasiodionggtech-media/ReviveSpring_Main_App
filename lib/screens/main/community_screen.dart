import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/premium_upgrade_sheet.dart';
import 'accountability_partner_screen.dart';
import 'mentorship_screen.dart';
import 'prayer_chain_screen.dart';
import 'prayer_groups_screen.dart';
import 'testimony_feed_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Community')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          const Text(
            "You're not alone in this. Pray with others, celebrate answered prayers, and grow together.",
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          _CommunityTile(
            title: 'Prayer Chain',
            subtitle: 'Share a request and let others pray with you.',
            icon: Icons.favorite_outline,
            color: AppColors.coral,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => PrayerChainScreen(controller: controller)),
            ),
          ),
          const SizedBox(height: 12),
          _CommunityTile(
            title: 'Testimony Feed',
            subtitle: 'Celebrate answered prayers with the community.',
            icon: Icons.auto_awesome,
            color: AppColors.leaf,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => TestimonyFeedScreen(controller: controller)),
            ),
          ),
          const SizedBox(height: 12),
          _CommunityTile(
            title: 'Accountability Partner',
            subtitle: 'Pair up with someone to stay consistent together.',
            icon: Icons.handshake_outlined,
            color: AppColors.deepEmerald,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AccountabilityPartnerScreen(controller: controller)),
            ),
          ),
          const SizedBox(height: 12),
          _CommunityTile(
            title: controller.isPremiumUser ? 'Prayer Groups' : 'Prayer Groups (Premium)',
            subtitle: 'Join a church or family group and pray together.',
            icon: Icons.groups_outlined,
            color: AppColors.sky,
            onTap: () {
              if (!controller.isPremiumUser) {
                PremiumUpgradeSheet.show(context, controller);
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PrayerGroupsScreen(controller: controller)),
              );
            },
          ),
          const SizedBox(height: 12),
          _CommunityTile(
            title: controller.isPremiumUser ? 'Spiritual Mentorship' : 'Spiritual Mentorship (Premium)',
            subtitle: 'Find a mentor or become one for someone else.',
            icon: Icons.diversity_3_outlined,
            color: AppColors.leafGreen,
            onTap: () {
              if (!controller.isPremiumUser) {
                PremiumUpgradeSheet.show(context, controller);
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => MentorshipScreen(controller: controller)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: GlassPanel(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, height: 1.3, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}
