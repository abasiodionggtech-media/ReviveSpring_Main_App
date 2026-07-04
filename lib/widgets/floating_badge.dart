import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class FloatingBadge extends StatefulWidget {
  const FloatingBadge({super.key, required this.icon, this.size = 70, this.color = AppColors.deepEmerald});

  final IconData icon;
  final double size;
  final Color color;

  @override
  State<FloatingBadge> createState() => _FloatingBadgeState();
}

class _FloatingBadgeState extends State<FloatingBadge> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    final badge = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * .28),
        gradient: LinearGradient(colors: [widget.color, widget.color.withValues(alpha: .62)]),
        boxShadow: [BoxShadow(color: widget.color.withValues(alpha: .3), blurRadius: 38, offset: const Offset(0, 18))],
      ),
      child: Icon(widget.icon, size: widget.size * .46, color: AppColors.iconCream),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .16), end: Offset.zero).animate(curve),
        child: badge,
      ),
    );
  }
}
