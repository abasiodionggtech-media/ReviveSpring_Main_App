import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class PrayerGroupsScreen extends StatefulWidget {
  const PrayerGroupsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PrayerGroupsScreen> createState() => _PrayerGroupsScreenState();
}

class _PrayerGroupsScreenState extends State<PrayerGroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final groups = await widget.controller.api.getPrayerGroups();
      if (mounted) setState(() => _groups = groups);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Prayer Group'),
        content: TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Group name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(nameController.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await widget.controller.api.createPrayerGroup(name);
      await _load();
    } catch (_) {}
  }

  Future<void> _join(String id) async {
    setState(() => _busyId = id);
    try {
      await widget.controller.api.joinPrayerGroup(id);
      await _load();
      if (mounted) _openDetail(id);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _openDetail(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _PrayerGroupDetailScreen(controller: widget.controller, groupId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        elevation: 0,
        title: const Text('Prayer Groups'),
        actions: [IconButton(onPressed: _create, icon: const Icon(Icons.add))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                const Text(
                  'Join a public group, or create your own for your church or family.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                ..._groups.map((group) {
                  final isMember = group['is_member'] == true;
                  final busy = _busyId == group['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: isMember ? () => _openDetail(group['id'].toString()) : null,
                      child: GlassPanel(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(group['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                                  if ((group['description'] as String?)?.isNotEmpty == true)
                                    Text(group['description'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('${group['member_count'] ?? 0} members', style: const TextStyle(color: AppColors.deepEmerald, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            if (!isMember)
                              OutlinedButton(
                                onPressed: busy ? null : () => _join(group['id'].toString()),
                                child: const Text('Join'),
                              )
                            else
                              const Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _PrayerGroupDetailScreen extends StatefulWidget {
  const _PrayerGroupDetailScreen({required this.controller, required this.groupId});

  final AppController controller;
  final String groupId;

  @override
  State<_PrayerGroupDetailScreen> createState() => _PrayerGroupDetailScreenState();
}

class _PrayerGroupDetailScreenState extends State<_PrayerGroupDetailScreen> {
  final _textController = TextEditingController();
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _posting = false;

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
    try {
      final detail = await widget.controller.api.getPrayerGroupDetail(widget.groupId);
      if (mounted) setState(() => _detail = detail);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await widget.controller.api.postGroupPrayerRequest(widget.groupId, text);
      _textController.clear();
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = (_detail?['members'] as List? ?? const []).map((m) => Map<String, dynamic>.from(m as Map)).toList();
    final requests = (_detail?['requests'] as List? ?? const []).map((r) => Map<String, dynamic>.from(r as Map)).toList();

    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: Text(_detail?['name']?.toString() ?? 'Prayer Group')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                Text('${members.length} members', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                GlassPanel(
                  child: Column(
                    children: [
                      AppTextField(label: 'Share a prayer request with the group', icon: Icons.favorite_outline, controller: _textController, minLines: 2, maxLines: 4),
                      const SizedBox(height: 10),
                      AnimatedPrimaryButton(label: _posting ? 'Posting...' : 'Post', icon: Icons.send, busy: _posting, onPressed: _posting ? null : _post),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...requests.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['text']?.toString() ?? '', style: const TextStyle(height: 1.4)),
                            const SizedBox(height: 6),
                            Text(r['author']?.toString() ?? 'Anonymous', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
