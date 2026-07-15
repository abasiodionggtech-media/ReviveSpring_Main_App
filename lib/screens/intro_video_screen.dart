import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/app_colors.dart';
import '../core/app_controller.dart';
import '../core/app_stage.dart';
import '../services/intro_video_service.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  VideoPlayerController? _videoController;
  bool _preparing = true;
  bool _failed = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final service = IntroVideoService.instance;
    final localFile = await service.waitUntilReady(
      timeout: const Duration(seconds: 12),
    );

    VideoPlayerController controller;
    if (localFile != null) {
      controller = VideoPlayerController.file(localFile);
    } else {
      // Background download wasn't ready in time (slow connection) — fall
      // back to streaming it directly rather than leaving the user stuck.
      final url = '${widget.controller.api.mediaBaseUrl}/media/intro-video.mp4';
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    try {
      // If the file is missing on the server (404) or the network stalls,
      // initialize() can otherwise hang forever and leave the user staring
      // at a blank black card. Time it out and fail visibly instead.
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Surfaces decode/network errors that happen *after* initialize()
      // succeeds — otherwise those also show as a silent black rectangle.
      controller.addListener(_onVideoTick);
      if (controller.value.hasError) {
        throw Exception(controller.value.errorDescription ?? 'playback error');
      }

      await controller.setVolume(1);
      await controller.play();

      setState(() {
        _videoController = controller;
        _preparing = false;
        _failed = false;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _videoController = null;
          _failed = true;
          _preparing = false;
        });
      }
    }
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null) return;
    final value = controller.value;
    if (value.hasError && !_failed && mounted) {
      setState(() {
        _failed = true;
        _preparing = false;
      });
      return;
    }
    if (value.isInitialized && !value.isPlaying && value.position >= value.duration && value.duration > Duration.zero) {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await _videoController?.pause();
    await IntroVideoService.instance.deleteCachedFile();
    if (mounted) widget.controller.go(AppStage.app);
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepEmerald,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .35),
                        blurRadius: 40,
                        spreadRadius: 4,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: _preparing || _failed || _videoController == null
                          ? 16 / 9
                          : _videoController!.value.aspectRatio,
                      child: _buildVideoArea(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _finish,
                  child: Text(
                    _failed ? 'Continue' : 'Skip',
                    style: TextStyle(color: Colors.white.withValues(alpha: .7)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_failed) {
      return Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 40),
      );
    }
    if (_preparing || _videoController == null) {
      return Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white70),
      );
    }
    return GestureDetector(
      onTap: () {
        final controller = _videoController!;
        setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        });
      },
      child: VideoPlayer(_videoController!),
    );
  }
}
