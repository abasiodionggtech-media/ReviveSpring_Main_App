import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/gentle_float.dart';

class PrayerRoomScreen extends StatefulWidget {
  const PrayerRoomScreen({super.key});

  @override
  State<PrayerRoomScreen> createState() => _PrayerRoomScreenState();
}

class _PrayerRoomScreenState extends State<PrayerRoomScreen> with SingleTickerProviderStateMixin {
  static const _durations = [5, 10, 15, 20];
  static const _prompts = [
    'Come as you are. There is nothing you need to fix before entering this space.',
    'Bring to mind one thing you are grateful for today.',
    'Rest in silence for a moment. He is near.',
    'Bring your worries here and lay them down, one by one.',
    'Whisper the name of someone you want to pray for.',
    'Let your breathing slow. There is no rush in this room.',
  ];

  int? _selectedMinutes;
  int _secondsLeft = 0;
  Timer? _timer;
  int _promptIndex = 0;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }

  void _start(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _secondsLeft = minutes * 60;
      _promptIndex = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) {
          _timer?.cancel();
        } else if (_secondsLeft % 45 == 0) {
          _promptIndex = (_promptIndex + 1) % _prompts.length;
        }
      });
    });
  }

  void _end() {
    _timer?.cancel();
    setState(() {
      _selectedMinutes = null;
      _secondsLeft = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final inSession = _selectedMinutes != null;
    final finished = inSession && _secondsLeft <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F1A),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: Colors.white.withValues(alpha: .8)),
              ),
            ),
            Expanded(
              child: Center(
                child: inSession
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              final scale = 0.9 + (_glowController.value * 0.25);
                              return Transform.scale(scale: scale, child: child);
                            },
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.sproutGreen.withValues(alpha: .45),
                                    AppColors.sproutGreen.withValues(alpha: .05),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            finished ? 'Amen.' : _format(_secondsLeft),
                            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: GentleFloat(
                                key: ValueKey(finished ? -1 : _promptIndex),
                                child: Text(
                                  finished ? 'Thank You for this time with You, Lord.' : _prompts[_promptIndex],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 16, height: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextButton(
                            onPressed: _end,
                            child: Text(
                              finished ? 'Close' : 'End session',
                              style: TextStyle(color: Colors.white.withValues(alpha: .6)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.self_improvement, color: Colors.white, size: 40),
                          const SizedBox(height: 18),
                          const Text(
                            'The Prayer Room',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'An immersive, quiet space to sit with God. Choose how long you\'d like to stay.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: .7), height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 12,
                            alignment: WrapAlignment.center,
                            children: _durations.map((minutes) {
                              return OutlinedButton(
                                onPressed: () => _start(minutes),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: .4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text('$minutes min'),
                              );
                            }).toList(),
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
}
