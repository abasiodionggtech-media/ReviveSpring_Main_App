import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'glass_panel.dart';
import 'section_header.dart';

class GrowthScoreCard extends StatelessWidget {
  const GrowthScoreCard({super.key, required this.growthScore});

  final Map<String, dynamic> growthScore;

  @override
  Widget build(BuildContext context) {
    final overall = (growthScore['overall'] as num?)?.toInt() ?? 0;
    final categories = (growthScore['categories'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (categories.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(title: 'Spiritual Growth Score', trailing: 'Live'),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: overall / 100,
                      strokeWidth: 8,
                      backgroundColor: AppColors.deepEmerald.withValues(alpha: .12),
                      color: AppColors.leaf,
                    ),
                    Text('$overall%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  overall >= 75
                      ? 'You are growing steadily across every area — keep going.'
                      : overall >= 40
                          ? 'Good progress. A little more consistency will lift your score.'
                          : 'Every small step counts. Pick one area below to focus on today.',
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category['label']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${category['score'] ?? 0}%',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.deepEmerald),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ((category['score'] as num?)?.toDouble() ?? 0) / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.deepEmerald.withValues(alpha: .1),
                      color: AppColors.sky,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
