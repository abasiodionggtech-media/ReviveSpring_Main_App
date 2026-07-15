import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const deepEmerald = Color(0xFF0E4B3E);
  static const iconCream = Color(0xFFFFFFFF);
  static const sproutGreen = Color(0xFFA8D672);
  static const leafGreen = Color(0xFF3F8F48);
  static const baseEarth = Color(0xFF6F6A4D);

  // Genuine distinct accent hues — previously `sky` and `lavender` were
  // aliased to the green/brown above, which quietly flattened the palette.
  static const skyBlue = Color(0xFF2D8F9B);
  static const softLavender = Color(0xFF8874A3);
  static const gold = Color(0xFFB58B2B);

  static const ink = deepEmerald;
  // The page behind the glass. Deliberately NOT pure white — glossy white
  // panels are invisible on a pure white page, so this soft green-tinted
  // off-white is what gives the gloss something to stand against.
  static const panel = Color(0xFFF1F6F3);
  static const glass = Color(0xF2FFFFFF);
  static const leaf = leafGreen;
  static const coral = Color(0xFFB85B48);
  static const sky = skyBlue;
  static const lavender = softLavender;
  static const cream = iconCream;
  static const muted = baseEarth;
}
