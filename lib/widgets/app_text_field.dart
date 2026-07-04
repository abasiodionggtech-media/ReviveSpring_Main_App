import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      decoration: appInputDecoration(label, icon),
    );
  }
}

InputDecoration appInputDecoration(String label, IconData icon) {
  return InputDecoration(
    hintText: label,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: .68), fontWeight: FontWeight.w600),
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: AppColors.iconCream.withValues(alpha: .75),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.deepEmerald)),
  );
}
