import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class SermonSummarizerScreen extends StatefulWidget {
  const SermonSummarizerScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SermonSummarizerScreen> createState() => _SermonSummarizerScreenState();
}

class _SermonSummarizerScreenState extends State<SermonSummarizerScreen> {
  final _textController = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<void> _summarize() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.controller.api.summarizeSermon(text, language: widget.controller.language);
      if (mounted) setState(() => _result = result);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.statusCode == 403
            ? 'AI Sermon Summarizer is a Premium feature.'
            : error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't summarize right now. Please try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final keyPoints = (result?['keyPoints'] as List? ?? const []).cast<String>();
    final plan = (result?['plan'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('AI Sermon Summarizer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          const Text(
            'Paste your sermon notes or a rough transcript to get a summary and a 3-day application plan.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Paste sermon notes here...',
            icon: Icons.description_outlined,
            controller: _textController,
            minLines: 5,
            maxLines: 10,
          ),
          const SizedBox(height: 14),
          AnimatedPrimaryButton(
            label: _loading ? 'Summarizing...' : 'Summarize Sermon',
            icon: Icons.summarize_outlined,
            busy: _loading,
            onPressed: _loading ? null : _summarize,
          ),
          const SizedBox(height: 18),
          if (_error != null)
            GlassPanel(child: Text(_error!, style: const TextStyle(color: AppColors.coral, height: 1.4))),
          if (result != null) ...[
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(result['summary']?.toString() ?? '', style: const TextStyle(height: 1.5)),
                  if (keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('Key Points', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.deepEmerald)),
                    const SizedBox(height: 8),
                    ...keyPoints.map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 6, color: AppColors.deepEmerald),
                            const SizedBox(width: 8),
                            Expanded(child: Text(point, style: const TextStyle(height: 1.4))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...plan.map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day ${day['day']}: ${day['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(day['action']?.toString() ?? '', style: const TextStyle(color: AppColors.muted, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
