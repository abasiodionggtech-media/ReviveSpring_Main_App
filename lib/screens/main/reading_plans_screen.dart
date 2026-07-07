import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/glass_panel.dart';

class ReadingPlansScreen extends StatefulWidget {
  const ReadingPlansScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ReadingPlansScreen> createState() => _ReadingPlansScreenState();
}

class _ReadingPlansScreenState extends State<ReadingPlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final plans = await widget.controller.api.getReadingPlans();
      if (mounted) setState(() => _plans = plans);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start(String id) async {
    setState(() => _busyId = id);
    try {
      await widget.controller.api.startReadingPlan(id);
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _checkOff(String id) async {
    setState(() => _busyId = id);
    try {
      final updated = await widget.controller.api.checkOffReadingPlanDay(id);
      if (!mounted) return;
      setState(() {
        final index = _plans.indexWhere((p) => p['id'] == id);
        if (index != -1) _plans[index] = updated;
      });
      if (updated['finished'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📖 Reading plan complete!'), backgroundColor: AppColors.deepEmerald),
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
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Bible Reading Plans')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: _plans.map((plan) {
                final days = (plan['days'] as List? ?? const []).map((d) => Map<String, dynamic>.from(d as Map)).toList();
                final daysCompleted = (plan['days_completed'] as num?)?.toInt() ?? 0;
                final duration = (plan['duration_days'] as num?)?.toInt() ?? days.length;
                final started = plan['started'] == true;
                final finished = plan['finished'] == true;
                final checkedInToday = plan['checked_in_today'] == true;
                final busy = _busyId == plan['id'];
                final currentDay = days.isNotEmpty && daysCompleted < days.length ? days[daysCompleted] : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(plan['description']?.toString() ?? '', style: const TextStyle(color: AppColors.muted, height: 1.4)),
                        if (started && !finished && currentDay != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.sky.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Day ${currentDay['day']}: ${currentDay['titleEn'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(currentDay['referenceEn']?.toString() ?? '', style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                        if (started) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (daysCompleted / (duration == 0 ? 1 : duration)).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: AppColors.deepEmerald.withValues(alpha: .12),
                              color: finished ? AppColors.leaf : AppColors.sky,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            finished ? 'Completed! 📖' : 'Day $daysCompleted of $duration',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.deepEmerald),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: !started
                              ? AnimatedPrimaryButton(
                                  label: 'Start Plan',
                                  icon: Icons.menu_book_outlined,
                                  busy: busy,
                                  onPressed: busy ? null : () => _start(plan['id'].toString()),
                                )
                              : finished
                                  ? OutlinedButton.icon(
                                      onPressed: null,
                                      icon: const Icon(Icons.check_circle, color: AppColors.leaf),
                                      label: const Text('Completed'),
                                    )
                                  : AnimatedPrimaryButton(
                                      label: checkedInToday ? "Today's reading done" : "Mark Today's Reading Done",
                                      icon: checkedInToday ? Icons.check : Icons.check_circle_outline,
                                      busy: busy,
                                      onPressed: (busy || checkedInToday) ? null : () => _checkOff(plan['id'].toString()),
                                    ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
