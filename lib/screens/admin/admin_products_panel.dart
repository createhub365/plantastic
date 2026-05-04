import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/seed_products.dart';
import '../../models/product.dart';
import '../../providers/catalog_notifier.dart';
import '../../services/admin_catalog_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';
import 'admin_product_editor_screen.dart';

class AdminProductsPanel extends StatefulWidget {
  const AdminProductsPanel({super.key});

  @override
  State<AdminProductsPanel> createState() => _AdminProductsPanelState();
}

class _AdminProductsPanelState extends State<AdminProductsPanel>
    with AutomaticKeepAliveClientMixin {
  List<Product> _items = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await AdminCatalogService.fetchAllProducts();
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
      if (!mounted) return;
      final catalog = context.read<CatalogNotifier>();
      await _reload();
      if (!mounted) return;
      await catalog.refresh(silent: true, warmShopCovers: false);
    });
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

  Widget _avatar(Product p, {double radius = 24}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surfaceBorder.withValues(alpha: 0.45),
      child: Icon(
        p.category == kCategoryFlowerSeed
            ? Icons.local_florist_outlined
            : Icons.spa_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: radius > 21 ? 26 : 22,
      ),
    );
  }

  Widget _subtitle(Product p) {
    return Text(
      '${p.visibleInShop ? 'On shop' : 'Hidden'} • '
      '${p.category} • '
      '${p.inStock ? 'In stock' : 'OUT OF STOCK'}\n'
      'From ₹${p.lowestKitPriceInr} • ${p.kits.length} kit option(s)',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        height: 1.42,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _actionsRow(Product p) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 2,
      runSpacing: 4,
      children: [
        IconButton(
          tooltip: p.visibleInShop ? 'Hide from shop' : 'Show in shop',
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: _loading
              ? null
              : () => _setShopVisible(p, !p.visibleInShop),
          icon: Icon(
            p.visibleInShop
                ? Icons.storefront_outlined
                : Icons.visibility_off_outlined,
            color: p.visibleInShop
                ? Theme.of(context).colorScheme.primary
                : AppTheme.textMuted,
          ),
        ),
        IconButton(
          tooltip: 'Remove product',
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: _loading ? null : () => _delete(p),
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.9),
          ),
        ),
        Tooltip(
          message: 'In stock toggle',
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_fab_products_add',
        onPressed: _loading ? null : () => _openEditor(null),
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),
      body: _loading
          ? const AdminBusyView(message: 'Loading catalogue…')
          : (_error != null)
          ? AdminErrorView(message: _error!, onRetry: _reload)
          : RefreshIndicator(
              onRefresh: () async {
                final catalog = context.read<CatalogNotifier>();
                await _reload();
                if (!mounted) return;
                await catalog.refresh(silent: true, warmShopCovers: false);
              },
              child: ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 88,
                  top: 8,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final p = _items[index];
                  return AdminInsetCard(
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _openEditor(p),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                              child: LayoutBuilder(
                                builder: (context, box) {
                                  final titleStyle =
                                      Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ) ??
                                      const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      );

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _avatar(
                                        p,
                                        radius: box.maxWidth < 340 ? 20 : 24,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.title,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: titleStyle,
                                            ),
                                            const SizedBox(height: 6),
                                            _subtitle(p),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                            child: _actionsRow(p),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
