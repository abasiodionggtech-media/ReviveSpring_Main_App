import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/content_tiles.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/premium_upgrade_sheet.dart';
import '../../widgets/section_header.dart';
import 'breathing_exercise_screen.dart';
import 'grief_crisis_support_screen.dart';
import 'prayer_room_screen.dart';
import 'sleep_prayer_screen.dart';
import 'weekly_review_screen.dart';
import 'worship_mode_screen.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({
    super.key,
    required this.controller,
    required this.onNavigate,
  });

  final AppController controller;
  final ValueChanged<int> onNavigate;

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  Map<String, dynamic> wellness = {};
  bool loading = true;
  String selectedArea = 'prayer';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      wellness = await widget.controller.api.getWellness();
    } catch (_) {
      wellness = {
        'overall': 68,
        'insight':
            'Prayer, reflection, and daily goals are building a steadier rhythm.',
        'pillars': {
          'prayer': {'score': 76},
          'journal': {'score': 58},
          'goals': {'score': 72},
          'streak': {'score': 64},
        },
      };
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int score(String key) {
    final pillars = wellness['pillars'];
    if (pillars is Map && pillars[key] is Map) {
      return int.tryParse('${(pillars[key] as Map)['score']}') ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final overall = int.tryParse('${wellness['overall'] ?? 0}') ?? 0;
    final selected = _wellnessAreas.firstWhere(
      (area) => area.id == selectedArea,
      orElse: () => _wellnessAreas.first,
    );
    return ListView(
      key: const ValueKey('wellness'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        const SectionHeader(
          title: 'Spiritual Wellness',
          subtitle: 'AI-guided faith health from your onboarding and progress.',
          icon: Icons.spa,
        ),
        const SizedBox(height: 18),
        if (loading)
          const LinearProgressIndicator(color: AppColors.deepEmerald),
        GlassPanel(
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: overall / 100,
                      strokeWidth: 9,
                      color: AppColors.leaf,
                      backgroundColor: AppColors.deepEmerald.withValues(
                        alpha: .12,
                      ),
                    ),
                    Text(
                      '$overall%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wellness Score',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      (wellness['insight'] ??
                              'Your wellness score will update as you pray, journal, and complete goals.')
                          .toString(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WellnessMetric(
                value: '${score('prayer')}%',
                label: 'Peace',
                icon: Icons.water_drop_outlined,
                color: AppColors.sky,
                selected: selectedArea == 'prayer',
                onTap: () => setState(() => selectedArea = 'prayer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WellnessMetric(
                value: '${score('journal')}%',
                label: 'Rest',
                icon: Icons.nightlight_outlined,
                color: AppColors.lavender,
                selected: selectedArea == 'journal',
                onTap: () => setState(() => selectedArea = 'journal'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _WellnessMetric(
                value: '${score('goals')}%',
                label: 'Scripture Awareness',
                icon: Icons.menu_book_outlined,
                color: AppColors.leaf,
                selected: selectedArea == 'goals',
                onTap: () => setState(() => selectedArea = 'goals'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WellnessMetric(
                value: '${score('streak')}%',
                label: 'Consistency',
                icon: Icons.local_fire_department_outlined,
                color: AppColors.deepEmerald,
                selected: selectedArea == 'streak',
                onTap: () => setState(() => selectedArea = 'streak'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _WellnessDetailCard(
          area: selected,
          score: score(selected.id),
          onOpen: () => widget.onNavigate(selected.targetTab),
        ),
        const SizedBox(height: 16),
        PrayerTile(
          title: 'Guided Affirmations',
          body:
              'Open five faith-filled declarations for peace, restoration, courage, and hope.',
          icon: Icons.auto_awesome,
          color: AppColors.leaf,
          onTap: () => _showAffirmations(context),
        ),
        const SizedBox(height: 12),
        PrayerTile(
          title: 'Breathing & Prayer Exercise',
          body:
              'A guided 4-7-8 breathing rhythm paired with short prayer prompts — great for anxious moments.',
          icon: Icons.self_improvement,
          color: AppColors.sky,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BreathingExerciseScreen(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PrayerTile(
          title: 'Sleep Prayer',
          body:
              'A calming night-mode screen with a slow prayer to help you rest, worry-free.',
          icon: Icons.nightlight_round,
          color: AppColors.lavender,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SleepPrayerScreen(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PrayerTile(
          title: 'Prayer Room',
          body:
              'An immersive, ambient timer for sitting quietly with God — choose 5 to 20 minutes.',
          icon: Icons.self_improvement,
          color: AppColors.deepEmerald,
          trailing: widget.controller.isPremiumUser ? null : const _PremiumBadge(),
          onTap: () {
            if (!widget.controller.isPremiumUser) {
              PremiumUpgradeSheet.show(context, widget.controller);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrayerRoomScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        PrayerTile(
          title: 'Worship Mode',
          body:
              'A curated worship playlist — tap a track to open it in YouTube or Spotify.',
          icon: Icons.music_note_outlined,
          color: AppColors.coral,
          trailing: widget.controller.isPremiumUser ? null : const _PremiumBadge(),
          onTap: () {
            if (!widget.controller.isPremiumUser) {
              PremiumUpgradeSheet.show(context, widget.controller);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => WorshipModeScreen(controller: widget.controller)),
            );
          },
        ),
        const SizedBox(height: 12),
        PrayerTile(
          title: 'Weekly Spiritual Review',
          body:
              'A short AI reflection on your week, refreshed every Sunday, plus space for your own thoughts.',
          icon: Icons.calendar_today_outlined,
          color: AppColors.sky,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => WeeklyReviewScreen(controller: widget.controller)),
          ),
        ),
        const SizedBox(height: 12),
        PrayerTile(
          title: 'Grief & Crisis Support',
          body:
              'Gentle content for heavy seasons, plus crisis resources — always free, always here.',
          icon: Icons.volunteer_activism_outlined,
          color: AppColors.leaf,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => GriefCrisisSupportScreen(controller: widget.controller)),
          ),
        ),
      ],
    );
  }

  void _showAffirmations(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AffirmationSheet(),
    );
  }
}

class _WellnessMetric extends StatelessWidget {
  const _WellnessMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label:
          '$label, $value. ${selected ? 'Details currently displayed' : 'Tap to view details'}',
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        scale: selected ? 1.025 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: .12)
                  : Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? color
                    : AppColors.deepEmerald.withValues(alpha: .1),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: .16),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selected ? 'Viewing details' : 'Tap to explore',
                      style: TextStyle(
                        color: selected ? color : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, size: 18, color: color),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AffirmationSheet extends StatelessWidget {
  const _AffirmationSheet();

  static const affirmations = [
    'I am loved by God completely, even while I am still growing.',
    'I am held in peace; fear does not have the final word over my day.',
    'God is restoring my mind, renewing my strength, and guiding my next step.',
    'I can move slowly, breathe deeply, and trust that grace is already present.',
    'I am not alone. I am seen, supported, and strengthened for what is ahead.',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .72,
      minChildSize: .5,
      maxChildSize: .92,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FBF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.deepEmerald.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.auto_awesome, color: AppColors.leaf, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Guided Affirmations',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Read each declaration slowly. Pause after every line and let the words settle in your heart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 20),
            for (var index = 0; index < affirmations.length; index++) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.leaf.withValues(alpha: .18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: const TextStyle(
                        color: AppColors.leaf,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        affirmations[index],
                        style: const TextStyle(
                          color: AppColors.ink,
                          height: 1.48,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _WellnessArea {
  const _WellnessArea({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.summary,
    required this.nextStep,
    required this.signals,
    required this.targetTab,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String summary;
  final String nextStep;
  final List<String> signals;
  final int targetTab;
}

const _wellnessAreas = [
  _WellnessArea(
    id: 'prayer',
    title: 'Peace',
    icon: Icons.water_drop_outlined,
    color: AppColors.sky,
    summary:
        'Prayer activity shows how often you pause, breathe, and bring your real life to God.',
    nextStep:
        'Choose one feeling on Home and stay with the prayer for the full timer.',
    signals: ['Guided prayers', 'Mood prayers', 'Prayer time'],
    targetTab: 1,
  ),
  _WellnessArea(
    id: 'journal',
    title: 'Rest',
    icon: Icons.nightlight_outlined,
    color: AppColors.lavender,
    summary:
        'Journal entries help measure reflection, emotional release, gratitude, and spiritual rest.',
    nextStep:
        'Write one honest journal note about what you are carrying today.',
    signals: ['Journal rhythm', 'Reflection depth', 'Gratitude'],
    targetTab: 2,
  ),
  _WellnessArea(
    id: 'goals',
    title: 'Scripture Awareness',
    icon: Icons.menu_book_outlined,
    color: AppColors.leaf,
    summary:
        'Daily goals and Scripture steps show how consistently you turn intention into practice.',
    nextStep: 'Open Daily Goals and complete one Scripture activity today.',
    signals: ['Completed goals', 'Scripture actions', 'Daily consistency'],
    targetTab: 3,
  ),
  _WellnessArea(
    id: 'streak',
    title: 'Consistency',
    icon: Icons.local_fire_department_outlined,
    color: AppColors.deepEmerald,
    summary:
        'Consistency connects visits, streaks, and completed actions into a visible growth rhythm.',
    nextStep:
        'Return tomorrow and complete one small action to keep your rhythm alive.',
    signals: ['Current streak', 'Visits', 'Repeat practice'],
    targetTab: 0,
  ),
];

class _WellnessDetailCard extends StatelessWidget {
  const _WellnessDetailCard({
    required this.area,
    required this.score,
    required this.onOpen,
  });

  final _WellnessArea area;
  final int score;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: area.color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: area.color.withValues(alpha: .22)),
                ),
                child: Icon(area.icon, color: area.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$score% current score',
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
          const SizedBox(height: 14),
          Text(
            area.summary,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: area.signals
                .map(
                  (signal) => ActionChip(
                    label: Text(signal),
                    avatar: Icon(area.icon, size: 16, color: area.color),
                    onPressed: onOpen,
                    backgroundColor: AppColors.iconCream.withValues(alpha: .72),
                    side: BorderSide(color: area.color.withValues(alpha: .24)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.leaf.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.leaf.withValues(alpha: .18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Step',
                          style: TextStyle(
                            color: AppColors.deepEmerald,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          area.nextStep,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.deepEmerald,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Premium',
        style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w800, fontSize: 10),
      ),
    );
  }
}
