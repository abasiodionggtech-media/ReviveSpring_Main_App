import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// The V3 navigation, in Flutter.
///
/// The bar's top edge is a live path, redrawn every frame. It bulges upward
/// into a circular cradle that sits concentric with the raised active disc, so
/// the white wraps the icon with an even halo — by construction, not by
/// eyeballing. Two fillets ease tangentially back into the flat bar, so there
/// are no corners anywhere in the shape.
///
/// The entrance is staged deliberately so nothing snaps:
///   1. the bar rises with a perfectly FLAT top
///   2. the icons pop in, staggered, ALL of them inactive
///   3. only then does the active icon lift, as the cradle swells to meet it
class CurvedNavItem {
  const CurvedNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class CurvedNavBar extends StatefulWidget {
  const CurvedNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<CurvedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<CurvedNavBar> createState() => _CurvedNavBarState();
}

class _CurvedNavBarState extends State<CurvedNavBar> with TickerProviderStateMixin {
  // Geometry — mirrors the web exactly.
  static const double barHeight = 70;
  static const double discR = 22;
  static const double gap = 7;
  static const double cradleR = discR + gap;         // 29
  static const double alpha = 58 * math.pi / 180;    // how much of the circle we use
  static const double fillet = 18;
  static const double corner = 14;
  static const double lift = 26;
  static const double headroom = 40;                 // space above the bar for the cradle

  late final AnimationController _entrance;   // bar rise + icon stagger
  late final AnimationController _swell;      // cradle growing out of the flat bar
  late final AnimationController _slide;      // cradle travelling sideways

  double _fromX = 0;
  double _toX = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
    _swell = AnimationController(vsync: this, duration: const Duration(milliseconds: 640));
    _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 620), value: 1);

    // Hand over from the entrance to the live state, then let the cradle rise.
    _entrance.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _ready = true);
        _swell.forward();
      }
    });
  }

  @override
  void didUpdateWidget(CurvedNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _fromX = _currentX;          // start the glide from wherever we actually are
      _toX = _centreOf(widget.currentIndex);
      _slide.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _swell.dispose();
    _slide.dispose();
    super.dispose();
  }

  double _width = 0;

  /// Where each icon's centre sits. The padding is set so the OUTERMOST icons
  /// are still far enough from the ends for the cradle to reach fully beneath
  /// them — otherwise the disc drifts off the white, which is exactly the bug
  /// the web version had.
  double get _pad => cradleR * math.sin(alpha) + fillet + corner;

  double _centreOf(int i) {
    if (_width == 0 || widget.items.isEmpty) return 0;
    final usable = _width - _pad * 2;
    final step = widget.items.length > 1 ? usable / (widget.items.length - 1) : 0;
    return _pad + step * i;
  }

  double get _currentX {
    if (!_slide.isAnimating && _slide.value == 1) return _toX == 0 ? _centreOf(widget.currentIndex) : _toX;
    final t = Curves.easeInOutCubic.transform(_slide.value);
    return _fromX + (_toX - _fromX) * t;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _width = constraints.maxWidth;
      if (_toX == 0) _toX = _centreOf(widget.currentIndex);

      return SizedBox(
        height: barHeight + headroom,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entrance, _swell, _slide]),
          builder: (context, _) {
            // The bar slides up first, on its own.
            final rise = Curves.easeOutCubic.transform(
              (_entrance.value / 0.46).clamp(0.0, 1.0),
            );
            final swell = _ready ? Curves.easeOutBack.transform(_swell.value).clamp(0.0, 1.2) : 0.0;

            return Transform.translate(
              offset: Offset(0, (1 - rise) * (barHeight + headroom) * 1.4),
              child: Opacity(
                opacity: rise,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // the bar itself
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BarPainter(
                          cradleX: _currentX,
                          swell: swell.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                    // the icons
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: barHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < widget.items.length; i++)
                            Expanded(child: _buildItem(i)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildItem(int i) {
    final item = widget.items[i];
    final active = _ready && i == widget.currentIndex;

    // Each icon pops in after the bar has landed, staggered 65ms apart.
    const barDone = 0.46;
    final start = barDone + i * 0.05;
    final raw = ((_entrance.value - start) / 0.30).clamp(0.0, 1.0);
    final pop = Curves.elasticOut.transform(raw).clamp(0.0, 1.15);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(i),
      child: AnimatedSlide(
        offset: Offset(0, active ? -lift / barHeight : 0),
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutBack,
        child: AnimatedScale(
          scale: active ? 1.14 : 0.92,
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutBack,
          child: Opacity(
            opacity: _ready ? (active ? 1 : 0.9) : raw,
            child: Transform.scale(
              scale: _ready ? 1 : pop.clamp(0.0, 1.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // the glossy disc, behind the icon
                  SizedBox(
                    width: discR * 2,
                    height: discR * 2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedScale(
                          scale: active ? 1 : 0,
                          duration: const Duration(milliseconds: 620),
                          curve: Curves.easeOutBack,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF3E8A72), AppColors.deepEmerald, Color(0xFF0A3A30)],
                                stops: [0, .58, 1],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.deepEmerald.withValues(alpha: .55),
                                  blurRadius: 20,
                                  spreadRadius: -6,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(
                          item.icon,
                          size: 21,
                          color: active ? Colors.white : const Color(0xFF3A5449),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                      // white on the dark disc; a readable slate-green otherwise
                      color: active ? Colors.white : const Color(0xFF3A5449),
                      shadows: active
                          ? [const Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1))]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.cradleX, required this.swell});

  final double cradleX;
  final double swell; // 0 = flat, 1 = fully cradled

  @override
  void paint(Canvas canvas, Size size) {
    const s = _CurvedNavBarState.cradleR;
    const a = _CurvedNavBarState.alpha;
    const f = _CurvedNavBarState.fillet;
    const r = _CurvedNavBarState.corner;

    final t = size.height - _CurvedNavBarState.barHeight;   // the flat top edge
    final w = size.width;

    // At swell = 0 the circle's centre sits exactly one radius below the top
    // edge, so the arc is tangent to the flat line and the hump has literally
    // zero height. Raising it lifts the centre, and the cradle emerges.
    final restY = t - _CurvedNavBarState.lift + 6;
    final flatY = t + s;
    final cy = flatY + (restY - flatY) * swell;
    final cx = cradleX.clamp(s * math.sin(a) + f + r, w - s * math.sin(a) - f - r);

    final lx = cx - s * math.sin(a);
    final ly = cy - s * math.cos(a);
    final rx = cx + s * math.sin(a);
    final k = f * 0.62;

    final path = Path()..moveTo(r, t);

    if (ly >= t - 0.4) {
      path.lineTo(w - r, t);                        // dead flat
    } else {
      path
        ..lineTo(lx - f, t)
        // ease up off the flat, arriving tangent to the circle
        ..cubicTo(
          lx - f + f * 0.6, t,
          lx - k * math.cos(a), ly + k * math.sin(a),
          lx, ly,
        )
        // the cradle: a genuine circular arc, concentric with the disc
        ..arcToPoint(
          Offset(rx, ly),
          radius: const Radius.circular(s),
          clockwise: true,
        )
        // and back down to the flat, leaving tangent to the circle
        ..cubicTo(
          rx + k * math.cos(a), ly + k * math.sin(a),
          rx + f - f * 0.6, t,
          rx + f, t,
        )
        ..lineTo(w - r, t);
    }

    path
      ..quadraticBezierTo(w, t, w, t + r)
      ..lineTo(w, size.height - r)
      ..quadraticBezierTo(w, size.height, w - r, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..lineTo(0, t + r)
      ..quadraticBezierTo(0, t, r, t)
      ..close();

    // it floats
    canvas.drawShadow(path, AppColors.deepEmerald.withValues(alpha: .5), 12, false);

    // glossy white glass
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFCFFFFFF), Color(0xE0FFFFFF), Color(0xF5FFFFFF)],
        stops: [0, .45, 1],
      ).createShader(Rect.fromLTWH(0, t, w, size.height - t));
    canvas.drawPath(path, paint);

    // the specular top edge — the thing that actually sells the gloss
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .95),
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.cradleX != cradleX || old.swell != swell;
}
