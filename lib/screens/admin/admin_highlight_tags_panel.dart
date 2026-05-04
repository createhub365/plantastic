import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/highlight_tag.dart';
import '../../providers/catalog_notifier.dart';
import '../../services/highlight_tag_service.dart';
import '../../theme/highlight_icons.dart';
import '../../widgets/admin/admin_widgets.dart';

/// Admin catalogue for shopper “highlight” pills (eco, vastu, etc.).
class AdminHighlightTagsPanel extends StatefulWidget {
  const AdminHighlightTagsPanel({super.key});

  @override
  State<AdminHighlightTagsPanel> createState() =>
      _AdminHighlightTagsPanelState();
}

class _AdminHighlightTagsPanelState extends State<AdminHighlightTagsPanel>
    with AutomaticKeepAliveClientMixin {
  List<HighlightTag> _items = [];
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
        _items = List<HighlightTag>.from(
          context.read<CatalogNotifier>().highlightCatalog,
        );
      } else {
        _items = await HighlightTagService.fetchAllOrdered();
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
      await n.reloadHighlightCatalog();
      if (!mounted) return;
      await _reload();
    });
  }

  Future<void> _addHighlight() async {
    final titleCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New highlight'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Eco-friendly',
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
    final raw = titleCtrl.text.trim();
    titleCtrl.dispose();
    if (submitted != true || !mounted) return;
    if (raw.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a title with at least 2 characters.'),
        ),
      );
      return;
    }
    if (!AppConfig.supabaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase not configured — cannot save highlights.'),
        ),
      );
      return;
    }
    try {
      final maxOrder = _items.isEmpty
          ? 0
          : _items.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);
      await HighlightTagService.create(title: raw, sortOrder: maxOrder + 10);
      await _reload();
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadHighlightCatalog();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Highlight added.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _edit(HighlightTag item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final labelCtrl = TextEditingController(text: item.label);
    final bodyCtrl = TextEditingController(text: item.body);
    String selectedIcon = item.iconKey.trim().isEmpty
        ? 'eco'
        : item.iconKey.trim();
    if (!kHighlightIconKeys.contains(selectedIcon)) {
      selectedIcon = 'eco';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit highlight'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pill label (optional)',
                    helperText: 'Short text on shopper chips; empty uses title',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(selectedIcon),
                  decoration: const InputDecoration(labelText: 'Icon'),
                  initialValue: selectedIcon,
                  items: [
                    for (final k in kHighlightIconKeys)
                      DropdownMenuItem(
                        value: k,
                        child: Row(
                          children: [
                            Icon(highlightIcon(k), size: 20),
                            const SizedBox(width: 10),
                            Text(k),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setLocal(() => selectedIcon = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Detail text',
                    hintText: 'Shown when shopper taps the pill',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
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
      ),
    );

    final title = titleCtrl.text.trim();
    final label = labelCtrl.text.trim();
    final body = bodyCtrl.text;
    titleCtrl.dispose();
    labelCtrl.dispose();
    bodyCtrl.dispose();

    if (ok != true || !mounted || !AppConfig.supabaseReady) return;
    if (title.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must be at least 2 characters.')),
      );
      return;
    }

    try {
      await HighlightTagService.update(
        id: item.id,
        title: title,
        label: label,
        iconKey: selectedIcon,
        body: body,
      );
      await _reload();
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadHighlightCatalog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  static String _deleteConfirmationName(HighlightTag item) {
    final t = item.title.trim();
    if (t.isNotEmpty) return t;
    final l = item.label.trim();
    if (l.isNotEmpty) return l;
    return item.id;
  }

  Future<void> _delete(HighlightTag item) async {
    if (!AppConfig.supabaseReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase not configured — cannot delete highlights.'),
        ),
      );
      return;
    }

    final expected = _deleteConfirmationName(item);
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final typed = confirmCtrl.text.trim();
            final matches = typed == expected;

            return AlertDialog(
              title: const Text('Remove highlight'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'This will remove the highlight from the catalogue. '
                      'Type its name exactly as below to confirm.',
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      expected,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Type name to confirm',
                        errorText: typed.isNotEmpty && !matches
                            ? 'Does not match'
                            : null,
                      ),
                      onChanged: (_) => setLocal(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                  ),
                  onPressed: matches ? () => Navigator.pop(ctx, true) : null,
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        );
      },
    );

    confirmCtrl.dispose();

    if (ok != true || !mounted) return;
    try {
      await HighlightTagService.deleteById(item.id);
      await _reload();
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadHighlightCatalog();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Highlight removed.')));
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
      await HighlightTagService.updateSortOrders(_items);
      if (!mounted) return;
      await context.read<CatalogNotifier>().reloadHighlightCatalog();
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
      return const AdminBusyView(message: 'Loading highlights…');
    }
    if (_error != null) {
      return AdminErrorView(message: _error!, onRetry: _reload);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_fab_highlight_add',
        onPressed: _addHighlight,
        icon: const Icon(Icons.add),
        label: const Text('Highlight'),
      ),
      body: _items.isEmpty
          ? RefreshIndicator(
              onRefresh: () async {
                await context.read<CatalogNotifier>().reloadHighlightCatalog();
                if (!mounted) return;
                await _reload();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.paddingOf(context).top + 40),
                  AdminEmptyView(
                    icon: Icons.interests_outlined,
                    title: 'No highlights yet',
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
                      await context
                          .read<CatalogNotifier>()
                          .reloadHighlightCatalog();
                      if (!mounted) return;
                      await _reload();
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
                            leading: Icon(highlightIcon(item.iconKey)),
                            title: Text(item.title),
                            subtitle: Text(
                              item.body.trim().isEmpty
                                  ? 'No detail text • ${item.iconKey}'
                                  : item.body
                                            .trim()
                                            .replaceAll('\n', ' ')
                                            .length >
                                        72
                                  ? '${item.body.trim().replaceAll(RegExp(r'\s+'), ' ').substring(0, 69)}…'
                                  : item.body.trim().replaceAll(
                                      RegExp(r'\s+'),
                                      ' ',
                                    ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit',
                                  iconSize: 20,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () => _edit(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Remove',
                                  iconSize: 20,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () => _delete(item),
                                ),
                              ],
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
