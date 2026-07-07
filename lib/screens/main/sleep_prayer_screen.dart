import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class SleepPrayerScreen extends StatefulWidget {
  const SleepPrayerScreen({super.key});

  @override
  State<SleepPrayerScreen> createState() => _SleepPrayerScreenState();
}

class _SleepPrayerScreenState extends State<SleepPrayerScreen> {
  static const _prayers = [
    (
      'Lord, as I close my eyes tonight, I release every worry from today into Your hands. '
          'Watch over me as I sleep, and let me wake refreshed in Your peace.',
      'Psalm 4:8',
      'I will lie down and sleep in peace, for you alone, Lord, make me dwell in safety.',
    ),
    (
      'Father, quiet my racing thoughts. Let Your presence surround this room, and let sleep come '
          'gently as a gift from You.',
      'Proverbs 3:24',
      'When you lie down, you will not be afraid; when you lie down, your sleep will be sweet.',
    ),
    (
      'God, thank You for this day, its joys and its hard parts alike. Tonight I rest in knowing '
          'You are awake even when I am not.',
      'Psalm 121:4',
      'He who watches over Israel will neither slumber nor sleep.',
    ),
    (
      'Lord, cover my mind with calm. Take every anxious thought and replace it with trust in '
          'Your unfailing care.',
      '1 Peter 5:7',
      'Cast all your anxiety on him because he cares for you.',
    ),
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 14), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _prayers.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (prayer, reference, verse) = _prayers[_index];
    return Scaffold(
      backgroundColor: const Color(0xFF090D0C),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: Colors.white.withValues(alpha: .7)),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 900),
                    child: Column(
                      key: ValueKey(_index),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.nightlight_round, color: Colors.white.withValues(alpha: .35), size: 34),
                        const SizedBox(height: 28),
                        Text(
                          prayer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .82),
                            fontSize: 18,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          '"$verse"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .5),
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reference,
                          style: TextStyle(
                            color: AppColors.sproutGreen.withValues(alpha: .8),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                'Rest well. A new prayer follows every 14 seconds.',
                style: TextStyle(color: Colors.white.withValues(alpha: .3), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
