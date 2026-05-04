import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/kit_catalog_item.dart';
import '../../providers/catalog_notifier.dart';
import '../../services/kit_catalog_service.dart';
import '../../widgets/admin/admin_widgets.dart';

class AdminKitCatalogPanel extends StatefulWidget {
  const AdminKitCatalogPanel({super.key});

  @override
  State<AdminKitCatalogPanel> createState() => _AdminKitCatalogPanelState();
}

class _AdminKitCatalogPanelState extends State<AdminKitCatalogPanel>
    with AutomaticKeepAliveClientMixin {
  List<KitCatalogItem> _items = [];
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
      if (!AppConfig.supabaseReady) {
        final n = context.read<CatalogNotifier>();
        _items = List<KitCatalogItem>.from(n.kitCatalog);
      } else {
        _items = await KitCatalogService.fetchAllOrdered();
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final n = context.read<CatalogNotifier>();
      await n.reloadKitCatalog();
      if (!mounted) return;
      await _reload();
    });
  }

  Future<void> _addItem() async {
    final labelCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New kit item'),
        content: TextField(
          controller: labelCtrl,
          decoration: const InputDecoration(
            labelText: 'Label (shown in product editor)',
            hintText: 'e.g. Watering can',
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final raw = labelCtrl.text.trim();
    labelCtrl.dispose();
    if (raw.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a label with at least 2 characters.'),
        ),
      );
      return;
    }
    if (!AppConfig.supabaseReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase is not configured — items cannot be saved.'),
        ),
      );
      return;
    }
    try {
      final maxOrder = _items.isEmpty
          ? 0
          : _items.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);
      await KitCatalogService.createLabelOnly(
        label: raw,
        sortOrder: maxOrder + 10,
      );
      await _reload();
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadKitCatalog();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item added.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _rename(KitCatalogItem item) async {
    final c = TextEditingController(text: item.label);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final label = c.text.trim();
    c.dispose();
    if (label.length < 2) return;
    if (!AppConfig.supabaseReady) return;
    try {
      await KitCatalogService.updateLabel(id: item.id, label: label);
      await _reload();
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadKitCatalog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(KitCatalogItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.label}"?'),
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
    if (ok != true || !AppConfig.supabaseReady) return;
    try {
      await KitCatalogService.deleteById(item.id);
      await _reload();
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadKitCatalog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final row = _items.removeAt(oldIndex);
      _items.insert(newIndex, row);
    });
    if (!AppConfig.supabaseReady) return;
    try {
      await KitCatalogService.updateSortOrders(_items);
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadKitCatalog();
    } catch (e) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const AdminBusyView(message: 'Loading kit catalogue…');
    }
    if (_error != null) {
      return AdminErrorView(message: _error!, onRetry: _reload);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_fab_kit_catalog_add',
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Kit item'),
      ),
      body: _items.isEmpty
          ? RefreshIndicator(
              onRefresh: () async {
                final notifier = context.read<CatalogNotifier>();
                await _reload();
                if (!mounted) return;
                await notifier.reloadKitCatalog();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.paddingOf(context).top + 40),
                  AdminEmptyView(
                    icon: Icons.checklist_rtl_outlined,
                    title: 'No kit items yet',
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final notifier = context.read<CatalogNotifier>();
                      await _reload();
                      if (!mounted) return;
                      await notifier.reloadKitCatalog();
                    },
                    child: ReorderableListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 88,
                        top: 4,
                      ),
                      itemCount: _items.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return AdminInsetCard(
                          key: ValueKey(item.id),
                          child: ListTile(
                            leading: Icon(
                              Icons.drag_handle,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.85),
                            ),
                            title: Text(item.label),
                            subtitle: Text(
                              'Hold to delete • Drag to reorder',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _rename(item),
                            ),
                            onLongPress: () => _delete(item),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
