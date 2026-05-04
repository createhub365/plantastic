import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layout/plantastic_layout.dart';
import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Floating cart banner — glass shell + solid primary CTA.
class CartStripBar extends StatelessWidget {
  const CartStripBar({super.key, this.margin});

  /// Margin around rounded bar (floating inset above content).
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartNotifier>(
      builder: (context, cart, _) {
        if (cart.itemCount == 0) return const SizedBox.shrink();

        final textTheme = Theme.of(context).textTheme;

        final itemLabel = cart.itemCount == 1
            ? '1 item'
            : '${cart.itemCount} items';

        Widget bar = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: GlassCard(
            borderRadius: 18,
            blur: true,
            sigma: 14,
            padding: EdgeInsets.symmetric(
              horizontal: PlantasticLayout.compactPhone(context) ? 12 : 16,
              vertical: PlantasticLayout.compactPhone(context) ? 12 : 14,
            ),
            child: Material(
              color: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                final cramped = constraints.maxWidth < 320;
                final compact = cramped ||
                    PlantasticLayout.compactPhone(context);
                return Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            Navigator.of(context).pushNamed('/cart'),
                        borderRadius: BorderRadius.circular(12),
                        splashColor: Colors.white.withValues(alpha: 0.14),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                itemLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.96),
                                  fontWeight: FontWeight.w700,
                                  fontSize: compact ? 13 : null,
                                ),
                              ),
                              Text(
                                '₹${cart.grandTotal}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ) ??
                                    TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: compact ? 20 : 22,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 12 : 16,
                          vertical: compact ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/cart'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            compact ? 'CART' : 'VIEW CART',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.35,
                              fontSize: cramped ? 11 : 13,
                            ),
                          ),
                          SizedBox(width: compact ? 4 : 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: compact ? 11 : 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
