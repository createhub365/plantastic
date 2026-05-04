import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/kit_preset.dart';
import '../../providers/catalog_notifier.dart';
import '../../services/kit_preset_service.dart';
import '../../theme/admin_shell.dart';
import '../../widgets/plantastic_app_bar.dart';
import '../../widgets/plantastic_loading.dart';

class AdminKitPresetEditorScreen extends StatefulWidget {
  const AdminKitPresetEditorScreen({super.key, this.initial});

  final KitPreset? initial;

  @override
  State<AdminKitPresetEditorScreen> createState() =>
      _AdminKitPresetEditorScreenState();
}

class _AdminKitPresetEditorScreenState
    extends State<AdminKitPresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late Set<String> _selectedIds;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _selectedIds = {};
    final cat = Provider.of<CatalogNotifier>(context, listen: false);
    if (p != null) {
      _selectedIds.addAll(p.catalogIds);
      _sanitizeAgainstCatalog(cat);
    } else {
      _selectedIds.addAll(cat.kitCatalog.take(4).map((e) => e.id));
      if (_selectedIds.isEmpty) {
        _selectedIds.addAll(cat.kitCatalog.map((e) => e.id));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await cat.refresh(silent: true, warmShopCovers: false);
      if (!mounted) return;
      setState(() => _sanitizeAgainstCatalog(cat));
    });
  }

  void _sanitizeAgainstCatalog(CatalogNotifier cat) {
    final ok = cat.kitCatalog.map((e) => e.id).toSet();
    _selectedIds.removeWhere((id) => !ok.contains(id));
    if (!_isEdit && _selectedIds.isEmpty && cat.kitCatalog.isNotEmpty) {
      _selectedIds.addAll(cat.kitCatalog.take(4).map((e) => e.id));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = context.read<CatalogNotifier>();
    final trimmed = _name.text.trim();
    if (trimmed.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name (at least 2 characters).')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick at least one catalog item for this preset.'),
        ),
      );
      return;
    }

    final orderedIds = notifier.orderedSelectedIds(
      _selectedIds,
      notifier.kitCatalog,
    );

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await KitPresetService.updateFull(
          widget.initial!.copyWith(name: trimmed, catalogIds: orderedIds),
        );
      } else {
        final highest = notifier.kitPresets.fold<int>(
          0,
          (m, q) => q.sortOrder > m ? q.sortOrder : m,
        );
        await KitPresetService.create(
          name: trimmed,
          catalogIds: orderedIds,
          sortOrder: highest + 10,
        );
      }
      if (!mounted) return;
      await notifier.reloadKitPresets();
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CatalogNotifier>();
    final kits = notifier.kitCatalog;

    return Theme(
      data: AdminShell.themeShopperChrome(),
      child: DecoratedBox(
        decoration: AdminShell.shopperBackground,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PlantasticAppBar(
            showBack: true,
            replacementToolbarHeight: 56,
            replacementTitle: Text(
              _isEdit ? 'Edit kit preset' : 'New kit preset',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.paddingOf(context).bottom + 80,
                ),
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Preset name',
                      hintText: 'e.g. Balcony starter',
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Name required'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Include kit items',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (kits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Catalog is empty. Add kit items first (Kit items tab).',
                      ),
                    )
                  else
                    ...kits.map((item) {
                      final on = _selectedIds.contains(item.id);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: on,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.add(item.id);
                            } else {
                              _selectedIds.remove(item.id);
                            }
                          });
                        },
                        title: Text(item.label),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  const SizedBox(height: 24),
                  Text(
                    'On a product, use "Choose a preset to apply…" above each '
                    'checklist to copy this bundle.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: kits.isEmpty || _saving
                        ? null
                        : () => _save(context),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: Center(child: PlantasticLoading.inline),
                          )
                        : Text(_isEdit ? 'Save preset' : 'Create preset'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
