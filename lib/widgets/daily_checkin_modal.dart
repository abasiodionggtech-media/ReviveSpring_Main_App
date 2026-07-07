import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_data.dart';

class DailyCheckInModal extends StatefulWidget {
  const DailyCheckInModal({super.key, required this.onSubmit});

  final Future<void> Function(String mood, String? note) onSubmit;

  @override
  State<DailyCheckInModal> createState() => _DailyCheckInModalState();
}

class _DailyCheckInModalState extends State<DailyCheckInModal> {
  String? selectedMood;
  final noteController = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final mood = selectedMood;
    if (mood == null || saving) return;
    setState(() => saving = true);
    try {
      await widget.onSubmit(mood, noteController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your check-in. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.all(22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('How are you today?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Your daily check-in takes a few seconds.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: moods.map((mood) {
                final selected = mood.id == selectedMood;
                return ChoiceChip(
                  selected: selected,
                  label: Text(mood.en),
                  avatar: Icon(mood.icon, size: 16, color: selected ? AppColors.iconCream : mood.color),
                  selectedColor: mood.color,
                  backgroundColor: AppColors.iconCream.withValues(alpha: .7),
                  labelStyle: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.iconCream : AppColors.ink),
                  side: BorderSide(color: mood.color.withValues(alpha: .35)),
                  onSelected: (_) => setState(() => selectedMood = mood.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a quick note (optional)',
                filled: true,
                fillColor: AppColors.glass,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selectedMood == null || saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepEmerald,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.iconCream))
                    : const Text('Save check-in', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
