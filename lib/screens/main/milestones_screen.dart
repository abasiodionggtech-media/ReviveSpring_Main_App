import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';

class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  List<Map<String, dynamic>> _milestones = [];
  bool _loading = true;

  static const _iconMap = {
    'favorite': Icons.favorite,
    'military_tech': Icons.military_tech,
    'local_fire_department': Icons.local_fire_department,
    'check_circle': Icons.check_circle,
    'edit_note': Icons.edit_note,
    'no_food': Icons.no_food,
    'emoji_events': Icons.emoji_events,
    'menu_book': Icons.menu_book,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.controller.api.checkMilestones();
      final list = (result['milestones'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (mounted) setState(() => _milestones = list);

      final newlyAwarded = (result['newlyAwarded'] as List? ?? const []).cast<String>();
      if (newlyAwarded.isNotEmpty && mounted) {
        final titles = list
            .where((m) => newlyAwarded.contains(m['key']))
            .map((m) => m['titleEn']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .join(', ');
        if (titles.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('🎉 New badge earned: $titles'), backgroundColor: AppColors.deepEmerald),
            );
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Faith Milestones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .85,
              ),
              itemCount: _milestones.length,
              itemBuilder: (context, index) {
                final milestone = _milestones[index];
                final achieved = milestone['achieved'] == true;
                final progress = (milestone['progress'] as num?)?.toDouble() ?? 0;
                final icon = _iconMap[milestone['icon']?.toString()] ?? Icons.emoji_events;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: achieved ? AppColors.leafGreen.withValues(alpha: .12) : AppColors.iconCream.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: achieved ? AppColors.leafGreen : Colors.transparent, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: achieved ? AppColors.leafGreen : AppColors.muted.withValues(alpha: .15),
                        ),
                        child: Icon(
                          achieved ? icon : Icons.lock_outline,
                          color: achieved ? AppColors.iconCream : AppColors.muted,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        milestone['titleEn']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: achieved ? AppColors.deepEmerald : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        milestone['descriptionEn']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
                      ),
                      if (!achieved) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: AppColors.muted.withValues(alpha: .15),
                            color: AppColors.deepEmerald,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
