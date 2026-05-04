import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../layout/screen_breakpoints.dart';
import '../../theme/admin_shell.dart';
import '../../widgets/admin/admin_dashboard_sidebar.dart';
import 'admin_highlight_tags_panel.dart';
import 'admin_kit_catalog_panel.dart';
import 'admin_kit_presets_panel.dart';
import 'admin_orders_panel.dart';
import 'admin_products_panel.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _productSearchCtrl = TextEditingController();

  int _sectionIndex = 0;
  VoidCallback? _addProductAction;

  static const _titles = [
    'Products',
    'Orders',
    'Kit items',
    'Kit presets',
    'Highlights',
  ];

  @override
  void dispose() {
    _productSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    if (AppConfig.supabaseReady) {
      await Supabase.instance.client.auth.signOut();
    }
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final useDrawer =
        MediaQuery.sizeOf(context).width < ScreenBreakpoints.tablet;

    return Theme(
      data: AdminShell.themeDashboardChrome(),
      child: DecoratedBox(
        decoration: AdminShell.dashboardBackdrop,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: useDrawer
              ? Drawer(
                  child: SafeArea(
                    child: AdminDashboardSidebar(
                      selectedIndex: _sectionIndex,
                      onSelect: (i) {
                        setState(() => _sectionIndex = i);
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                      onSignOut: () => _signOut(context),
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!useDrawer)
                  AdminDashboardSidebar(
                    selectedIndex: _sectionIndex,
                    onSelect: (i) => setState(() => _sectionIndex = i),
                    onSignOut: () => _signOut(context),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AdminDashboardHeader(
                        title: _titles[_sectionIndex],
                        showMenu: useDrawer,
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        showProductSearch: _sectionIndex == 0,
                        searchController: _productSearchCtrl,
                        onSearchChanged: () => setState(() {}),
                        addProductLabel: '+ Add product',
                        showAddProduct: _sectionIndex == 0,
                        onAddProduct: _sectionIndex == 0
                            ? () => _addProductAction?.call()
                            : null,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: IndexedStack(
                            index: _sectionIndex,
                            children: [
                              AdminProductsPanel(
                                searchQuery: _productSearchCtrl.text.trim(),
                                onRegisterAddAction: (fn) =>
                                    _addProductAction = fn,
                              ),
                              const AdminOrdersPanel(),
                              const AdminKitCatalogPanel(),
                              const AdminKitPresetsPanel(),
                              const AdminHighlightTagsPanel(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardHeader extends StatelessWidget {
  const _AdminDashboardHeader({
    required this.title,
    required this.showMenu,
    required this.onMenu,
    required this.showProductSearch,
    required this.searchController,
    required this.onSearchChanged,
    required this.showAddProduct,
    required this.addProductLabel,
    required this.onAddProduct,
  });

  final String title;
  final bool showMenu;
  final VoidCallback onMenu;
  final bool showProductSearch;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final bool showAddProduct;
  final String addProductLabel;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final searchField = TextField(
      controller: searchController,
      onChanged: (_) => onSearchChanged(),
      decoration: InputDecoration(
        hintText: 'Search products…',
        isDense: true,
        prefixIcon: Icon(
          Icons.search,
          size: 22,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
        filled: true,
        fillColor: AdminShell.dashboardCanvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outline.withValues(alpha: 0.35),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outline.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.85),
          ),
        ),
      ),
    );

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(showMenu ? 4 : 18, 10, 18, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackFilters =
                showProductSearch && constraints.maxWidth < 560;

            final titleRow = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showMenu)
                  IconButton(
                    tooltip: 'Menu',
                    onPressed: onMenu,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: const Color(0xFF2D3748),
                        ),
                  ),
                ),
                if (!stackFilters && showAddProduct)
                  FilledButton.icon(
                    onPressed: onAddProduct,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(addProductLabel),
                  ),
              ],
            );

            if (!showProductSearch) {
              return titleRow;
            }

            if (stackFilters) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleRow,
                  const SizedBox(height: 12),
                  searchField,
                  if (showAddProduct) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: onAddProduct,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(addProductLabel),
                      ),
                    ),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showMenu)
                  IconButton(
                    tooltip: 'Menu',
                    onPressed: onMenu,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: const Color(0xFF2D3748),
                        ),
                  ),
                ),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: searchField,
                  ),
                ),
                const SizedBox(width: 12),
                if (showAddProduct)
                  FilledButton.icon(
                    onPressed: onAddProduct,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(addProductLabel),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
