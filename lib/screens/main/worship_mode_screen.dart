import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/glass_panel.dart';

class WorshipModeScreen extends StatefulWidget {
  const WorshipModeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<WorshipModeScreen> createState() => _WorshipModeScreenState();
}

class _WorshipModeScreenState extends State<WorshipModeScreen> {
  List<Map<String, dynamic>> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tracks = await widget.controller.api.getWorshipTracks();
      if (mounted) setState(() => _tracks = tracks);
    } catch (_) {
      if (mounted) setState(() => _error = 'Worship Mode is a Premium feature.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _play(Map<String, dynamic> track) async {
    final url = track['url']?.toString();
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  IconData _platformIcon(String? platform) {
    switch (platform) {
      case 'spotify':
        return Icons.podcasts;
      case 'audio_url':
        return Icons.audiotrack;
      default:
        return Icons.play_circle_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Worship Mode')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.coral)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                  children: [
                    const Text(
                      'Tap a track to open it in YouTube or Spotify and worship along.',
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ..._tracks.map(
                      (track) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _play(track),
                          child: GlassPanel(
                            child: Row(
                              children: [
                                Icon(_platformIcon(track['platform']?.toString()), color: AppColors.deepEmerald, size: 30),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(track['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                                      if ((track['artist'] as String?)?.isNotEmpty == true)
                                        Text(track['artist'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if ((track['duration_label'] as String?)?.isNotEmpty == true)
                                  Text(track['duration_label'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                const SizedBox(width: 8),
                                const Icon(Icons.open_in_new, size: 16, color: AppColors.muted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
