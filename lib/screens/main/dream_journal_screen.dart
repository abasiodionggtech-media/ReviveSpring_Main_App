import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class DreamJournalScreen extends StatefulWidget {
  const DreamJournalScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  final _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final entries = await widget.controller.api.getDreamJournal();
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final entry = await widget.controller.api.submitDreamEntry(description, language: widget.controller.language);
      if (mounted) {
        setState(() {
          _entries.insert(0, entry);
          _descriptionController.clear();
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.statusCode == 403
            ? 'AI Dream/Vision Journal is a Premium feature.'
            : error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't save your entry right now. Please try again.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Dream & Vision Journal')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                const Text(
                  'Describe a dream or vision. Reflections offered here are for prayerful consideration, not certain interpretation.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Describe your dream or vision...',
                  icon: Icons.nights_stay_outlined,
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 8,
                ),
                const SizedBox(height: 14),
                AnimatedPrimaryButton(
                  label: _submitting ? 'Reflecting...' : 'Get a Reflection',
                  icon: Icons.auto_awesome,
                  busy: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  GlassPanel(child: Text(_error!, style: const TextStyle(color: AppColors.coral, height: 1.4))),
                ],
                const SizedBox(height: 22),
                if (_entries.isNotEmpty) const Text('Past Entries', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 12),
                ..._entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(entry['content']?.toString() ?? '', style: const TextStyle(color: AppColors.muted, height: 1.4)),
                          if ((entry['ai_interpretation'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.leafGreen.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(entry['ai_interpretation'].toString(), style: const TextStyle(height: 1.4)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
