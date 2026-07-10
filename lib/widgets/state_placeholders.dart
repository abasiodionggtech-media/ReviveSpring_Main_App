import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_tokens.dart';

/// A friendly "nothing here yet" placeholder, for use wherever a list can
/// legitimately be empty (no prayers posted yet, no group members, etc.)
/// instead of just rendering nothing.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.deepEmerald.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: AppColors.deepEmerald.withValues(alpha: .6), size: 30),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          if (body != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(body!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A "something didn't load" placeholder with a retry action, so a failed
/// network call never just leaves the user staring at a blank screen.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = "Couldn't load this right now.",
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, color: AppColors.coral.withValues(alpha: .7), size: 32),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

/// A simple shimmering placeholder card, shaped roughly like the content
/// that's about to load — used instead of a bare spinner on list screens.
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key, this.height = 84});

  final double height;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = .06 + (_controller.value * .06);
        return Container(
          height: widget.height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.deepEmerald.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        );
      },
    );
  }
}

/// A column of [SkeletonCard]s, for dropping straight into a list screen's
/// loading state instead of a bare CircularProgressIndicator.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3, this.itemHeight = 84});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => SkeletonCard(height: itemHeight)),
    );
  }
}
