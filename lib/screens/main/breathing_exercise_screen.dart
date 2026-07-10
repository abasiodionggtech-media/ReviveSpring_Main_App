import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../widgets/gentle_float.dart';

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
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  void _begin() {
    setState(() => _started = true);
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

    if (!_started) {
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.self_improvement, color: Colors.white70, size: 42),
                      const SizedBox(height: 20),
                      const Text(
                        '4-7-8 Breathing',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "We're here to help you find calm and peace within your heart and soul. This simple rhythm — breathe in for 4 seconds, hold for 7, breathe out for 8 — gives your body a moment to settle, while short prayers guide your thoughts back to God.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: .82), height: 1.5, fontSize: 15),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Find a quiet spot, get comfortable, and when you're ready, we'll begin together.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: .82), height: 1.5, fontSize: 15),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _begin,
                          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.deepEmerald),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Begin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                        stops: const [0.0, 0.55, 0.85, 1.0],
                        colors: [
                          AppColors.sproutGreen.withValues(alpha: .6),
                          AppColors.sproutGreen.withValues(alpha: .32),
                          AppColors.sproutGreen.withValues(alpha: .08),
                          AppColors.sproutGreen.withValues(alpha: 0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sproutGreen.withValues(alpha: .25),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
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
                child: GentleFloat(
                  key: ValueKey(prayer),
                  child: Text(
                    '"$prayer"',
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
