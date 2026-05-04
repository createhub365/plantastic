import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../theme/admin_shell.dart';
import '../../theme/app_theme.dart';
import '../../widgets/plantastic_app_bar.dart';
import 'admin_highlight_tags_panel.dart';
import 'admin_kit_catalog_panel.dart';
import 'admin_kit_presets_panel.dart';
import 'admin_orders_panel.dart';
import 'admin_products_panel.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    if (AppConfig.supabaseReady) {
      await Supabase.instance.client.auth.signOut();
    }
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final top = PlantasticAppBar(
      showBack: true,
      brandSubtitle: 'Admin',
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: () => _signOut(context),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF2D4A3C),
            hoverColor: AppTheme.mintGlow.withValues(alpha: 0.16),
            highlightColor: AppTheme.mintGlow.withValues(alpha: 0.22),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.all(10),
          ),
          iconSize: 24,
          icon: const Icon(Icons.logout_rounded),
        ),
        const SizedBox(width: 4),
      ],
    );

    const tabBar = TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(6, 0, 12, 0),
      labelPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      tabs: [
        Tab(
          height: 62,
          text: 'Products',
          icon: Icon(Icons.inventory_2_outlined, size: 22),
        ),
        Tab(
          height: 62,
          text: 'Orders',
          icon: Icon(Icons.receipt_long_outlined, size: 22),
        ),
        Tab(
          height: 62,
          text: 'Kit items',
          icon: Icon(Icons.checklist_rtl_outlined, size: 22),
        ),
        Tab(
          height: 62,
          text: 'Kit presets',
          icon: Icon(Icons.layers_outlined, size: 22),
        ),
        Tab(
          height: 62,
          text: 'Highlights',
          icon: Icon(Icons.auto_awesome_outlined, size: 22),
        ),
      ],
    );

    return Theme(
      data: AdminShell.themeShopperChrome(),
      child: DecoratedBox(
        decoration: AdminShell.shopperBackground,
        child: DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(
                top.preferredSize.height + tabBar.preferredSize.height,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  top,
                  ColoredBox(
                    color: Colors.white,
                    child: tabBar,
                  ),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                AdminProductsPanel(),
                AdminOrdersPanel(),
                AdminKitCatalogPanel(),
                AdminKitPresetsPanel(),
                AdminHighlightTagsPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
