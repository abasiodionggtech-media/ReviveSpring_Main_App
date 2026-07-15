import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/video_cache_service.dart';

/// Plays a muted, endlessly looping video that fills its parent completely —
/// cropping overflow rather than stretching or letterboxing (the same idea as
/// CSS `object-fit: cover`).
///
/// Prefers a locally cached copy (instant, works offline) and falls back to
/// streaming if the video hasn't been cached yet. Shows nothing at all if
/// playback fails, so it's always safe to drop behind other content.
class CoverLoopVideo extends StatefulWidget {
  const CoverLoopVideo({super.key, required this.urls});

  final List<String> urls;

  @override
  State<CoverLoopVideo> createState() => _CoverLoopVideoState();
}

class _CoverLoopVideoState extends State<CoverLoopVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.urls.isEmpty) return;

    final url = widget.urls[Random().nextInt(widget.urls.length)];

    // Play from the local cache when we have it — instant start, no network.
    final cached = await VideoCacheService.instance.cachedFileFor(url);
    final controller = cached != null
        ? VideoPlayerController.file(cached)
        : VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      // IMPORTANT: initialize() must complete *before* setLooping/setVolume.
      // Calling them on an uninitialized controller silently does nothing —
      // that's what stopped these videos from looping.
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      setState(() {
        _controller = controller;
        _ready = true;
      });

      controller.addListener(_ensureStillLooping);

      // If we had to stream it, cache it now so next time is instant/offline.
      if (cached == null) {
        VideoCacheService.instance.download(url);
      }
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _ready = false);
    }
  }

  // Belt-and-braces: if the platform ever drops out of the loop (some Android
  // builds do on a decoder hiccup), nudge it back to the start rather than
  // freezing on the last frame.
  void _ensureStillLooping() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final value = controller.value;
    final atEnd =
        value.position >= value.duration && value.duration > Duration.zero;
    if (atEnd && !value.isPlaying) {
      controller.seekTo(Duration.zero);
      controller.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_ensureStillLooping);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
