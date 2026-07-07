import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/glass_panel.dart';

class FastingTrackerScreen extends StatefulWidget {
  const FastingTrackerScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<FastingTrackerScreen> createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  Map<String, dynamic>? _active;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  bool _busy = false;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  static const _types = [
    ('water', 'Water Fast'),
    ('daniel', 'Daniel Fast'),
    ('partial', 'Partial Fast'),
    ('full', 'Full Fast'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_active == null) return;
    final startedAt = DateTime.tryParse(_active!['started_at']?.toString() ?? '');
    if (startedAt == null) return;
    if (mounted) setState(() => _elapsed = DateTime.now().toUtc().difference(startedAt.toUtc()));
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.controller.api.getActiveFast(),
        widget.controller.api.getFasts(),
      ]);
      if (!mounted) return;
      setState(() {
        _active = results[0] as Map<String, dynamic>?;
        _history = results[1] as List<Map<String, dynamic>>;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start(String type) async {
    setState(() => _busy = true);
    try {
      final fast = await widget.controller.api.startFast(type);
      if (mounted) setState(() => _active = fast);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end({required bool completed}) async {
    if (_active == null) return;
    setState(() => _busy = true);
    try {
      await widget.controller.api.endFast(_active!['id'].toString(), completed: completed);
      if (mounted) setState(() => _active = null);
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Fasting Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                if (_active != null) ...[
                  GlassPanel(
                    child: Column(
                      children: [
                        Text(
                          _types.firstWhere((t) => t.$1 == _active!['fast_type'], orElse: () => ('', 'Fast')).$2,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _formatDuration(_elapsed),
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.deepEmerald, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Goal: ${_active!['goal_hours']} hours',
                          style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy ? null : () => _end(completed: false),
                                child: const Text('Break Fast'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AnimatedPrimaryButton(
                                label: 'Complete',
                                icon: Icons.check_circle_outline,
                                busy: _busy,
                                onPressed: _busy ? null : () => _end(completed: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Choose a fast type to begin. Your timer will keep running even if you close the app.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ..._types.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _start(type.$1),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text(type.$2, style: const TextStyle(fontWeight: FontWeight.w700))],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_history.isNotEmpty) ...[
                  const Text('History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 12),
                  ..._history.map((fast) {
                    final status = fast['status']?.toString() ?? '';
                    final typeLabel = _types.firstWhere((t) => t.$1 == fast['fast_type'], orElse: () => ('', 'Fast')).$2;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassPanel(
                        child: Row(
                          children: [
                            Icon(
                              status == 'completed' ? Icons.check_circle : (status == 'broken' ? Icons.cancel_outlined : Icons.hourglass_top),
                              color: status == 'completed' ? AppColors.leaf : (status == 'broken' ? AppColors.coral : AppColors.muted),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(
                                    status[0].toUpperCase() + status.substring(1),
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
