import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_tokens.dart';
import '../data/app_data.dart';
import 'glass_panel.dart';
import 'section_header.dart';

class VerseCard extends StatelessWidget {
  const VerseCard({super.key, this.verse, this.reference});

  final String? verse;
  final String? reference;

  @override
  Widget build(BuildContext context) {
    final fallback = verseForToday();
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: AppColors.deepEmerald, size: 34),
          const SizedBox(height: 10),
          Text('"${verse ?? fallback.verse}"', style: const TextStyle(fontSize: 21, height: 1.45, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(reference ?? fallback.ref, style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, required this.icon, required this.color, this.onTap});

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: GlassPanel(
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class MoodSelector extends StatelessWidget {
  const MoodSelector({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(title: 'How are you feeling?', trailing: 'Today'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: moods
                .map(
                  (mood) => ActionChip(
                    avatar: _IconBadge(icon: mood.icon, color: mood.color, size: 28, iconSize: 16),
                    label: Text(mood.en),
                    backgroundColor: AppColors.iconCream.withValues(alpha: .7),
                    side: BorderSide(color: mood.color.withValues(alpha: .35)),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                    onPressed: () => onSelected(mood.id),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class PrayerTile extends StatelessWidget {
  const PrayerTile({super.key, required this.title, required this.body, required this.icon, required this.color, this.onTap, this.trailing});

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: GlassPanel(
          child: Row(
            children: [
              _IconBadge(icon: icon, color: color, size: 50, iconSize: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(body, style: const TextStyle(color: AppColors.muted, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? Icon(Icons.arrow_forward_ios, color: AppColors.deepEmerald.withValues(alpha: .58), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color, required this.size, required this.iconSize});

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(size * .32),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class WellnessScore extends StatelessWidget {
  const WellnessScore({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: .78),
              duration: const Duration(milliseconds: 1100),
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(value: value, strokeWidth: 9, color: AppColors.leaf, backgroundColor: AppColors.deepEmerald.withValues(alpha: .12)),
                  Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wellness Score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 7),
                Text('Prayer, goals, gratitude, and rest are moving in a strong direction.', style: TextStyle(color: AppColors.muted, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
