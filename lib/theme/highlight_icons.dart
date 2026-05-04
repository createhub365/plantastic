import 'package:flutter/material.dart';

/// Allowed [HighlightTag.icon_key] values from admin / DB → [IconData].
IconData highlightIcon(String key) {
  switch (key.trim()) {
    case 'eco':
      return Icons.eco_rounded;
    case 'forest':
      return Icons.forest_outlined;
    case 'local_florist':
      return Icons.local_florist_outlined;
    case 'air':
    case 'air_purifying':
      return Icons.air_rounded;
    case 'oxygen':
      return Icons.spa_outlined;
    case 'home':
    case 'vastu':
      return Icons.home_work_outlined;
    case 'water_drop':
      return Icons.water_drop_outlined;
    case 'wb_sunny':
      return Icons.wb_sunny_outlined;
    case 'energy':
      return Icons.bolt_outlined;
    case 'favorite':
      return Icons.favorite_outline_rounded;
    case 'health':
      return Icons.health_and_safety_outlined;
    case 'recycling':
      return Icons.recycling_outlined;
    case 'compost':
      return Icons.compost_outlined;
    default:
      return Icons.eco_outlined;
  }
}

/// Keys shown in admin icon dropdown (order = display order).
const List<String> kHighlightIconKeys = [
  'eco',
  'local_florist',
  'air',
  'oxygen',
  'home',
  'vastu',
  'forest',
  'water_drop',
  'wb_sunny',
  'energy',
  'favorite',
  'health',
  'recycling',
  'compost',
];
