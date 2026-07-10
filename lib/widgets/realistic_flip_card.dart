import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_colors.dart';
import '../core/app_tokens.dart';

/// A realistic 3D flip card — the front and back rotate through a shared Y
/// axis with perspective, rather than a flat cross-fade. Also exposes
/// [captureAndShare] so the front, back, or both can be shared as images.
class RealisticFlipCard extends StatefulWidget {
  const RealisticFlipCard({
    super.key,
    required this.front,
    required this.back,
    this.height = 220,
    this.glowColor,
    this.onTap,
    this.startFlipped = false,
  });

  final Widget front;
  final Widget back;
  final double height;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool startFlipped;

  @override
  State<RealisticFlipCard> createState() => RealisticFlipCardState();
}

class RealisticFlipCardState extends State<RealisticFlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey _frontKey = GlobalKey();
  final GlobalKey _backKey = GlobalKey();
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.startFlipped) {
      _showFront = false;
      _controller.value = 1;
    }
    _controller.addListener(() {
      final isFront = _controller.value < 0.5;
      if (isFront != _showFront) setState(() => _showFront = isFront);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (_controller.value == 0) {
      _controller.forward();
    } else if (_controller.value == 1) {
      _controller.reverse();
    } else {
      _controller.value < 0.5 ? _controller.forward() : _controller.reverse();
    }
  }

  Future<Uint8List?> _captureBoundary(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Captures the front, back, or both faces of the card and opens the
  /// native share sheet with the resulting image(s).
  Future<void> captureAndShare({required bool includeFront, required bool includeBack}) async {
    final dir = await getTemporaryDirectory();
    final files = <XFile>[];

    if (includeFront) {
      final bytes = await _captureBoundary(_frontKey);
      if (bytes != null) {
        final path = '${dir.path}/memory_card_front_${DateTime.now().millisecondsSinceEpoch}.png';
        await XFile.fromData(bytes, mimeType: 'image/png').saveTo(path);
        files.add(XFile(path));
      }
    }
    if (includeBack) {
      final bytes = await _captureBoundary(_backKey);
      if (bytes != null) {
        final path = '${dir.path}/memory_card_back_${DateTime.now().millisecondsSinceEpoch}.png';
        await XFile.fromData(bytes, mimeType: 'image/png').saveTo(path);
        files.add(XFile(path));
      }
    }
    if (files.isNotEmpty) {
      await Share.shareXFiles(files, text: 'From my ReviveSpring Scripture Memory Cards');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 3.14159;
          final showingFront = angle <= 3.14159 / 2;
          final displayAngle = showingFront ? angle : angle - 3.14159;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(displayAngle),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: widget.glowColor == null
                    ? [BoxShadow(color: AppColors.deepEmerald.withValues(alpha: .18), blurRadius: 20, offset: const Offset(0, 10))]
                    : [BoxShadow(color: widget.glowColor!.withValues(alpha: .65), blurRadius: 28, spreadRadius: 2)],
              ),
              child: showingFront
                  ? RepaintBoundary(key: _frontKey, child: SizedBox(height: widget.height, width: double.infinity, child: widget.front))
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.14159),
                      child: RepaintBoundary(key: _backKey, child: SizedBox(height: widget.height, width: double.infinity, child: widget.back)),
                    ),
            ),
          );
        },
      ),
    );
  }
}
