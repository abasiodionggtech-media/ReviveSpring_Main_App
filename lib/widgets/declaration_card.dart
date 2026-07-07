import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'glass_panel.dart';
import 'section_header.dart';

class DeclarationCard extends StatefulWidget {
  const DeclarationCard({super.key, required this.declaration, required this.onConfirm});

  final Map<String, dynamic> declaration;
  final Future<void> Function() onConfirm;

  @override
  State<DeclarationCard> createState() => _DeclarationCardState();
}

class _DeclarationCardState extends State<DeclarationCard> {
  bool confirming = false;

  Future<void> _confirm() async {
    if (confirming || confirmed) return;
    setState(() => confirming = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) setState(() => confirming = false);
    }
  }

  bool get confirmed => widget.declaration['confirmedToday'] == true;

  @override
  Widget build(BuildContext context) {
    final text = widget.declaration['declaration']?['text']?.toString();
    final streak = (widget.declaration['streak'] ?? 0) as int;
    if (text == null) return const SizedBox.shrink();

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(title: 'Today\'s Declaration', trailing: streak > 0 ? '$streak-day streak' : 'Today'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.leafGreen.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.leafGreen.withValues(alpha: .28)),
            ),
            child: Text(
              '"$text"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, height: 1.4, color: AppColors.deepEmerald),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: confirmed || confirming ? null : _confirm,
              icon: Icon(confirmed ? Icons.check_circle : Icons.record_voice_over_outlined),
              label: Text(
                confirmed
                    ? 'Declared today'
                    : confirming
                        ? 'Confirming...'
                        : 'I declare this over my life',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.deepEmerald,
                side: BorderSide(color: AppColors.deepEmerald.withValues(alpha: .4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
