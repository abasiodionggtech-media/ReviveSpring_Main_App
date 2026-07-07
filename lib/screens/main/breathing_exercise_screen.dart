import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';

enum _BreathPhase { inhale, hold, exhale }

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  static const _phaseSeconds = {
    _BreathPhase.inhale: 4,
    _BreathPhase.hold: 7,
    _BreathPhase.exhale: 8,
  };

  static const _prayers = [
    'Lord, breathe Your peace into me.',
    'I release my worry into Your hands.',
    'You are near to me in this moment.',
    'Fill me with Your calm and quiet strength.',
    'I trust You with what I cannot control.',
  ];

  late final AnimationController _controller;
  _BreathPhase _phase = _BreathPhase.inhale;
  Timer? _phaseTimer;
  int _cycles = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _startPhase(_BreathPhase.inhale);
  }

  void _startPhase(_BreathPhase phase) {
    _phaseTimer?.cancel();
    if (!mounted) return;
    setState(() => _phase = phase);
    HapticFeedback.lightImpact();

    final seconds = _phaseSeconds[phase]!;
    final begin = phase == _BreathPhase.exhale ? 1.0 : (phase == _BreathPhase.inhale ? 0.4 : 1.0);
    final end = phase == _BreathPhase.exhale ? 0.4 : 1.0;
    _controller
      ..stop()
      ..value = begin
      ..animateTo(
        end,
        duration: Duration(seconds: phase == _BreathPhase.hold ? 0 : seconds),
        curve: Curves.easeInOut,
      );

    _phaseTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || !_running) return;
      switch (phase) {
        case _BreathPhase.inhale:
          _startPhase(_BreathPhase.hold);
          break;
        case _BreathPhase.hold:
          _startPhase(_BreathPhase.exhale);
          break;
        case _BreathPhase.exhale:
          setState(() => _cycles += 1);
          _startPhase(_BreathPhase.inhale);
          break;
      }
    });
  }

  void _togglePause() {
    setState(() => _running = !_running);
    if (_running) {
      _startPhase(_phase);
    } else {
      _phaseTimer?.cancel();
      _controller.stop();
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case _BreathPhase.inhale:
        return 'Breathe in...';
      case _BreathPhase.hold:
        return 'Hold...';
      case _BreathPhase.exhale:
        return 'Breathe out...';
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayer = _prayers[_cycles % _prayers.length];
    return Scaffold(
      backgroundColor: AppColors.deepEmerald,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '4-7-8 Breathing',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Cycle $_cycles',
              style: TextStyle(color: Colors.white.withValues(alpha: .6), fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final scale = 0.65 + (_controller.value * 0.55);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.sproutGreen.withValues(alpha: .55),
                          AppColors.sproutGreen.withValues(alpha: .08),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: .35), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _phaseLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  '"$prayer"',
                  key: ValueKey(prayer),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: IconButton(
                onPressed: _togglePause,
                icon: Icon(
                  _running ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
