import 'package:flutter/material.dart';

import '../data/kit_catalog_ids.dart';
import '../models/product_kit_line.dart';

/// Icon for catalogue-backed kit inclusion rows (+ label fallback).
IconData kitInclusionIcon(KitInclusionEntry entry) {
  final id = entry.catalogId.trim();
  if (id.isNotEmpty) {
    if (id == KitCatalogIds.seedPacket) return Icons.spa_rounded;
    if (id == KitCatalogIds.soilMix) return Icons.landscape_rounded;
    if (id == KitCatalogIds.compost) return Icons.compost_rounded;
    if (id == KitCatalogIds.coconutCoir) return Icons.layers_rounded;
    if (id == KitCatalogIds.towel) return Icons.dry_cleaning_rounded;
    if (id == KitCatalogIds.gloves) return Icons.front_hand_rounded;
    if (id == KitCatalogIds.scoop) return Icons.hardware_rounded;
  }
  return _kitInclusionIconFromLabel(entry.label);
}

IconData _kitInclusionIconFromLabel(String raw) {
  final l = raw.toLowerCase();
  if (l.contains('seed')) return Icons.spa_rounded;
  if (l.contains('compost')) return Icons.compost_rounded;
  if (l.contains('coir')) return Icons.layers_rounded;
  if (l.contains('brush')) return Icons.brush_rounded;
  if (l.contains('soil') || l.contains('mix')) return Icons.landscape_rounded;
  if (l.contains('towel')) return Icons.dry_cleaning_rounded;
  if (l.contains('glove')) return Icons.front_hand_rounded;
  if (l.contains('scoop') || l.contains('trowel') || l.contains('tool')) {
    return Icons.hardware_rounded;
  }
  if (l.contains('pot') || l.contains('planter')) {
    return Icons.agriculture_rounded;
  }
  if (l.contains('fertil')) return Icons.science_rounded;
  if (l.contains('water') || l.contains('spray')) {
    return Icons.water_drop_rounded;
  }
  if (l.contains('stick') || l.contains('tag') || l.contains('label')) {
    return Icons.label_rounded;
  }
  return Icons.inventory_2_rounded;
}
