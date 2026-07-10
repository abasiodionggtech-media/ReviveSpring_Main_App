import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/state_placeholders.dart';

class PrayerChainScreen extends StatefulWidget {
  const PrayerChainScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PrayerChainScreen> createState() => _PrayerChainScreenState();
}

class _PrayerChainScreenState extends State<PrayerChainScreen> {
  final _textController = TextEditingController();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _hasError = false;
  bool _posting = false;
  bool _anonymous = false;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _requests.isEmpty;
      _hasError = false;
    });
    try {
      final requests = await widget.controller.api.getPrayerChain();
      if (mounted) setState(() => _requests = requests);
    } catch (_) {
      if (mounted && _requests.isEmpty) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final request = await widget.controller.api.postPrayerRequest(text, isAnonymous: _anonymous);
      if (mounted) {
        setState(() {
          _requests.insert(0, request);
          _textController.clear();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _pray(String id) async {
    setState(() => _busyId = id);
    try {
      final updated = await widget.controller.api.prayForRequest(id);
      if (mounted) {
        setState(() {
          final index = _requests.indexWhere((r) => r['id'] == id);
          if (index != -1) _requests[index] = updated;
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
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Prayer Chain')),
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
                  GlassPanel(
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'What would you like prayer for?',
                          icon: Icons.favorite_outline,
                          controller: _textController,
                          minLines: 2,
                          maxLines: 4,
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
                          label: _posting ? 'Posting...' : 'Share Request',
                          icon: Icons.send,
                          busy: _posting,
                          onPressed: _posting ? null : _post,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_hasError)
                    ErrorState(message: "Couldn't load the prayer chain right now.", onRetry: _load)
                  else if (_requests.isEmpty)
                    const EmptyState(
                      icon: Icons.favorite_outline,
                      title: 'No requests yet',
                      body: 'Be the first to share something the community can pray for.',
                    )
                  else
                    ..._requests.map((request) {
                      final busy = _busyId == request['id'];
                      final prayedByMe = request['prayed_by_me'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(request['text']?.toString() ?? '', style: const TextStyle(height: 1.4)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      request['is_anonymous'] == true ? 'Anonymous' : (request['author']?.toString() ?? 'A friend'),
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: (busy || prayedByMe || request['is_mine'] == true) ? null : () => _pray(request['id'].toString()),
                                    icon: const Icon(Icons.volunteer_activism_outlined, size: 16),
                                    label: Text(prayedByMe ? 'Prayed (${request['prayer_count']})' : 'I Prayed This (${request['prayer_count']})'),
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
