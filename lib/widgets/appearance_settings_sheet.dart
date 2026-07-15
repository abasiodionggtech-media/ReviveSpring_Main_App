import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/app_controller.dart';
import '../core/app_tokens.dart';
import '../core/app_typography.dart';

class AppearanceSettingsSheet {
  static Future<void> show(BuildContext context, AppController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppearanceSheetBody(controller: controller),
    );
  }
}

class _AppearanceSheetBody extends StatefulWidget {
  const _AppearanceSheetBody({required this.controller});

  final AppController controller;

  @override
  State<_AppearanceSheetBody> createState() => _AppearanceSheetBodyState();
}

class _AppearanceSheetBodyState extends State<_AppearanceSheetBody> {
  late String _selectedFont = widget.controller.fontFamily;
  late double _selectedScale = widget.controller.fontScale;
  bool _savingFont = false;
  bool _savingScale = false;

  Future<void> _applyFont(String fontId) async {
    if (fontId == _selectedFont || _savingFont) return;
    setState(() {
      _selectedFont = fontId;
      _savingFont = true;
    });
    final error = await widget.controller.updateFontFamily(fontId);
    if (!mounted) return;
    setState(() => _savingFont = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _applyScale(double scale) async {
    setState(() {
      _selectedScale = scale;
      _savingScale = true;
    });
    final error = await widget.controller.updateFontScale(scale);
    if (!mounted) return;
    setState(() => _savingScale = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .82),
        decoration: const BoxDecoration(
          color: AppColors.iconCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.deepEmerald.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Appearance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text(
              'Choose a font and text size for the whole app. New fonts download once, then stay cached on your device.',
              style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Text(
              'Text Size',
              style: GoogleFonts.getFont(_selectedFont, fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.deepEmerald),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                Expanded(
                  child: Slider(
                    value: _selectedScale,
                    min: 0.85,
                    max: 1.3,
                    divisions: 9,
                    activeColor: AppColors.deepEmerald,
                    label: '${(_selectedScale * 100).round()}%',
                    onChanged: (value) => setState(() => _selectedScale = value),
                    onChangeEnd: _applyScale,
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 20, color: AppColors.muted)),
                if (_savingScale) ...[
                  const SizedBox(width: 8),
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.leafGreen.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Come as you are — this is your daily space for prayer and peace.',
                style: GoogleFonts.getFont(
                  _selectedFont,
                  fontSize: 15 * _selectedScale,
                  height: 1.4,
                  color: AppColors.deepEmerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text('Font', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.deepEmerald)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableFonts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final font = availableFonts[index];
                  final selected = font.id == _selectedFont;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => _applyFont(font.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.leafGreen.withValues(alpha: .12) : AppColors.iconCream.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: selected ? AppColors.deepEmerald : Colors.transparent, width: 1.4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  font.label,
                                  style: GoogleFonts.getFont(font.id, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(font.description, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (selected && _savingFont)
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          else if (selected)
                            const Icon(Icons.check_circle, color: AppColors.deepEmerald),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
