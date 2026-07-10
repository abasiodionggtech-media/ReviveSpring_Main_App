import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/state_placeholders.dart';

class TestimonyFeedScreen extends StatefulWidget {
  const TestimonyFeedScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<TestimonyFeedScreen> createState() => _TestimonyFeedScreenState();
}

class _TestimonyFeedScreenState extends State<TestimonyFeedScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<Map<String, dynamic>> _testimonies = [];
  bool _loading = true;
  bool _hasError = false;
  bool _posting = false;
  bool _anonymous = false;
  bool _showForm = false;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _testimonies.isEmpty;
      _hasError = false;
    });
    try {
      final testimonies = await widget.controller.api.getTestimonies();
      if (mounted) setState(() => _testimonies = testimonies);
    } catch (_) {
      if (mounted && _testimonies.isEmpty) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final testimony = await widget.controller.api.postTestimony(title, content, isAnonymous: _anonymous);
      if (mounted) {
        setState(() {
          _testimonies.insert(0, testimony);
          _titleController.clear();
          _contentController.clear();
          _showForm = false;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _react(String id) async {
    setState(() => _busyId = id);
    try {
      final result = await widget.controller.api.reactToTestimony(id);
      if (mounted) {
        setState(() {
          final index = _testimonies.indexWhere((t) => t['id'] == id);
          if (index != -1) {
            _testimonies[index] = {
              ..._testimonies[index],
              'amen_count': result['amen_count'],
              'reacted_by_me': result['reacted_by_me'],
            };
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        elevation: 0,
        title: const Text('Testimony Feed'),
        actions: [
          IconButton(onPressed: () => setState(() => _showForm = !_showForm), icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: const [SkeletonList()],
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.deepEmerald,
              child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                if (_showForm) ...[
                  GlassPanel(
                    child: Column(
                      children: [
                        AppTextField(label: 'A short title', icon: Icons.title, controller: _titleController),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Share how God answered your prayer...',
                          icon: Icons.auto_awesome,
                          controller: _contentController,
                          minLines: 3,
                          maxLines: 6,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(value: _anonymous, onChanged: (v) => setState(() => _anonymous = v ?? false)),
                            const Text('Post anonymously', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedPrimaryButton(
                          label: _posting ? 'Sharing...' : 'Share Testimony',
                          icon: Icons.send,
                          busy: _posting,
                          onPressed: _posting ? null : _post,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (_hasError)
                  ErrorState(message: "Couldn't load the testimony feed right now.", onRetry: _load)
                else if (_testimonies.isEmpty)
                  const EmptyState(
                    icon: Icons.auto_awesome,
                    title: 'No testimonies yet',
                    body: 'Be the first to celebrate what God has done.',
                  )
                else
                  ..._testimonies.map((item) {
                  final busy = _busyId == item['id'];
                  final reacted = item['reacted_by_me'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          const SizedBox(height: 8),
                          Text(item['content']?.toString() ?? '', style: const TextStyle(height: 1.4)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['is_anonymous'] == true ? 'Anonymous' : (item['author']?.toString() ?? 'A friend'),
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: busy ? null : () => _react(item['id'].toString()),
                                icon: Icon(reacted ? Icons.favorite : Icons.favorite_border, size: 18, color: AppColors.coral),
                                label: Text('Amen (${item['amen_count'] ?? 0})'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            ),
    );
  }
}
