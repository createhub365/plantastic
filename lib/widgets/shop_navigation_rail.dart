import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';

/// Primary destinations when [Responsive.isDesktop] — shop home vs cart.
enum ShopNavSection {
  shop,
  cart,
}

/// Compact [NavigationRail] for desktop shop shell (home + cart).
class ShopNavigationRail extends StatelessWidget {
  const ShopNavigationRail({
    super.key,
    required this.section,
  });

  final ShopNavSection section;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = section == ShopNavSection.cart ? 1 : 0;
    final railBg = AppColors.primary.withValues(alpha: 0.92);

    return Consumer<CartNotifier>(
      builder: (context, cart, _) {
        final count = cart.itemCount;
        return NavigationRail(
          backgroundColor: railBg,
          selectedIndex: selectedIndex,
          indicatorColor: Colors.white.withValues(alpha: 0.22),
          labelType: NavigationRailLabelType.all,
          selectedIconTheme: const IconThemeData(color: Colors.white, size: 26),
          unselectedIconTheme: IconThemeData(
            color: Colors.white.withValues(alpha: 0.62),
            size: 24,
          ),
          selectedLabelTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          onDestinationSelected: (i) {
            if (i == selectedIndex) return;
            if (i == 0) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            } else {
              Navigator.of(context).pushNamed('/cart');
            }
          },
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: Text('Shop'),
            ),
            NavigationRailDestination(
              icon: _cartDestinationIcon(count, highlighted: false),
              selectedIcon: _cartDestinationIcon(count, highlighted: true),
              label: const Text('Cart'),
            ),
          ],
        );
      },
    );
  }

  static Widget _cartDestinationIcon(int count, {required bool highlighted}) {
    final opacity = highlighted ? 1.0 : 0.62;
    final icon = Icon(
      Icons.shopping_cart_outlined,
      color: Colors.white.withValues(alpha: opacity),
    );
    if (count <= 0) return icon;
    return Badge(
      label: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
      child: icon,
    );
  }
}
