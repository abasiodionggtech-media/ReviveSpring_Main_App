import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/glass_panel.dart';

class GriefCrisisSupportScreen extends StatefulWidget {
  const GriefCrisisSupportScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<GriefCrisisSupportScreen> createState() => _GriefCrisisSupportScreenState();
}

class _GriefCrisisSupportScreenState extends State<GriefCrisisSupportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.controller.api.getCrisisSupport(language: widget.controller.language);
      if (mounted) setState(() => _data = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = (_data?['content'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final resources = (_data?['resources'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Grief & Crisis Support')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'If you are in immediate danger, please contact local emergency services right away.',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coral, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      ...resources.map(
                        (resource) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(resource['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(resource['detail']?.toString() ?? '', style: const TextStyle(height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                      if ((_data?['note'] as String?)?.isNotEmpty == true)
                        Text(
                          _data!['note'].toString(),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...content.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(item['content']?.toString() ?? '', style: const TextStyle(height: 1.5)),
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
