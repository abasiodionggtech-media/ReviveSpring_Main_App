import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../models/goal_item.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/section_header.dart';
import 'challenges_screen.dart';
import 'memory_cards_screen.dart';
import 'reading_plans_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('goals'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        const SectionHeader(title: 'Daily Goals', subtitle: 'Open each activity and complete the faithful step.', icon: Icons.flag),
        const SizedBox(height: 18),
        ...controller.goals.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: goal.done ? null : () => showDialog<void>(context: context, builder: (_) => _GoalActivity(goal: goal, controller: controller)),
              child: GlassPanel(
                child: Row(
                  children: [
                    Icon(goal.done ? Icons.check_circle : Icons.flag_outlined, color: goal.done ? AppColors.leaf : AppColors.deepEmerald),
                    const SizedBox(width: 12),
                    Expanded(child: Text(goal.text, style: TextStyle(decoration: goal.done ? TextDecoration.lineThrough : null))),
                    if (!goal.done) const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SectionHeader(title: 'Structured Growth', subtitle: 'Build a deeper habit over days and weeks.', icon: Icons.trending_up),
        const SizedBox(height: 18),
        _GrowthTile(
          title: 'Prayer Challenges',
          subtitle: 'Join a multi-day prayer challenge and check in daily.',
          icon: Icons.emoji_events_outlined,
          color: AppColors.coral,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChallengesScreen(controller: controller))),
        ),
        const SizedBox(height: 12),
        _GrowthTile(
          title: 'Fasting Tracker',
          subtitle: 'Coming soon.',
          icon: Icons.no_food_outlined,
          color: AppColors.leaf,
          badge: 'Soon',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fasting Tracker is coming soon! We're still polishing this one.")),
          ),
        ),
        const SizedBox(height: 12),
        _GrowthTile(
          title: 'Bible Reading Plan',
          subtitle: 'Follow a guided plan through Scripture, one day at a time.',
          icon: Icons.menu_book_outlined,
          color: AppColors.sky,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReadingPlansScreen(controller: controller))),
        ),
        const SizedBox(height: 12),
        _GrowthTile(
          title: 'Scripture Memory Cards',
          subtitle: 'Flashcard your way to memorizing verses, then take the 7-day quiz.',
          icon: Icons.style_outlined,
          color: AppColors.deepEmerald,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MemoryCardsScreen(controller: controller))),
        ),
      ],
    );
  }
}

class _GrowthTile extends StatelessWidget {
  const _GrowthTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

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
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
                child: Text(badge!.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.deepEmerald)),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

class _GoalActivity extends StatefulWidget {
  const _GoalActivity({required this.goal, required this.controller});
  final GoalItem goal;
  final AppController controller;

  @override
  State<_GoalActivity> createState() => _GoalActivityState();
}

class _GoalActivityState extends State<_GoalActivity> {
  Timer? timer;
  int elapsed = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => elapsed++));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (widget.goal.durationSeconds - elapsed).clamp(0, widget.goal.durationSeconds);
    return AlertDialog(
      title: Text(widget.goal.text),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.goal.content ?? 'Take a quiet moment to complete this activity faithfully.', style: const TextStyle(height: 1.5)),
        const SizedBox(height: 18),
        Text(remaining == 0 ? 'Ready to mark complete.' : 'Stay here for $remaining more seconds.', style: const TextStyle(color: AppColors.leaf, fontWeight: FontWeight.w800)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          onPressed: remaining > 0 ? null : () async { await widget.controller.completeGoal(widget.goal, elapsed); if (context.mounted) Navigator.pop(context); },
          child: const Text('Complete'),
        ),
      ],
    );
  }
}
