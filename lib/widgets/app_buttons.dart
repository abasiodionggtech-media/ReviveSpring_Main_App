import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AnimatedPrimaryButton extends StatefulWidget {
  const AnimatedPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => pressed = false) : null,
      onTapUp: enabled ? (_) => setState(() => pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: pressed ? .97 : 1,
        child: Opacity(
          opacity: enabled ? 1 : .68,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.deepEmerald, Color(0xFF0B3F35)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.deepEmerald.withValues(alpha: .22), blurRadius: 26, offset: const Offset(0, 12))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.busy)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.iconCream))
                else ...[
                  Text(widget.label, style: const TextStyle(color: AppColors.iconCream, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(width: 10),
                  Icon(widget.icon, color: AppColors.iconCream),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingIconButton extends StatelessWidget {
  const FloatingIconButton({super.key, required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.deepEmerald.withValues(alpha: .12),
        foregroundColor: AppColors.deepEmerald,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
