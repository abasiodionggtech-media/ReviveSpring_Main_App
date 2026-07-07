import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class SeasonalEventBanner extends StatelessWidget {
  const SeasonalEventBanner({super.key, required this.events});

  final List<Map<String, dynamic>> events;

  static const _iconMap = {
    'celebration': Icons.celebration,
    'auto_awesome': Icons.auto_awesome,
    'church': Icons.church,
  };

  @override
  Widget build(BuildContext context) {
    final current = events.where((e) => e['is_current'] == true).toList();
    if (current.isEmpty) return const SizedBox.shrink();
    final event = current.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.coral.withValues(alpha: .16), AppColors.coral.withValues(alpha: .04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.coral.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(_iconMap[event['icon']] ?? Icons.celebration, color: AppColors.coral, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  event['description']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
