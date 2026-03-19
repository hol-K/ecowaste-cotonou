import 'package:flutter/material.dart';

class GuideItem {
  final String name;
  final String category;
  final String wasteType;
  final Color color;
  final IconData icon;

  GuideItem({
    required this.name,
    required this.category,
    required this.wasteType,
    required this.color,
    required this.icon,
  });
}