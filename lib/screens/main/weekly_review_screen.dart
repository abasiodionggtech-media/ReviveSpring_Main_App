import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  final _reflectionController = TextEditingController();
  Map<String, dynamic>? _review;
  bool _loading = true;
  bool _hasError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final review = await widget.controller.api.getWeeklyReview(language: widget.controller.language);
      if (mounted) {
        setState(() {
          _review = review;
          _reflectionController.text = review['user_reflection']?.toString() ?? '';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveReflection() async {
    final text = _reflectionController.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final review = await widget.controller.api.saveWeeklyReflection(text, language: widget.controller.language);
      if (mounted) setState(() => _review = review);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection saved.'), backgroundColor: AppColors.deepEmerald),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save your reflection. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = (_review?['stats'] as Map?) ?? {};
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Weekly Spiritual Review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, color: AppColors.coral, size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          "Couldn't load your weekly review right now.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                Text(
                  'Week of ${_review?['week_start_date'] ?? ''}',
                  style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 12),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Week', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 10),
                      Text(
                        (_review?['ai_summary'] as String?) ?? "Your week's reflection will appear here.",
                        style: const TextStyle(height: 1.55),
                      ),
                      if (stats.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _StatChip(label: 'Prayers', value: '${stats['prayers'] ?? 0}'),
                            _StatChip(label: 'Journal', value: '${stats['journalEntries'] ?? 0}'),
                            _StatChip(label: 'Goals done', value: '${stats['goalsCompleted'] ?? 0}'),
                            _StatChip(label: 'Streak', value: '${stats['currentStreak'] ?? 0}d'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Your Reflection', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'How was your week with God?',
                  icon: Icons.edit_note,
                  controller: _reflectionController,
                  minLines: 4,
                  maxLines: 8,
                ),
                const SizedBox(height: 12),
                AnimatedPrimaryButton(
                  label: _saving ? 'Saving...' : 'Save Reflection',
                  icon: Icons.check_circle_outline,
                  busy: _saving,
                  onPressed: _saving ? null : _saveReflection,
                ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.leafGreen.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.deepEmerald),
      ),
    );
  }
}
