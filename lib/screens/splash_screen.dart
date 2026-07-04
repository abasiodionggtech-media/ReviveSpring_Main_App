import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_controller.dart';
import '../core/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 4300), () {
      if (mounted) widget.controller.completeSplash();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.controller.language;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _AnimatedLogo(),
                const SizedBox(height: 28),
                const Text('REVIVESPRING', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: .8)),
                const SizedBox(height: 10),
                Text(
                  AppStrings.of(
                    language,
                    'Revive Your Spirit. Renew Your Day.',
                    'Ranimez votre esprit. Renouvelez votre journee.',
                  ),
                  style: const TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 34),
                const _LoadingBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pulse = .96 + math.sin(controller.value * math.pi * 2) * .04;
        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: 174,
            height: 174,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: controller.value * math.pi * 2,
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.sproutGreen.withValues(alpha: .7), width: 2),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -controller.value * math.pi * 2,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.deepEmerald.withValues(alpha: .35), width: 3),
                    ),
                  ),
                ),
                Container(
                  width: 116,
                  height: 116,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.iconCream,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: AppColors.deepEmerald.withValues(alpha: .25), blurRadius: 34, offset: const Offset(0, 16))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1450))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 8,
      decoration: BoxDecoration(color: AppColors.deepEmerald.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: .28 + controller.value * .64,
          child: Container(decoration: BoxDecoration(color: AppColors.deepEmerald, borderRadius: BorderRadius.circular(99))),
        ),
      ),
    );
  }
}
