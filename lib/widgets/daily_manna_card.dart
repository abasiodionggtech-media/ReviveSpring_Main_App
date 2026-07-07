import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'glass_panel.dart';
import 'section_header.dart';

class DailyMannaCard extends StatefulWidget {
  const DailyMannaCard({super.key, required this.manna, required this.onClaim});

  final Map<String, dynamic> manna;
  final Future<Map<String, dynamic>> Function() onClaim;

  @override
  State<DailyMannaCard> createState() => _DailyMannaCardState();
}

class _DailyMannaCardState extends State<DailyMannaCard> {
  bool opening = false;
  Map<String, dynamic>? claimedResult;

  bool get _available => widget.manna['available'] != false && claimedResult == null;

  Future<void> _open() async {
    if (opening || !_available) return;
    setState(() => opening = true);
    try {
      final result = await widget.onClaim();
      if (mounted) setState(() => claimedResult = result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open today\'s manna. Try again in a moment.')),
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = (claimedResult?['streak'] ?? widget.manna['streak'] ?? 0) as int;
    final gift = (claimedResult?['gift'] ?? widget.manna['preview']) as Map?;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(title: 'Daily Manna', trailing: 'Today'),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween(begin: .85, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _available
                ? _ClosedGift(key: const ValueKey('closed'), opening: opening, onTap: _open)
                : _RevealedGift(key: const ValueKey('revealed'), gift: gift, streak: streak),
          ),
        ],
      ),
    );
  }
}

class _ClosedGift extends StatelessWidget {
  const _ClosedGift({super.key, required this.opening, required this.onTap});

  final bool opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.sky.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sky.withValues(alpha: .32)),
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: opening ? 1 : 0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(scale: 1 + value * .18, child: child),
              child: const Icon(Icons.card_giftcard, size: 46, color: AppColors.deepEmerald),
            ),
            const SizedBox(height: 10),
            Text(
              opening ? 'Opening...' : "Tap to receive today's manna",
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepEmerald),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealedGift extends StatelessWidget {
  const _RevealedGift({super.key, required this.gift, required this.streak});

  final Map? gift;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final verse = gift?['verse']?.toString();
    final ref = gift?['ref']?.toString();
    final blessing = gift?['blessing']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_outlined, color: AppColors.coral, size: 18),
            const SizedBox(width: 6),
            Text('$streak-day manna streak', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.coral)),
          ],
        ),
        if (verse != null) ...[
          const SizedBox(height: 10),
          Text('"$verse"', style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4)),
        ],
        if (ref != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(ref, style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w800))),
        if (blessing != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(blessing, style: const TextStyle(color: AppColors.muted, height: 1.4))),
      ],
    );
  }
}
