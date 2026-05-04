import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/kit_preset.dart';
import '../../providers/catalog_notifier.dart';
import '../../services/kit_preset_service.dart';
import '../../widgets/admin/admin_widgets.dart';
import 'admin_kit_preset_editor_screen.dart';

class AdminKitPresetsPanel extends StatefulWidget {
  const AdminKitPresetsPanel({super.key});

  @override
  State<AdminKitPresetsPanel> createState() => _AdminKitPresetsPanelState();
}

class _AdminKitPresetsPanelState extends State<AdminKitPresetsPanel>
    with AutomaticKeepAliveClientMixin {
  List<KitPreset> _items = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  Future<void> _reload() async {
    final notifier = context.read<CatalogNotifier>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!AppConfig.supabaseReady) {
        _items = List<KitPreset>.from(notifier.kitPresets);
      } else {
        _items = await KitPresetService.fetchAllOrdered();
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
      await n.reloadKitPresets();
      if (!mounted) return;
      await _reload();
    });
  }

  Future<void> _delete(KitPreset p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text('Remove "${p.name}"? Products are not deleted.'),
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
      await KitPresetService.deleteById(p.id);
      await _reload();
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadKitPresets();
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
      await KitPresetService.updateSortOrders(_items);
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadKitPresets();
    } catch (e) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openEditor(KitPreset? initial) async {
    final notifier = context.read<CatalogNotifier>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminKitPresetEditorScreen(initial: initial),
      ),
    );
    if (!mounted || saved != true) return;
    await _reload();
    if (!mounted) return;
    await notifier.reloadKitPresets();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const AdminBusyView(message: 'Loading presets…');
    }
    if (_error != null) {
      return AdminErrorView(message: _error!, onRetry: _reload);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_fab_kit_presets_add',
        onPressed: () => _openEditor(null),
        icon: const Icon(Icons.add),
        label: const Text('Preset'),
      ),
      body: _items.isEmpty
          ? RefreshIndicator(
              onRefresh: () async {
                final notifier = context.read<CatalogNotifier>();
                await _reload();
                if (!mounted) return;
                await notifier.reloadKitPresets();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.paddingOf(context).top + 40),
                  AdminEmptyView(
                    icon: Icons.layers_outlined,
                    title: 'No kit presets yet',
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
                      await notifier.reloadKitPresets();
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
                            title: Text(item.name),
                            subtitle: Text(
                              '${item.catalogIds.length} item(s) • Tap to edit',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () => _openEditor(item),
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
