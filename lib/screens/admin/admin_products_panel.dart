import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../catalog/catalog_assets.dart';
import '../../data/seed_products.dart';
import '../../models/product.dart';
import '../../providers/catalog_notifier.dart';
import '../../services/admin_catalog_service.dart';
import '../../theme/admin_shell.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';
import '../../widgets/decode_aware_product_image.dart';
import 'admin_product_editor_screen.dart';

enum _StockFilter { any, inStock, outOfStock }

class AdminProductsPanel extends StatefulWidget {
  const AdminProductsPanel({
    super.key,
    this.searchQuery = '',
    this.onRegisterAddAction,
  });

  final String searchQuery;
  final void Function(VoidCallback openNew)? onRegisterAddAction;

  @override
  State<AdminProductsPanel> createState() => _AdminProductsPanelState();
}

class _AdminProductsPanelState extends State<AdminProductsPanel>
    with AutomaticKeepAliveClientMixin {
  List<Product> _items = [];
  bool _loading = true;
  String? _error;

  final ScrollController _horizontalTableScroll = ScrollController();

  _StockFilter _stockFilter = _StockFilter.any;
  String? _categoryFilter;
  final Set<String> _selectedIds = {};

  @override
  bool get wantKeepAlive => true;

  List<Product> get _filtered {
    final q = widget.searchQuery.trim().toLowerCase();
    return _items.where((p) {
      if (_categoryFilter != null && p.category != _categoryFilter) {
        return false;
      }
      switch (_stockFilter) {
        case _StockFilter.inStock:
          if (!p.inStock) return false;
        case _StockFilter.outOfStock:
          if (p.inStock) return false;
        case _StockFilter.any:
          break;
      }
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await AdminCatalogService.fetchAllProducts();
      _selectedIds.removeWhere((id) => !_items.any((e) => e.id == id));
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.onRegisterAddAction?.call(() {
        if (mounted) _openEditor(null);
      });
      if (!mounted) return;
      final catalog = context.read<CatalogNotifier>();
      await _reload();
      if (!mounted) return;
      await catalog.refresh(silent: true, warmShopCovers: false);
    });
  }

  void _toggleSelectAllVisible() {
    final visibleIds = _filtered.map((e) => e.id).toSet();
    if (visibleIds.isEmpty) return;
    setState(() {
      if (visibleIds.every(_selectedIds.contains)) {
        _selectedIds.removeAll(visibleIds);
      } else {
        _selectedIds.addAll(visibleIds);
      }
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final ids = List<String>.from(_selectedIds);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected products?'),
        content: Text('Permanently remove ${ids.length} product(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final catalog = context.read<CatalogNotifier>();
    try {
      for (final id in ids) {
        await AdminCatalogService.deleteProduct(id);
      }
      _selectedIds.clear();
      await _reload();
      if (!mounted) return;
      await catalog.refresh(silent: true, warmShopCovers: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ids.length} product(s) deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleStock(Product p, bool v) async {
    final catalog = context.read<CatalogNotifier>();
    try {
      await AdminCatalogService.setInStock(id: p.id, inStock: v);
      await _reload();
      if (!mounted) return;
      await catalog.refresh(silent: true, warmShopCovers: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(v ? '${p.title} in stock' : '${p.title} out of stock'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _setShopVisible(Product p, bool visible) async {
    final catalog = context.read<CatalogNotifier>();
    try {
      await AdminCatalogService.setVisibleInShop(id: p.id, visible: visible);
      await _reload();
      if (!mounted) return;
      await catalog.refresh(silent: true, warmShopCovers: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            visible
                ? '${p.title} visible in shop'
                : '${p.title} hidden from shop',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Permanently remove "${p.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final catalog = context.read<CatalogNotifier>();
    try {
      await AdminCatalogService.deleteProduct(p.id);
      _selectedIds.remove(p.id);
      await _reload();
      if (!mounted) return;
      await catalog.refresh(silent: true, warmShopCovers: false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${p.title}" deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openEditor(Product? p) async {
    final catalog = context.read<CatalogNotifier>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminProductEditorScreen(initial: p),
      ),
    );
    if (!mounted || saved != true) return;
    await _reload();
    if (!mounted) return;
    await catalog.refresh(silent: true, warmShopCovers: false);
  }

  Widget _productThumb(Product p, double side) {
    final scheme = Theme.of(context).colorScheme;
    final ref = p.effectiveShopCoverPrimaryRef?.trim();

    Widget fallback() {
      return ColoredBox(
        color: AppTheme.surfaceBorder.withValues(alpha: 0.38),
        child: Icon(
          p.category == kCategoryFlowerSeed
              ? Icons.local_florist_outlined
              : Icons.spa_outlined,
          color: scheme.primary.withValues(alpha: 0.88),
          size: side * 0.42,
        ),
      );
    }

    Widget square(Widget inner) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(dimension: side, child: inner),
    );

    if (ref == null || ref.isEmpty) {
      return square(fallback());
    }

    if (CatalogAssets.looksLikeUsableShopRemoteUrl(ref)) {
      return square(
        DecodeAwareProductImage(
          image: NetworkImage(ref),
          width: side,
          height: side,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => fallback(),
          loadingBuilder: (context, child, prog) {
            if (prog == null) return child;
            return ColoredBox(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
              child: Center(
                child: SizedBox(
                  width: side * 0.36,
                  height: side * 0.36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary.withValues(alpha: 0.58),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return square(
      DecodeAwareProductImage(
        image: AssetImage(CatalogAssets.assetPath(ref)),
        width: side,
        height: side,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => fallback(),
      ),
    );
  }

  Widget _actionToolbar(Product p) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Edit',
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: _loading ? null : () => _openEditor(p),
          icon: Icon(Icons.edit_outlined, color: scheme.primary),
        ),
        IconButton(
          tooltip: p.visibleInShop ? 'Hide from shop' : 'Show in shop',
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: _loading
              ? null
              : () => _setShopVisible(p, !p.visibleInShop),
          icon: Icon(
            p.visibleInShop
                ? Icons.storefront_outlined
                : Icons.visibility_off_outlined,
            color: p.visibleInShop ? scheme.primary : AppTheme.textMuted,
          ),
        ),
        IconButton(
          tooltip: 'Remove product',
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: _loading ? null : () => _delete(p),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: scheme.error.withValues(alpha: 0.92),
          ),
        ),
        Tooltip(
          message: 'In stock',
          child: Transform.scale(
            scale: 0.82,
            alignment: Alignment.center,
            child: Switch.adaptive(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: p.inStock,
              onChanged: _loading ? null : (v) => _toggleStock(p, v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AdminShell.cardRadiusSm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminShell.cardRadiusSm),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3748),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _categoryFilter,
                hint: const Text('All categories'),
                borderRadius: BorderRadius.circular(12),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  const DropdownMenuItem(
                    value: kCategoryFlowerSeed,
                    child: Text(kCategoryFlowerSeed),
                  ),
                  const DropdownMenuItem(
                    value: kCategoryPlantSeed,
                    child: Text(kCategoryPlantSeed),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryFilter = v),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<_StockFilter>(
                value: _stockFilter,
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(
                    value: _StockFilter.any,
                    child: Text('Any stock'),
                  ),
                  DropdownMenuItem(
                    value: _StockFilter.inStock,
                    child: Text('In stock'),
                  ),
                  DropdownMenuItem(
                    value: _StockFilter.outOfStock,
                    child: Text('Out of stock'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _stockFilter = v);
                },
              ),
            ),
            Text(
              '${_filtered.length} shown',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bulkBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminShell.cardRadiusSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminShell.cardRadiusSm),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedIds.length} selected',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: _bulkDelete,
                child: const Text('Delete selected'),
              ),
              TextButton(
                onPressed: () => setState(_selectedIds.clear),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 8; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AdminShell.dashboardCanvas,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: AdminShell.dashboardCanvas,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _productsTable(List<Product> rows, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleIds = rows.map((e) => e.id).toSet();
    final selOnPage = visibleIds.where(_selectedIds.contains).length;
    final allSelected = visibleIds.isNotEmpty && selOnPage == visibleIds.length;
    final noneSelected = selOnPage == 0;

    final dt = Theme.of(context).dataTableTheme.copyWith(
      headingRowColor: WidgetStateProperty.all(AdminShell.dashboardCanvas),
      dataRowMinHeight: 56,
      headingRowHeight: 44,
      dividerThickness: 0.6,
    );

    return Theme(
      data: Theme.of(context).copyWith(dataTableTheme: dt),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AdminShell.cardRadiusSm),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminShell.cardRadiusSm),
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
          ),
          child: Scrollbar(
            controller: _horizontalTableScroll,
            thumbVisibility: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _horizontalTableScroll,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 880),
                child: SingleChildScrollView(
                  child: DataTable(
                    showCheckboxColumn: false,
                    horizontalMargin: 16,
                    columns: [
                      DataColumn(
                        label: Checkbox(
                          value: allSelected
                              ? true
                              : (noneSelected ? false : null),
                          tristate: true,
                          onChanged: (_) => _toggleSelectAllVisible(),
                        ),
                      ),
                      const DataColumn(label: Text('Image')),
                      const DataColumn(label: Text('Product')),
                      const DataColumn(label: Text('Category')),
                      const DataColumn(label: Text('From ₹')),
                      const DataColumn(label: Text('Shop')),
                      const DataColumn(label: Text('Stock')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final p in rows)
                        DataRow(
                          cells: [
                            DataCell(
                              Checkbox(
                                value: _selectedIds.contains(p.id),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedIds.add(p.id);
                                    } else {
                                      _selectedIds.remove(p.id);
                                    }
                                  });
                                },
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: () => _openEditor(p),
                                child: _productThumb(p, 40),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: () => _openEditor(p),
                                child: Text(
                                  p.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(p.category)),
                            DataCell(Text('₹${p.lowestKitPriceInr}')),
                            DataCell(
                              Icon(
                                p.visibleInShop
                                    ? Icons.check_circle_outline
                                    : Icons.hide_source_outlined,
                                size: 20,
                                color: p.visibleInShop
                                    ? scheme.primary
                                    : scheme.outline,
                              ),
                            ),
                            DataCell(Text(p.inStock ? 'Yes' : 'No')),
                            DataCell(_actionToolbar(p)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _horizontalTableScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filtered = _filtered;

    return AnimatedSwitcher(
      duration: AdminShell.motionMedium,
      switchInCurve: AdminShell.motionCurve,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: AdminShell.motionCurve),
                ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(
          _loading
              ? 'busy'
              : (_error != null ? 'err:${_error.hashCode}' : 'list'),
        ),
        child: _loading
            ? _loadingSkeleton()
            : (_error != null)
            ? AdminErrorView(message: _error!, onRetry: _reload)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _filterBar(context),
                  if (_selectedIds.isNotEmpty) _bulkBar(context),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        final catalog = context.read<CatalogNotifier>();
                        await _reload();
                        if (!mounted) return;
                        await catalog.refresh(
                          silent: true,
                          warmShopCovers: false,
                        );
                      },
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 48),
                                AdminEmptyView(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'No products match',
                                  subtitle:
                                      'Adjust filters or search, or add a new product.',
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.paddingOf(context).bottom + 12,
                                top: 12,
                              ),
                              child: _productsTable(filtered, context),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
