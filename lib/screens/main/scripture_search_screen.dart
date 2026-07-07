import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class ScriptureSearchScreen extends StatefulWidget {
  const ScriptureSearchScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ScriptureSearchScreen> createState() => _ScriptureSearchScreenState();
}

class _ScriptureSearchScreenState extends State<ScriptureSearchScreen> {
  final _topicController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  String? _closingPrayer;
  bool _loading = false;
  bool _searchedOnce = false;
  int? _remainingToday;
  String? _error;

  static const _suggestions = [
    'Dealing with fear',
    'Forgiveness',
    'Waiting on God',
    'Financial provision',
    'Healing',
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await widget.controller.api.getScriptureSearchStatus();
      if (mounted) setState(() => _remainingToday = status['remainingToday'] as int?);
    } catch (_) {}
  }

  Future<void> _search([String? suggestion]) async {
    final topic = (suggestion ?? _topicController.text).trim();
    if (topic.isEmpty || _loading) return;
    if (suggestion != null) _topicController.text = suggestion;
    setState(() {
      _loading = true;
      _error = null;
      _searchedOnce = true;
      _closingPrayer = null;
    });
    try {
      final result = await widget.controller.api.searchScripture(
        topic,
        language: widget.controller.language,
      );
      if (!mounted) return;
      setState(() {
        _results = (result['results'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _closingPrayer = (result['closingPrayer'] as String?)?.trim().isNotEmpty == true
            ? result['closingPrayer'] as String
            : null;
        _remainingToday = result['remainingToday'] as int?;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.statusCode == 403
            ? "You've used all 3 free searches today. Upgrade for unlimited searches, or come back tomorrow."
            : error.message;
        _results = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't complete the search. Please try again.";
        _results = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        elevation: 0,
        title: const Text('Topical Scripture Search'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          Text(
            'Search a topic or feeling — get real, relevant Bible verses.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'e.g. "dealing with anxiety"',
            icon: Icons.search,
            controller: _topicController,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (item) => ActionChip(
                    label: Text(item),
                    onPressed: _loading ? null : () => _search(item),
                    backgroundColor: AppColors.iconCream.withValues(alpha: .7),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          AnimatedPrimaryButton(
            label: _loading ? 'Searching...' : 'Search Scripture',
            icon: Icons.auto_stories_outlined,
            busy: _loading,
            onPressed: _loading ? null : () => _search(),
          ),
          if (_remainingToday != null) ...[
            const SizedBox(height: 10),
            Text(
              '$_remainingToday free search${_remainingToday == 1 ? '' : 'es'} left today',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          if (_error != null)
            GlassPanel(
              child: Text(_error!, style: const TextStyle(color: AppColors.coral, height: 1.4)),
            ),
          if (!_loading && _searchedOnce && _error == null && _results.isEmpty)
            const GlassPanel(
              child: Text('No verses found for that topic. Try rephrasing it.'),
            ),
          ..._results.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['reference']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.deepEmerald),
                    ),
                    const SizedBox(height: 6),
                    Text('"${item['verse'] ?? ''}"', style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4)),
                    if ((item['note'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(item['note'].toString(), style: const TextStyle(color: AppColors.muted, height: 1.4)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_closingPrayer != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.leafGreen.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A prayer with these verses',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepEmerald),
                  ),
                  const SizedBox(height: 8),
                  Text(_closingPrayer!, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
