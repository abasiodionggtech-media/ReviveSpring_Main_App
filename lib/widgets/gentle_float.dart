import 'package:flutter/material.dart';

/// Wraps [child] in a slow, smooth, continuous up-and-down float — a few
/// pixels of vertical drift on an easing curve, looped forever. Used for
/// prayer text so it feels alive rather than static, without being
/// distracting to read.
class GentleFloat extends StatefulWidget {
  const GentleFloat({
    super.key,
    required this.child,
    this.distance = 6,
    this.duration = const Duration(seconds: 4),
  });

  final Widget child;
  final double distance;
  final Duration duration;

  @override
  State<GentleFloat> createState() => _GentleFloatState();
}

class _GentleFloatState extends State<GentleFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _offset = Tween<double>(begin: -widget.distance, end: widget.distance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(offset: Offset(0, _offset.value), child: child),
      child: widget.child,
    );
  }
}
