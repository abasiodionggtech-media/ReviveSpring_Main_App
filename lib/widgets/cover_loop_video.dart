import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays a muted, looping video that fills its parent completely — cropping
/// overflow rather than stretching or letterboxing, the same idea as CSS
/// `object-fit: cover`. Picks one url at random from [urls] and shows
/// nothing (transparent) if the list is empty or playback fails, so it's
/// always safe to drop behind other content.
class CoverLoopVideo extends StatefulWidget {
  const CoverLoopVideo({super.key, required this.urls});

  final List<String> urls;

  @override
  State<CoverLoopVideo> createState() => _CoverLoopVideoState();
}

class _CoverLoopVideoState extends State<CoverLoopVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.urls.isNotEmpty) {
      final url = widget.urls[Random().nextInt(widget.urls.length)];
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          controller.play();
        }).catchError((_) {});
      _controller = controller;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
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
