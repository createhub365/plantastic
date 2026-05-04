import 'package:flutter/material.dart';

import '../screens/product_detail_screen.dart';
import '../theme/app_motion.dart';

/// Fade + slight upward slide when opening product detail (MaterialPageRoute alternative).
Route<void> plantasticProductDetailRoute(String productId) {
  return PageRouteBuilder<void>(
    transitionDuration: AppMotion.transition,
    reverseTransitionDuration: AppMotion.transition,
    pageBuilder: (context, animation, secondaryAnimation) =>
        ProductDetailScreen(productId: productId),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
