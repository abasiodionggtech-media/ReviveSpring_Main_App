import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  List<Map<String, dynamic>> _challenges = [];
  List<Map<String, dynamic>> _suggestions = [];
  final _suggestionController = TextEditingController();
  bool _loading = true;
  bool _submittingSuggestion = false;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.controller.api.getChallenges(),
        widget.controller.api.getChallengeSuggestions(),
      ]);
      if (mounted) {
        setState(() {
          _challenges = results[0];
          _suggestions = results[1];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitSuggestion() async {
    final text = _suggestionController.text.trim();
    if (text.isEmpty || _submittingSuggestion) return;
    setState(() => _submittingSuggestion = true);
    try {
      final suggestion = await widget.controller.api.submitChallengeSuggestion(text);
      if (mounted) {
        setState(() {
          _suggestions.insert(0, suggestion);
          _suggestionController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thank you! Your idea has been sent to our team and saved to your account."), backgroundColor: AppColors.deepEmerald),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't submit your idea right now. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingSuggestion = false);
    }
  }

  Future<void> _join(String id) async {
    setState(() => _busyId = id);
    try {
      await widget.controller.api.joinChallenge(id);
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _checkIn(String id) async {
    setState(() => _busyId = id);
    try {
      final updated = await widget.controller.api.checkInChallenge(id);
      if (!mounted) return;
      setState(() {
        final index = _challenges.indexWhere((c) => c['id'] == id);
        if (index != -1) _challenges[index] = updated;
      });
      if (updated['finished'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Challenge complete! Well done.'), backgroundColor: AppColors.deepEmerald),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Prayer Challenges')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                const Text(
                  'Join a multi-day challenge and check in once a day to build the habit.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                ..._challenges.map((challenge) {
                  final daysCompleted = (challenge['days_completed'] as num?)?.toInt() ?? 0;
                  final duration = (challenge['duration_days'] as num?)?.toInt() ?? 1;
                  final progress = (daysCompleted / duration).clamp(0.0, 1.0);
                  final enrolled = challenge['enrolled'] == true;
                  final finished = challenge['finished'] == true;
                  final checkedInToday = challenge['checked_in_today'] == true;
                  final busy = _busyId == challenge['id'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  challenge['title']?.toString() ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$duration days',
                                  style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w800, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            challenge['description']?.toString() ?? '',
                            style: const TextStyle(color: AppColors.muted, height: 1.4),
                          ),
                          if (enrolled) ...[
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: AppColors.deepEmerald.withValues(alpha: .12),
                                color: finished ? AppColors.leaf : AppColors.deepEmerald,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              finished ? 'Completed! 🎉' : 'Day $daysCompleted of $duration',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.deepEmerald),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: !enrolled
                                ? AnimatedPrimaryButton(
                                    label: 'Join Challenge',
                                    icon: Icons.emoji_events_outlined,
                                    busy: busy,
                                    onPressed: busy ? null : () => _join(challenge['id'].toString()),
                                  )
                                : finished
                                    ? OutlinedButton.icon(
                                        onPressed: null,
                                        icon: const Icon(Icons.check_circle, color: AppColors.leaf),
                                        label: const Text('Completed'),
                                      )
                                    : AnimatedPrimaryButton(
                                        label: checkedInToday ? "Checked in for today" : "Check In Today",
                                        icon: checkedInToday ? Icons.check : Icons.check_circle_outline,
                                        busy: busy,
                                        onPressed: (busy || checkedInToday) ? null : () => _checkIn(challenge['id'].toString()),
                                      ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text('Suggest Your Own Challenge', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text(
                  "Have an idea for a prayer challenge? Share it — we'll review it, and it's saved to your account so you can track it.",
                  style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
                ),
                const SizedBox(height: 12),
                GlassPanel(
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'e.g. "21 Days praying for our nation"',
                        icon: Icons.lightbulb_outline,
                        controller: _suggestionController,
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 10),
                      AnimatedPrimaryButton(
                        label: _submittingSuggestion ? 'Submitting...' : 'Submit Idea',
                        icon: Icons.send,
                        busy: _submittingSuggestion,
                        onPressed: _submittingSuggestion ? null : _submitSuggestion,
                      ),
                    ],
                  ),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text('Your Submitted Ideas', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 10),
                  ..._suggestions.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassPanel(
                          child: Row(
                            children: [
                              Expanded(child: Text(s['text']?.toString() ?? '', style: const TextStyle(height: 1.4))),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.sky.withValues(alpha: .16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  (s['status']?.toString() ?? 'submitted').toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.deepEmerald),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}
