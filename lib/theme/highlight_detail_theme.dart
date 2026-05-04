import 'package:flutter/material.dart';

/// Saturated gradients for shopper highlight detail cards (aligned with icon_key).
HighlightDetailDecoration highlightDetailDecoration(String iconKey) {
  Color c(int hex) => Color(hex);

  switch (iconKey.trim()) {
    case 'eco':
      return HighlightDetailDecoration(c(0xFF1B4332), c(0xFF40916C));
    case 'local_florist':
      return HighlightDetailDecoration(c(0xFF841E5C), c(0xFFF06292));
    case 'air':
    case 'air_purifying':
      return HighlightDetailDecoration(c(0xFF01579B), c(0xFF4FC3F7));
    case 'oxygen':
      return HighlightDetailDecoration(c(0xFF00695C), c(0xFF4DB6AC));
    case 'home':
      return HighlightDetailDecoration(c(0xFFB45309), c(0xFFFBBF24));
    case 'vastu':
      return HighlightDetailDecoration(c(0xFF4A148C), c(0xFFBA68C8));
    case 'forest':
      return HighlightDetailDecoration(c(0xFF1B3314), c(0xFF558B2F));
    case 'water_drop':
      return HighlightDetailDecoration(c(0xFF0D47A1), c(0xFF29B6F6));
    case 'wb_sunny':
      return HighlightDetailDecoration(c(0xFFE65100), c(0xFFFFD54F));
    case 'energy':
      return HighlightDetailDecoration(c(0xFF4A148C), c(0xFFFF5252));
    case 'favorite':
      return HighlightDetailDecoration(c(0xFFB71C1C), c(0xFFFF8A80));
    case 'health':
      return HighlightDetailDecoration(c(0xFF004D40), c(0xFF69F0AE));
    case 'recycling':
      return HighlightDetailDecoration(c(0xFF1B5E20), c(0xFF00BFA5));
    case 'compost':
      return HighlightDetailDecoration(c(0xFF3E2723), c(0xFF8D6E63));
    default:
      return HighlightDetailDecoration(c(0xFF006064), c(0xFF26C6DA));
  }
}

class HighlightDetailDecoration {
  HighlightDetailDecoration(this.colorTop, this.colorBottom);

  final Color colorTop;
  final Color colorBottom;

  LinearGradient gradient({AlignmentGeometry begin = Alignment.topLeft}) {
    return LinearGradient(
      begin: begin,
      end: Alignment.bottomRight,
      colors: [colorTop, colorBottom],
    );
  }
}
