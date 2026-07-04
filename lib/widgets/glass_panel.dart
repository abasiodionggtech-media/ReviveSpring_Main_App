import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.deepEmerald.withValues(alpha: .09)),
        boxShadow: [BoxShadow(color: AppColors.deepEmerald.withValues(alpha: .12), blurRadius: 24, offset: const Offset(0, 14))],
      ),
      child: child,
    );
  }
}
