import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
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
      builder: (context, _) {
        final t = controller.value * math.pi * 2;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFF8FBF9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              _Orb(size: 210, color: AppColors.deepEmerald.withValues(alpha: .09), left: -60 + math.sin(t) * 18, top: 70 + math.cos(t) * 24),
              _Orb(size: 170, color: AppColors.leafGreen.withValues(alpha: .14), right: -45 + math.cos(t * .7) * 22, bottom: 130 + math.sin(t * .8) * 18),
              _Orb(size: 130, color: AppColors.sproutGreen.withValues(alpha: .18), right: 40 + math.sin(t * 1.2) * 16, top: 260 + math.cos(t) * 18),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color, this.left, this.top, this.right, this.bottom});

  final double size;
  final Color color;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color, blurRadius: 60, spreadRadius: 12)],
          ),
        ),
      ),
    );
  }
}
