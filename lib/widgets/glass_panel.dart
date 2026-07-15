import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_tokens.dart';

/// The shared surface for every card in the app.
///
/// Glossy treatment, built from the same four ingredients used on the web:
///   1. a top-to-bottom gradient body  → reads as curved glass, not flat card
///   2. a bright inset top edge        → the specular highlight (sells the gloss)
///   3. a soft cast shadow             → it floats above the page
///   4. a faint inner bottom shade     → the underside of the curve
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppRadius.xl;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xF7FFFFFF), // near-opaque white at the crown
            Color(0xCCFFFFFF), // thinner through the middle
            Color(0xEDFFFFFF), // firming up again at the base
          ],
          stops: [0.0, 0.46, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .85)),
        boxShadow: [
          // the cast shadow — the panel floats
          BoxShadow(
            color: AppColors.deepEmerald.withValues(alpha: .16),
            blurRadius: 28,
            spreadRadius: -12,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.deepEmerald.withValues(alpha: .07),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            // the specular highlight across the top — this is the thing that
            // actually makes a surface look glossy rather than merely white.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 60,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .72),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// A domed, glossy chip — the little coloured icon squares beside tiles and
/// moods. Same idea as the web's `.tile-icon`: a bead of coloured glass.
class GlossChip extends StatelessWidget {
  const GlossChip({
    super.key,
    required this.child,
    required this.color,
    this.size = 46,
    this.radius = 14,
  });

  final Widget child;
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: .55), color),
            color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepEmerald.withValues(alpha: .3),
            blurRadius: 12,
            spreadRadius: -6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // top-half gloss dome
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size * .5,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .70),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}
