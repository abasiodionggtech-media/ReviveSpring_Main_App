import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/app_colors.dart';
import '../services/video_cache_service.dart';

/// Which moods have a video, and what the file is called.
///
/// To add another: drop the file into the backend at
///   public/media/wellness/<filename>
/// and add one line here. Nothing else needs to change.
const Map<String, String> moodVideoFiles = {
  'anxious': 'anxiety.mp4',
};

String? moodVideoUrl(String moodId, String mediaBaseUrl) {
  final file = moodVideoFiles[moodId];
  if (file == null) return null;
  return '$mediaBaseUrl/media/wellness/$file';
}

/// A video card shown at the bottom of a mood's prayer screen.
///
/// Renders nothing at all when there's no video for this mood, or when the
/// file can't be loaded — so a missing video degrades to "no card" rather
/// than a broken black box.
class MoodVideoCard extends StatefulWidget {
  const MoodVideoCard({super.key, required this.moodId, required this.mediaBaseUrl});

  final String moodId;
  final String mediaBaseUrl;

  @override
  State<MoodVideoCard> createState() => _MoodVideoCardState();
}

class _MoodVideoCardState extends State<MoodVideoCard> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = moodVideoUrl(widget.moodId, widget.mediaBaseUrl);
    if (url == null) {
      setState(() => _failed = true);
      return;
    }

    // Play from cache when we have it — instant, and works offline.
    final cached = await VideoCacheService.instance.cachedFileFor(url);
    final controller = cached != null
        ? VideoPlayerController.file(cached)
        : VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      // A missing file (404) would otherwise hang here forever on a black
      // rectangle, so give it a deadline and fail cleanly instead.
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (!mounted) {
        await controller.dispose();
        return;
      }
      if (controller.value.hasError) throw Exception('playback error');

      controller.addListener(_onTick);
      setState(() {
        _controller = controller;
        _ready = true;
      });

      // Cache for next time so it opens instantly and works offline.
      if (cached == null) VideoCacheService.instance.download(url);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick() {
    final c = _controller;
    if (c != null && c.value.hasError && !_failed && mounted) {
      setState(() => _failed = true);
    } else if (mounted) {
      setState(() {}); // keep the play/pause button in sync
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No video for this mood, or it wouldn't load — show nothing.
    if (_failed) return const SizedBox.shrink();

    final controller = _controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.skyBlue.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('05', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.skyBlue)),
            ),
            const SizedBox(width: 10),
            const Text('Watch and listen', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: (_ready && controller != null) ? controller.value.aspectRatio : 16 / 9,
            child: (!_ready || controller == null)
                ? Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(controller),
                      // A single, obvious tap target. No fiddly scrub bar in
                      // a prayer screen — the point is to listen, not to seek.
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            controller.value.isPlaying ? controller.pause() : controller.play();
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: controller.value.isPlaying ? 0 : 1,
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(playedColor: AppColors.sproutGreen),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sit with this for a few minutes. There is no rush.',
          style: TextStyle(
            fontSize: 12.5,
            fontStyle: FontStyle.italic,
            color: AppColors.baseEarth.withValues(alpha: .9),
          ),
        ),
      ],
    );
  }
}
