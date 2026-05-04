import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';

/// Shopping-cart icon with cart count badge + light haptic on tap.
class CartToolbarIconButton extends StatelessWidget {
  const CartToolbarIconButton({
    super.key,
    this.tooltip = 'Shopping cart',
  });

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pushNamed('/cart');
      },
      icon: Consumer<CartNotifier>(
        builder: (context, cart, _) {
          final count = cart.itemCount;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: count > 9
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                        : const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
