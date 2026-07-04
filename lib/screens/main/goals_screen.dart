import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../models/goal_item.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/section_header.dart';

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
      ],
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
