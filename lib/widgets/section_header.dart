import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'floating_badge.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.subtitle, this.icon = Icons.auto_awesome});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
        FloatingBadge(icon: icon, size: 52, color: AppColors.leaf),
      ],
    );
  }
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({super.key, required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.deepEmerald.withValues(alpha: .14), borderRadius: BorderRadius.circular(999)),
          child: Text(trailing, style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ],
    );
  }
}
