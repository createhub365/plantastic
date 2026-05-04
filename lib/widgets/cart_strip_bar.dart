import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

/// Floating-style cart banner (items · total · VIEW CART).
class CartStripBar extends StatelessWidget {
  const CartStripBar({super.key, this.margin});

  /// Margin around rounded bar (floating inset above content).
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartNotifier>(
      builder: (context, cart, _) {
        if (cart.itemCount == 0) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        final itemLabel = cart.itemCount == 1
            ? '1 item'
            : '${cart.itemCount} items';

        Widget bar = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.mintGlow.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer,
                      AppTheme.forestBright,
                      AppTheme.forest.withValues(alpha: 0.92),
                    ],
                  ),
                ),
                child: InkWell(
                  splashColor: AppTheme.mintGlow.withValues(alpha: 0.22),
                  highlightColor: Colors.white.withValues(alpha: 0.06),
                  onTap: () => Navigator.of(context).pushNamed('/cart'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                itemLabel,
                                style: textTheme.titleSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₹${cart.grandTotal}',
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'VIEW CART',
                                style: textTheme.labelLarge?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: cs.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        if (margin != null) {
          return Padding(padding: margin!, child: bar);
        }
        return bar;
      },
    );
  }
}

/// − [qty] + control (meal-app style bordered pill).
class FoodQtyStepper extends StatelessWidget {
  const FoodQtyStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.dense = false,
    this.incrementEnabled = true,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool dense;
  final bool incrementEnabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final pad = dense
        ? const EdgeInsets.symmetric(horizontal: 2, vertical: 2)
        : EdgeInsets.zero;
    final height = dense ? 36.0 : 42.0;
    final iconSize = dense ? 18.0 : 22.0;

    return Container(
      height: height,
      padding: pad,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: dense ? 32 : 40,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              iconSize: iconSize,
              onPressed: onDecrement,
              icon: const Icon(Icons.remove, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(
            width: dense ? 32 : 40,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              iconSize: iconSize,
              onPressed: incrementEnabled ? onIncrement : null,
              icon: Icon(
                Icons.add,
                color: incrementEnabled ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
