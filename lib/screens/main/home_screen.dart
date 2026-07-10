import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../data/app_data.dart';
import '../../models/prayer_response.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/content_tiles.dart';
import '../../widgets/daily_checkin_modal.dart';
import '../../widgets/daily_manna_card.dart';
import '../../widgets/declaration_card.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/growth_score_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/seasonal_event_banner.dart';
import '../../widgets/verse_of_moment_dialog.dart';
import 'community_screen.dart';

const _prayerRecordSeconds = 15;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller, required this.onOpenAi, required this.onOpenPrayers});
  final AppController controller;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenPrayers;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int verseIndex = 0;
  Timer? quoteTimer;

  @override
  void initState() {
    super.initState();
    verseIndex = DateTime.now().minute % dailyVerses.length;
    quoteTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) setState(() => verseIndex = (verseIndex + 1) % dailyVerses.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowCheckIn());
  }

  void _maybeShowCheckIn() {
    if (!mounted) return;
    final controller = widget.controller;
    if (controller.hasCheckedInToday) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DailyCheckInModal(
        onSubmit: (mood, note) => controller.submitMoodCheckIn(mood, note: note),
      ),
    );
  }

  @override
  void dispose() {
    quoteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final done = controller.goals.where((goal) => goal.done).length;
    final stats = controller.analytics;
    final streakAtGrace = _isStreakAtGraceDay(stats);
    final animatedVerse = dailyVerses[verseIndex];
    return ListView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        SectionHeader(title: 'Good morning, ${controller.user?.fullName ?? 'Friend'}', subtitle: 'A fresh spring for your spirit today.'),
        const SizedBox(height: 18),
        SeasonalEventBanner(events: controller.seasonalEvents),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          child: VerseCard(key: ValueKey(animatedVerse.ref), verse: animatedVerse.verse, reference: animatedVerse.ref),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            StatTile(value: '${stats['totalPrayers'] ?? 0}', label: 'Prayers', icon: Icons.favorite_outline, color: AppColors.coral, onTap: widget.onOpenPrayers),
            StatTile(value: '${stats['currentStreak'] ?? 0}', label: streakAtGrace ? 'Streak · grace day' : 'Streak', icon: Icons.local_fire_department_outlined, color: AppColors.deepEmerald),
            StatTile(value: '${stats['visitCount'] ?? 0}', label: 'Visits', icon: Icons.login, color: AppColors.sky),
            const StatTile(value: '5', label: 'Answered', icon: Icons.check_circle_outline, color: AppColors.leaf),
          ],
        ),
        const SizedBox(height: 18),
        GrowthScoreCard(growthScore: controller.growthScore),
        const SizedBox(height: 18),
        DailyMannaCard(manna: controller.dailyManna, onClaim: controller.claimDailyManna),
        const SizedBox(height: 18),
        DeclarationCard(declaration: controller.todaysDeclaration, onConfirm: controller.confirmDeclaration),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => VerseOfMomentDialog(
              fetchVerse: controller.fetchRandomVerse,
              fetchBackgrounds: controller.api.getVerseBackgroundVideoUrls,
            ),
          ),
          icon: const Icon(Icons.touch_app_outlined),
          label: const Text('Verse of the Moment — tap for a fresh word', style: TextStyle(fontWeight: FontWeight.w800)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.deepEmerald,
            side: BorderSide(color: AppColors.deepEmerald.withValues(alpha: .35)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 18),
        MoodSelector(onSelected: (id) => _openPrayer(context, id)),
        const SizedBox(height: 18),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => CommunityScreen(controller: controller)),
          ),
          child: GlassPanel(
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.diversity_3_outlined, color: AppColors.coral),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Community', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('Prayer chain, testimonies, partners, groups & more', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedPrimaryButton(label: 'Open AI Prayer Companion', icon: Icons.auto_awesome, onPressed: widget.onOpenAi),
        const SizedBox(height: 18),
        GlassPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PanelHeader(title: "Today's Goals", trailing: '$done/${controller.goals.length}'),
          const SizedBox(height: 10),
          ...controller.goals.take(3).map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(goal.done ? Icons.check_circle : Icons.radio_button_unchecked, color: goal.done ? AppColors.leaf : AppColors.muted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(goal.text)),
                ]),
              )),
        ])),
      ],
    );
  }

  bool _isStreakAtGraceDay(Map<String, dynamic> stats) {
    if (stats['gracePeriodAvailable'] == false) return false;
    final lastActive = stats['lastActiveDate']?.toString();
    if (lastActive == null || lastActive.isEmpty) return false;
    final last = DateTime.tryParse(lastActive);
    if (last == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final lastOnly = DateTime(last.year, last.month, last.day);
    // Grace day = user was last active exactly two days ago (missed yesterday,
    // hasn't acted yet today) and their 1-day grace hasn't been spent.
    return todayOnly.difference(lastOnly).inDays == 2;
  }

  void _openPrayer(BuildContext context, String mood) {
    final response = prayerResponses[mood] ?? prayerResponses['anxious']!;
    showDialog<void>(
      context: context,
      builder: (_) => CenteredTimedPrayer(mood: mood, response: response, controller: widget.controller),
    );
  }
}

class CenteredTimedPrayer extends StatefulWidget {
  const CenteredTimedPrayer({super.key, required this.mood, required this.response, required this.controller});
  final String mood;
  final PrayerResponse response;
  final AppController controller;

  @override
  State<CenteredTimedPrayer> createState() => _CenteredTimedPrayerState();
}

class _CenteredTimedPrayerState extends State<CenteredTimedPrayer> {
  Timer? timer;
  int elapsed = 0;
  bool recorded = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || recorded) return;
      setState(() => elapsed++);
      if (elapsed >= _prayerRecordSeconds) {
        recorded = true;
        await widget.controller.recordPrayer(widget.mood, widget.response, elapsed);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_prayerRecordSeconds - elapsed).clamp(0, _prayerRecordSeconds);
    final mood = moodForId(widget.mood);
    return Dialog(
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.all(22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: mood.color.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mood.color.withValues(alpha: .22)),
              ),
              child: Icon(mood.icon, color: mood.color),
            ),
            Expanded(child: Text(widget.response.encouragement, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 12),
          Text('"${widget.response.verse}"', style: const TextStyle(color: AppColors.deepEmerald, height: 1.5)),
          Text(widget.response.ref, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          Text(widget.response.prayer, style: const TextStyle(height: 1.55)),
          const SizedBox(height: 14),
          Text(widget.response.action, style: const TextStyle(color: AppColors.leaf)),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: recorded ? 1 : elapsed / _prayerRecordSeconds, color: AppColors.leaf),
          const SizedBox(height: 10),
          Text(recorded ? 'Prayer recorded.' : 'Stay in this prayer for $remaining more seconds to record it.', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
