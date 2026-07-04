import 'package:flutter/material.dart';

class Mood {
  const Mood({
    required this.id,
    required this.en,
    required this.fr,
    required this.icon,
    required this.color,
  });

  final String id;
  final String en;
  final String fr;
  final IconData icon;
  final Color color;
}
