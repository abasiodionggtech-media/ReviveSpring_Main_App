import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class AiPrayerWriterScreen extends StatefulWidget {
  const AiPrayerWriterScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AiPrayerWriterScreen> createState() => _AiPrayerWriterScreenState();
}

class _AiPrayerWriterScreenState extends State<AiPrayerWriterScreen> {
  final _descriptionController = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<void> _generate() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.controller.api.writeAiPrayer(
        description,
        language: widget.controller.language,
      );
      if (mounted) setState(() => _result = result);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.statusCode == 403
            ? 'AI Prayer Writer is a Premium feature.'
            : error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't write a prayer right now. Please try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        elevation: 0,
        title: const Text('AI Prayer Writer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          const Text(
            'Describe what\'s on your heart, and get a personalized written prayer.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'e.g. "my son is starting a new job and I\'m anxious for him"',
            icon: Icons.edit_note,
            controller: _descriptionController,
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: 14),
          AnimatedPrimaryButton(
            label: _loading ? 'Writing your prayer...' : 'Write My Prayer',
            icon: Icons.auto_awesome,
            busy: _loading,
            onPressed: _loading ? null : _generate,
          ),
          const SizedBox(height: 18),
          if (_error != null)
            GlassPanel(
              child: Text(_error!, style: const TextStyle(color: AppColors.coral, height: 1.4)),
            ),
          if (_result != null)
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _result!['prayer']?.toString() ?? '',
                    style: const TextStyle(height: 1.55, fontSize: 15),
                  ),
                  if ((_result!['verse'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.leafGreen.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('"${_result!['verse']}"', style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4)),
                          const SizedBox(height: 6),
                          Text(
                            _result!['verseRef']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepEmerald),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Saved to your prayers — you can mark it answered later from the Journal.',
                    style: TextStyle(color: AppColors.muted.withValues(alpha: .8), fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
