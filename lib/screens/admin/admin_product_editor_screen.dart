import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/kit_catalog_ids.dart';
import '../../data/kit_preset_ids.dart';
import '../../data/seed_products.dart';
import '../../models/gallery_slide_meta.dart';
import '../../models/kit_preset.dart';
import '../../models/product.dart';
import '../../models/product_kit_line.dart';
import '../../providers/catalog_notifier.dart';
import '../../catalog/catalog_assets.dart';
import '../../services/admin_catalog_service.dart';
import '../../services/product_image_upload_service.dart';
import '../../theme/admin_shell.dart';
import '../../theme/app_theme.dart';
import '../../data/world_flowers_catalog.dart';
import '../../util/gallery_pick.dart';
import '../../layout/plantastic_layout.dart';
import '../../theme/highlight_icons.dart';
import '../product_detail_screen.dart';
import '../../widgets/plantastic_loading.dart';
import '../../widgets/plantastic_app_bar.dart';
import '../../widgets/admin/admin_widgets.dart';
import '../../widgets/plantastic_scroll_behavior.dart';
import '../../widgets/product_shop_card.dart';
import '../../widgets/world_flower_tile_field.dart';

class _GallerySlot {
  _GallerySlot({
    required this.slotId,
    this.remoteUrl,
    this.pendingBytes,
    this.pendingFileName = '',
    this.onFlowerEdited,
    String flowerNameInitial = '',
    String persistedSnippetInitial = '',
  }) : flowerNameCtrl = TextEditingController(text: flowerNameInitial),
       flowerFocus = FocusNode(),
       persistedSnippet = persistedSnippetInitial.trim() {
    void listener() => onFlowerEdited?.call();
    _flowerListener = listener;
    flowerNameCtrl.addListener(_flowerListener);
  }

  final String slotId;
  String? remoteUrl;
  Uint8List? pendingBytes;
  String pendingFileName;

  /// From DB or last catalogue pick; keeps custom snippets when name is bespoke.
  String persistedSnippet;
  final TextEditingController flowerNameCtrl;
  final FocusNode flowerFocus;
  final void Function()? onFlowerEdited;
  late final VoidCallback _flowerListener;

  factory _GallerySlot.remote(
    String url, {
    String flowerNameInitial = '',
    String persistedSnippetInitial = '',
    void Function()? onFlowerEdited,
  }) {
    final u = url.trim();
    return _GallerySlot(
      slotId: EditorIds.newDraftLine(),
      remoteUrl: u.isEmpty ? null : u,
      onFlowerEdited: onFlowerEdited,
      flowerNameInitial: flowerNameInitial,
      persistedSnippetInitial: persistedSnippetInitial,
    );
  }

  factory _GallerySlot.pendingUpload(
    Uint8List bytes,
    String fileName, {
    void Function()? onFlowerEdited,
  }) {
    final name = fileName.trim().isEmpty ? 'photo.jpg' : fileName.trim();
    return _GallerySlot(
      slotId: EditorIds.newDraftLine(),
      pendingBytes: bytes,
      pendingFileName: name,
      onFlowerEdited: onFlowerEdited,
    );
  }

  void dispose() {
    flowerNameCtrl.removeListener(_flowerListener);
    flowerNameCtrl.dispose();
    flowerFocus.dispose();
  }

  Future<void> uploadIfNeeded(String productId) async {
    if ((remoteUrl ?? '').trim().isNotEmpty) return;
    final b = pendingBytes;
    if (b == null || b.isEmpty) return;
    final url = await ProductImageUploadService.uploadProductBytes(
      productId: productId,
      bytes: b,
      suggestedPath: pendingFileName.trim().isEmpty
          ? 'photo.jpg'
          : pendingFileName,
    );
    remoteUrl = url;
    pendingBytes = null;
    pendingFileName = '';
  }
}

class _DraftKit {
  _DraftKit({
    required this.lineId,
    required this.labelCtrl,
    required this.priceCtrl,
    required Set<String> catalogIds,
    this.presetId,
    this.kitUsesWholeGallery = true,
    Set<String>? kitSlotSelection,
  }) : catalogIds = Set<String>.from(catalogIds),
       kitSlotSelection = Set<String>.from(kitSlotSelection ?? const {});

  final String lineId;
  final TextEditingController labelCtrl;
  final TextEditingController priceCtrl;
  final Set<String> catalogIds;
  String? presetId;
  bool kitUsesWholeGallery;
  final Set<String> kitSlotSelection;

  void dispose() {
    labelCtrl.dispose();
    priceCtrl.dispose();
  }

  factory _DraftKit.fromKitLine(ProductKitLine k) {
    return _DraftKit(
      lineId: k.lineId,
      labelCtrl: TextEditingController(text: k.label),
      priceCtrl: TextEditingController(text: '${k.priceInr}'),
      catalogIds: Set<String>.from(k.catalogIds),
      presetId: k.presetId,
      kitUsesWholeGallery: k.imageUrls.isEmpty,
    );
  }

  factory _DraftKit.fromPreset(KitPreset p, {required int fallbackPrice}) {
    return _DraftKit(
      lineId: EditorIds.newDraftLine(),
      labelCtrl: TextEditingController(text: p.name),
      priceCtrl: TextEditingController(text: '$fallbackPrice'),
      catalogIds: Set<String>.from(p.catalogIds),
      presetId: p.id,
    );
  }
}

abstract final class EditorIds {
  static final _rnd = Random();
  static String newDraftLine() =>
      'k${DateTime.now().microsecondsSinceEpoch}_${_rnd.nextInt(999999)}';
}

class AdminProductEditorScreen extends StatefulWidget {
  const AdminProductEditorScreen({super.key, this.initial});

  final Product? initial;

  @override
  State<AdminProductEditorScreen> createState() =>
      _AdminProductEditorScreenState();
}

class _AdminProductEditorScreenState extends State<AdminProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleFieldKey = GlobalKey();
  final GlobalKey _productImagesSectionKey = GlobalKey();
  late TextEditingController _title;
  late TextEditingController _subtitle;
  late TextEditingController _itemFilter;

  final FocusNode _titleFlowerFocus = FocusNode();

  late String _category;
  late bool _inStock;
  late bool _visibleInShop;

  /// Selected highlight catalogue ids (persist order = catalogue sort_order).
  late List<String> _highlightIds;

  final List<_DraftKit> _drafts = [];
  final List<_GallerySlot> _gallery = [];
  String? _coverSlotId;

  /// Valid slot in [_gallery]. If [_coverSlotId] is unset or stale, first image wins.
  String? get _effectiveCoverSlotId {
    if (_gallery.isEmpty) return null;
    final id = _coverSlotId?.trim();
    if (id != null && id.isNotEmpty && _gallery.any((s) => s.slotId == id)) {
      return id;
    }
    return _gallery.first.slotId;
  }

  void _markFlowerEdited() {
    if (mounted) setState(() {});
  }

  bool _saving = false;

  /// Rebuild admin full-screen detail preview while that route is open.
  final ValueNotifier<int> _detailPreviewRevision = ValueNotifier<int>(0);
  bool _detailPreviewRouteOpen = false;

  bool get _isEdit => widget.initial != null;

  KitPreset? _findPreset(List<KitPreset> all, String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _clearDraftControllers() {
    for (final d in _drafts) {
      d.dispose();
    }
    _drafts.clear();
  }

  void _fillStarterDeluxe(CatalogNotifier cat) {
    _clearDraftControllers();
    final presets = cat.kitPresets;
    final sp = _findPreset(presets, KitPresetIds.starterBundle);
    final dp = _findPreset(presets, KitPresetIds.deluxeBundle);

    if (sp != null) {
      _drafts.add(_DraftKit.fromPreset(sp, fallbackPrice: 499));
    } else {
      _drafts.add(
        _DraftKit(
          lineId: EditorIds.newDraftLine(),
          labelCtrl: TextEditingController(text: 'Starter kit'),
          priceCtrl: TextEditingController(text: '499'),
          catalogIds: Set<String>.from(KitCatalogIds.defaultStarterIds),
        ),
      );
    }
    if (dp != null) {
      _drafts.add(_DraftKit.fromPreset(dp, fallbackPrice: 799));
    } else {
      _drafts.add(
        _DraftKit(
          lineId: EditorIds.newDraftLine(),
          labelCtrl: TextEditingController(text: 'Deluxe kit'),
          priceCtrl: TextEditingController(text: '799'),
          catalogIds: Set<String>.from(KitCatalogIds.defaultDeluxeIds),
        ),
      );
    }
  }

  void _afterCatalogBootstrap(CatalogNotifier cat) {
    if (_isEdit || _drafts.isNotEmpty) return;
    _fillStarterDeluxe(cat);
  }

  List<String> _labels(ProductKitLine k, CatalogNotifier cat) =>
      k.inclusionLines(cat.kitCatalog);

  void _syncDraftKitImagesFrom(Product prod) {
    final urlToSlot = <String, String>{};
    for (final s in _gallery) {
      final r = s.remoteUrl?.trim() ?? '';
      if (r.isNotEmpty) urlToSlot[r] = s.slotId;
    }
    for (var i = 0; i < _drafts.length && i < prod.kits.length; i++) {
      final dk = _drafts[i];
      final kk = prod.kits[i];
      if (kk.imageUrls.isEmpty) {
        dk.kitUsesWholeGallery = true;
        dk.kitSlotSelection.clear();
      } else {
        dk.kitUsesWholeGallery = false;
        dk.kitSlotSelection.clear();
        for (final url in kk.imageUrls) {
          final sid = urlToSlot[url.trim()];
          if (sid != null) dk.kitSlotSelection.add(sid);
        }
        if (dk.kitSlotSelection.isEmpty) {
          dk.kitUsesWholeGallery = true;
        }
      }
    }
  }

  List<String> _kitPersistedUrls(_DraftKit d) {
    if (d.kitUsesWholeGallery || _gallery.isEmpty) return const [];
    final out = <String>[];
    for (final s in _gallery) {
      if (!d.kitSlotSelection.contains(s.slotId)) continue;
      final u = s.remoteUrl?.trim() ?? '';
      if (u.isNotEmpty) out.add(u);
    }
    return out;
  }

  List<String> _galleryRemoteUrlsOrdered() {
    return [
      for (final s in _gallery)
        if ((s.remoteUrl ?? '').trim().isNotEmpty) s.remoteUrl!.trim(),
    ];
  }

  List<GallerySlideMeta> _gallerySlideMetaForSave() {
    final out = <GallerySlideMeta>[];
    for (final s in _gallery) {
      if ((s.remoteUrl ?? '').trim().isEmpty) continue;
      out.add(_slideMetaForGallerySlot(s));
    }
    return out;
  }

  /// Same indexing as [_previewCarouselSlotOrder] URLs (shop draft preview).
  List<GallerySlideMeta> _gallerySlideMetaAlignedWithPreviewCarousel() {
    final out = <GallerySlideMeta>[];
    for (final s in _gallery) {
      final bytes = s.pendingBytes;
      if (bytes != null && bytes.isNotEmpty) {
        out.add(_slideMetaForGallerySlot(s));
        continue;
      }
      final raw = (s.remoteUrl ?? '').trim();
      if (raw.isEmpty) continue;
      if (!CatalogAssets.looksLikeRemoteUrl(raw) &&
          !CatalogAssets.isBundledRef(raw)) {
        continue;
      }
      out.add(_slideMetaForGallerySlot(s));
    }
    return out;
  }

  void _onCatalogFlowerChosenForSlot(_GallerySlot s, WorldFlower w) {
    setState(() {
      s.persistedSnippet = w.snippet;
      if (_effectiveCoverSlotId != null && _effectiveCoverSlotId == s.slotId) {
        _subtitle.text = w.snippet;
      }
    });
  }

  GallerySlideMeta _slideMetaForGallerySlot(_GallerySlot s) {
    final name = s.flowerNameCtrl.text.trim();
    final sn = s.persistedSnippet.trim().isNotEmpty
        ? s.persistedSnippet.trim()
        : snippetForFlowerNameExact(name) ?? '';
    return GallerySlideMeta(flowerName: name, snippet: sn);
  }

  /// Bottom inset so floating snackbars stay **above** the pinned Cancel/Save bar.
  double _editorSnackMarginBottom(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    return mq.padding.bottom + mq.viewInsets.bottom + 108;
  }

  void _showEditorSnack(
    BuildContext ctx,
    String message, {
    bool error = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(ctx);
    final cs = theme.colorScheme;
    final messenger = ScaffoldMessenger.of(ctx);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(14, 0, 14, _editorSnackMarginBottom(ctx)),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        showCloseIcon: true,
        closeIconColor: error ? cs.onError : cs.onInverseSurface,
        backgroundColor: error
            ? cs.error.withValues(alpha: 0.96)
            : cs.inverseSurface.withValues(alpha: 0.94),
        duration: duration,
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: error ? cs.onError : cs.onInverseSurface,
            height: 1.38,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _resolvedCoverRemote() {
    if (_gallery.isEmpty) return '';
    final coverId = _effectiveCoverSlotId;
    if (coverId != null) {
      for (final s in _gallery) {
        if (s.slotId != coverId) continue;
        final u = s.remoteUrl?.trim() ?? '';
        if (u.isNotEmpty) return u;
        break;
      }
    }
    for (final s in _gallery) {
      final u = s.remoteUrl?.trim() ?? '';
      if (u.isNotEmpty) return u;
    }
    return '';
  }

  Future<void> _pickGallery() async {
    if (!mounted) return;
    try {
      final picked = await pickGalleryImages();
      if (!mounted) return;
      if (picked.isEmpty) return;
      setState(() {
        for (final p in picked) {
          _gallery.add(
            _GallerySlot.pendingUpload(
              p.bytes,
              p.name,
              onFlowerEdited: _markFlowerEdited,
            ),
          );
        }
        _coverSlotId ??= _gallery.first.slotId;
      });
      if (!mounted) return;
      final n = picked.length;
      _showEditorSnack(
        context,
        n == 1
            ? '1 image added · Scrolled you to Photos. Tap Save below to upload when ready.'
            : '$n images added · Scrolled to Photos. Tap Save below to upload them when ready.',
        duration: const Duration(seconds: 5),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _productImagesSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: 0.12,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showEditorSnack(context, '$e', error: true);
    }
  }

  void _removeGallerySlot(String slotId) {
    setState(() {
      final removed = _gallery.where((s) => s.slotId == slotId).toList();
      for (final s in removed) {
        s.dispose();
      }
      _gallery.removeWhere((s) => s.slotId == slotId);
      for (final d in _drafts) {
        d.kitSlotSelection.remove(slotId);
        if (!d.kitUsesWholeGallery &&
            _gallery.isNotEmpty &&
            d.kitSlotSelection.isEmpty) {
          d.kitUsesWholeGallery = true;
        }
      }
      if (_coverSlotId == slotId) {
        _coverSlotId = _gallery.isNotEmpty ? _gallery.first.slotId : null;
      }
    });
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_detailPreviewRouteOpen) {
      _detailPreviewRevision.value++;
    }
  }

  void _toggleCover(String slotId) {
    setState(() => _coverSlotId = slotId);
  }

  Product _assemblePreviewCatalogRow(
    List<ProductKitLine> kitsDraft,
    CatalogNotifier cat,
  ) {
    final gall = _previewCarouselSlotOrder().$1;
    var cover = '';
    final coverId = _effectiveCoverSlotId;
    if (coverId != null) {
      for (final s in _gallery) {
        if (s.slotId == coverId && (s.remoteUrl ?? '').trim().isNotEmpty) {
          cover = s.remoteUrl!.trim();
          break;
        }
      }
    }
    cover = cover.trim();

    return Product(
      id: widget.initial?.id ?? 'preview',
      title: _title.text.trim().isEmpty ? 'Title' : _title.text.trim(),
      subtitle: _subtitle.text.trim().isEmpty ? '—' : _subtitle.text.trim(),
      category: _category,
      galleryUrls: gall,
      coverImageUrl: cover,
      kits: kitsDraft,
      inStock: _inStock,
      visibleInShop: _visibleInShop,
      highlightTagIds: cat.orderedHighlightIds(
        _highlightIds.toSet(),
        cat.highlightCatalog,
      ),
      gallerySlideMeta: _gallerySlideMetaAlignedWithPreviewCarousel(),
    );
  }

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _title = TextEditingController(text: p?.title ?? '');
    _subtitle = TextEditingController(text: p?.subtitle ?? '');
    _itemFilter = TextEditingController();
    _subtitle.addListener(() => setState(() {}));
    _title.addListener(() => setState(() {}));

    if (p != null && p.galleryUrls.isNotEmpty) {
      for (var i = 0; i < p.galleryUrls.length; i++) {
        final u = p.galleryUrls[i];
        if (u.trim().isEmpty) continue;
        final gm = i < p.gallerySlideMeta.length ? p.gallerySlideMeta[i] : null;
        _gallery.add(
          _GallerySlot.remote(
            u,
            flowerNameInitial: gm?.flowerName ?? '',
            persistedSnippetInitial: gm?.snippet ?? '',
            onFlowerEdited: _markFlowerEdited,
          ),
        );
      }
      final cov = p.coverImageUrl.trim();
      if (cov.isNotEmpty) {
        final idx = _gallery.indexWhere((s) => (s.remoteUrl ?? '') == cov);
        if (idx >= 0) {
          _coverSlotId = _gallery[idx].slotId;
        }
      }
      if (_coverSlotId == null && _gallery.isNotEmpty) {
        _coverSlotId = _gallery.first.slotId;
      }
    }

    if (p != null && p.kits.isNotEmpty) {
      for (final k in p.kits) {
        _drafts.add(_DraftKit.fromKitLine(k));
      }
      _syncDraftKitImagesFrom(p);
    }

    _category = p?.category ?? kCategoryFlowerSeed;
    _inStock = p?.inStock ?? true;
    _visibleInShop = p?.visibleInShop ?? true;
    _highlightIds = List<String>.from(p?.highlightTagIds ?? const []);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<CatalogNotifier>().refresh(
        silent: true,
        warmShopCovers: false,
      );
      if (!mounted) return;
      setState(() => _afterCatalogBootstrap(context.read<CatalogNotifier>()));
    });
  }

  @override
  void dispose() {
    for (final s in _gallery) {
      s.dispose();
    }
    _scrollController.dispose();
    _clearDraftControllers();
    _title.dispose();
    _subtitle.dispose();
    _itemFilter.dispose();
    _titleFlowerFocus.dispose();
    _detailPreviewRevision.dispose();
    super.dispose();
  }

  void _scrollToTitle() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctx = _titleFieldKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _pickKits(BuildContext ctx, CatalogNotifier cat) async {
    final presets = cat.kitPresets;
    if (presets.isEmpty) {
      _showEditorSnack(ctx, 'Add kit presets first (Admin tab “Kit presets”).');
      return;
    }

    final selectedIds = presets
        .map((x) => x.id)
        .where((pid) => _drafts.any((d) => d.presetId == pid))
        .toSet();

    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (_, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.paddingOf(sheetCtx).bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All available kits',
                    style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select kits to sell on this product. Each gets its own ₹ price.',
                    style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: MediaQuery.of(sheetCtx).size.shortestSide > 380
                        ? 360
                        : 260,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final p in presets)
                            CheckboxListTile(
                              value: selectedIds.contains(p.id),
                              onChanged: (v) => setLocal(() {
                                if (v == true) {
                                  selectedIds.add(p.id);
                                } else {
                                  selectedIds.remove(p.id);
                                }
                              }),
                              title: Text(p.name),
                              subtitle: Text('${p.catalogIds.length} items'),
                              secondary: Icon(
                                Icons.inventory_2_outlined,
                                color: AppTheme.mintGlow.withValues(alpha: 0.9),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _drafts.removeWhere(
                              (d) =>
                                  d.presetId != null &&
                                  !selectedIds.contains(d.presetId),
                            );
                            final have = _drafts
                                .map((d) => d.presetId)
                                .whereType<String>()
                                .toSet();

                            for (final pid in selectedIds) {
                              if (have.contains(pid)) continue;
                              final preset = _findPreset(presets, pid);
                              if (preset == null) continue;
                              final priceGuess =
                                  pid == KitPresetIds.deluxeBundle ? 799 : 499;
                              _drafts.add(
                                _DraftKit.fromPreset(
                                  preset,
                                  fallbackPrice: priceGuess,
                                ),
                              );
                            }
                          });
                          Navigator.pop(sheetCtx);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _reorderDrafts(int o, int n) {
    setState(() {
      if (n > o) n -= 1;
      final r = _drafts.removeAt(o);
      _drafts.insert(n, r);
    });
  }

  Widget _section(
    BuildContext t, {
    Key? key,
    required String title,
    required IconData icon,
    required List<Widget> kids,
  }) {
    final theme = Theme.of(t);
    final scheme = theme.colorScheme;
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 18),
      color: Colors.white.withValues(alpha: 0.97),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.48)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.mintGlow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      icon,
                      size: 22,
                      color: AppTheme.forestBright.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.15,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outline.withValues(alpha: 0.32),
            ),
            const SizedBox(height: 16),
            ...kids,
          ],
        ),
      ),
    );
  }

  Widget _galleryImageMissingPlaceholder(BuildContext ctx, double side) {
    final scheme = Theme.of(ctx).colorScheme;
    final r = BorderRadius.circular(10);
    return SizedBox(
      width: side,
      height: side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: r,
          border: Border.all(color: scheme.outline.withValues(alpha: 0.42)),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: side * 0.38,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _gallerySlotPreview(
    BuildContext ctx,
    _GallerySlot slot, {
    double size = 72,
  }) {
    final r = BorderRadius.circular(10);
    Widget wrap(Widget child) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(borderRadius: r, child: child),
      );
    }

    final pending = slot.pendingBytes;
    if (pending != null && pending.isNotEmpty) {
      return wrap(
        Image.memory(
          pending,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _galleryImageMissingPlaceholder(ctx, size),
        ),
      );
    }

    final raw = (slot.remoteUrl ?? '').trim();
    if (raw.isEmpty) return _galleryImageMissingPlaceholder(ctx, size);

    if (CatalogAssets.isBundledRef(raw)) {
      return wrap(
        Image.asset(
          CatalogAssets.assetPath(raw),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _galleryImageMissingPlaceholder(ctx, size),
        ),
      );
    }

    if (CatalogAssets.looksLikeUsableShopRemoteUrl(raw)) {
      return wrap(
        Image.network(
          raw,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: PlantasticLoading.gallerySlot);
          },
          errorBuilder: (context, error, stackTrace) =>
              _galleryImageMissingPlaceholder(ctx, size),
        ),
      );
    }

    return _galleryImageMissingPlaceholder(ctx, size);
  }

  /// Same pixels as [_gallerySlotPreview] but fills parent (shop preview hero).
  Widget _gallerySlotCoverFill(BuildContext ctx, _GallerySlot slot) {
    Widget fallbackHero() =>
        SizedBox.expand(child: _previewHeroGradientFallback(ctx));

    final pending = slot.pendingBytes;
    if (pending != null && pending.isNotEmpty) {
      return SizedBox.expand(
        child: Image.memory(
          pending,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => fallbackHero(),
        ),
      );
    }

    final raw = (slot.remoteUrl ?? '').trim();
    if (raw.isEmpty) return fallbackHero();

    if (CatalogAssets.isBundledRef(raw)) {
      return SizedBox.expand(
        child: Image.asset(
          CatalogAssets.assetPath(raw),
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => fallbackHero(),
        ),
      );
    }

    if (CatalogAssets.looksLikeUsableShopRemoteUrl(raw)) {
      return SizedBox.expand(
        child: Image.network(
          raw,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: PlantasticLoading.thumbnail);
          },
          errorBuilder: (context, error, stackTrace) => fallbackHero(),
        ),
      );
    }

    return fallbackHero();
  }

  Widget _previewHeroGradientFallback(BuildContext ctx) {
    final flower = _category == kCategoryFlowerSeed;
    final scheme = Theme.of(ctx).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE8F5EF),
            scheme.surface.withValues(alpha: 0.96),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        flower ? Icons.local_florist_outlined : Icons.spa_outlined,
        size: 54,
        color: AppTheme.forestBright.withValues(alpha: 0.28),
      ),
    );
  }

  /// Live hero while editing (pending bytes + remote + bundled refs).
  Widget? _previewShopHeroOverride() {
    if (_gallery.isEmpty) return null;
    final id = _effectiveCoverSlotId;
    _GallerySlot? slot;
    if (id != null) {
      for (final s in _gallery) {
        if (s.slotId == id) {
          slot = s;
          break;
        }
      }
    }
    slot ??= _gallery.first;
    return _gallerySlotCoverFill(context, slot);
  }

  static const double _galleryStripThumbSize = 104;

  Widget _galleryStripIconChip({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _galleryHorizontalThumb(
    BuildContext cx,
    _GallerySlot s, {
    Key? wrapKey,
  }) {
    final coverId = _effectiveCoverSlotId;
    final isCover = coverId != null && coverId == s.slotId;
    final sz = _galleryStripThumbSize;
    return SizedBox(
      key: wrapKey,
      width: sz,
      height: sz,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _gallerySlotPreview(cx, s, size: sz),
          Positioned(
            left: 4,
            top: 4,
            child: _galleryStripIconChip(
              icon: isCover ? Icons.star_rounded : Icons.star_outline_rounded,
              iconColor: isCover
                  ? Colors.amber
                  : Colors.white.withValues(alpha: 0.9),
              tooltip: 'Grid cover',
              onTap: () => _toggleCover(s.slotId),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: _galleryStripIconChip(
              icon: Icons.close_rounded,
              iconColor: Colors.white,
              tooltip: 'Remove',
              onTap: () => _removeGallerySlot(s.slotId),
            ),
          ),
        ],
      ),
    );
  }

  static const double _kitCarouselPickSize = 82;

  void _toggleKitGallerySlot(_DraftKit d, _GallerySlot slot) {
    setState(() {
      if (d.kitUsesWholeGallery) {
        d.kitUsesWholeGallery = false;
        d.kitSlotSelection
          ..clear()
          ..addAll(_gallery.map((x) => x.slotId));
      }
      if (d.kitSlotSelection.contains(slot.slotId)) {
        d.kitSlotSelection.remove(slot.slotId);
      } else {
        d.kitSlotSelection.add(slot.slotId);
      }
      final all = _gallery.length;
      final sel = d.kitSlotSelection.length;
      if (all > 0 && sel >= all) {
        d.kitUsesWholeGallery = true;
        d.kitSlotSelection.clear();
      } else if (sel == 0) {
        d.kitUsesWholeGallery = true;
      }
    });
  }

  Widget _kitCarouselImagePickTile(
    BuildContext t,
    _DraftKit d,
    _GallerySlot slot,
  ) {
    final selected =
        !d.kitUsesWholeGallery && d.kitSlotSelection.contains(slot.slotId);
    final order = _gallery.indexWhere((g) => g.slotId == slot.slotId);
    final orderLabel = order < 0 ? '?' : '${order + 1}';
    final fname = slot.flowerNameCtrl.text.trim();
    final tip = fname.isEmpty
        ? (selected
              ? 'Slide $orderLabel in gallery — shown for this kit. Tap to exclude.'
              : 'Slide $orderLabel — excluded. Tap to include.')
        : (selected
              ? '$fname — shown for this kit. Tap to exclude.'
              : '$fname — excluded for this kit. Tap to include.');

    final sz = _kitCarouselPickSize;

    return Tooltip(
      message: tip,
      waitDuration: const Duration(milliseconds: 550),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleKitGallerySlot(d, slot),
          borderRadius: BorderRadius.circular(14),
          splashColor: AppTheme.mintGlow.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppTheme.mintGlow
                    : Theme.of(t).colorScheme.outline.withValues(alpha: 0.52),
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.mintGlow.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  width: sz,
                  height: sz,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _gallerySlotPreview(t, slot, size: sz),
                      if (!selected)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 4,
                        top: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.74),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Text(
                              orderLabel,
                              style: Theme.of(t).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 3,
                        bottom: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              selected
                                  ? Icons.check_rounded
                                  : Icons.circle_outlined,
                              size: 20,
                              color: selected
                                  ? AppTheme.mintGlow
                                  : Theme.of(t).colorScheme.onSurfaceVariant,
                            ),
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
      ),
    );
  }

  Widget _galleryImageTileWithFlowerType(BuildContext cx, _GallerySlot s) {
    final theme = Theme.of(cx);
    final coverId = _effectiveCoverSlotId;
    final isCover = coverId != null && coverId == s.slotId;
    const fieldExtra = 72.0;
    final columnW = _galleryStripThumbSize + fieldExtra;
    return SizedBox(
      key: ValueKey('${s.slotId}_gallery_col'),
      width: columnW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: _galleryHorizontalThumb(cx, s),
          ),
          if (isCover) ...[
            const SizedBox(height: 4),
            Text(
              '★ Cover — catalogue flower fills subtitle',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.mintGlow.withValues(alpha: 0.88),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 6),
          WorldFlowerTileField(
            controller: s.flowerNameCtrl,
            focusNode: s.flowerFocus,
            theme: theme,
            onCatalogFlowerChosen: (w) => _onCatalogFlowerChosenForSlot(s, w),
          ),
        ],
      ),
    );
  }

  Widget _kitCarouselCustomization(BuildContext t, _DraftKit d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 22),
        Text(
          'Images for this kit',
          style: Theme.of(t).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(t).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Detail page carousel uses your picks below. Order matches Product '
          'images (left → right).',
          style: Theme.of(t).textTheme.bodySmall?.copyWith(
            color: Theme.of(t).colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Same as product gallery'),
          subtitle: Text(
            'When off, tap thumbnails to include or exclude slides for this '
            'kit only.',
            style: Theme.of(t).textTheme.bodySmall?.copyWith(
              color: Theme.of(t).colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          value: d.kitUsesWholeGallery,
          onChanged: (v) {
            setState(() {
              d.kitUsesWholeGallery = v;
              if (v) {
                d.kitSlotSelection.clear();
              } else {
                d.kitSlotSelection
                  ..clear()
                  ..addAll(_gallery.map((x) => x.slotId));
              }
            });
          },
        ),
        if (!d.kitUsesWholeGallery) ...[
          if (_gallery.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(
                'Add photos under Product images first, then choose which '
                'slides this kit uses.',
                style: Theme.of(t).textTheme.bodySmall?.copyWith(
                  color: Theme.of(t).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final slot in _gallery)
                  _kitCarouselImagePickTile(t, d, slot),
              ],
            ),
        ],
      ],
    );
  }

  (List<String>, Map<int, Uint8List>) _previewCarouselSlotOrder() {
    final urls = <String>[];
    final mem = <int, Uint8List>{};
    const ph = 'https://preview.invalid/plantastic';
    for (final s in _gallery) {
      final bytes = s.pendingBytes;
      if (bytes != null && bytes.isNotEmpty) {
        mem[urls.length] = Uint8List.fromList(bytes);
        urls.add(ph);
        continue;
      }
      final raw = (s.remoteUrl ?? '').trim();
      if (raw.isEmpty) continue;
      if (CatalogAssets.looksLikeUsableShopRemoteUrl(raw)) {
        urls.add(raw);
      } else if (CatalogAssets.isBundledRef(raw)) {
        urls.add(CatalogAssets.assetPath(raw));
      }
    }
    return (urls, mem);
  }

  List<ProductKitLine> _previewKitLinesWithImages(CatalogNotifier cat) {
    final out = <ProductKitLine>[];
    for (final d in _drafts) {
      final inrRaw = int.tryParse(d.priceCtrl.text.trim()) ?? 0;
      final ordered = cat.orderedSelectedIds(d.catalogIds, cat.kitCatalog);
      final imgs = List<String>.from(_kitPersistedUrls(d));
      out.add(
        ProductKitLine(
          lineId: d.lineId,
          label: d.labelCtrl.text.trim().isEmpty
              ? 'Kit'
              : d.labelCtrl.text.trim(),
          presetId: d.presetId,
          catalogIds: ordered,
          priceInr: inrRaw < 1 ? 0 : inrRaw,
          imageUrls: imgs,
        ),
      );
    }
    return out;
  }

  ProductPreviewData _buildDetailPreviewPayload(CatalogNotifier cat) {
    final product = _assemblePreviewCatalogRow(
      _previewKitLinesWithImages(cat),
      cat,
    );
    final mem = _previewCarouselSlotOrder().$2;
    return ProductPreviewData(product: product, carouselMemory: mem);
  }

  Future<void> _openFullDetailPreview(
    BuildContext tc,
    CatalogNotifier catalog,
  ) async {
    _detailPreviewRouteOpen = true;
    _detailPreviewRevision.value++;
    await Navigator.of(tc).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => ProductDetailScreen.draftPreview(
          previewDataBuilder: () => _buildDetailPreviewPayload(catalog),
          previewRevision: _detailPreviewRevision,
        ),
      ),
    );
    _detailPreviewRouteOpen = false;
  }

  Widget _draftRow(BuildContext t, int idx, _DraftKit d, CatalogNotifier cat) {
    final q = _itemFilter.text.trim().toLowerCase();
    final catalogue = cat.kitCatalog.where((kit) {
      if (q.isEmpty) return true;
      return kit.label.toLowerCase().contains(q);
    }).toList();

    final carouselKids = [
      if (catalogue.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('No items match filter.'),
        ),
      if (catalogue.isNotEmpty)
        ...catalogue.map((item) {
          final on = d.catalogIds.contains(item.id);
          return CheckboxListTile(
            dense: true,
            title: Text(item.label),
            value: on,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  d.catalogIds.add(item.id);
                } else {
                  d.catalogIds.remove(item.id);
                }
              });
            },
          );
        }),
      if (_gallery.isNotEmpty) _kitCarouselCustomization(t, d),
    ];

    final body = ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: ReorderableDragStartListener(
        index: idx,
        child: Icon(
          Icons.drag_handle,
          color: Theme.of(
            t,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: d.labelCtrl,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Shown in shop',
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: d.priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              isDense: true,
              labelText: '₹ Price',
            ),
          ),
          if (d.presetId != null)
            Text(
              'Preset: ${_findPreset(cat.kitPresets, d.presetId!)?.name}',
              style: Theme.of(t).textTheme.bodySmall?.copyWith(
                color: Theme.of(t).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Remove',
        icon: Icon(
          Icons.delete_outline,
          color: Colors.redAccent.withValues(alpha: 0.85),
        ),
        onPressed: () {
          setState(() {
            final i = _drafts.indexWhere((x) => x.lineId == d.lineId);
            if (i < 0) return;
            final r = _drafts.removeAt(i);
            r.dispose();
          });
        },
      ),
      children: carouselKids,
    );

    return KeyedSubtree(
      key: ValueKey(d.lineId),
      child: Card(
        color: Colors.white.withValues(alpha: 0.97),
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(t).colorScheme.outline.withValues(alpha: 0.45),
          ),
        ),
        child: body,
      ),
    );
  }

  Future<void> _submit(BuildContext ctx) async {
    FocusScope.of(ctx).unfocus();
    final v = _formKey.currentState?.validate() ?? false;
    if (!v) {
      _scrollToTitle();
      return;
    }
    if (_title.text.trim().length < 2) {
      _showEditorSnack(ctx, 'Title required (type 2+ characters)');
      _scrollToTitle();
      return;
    }

    if (_drafts.isEmpty) {
      _showEditorSnack(ctx, 'Pick at least one kit.');
      return;
    }

    final cat = ctx.read<CatalogNotifier>();
    final lines = <ProductKitLine>[];

    for (final d in _drafts) {
      final name = d.labelCtrl.text.trim();
      final inr = int.tryParse(d.priceCtrl.text.trim());
      if (name.length < 2) {
        _showEditorSnack(ctx, 'Give each kit a short name');
        return;
      }
      if (inr == null || inr < 1) {
        _showEditorSnack(ctx, 'Enter a ₹ price for “$name”');
        return;
      }
      final ordered = cat.orderedSelectedIds(d.catalogIds, cat.kitCatalog);
      if (ordered.isEmpty) {
        _showEditorSnack(ctx, 'Tick items for “$name”');
        return;
      }
      lines.add(
        ProductKitLine(
          lineId: d.lineId,
          label: name,
          presetId: d.presetId,
          catalogIds: ordered,
          priceInr: inr,
        ),
      );
    }

    final snap0 = _labels(lines.first, cat);
    final snap1 = lines.length > 1 ? _labels(lines[1], cat) : snap0;

    final nav = Navigator.of(ctx);
    setState(() => _saving = true);
    WidgetsBinding.instance.scheduleFrame();
    await SchedulerBinding.instance.endOfFrame;
    try {
      late final String pid;
      if (_isEdit) {
        pid = widget.initial!.id;
      } else {
        final stub = Product(
          id: '',
          title: _title.text,
          subtitle: _subtitle.text,
          category: _category,
          galleryUrls: const [],
          coverImageUrl: '',
          kits: lines,
          inStock: _inStock,
          visibleInShop: _visibleInShop,
          highlightTagIds: cat.orderedHighlightIds(
            _highlightIds.toSet(),
            cat.highlightCatalog,
          ),
          gallerySlideMeta: const [],
        );
        final created = await AdminCatalogService.createProduct(
          stub,
          starterLabelSnapshot: snap0,
          deluxeLabelSnapshot: snap1,
        );
        pid = created.id;
      }

      for (final slot in _gallery) {
        await slot.uploadIfNeeded(pid);
      }

      final linesFinal = <ProductKitLine>[];
      for (var i = 0; i < lines.length; i++) {
        linesFinal.add(
          lines[i].copyWith(imageUrls: _kitPersistedUrls(_drafts[i])),
        );
      }

      final prod = Product(
        id: pid,
        title: _title.text,
        subtitle: _subtitle.text,
        category: _category,
        galleryUrls: _galleryRemoteUrlsOrdered(),
        coverImageUrl: _resolvedCoverRemote(),
        kits: linesFinal,
        inStock: _inStock,
        visibleInShop: _visibleInShop,
        highlightTagIds: cat.orderedHighlightIds(
          _highlightIds.toSet(),
          cat.highlightCatalog,
        ),
        gallerySlideMeta: _gallerySlideMetaForSave(),
      );

      await AdminCatalogService.updateProduct(
        prod,
        starterLabelSnapshot: snap0,
        deluxeLabelSnapshot: snap1,
      );

      if (!mounted) return;
      await cat.refresh(silent: true, warmShopCovers: false);
      if (!mounted) return;
      nav.pop(true);
    } catch (e) {
      if (!ctx.mounted) return;
      _showEditorSnack(
        ctx,
        '$e',
        error: true,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogNotifier>();
    return Theme(
      data: AdminShell.themeShopperChrome(),
      child: DecoratedBox(
        decoration: AdminShell.shopperBackground,
        child: Builder(
          builder: (tc) {
            final pad = MediaQuery.paddingOf(tc).bottom;
            final layoutG = PlantasticLayout.gutter(tc);
            return Stack(
              fit: StackFit.expand,
              children: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: PlantasticAppBar(
                    showBack: true,
                    replacementToolbarHeight: 78,
                    replacementTitle: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _title,
                      builder: (subCtx, val, _) {
                        final pv = val.text.trim();
                        final hint = _isEdit
                            ? (pv.isEmpty ? 'Editing' : pv)
                            : 'Draft';
                        final subScheme = Theme.of(subCtx).colorScheme;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isEdit ? 'Edit product' : 'New product',
                              style: Theme.of(subCtx).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: subScheme.onSurface,
                                  ),
                            ),
                            Text(
                              hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(subCtx).textTheme.bodySmall
                                  ?.copyWith(color: subScheme.onSurfaceVariant),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  body: Form(
                    key: _formKey,
                    child: PlantasticLayout.constrainedBody(
                      tc,
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              controller: _scrollController,
                              physics: plantasticViewportPhysics,
                              padding: EdgeInsets.fromLTRB(
                                layoutG,
                                10,
                                layoutG,
                                8,
                              ),
                              children: [
                                _section(
                                  tc,
                                  title: 'Basics',
                                  icon: Icons.article_outlined,
                                  kids: [
                                    KeyedSubtree(
                                      key: _titleFieldKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          WorldFlowerTileField(
                                            controller: _title,
                                            focusNode: _titleFlowerFocus,
                                            theme: Theme.of(tc),
                                            formStyle: true,
                                            dense: false,
                                            labelText: 'Title',
                                            hintText:
                                                'Type to search flowers or enter a custom title',
                                            suggestionsMaxWidth: 360,
                                            onCatalogFlowerChosen: (w) {
                                              setState(
                                                () =>
                                                    _subtitle.text = w.snippet,
                                              );
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                              left: 4,
                                              right: 4,
                                            ),
                                            child: Text(
                                              'Flower catalogue: typing shows matches; picking '
                                              'one fills Description below. Any custom title works too.',
                                              style: Theme.of(tc)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(tc)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    height: 1.35,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _subtitle,
                                      decoration: InputDecoration(
                                        labelText: 'Description',
                                        helperText:
                                            '${_subtitle.text.trim().length}/8 min',
                                        helperStyle: Theme.of(tc)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  _subtitle.text
                                                          .trim()
                                                          .length >=
                                                      8
                                                  ? AppTheme.forestBright
                                                  : Theme.of(
                                                      tc,
                                                    ).colorScheme.outline,
                                            ),
                                      ),
                                      maxLines: 5,
                                      minLines: 3,
                                      onChanged: (_) => setState(() {}),
                                      validator: (s) =>
                                          s != null && s.trim().length >= 8
                                          ? null
                                          : '8+ chars',
                                    ),
                                  ],
                                ),
                                _section(
                                  tc,
                                  title: 'Category & stock',
                                  icon: Icons.sell_outlined,
                                  kids: [
                                    InputDecorator(
                                      decoration:
                                          InputDecoration(
                                            labelText: 'Category',
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 12,
                                                ),
                                          ).applyDefaults(
                                            Theme.of(tc).inputDecorationTheme,
                                          ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: _category,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          icon: const Icon(
                                            Icons.expand_more_rounded,
                                          ),
                                          style: Theme.of(tc)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: Theme.of(
                                                  tc,
                                                ).colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          dropdownColor: Theme.of(
                                            tc,
                                          ).colorScheme.surface,
                                          items: const [
                                            DropdownMenuItem(
                                              value: kCategoryFlowerSeed,
                                              child: Text(kCategoryFlowerSeed),
                                            ),
                                            DropdownMenuItem(
                                              value: kCategoryPlantSeed,
                                              child: Text(kCategoryPlantSeed),
                                            ),
                                          ],
                                          onChanged: (x) {
                                            if (x != null) {
                                              setState(() => _category = x);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: false,
                                      title: const Text('In stock'),
                                      subtitle: Text(
                                        'Warehouse / fulfilment toggle',
                                        style: Theme.of(tc).textTheme.bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                tc,
                                              ).colorScheme.onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                      ),
                                      value: _inStock,
                                      onChanged: (b) =>
                                          setState(() => _inStock = b),
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: false,
                                      title: const Text('Visible in shop'),
                                      subtitle: Text(
                                        _visibleInShop
                                            ? 'Shown on shopper home.'
                                            : 'Hidden from shopper home — admin-only.',
                                        style: Theme.of(tc).textTheme.bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                tc,
                                              ).colorScheme.onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                      ),
                                      value: _visibleInShop,
                                      onChanged: (b) =>
                                          setState(() => _visibleInShop = b),
                                    ),
                                  ],
                                ),
                                _section(
                                  tc,
                                  title: 'Product highlights',
                                  icon: Icons.auto_awesome_outlined,
                                  kids: [
                                    if (catalog.highlightCatalog.isEmpty)
                                      Text(
                                        'No highlights in catalogue.',
                                        style: Theme.of(tc).textTheme.bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                tc,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      )
                                    else
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final h
                                              in catalog.highlightCatalog)
                                            FilterChip(
                                              selected: _highlightIds.contains(
                                                h.id,
                                              ),
                                              showCheckmark: true,
                                              avatar: Icon(
                                                highlightIcon(h.iconKey),
                                                size: 18,
                                              ),
                                              label: Text(h.pillText),
                                              selectedColor: AppTheme.mintGlow
                                                  .withValues(alpha: 0.22),
                                              checkmarkColor: AppTheme.mintGlow,
                                              side: BorderSide(
                                                color: AppTheme.surfaceBorder
                                                    .withValues(alpha: 0.85),
                                              ),
                                              onSelected: (_) {
                                                setState(() {
                                                  if (_highlightIds.contains(
                                                    h.id,
                                                  )) {
                                                    _highlightIds.remove(h.id);
                                                  } else {
                                                    _highlightIds.add(h.id);
                                                  }
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                                _section(
                                  tc,
                                  key: _productImagesSectionKey,
                                  title: 'Product images',
                                  icon: Icons.photo_library_outlined,
                                  kids: [
                                    FilledButton.icon(
                                      icon: const Icon(
                                        Icons.collections_outlined,
                                      ),
                                      label: const Text('Pick from gallery'),
                                      onPressed: () => _pickGallery(),
                                    ),
                                    if (_gallery.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(
                                              parent: ClampingScrollPhysics(),
                                            ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            for (
                                              var i = 0;
                                              i < _gallery.length;
                                              i++
                                            ) ...[
                                              if (i != 0)
                                                const SizedBox(width: 12),
                                              _galleryImageTileWithFlowerType(
                                                tc,
                                                _gallery[i],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                _section(
                                  tc,
                                  title: 'Shop preview',
                                  icon: Icons.storefront_outlined,
                                  kids: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppTheme.surfaceBorder
                                              .withValues(alpha: 0.5),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: 0.98,
                                            ),
                                            const Color(0xFFF4FAF6),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.forest.withValues(
                                              alpha: 0.06,
                                            ),
                                            blurRadius: 24,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          12,
                                          14,
                                          18,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.forestBright
                                                        .withValues(
                                                          alpha: 0.14,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.sync_rounded,
                                                          size: 15,
                                                          color: AppTheme
                                                              .forestBright,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          'Live preview',
                                                          style: Theme.of(tc)
                                                              .textTheme
                                                              .labelMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                letterSpacing:
                                                                    0.35,
                                                                color: AppTheme
                                                                    .forestBright,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),
                                            Center(
                                              child: Material(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                clipBehavior: Clip.antiAlias,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _openFullDetailPreview(
                                                        tc,
                                                        catalog,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.26,
                                                              ),
                                                          blurRadius: 18,
                                                          offset: const Offset(
                                                            0,
                                                            8,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                      child: SizedBox(
                                                        height: 288,
                                                        width: 210,
                                                        child: ProductShopCard(
                                                          previewWatermark:
                                                              true,
                                                          compact: true,
                                                          heroImageOverride:
                                                              _previewShopHeroOverride(),
                                                          product:
                                                              _assemblePreviewCatalogRow(
                                                                _previewKitLinesWithImages(
                                                                  catalog,
                                                                ),
                                                                catalog,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _section(
                                  tc,
                                  title: 'Kits & pricing',
                                  icon: Icons.layers_outlined,
                                  kids: [
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () =>
                                              _pickKits(tc, catalog),
                                          icon: const Icon(
                                            Icons.touch_app_outlined,
                                          ),
                                          label: const Text('Select kits…'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => setState(
                                            () => _fillStarterDeluxe(catalog),
                                          ),
                                          child: const Text(
                                            'Reset Starter+Deluxe',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _itemFilter,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Search items inside expandable kits…',
                                        prefixIcon: Icon(
                                          Icons.search,
                                          size: 22,
                                        ),
                                        isDense: true,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    const SizedBox(height: 10),
                                    if (_drafts.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 28,
                                        ),
                                        child: Text(
                                          'No kits.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(tc)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  tc,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      )
                                    else
                                      ReorderableListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        buildDefaultDragHandles: false,
                                        itemCount: _drafts.length,
                                        onReorder: _reorderDrafts,
                                        itemBuilder: (c, i) => _draftRow(
                                          tc,
                                          i,
                                          _drafts[i],
                                          catalog,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.99),
                            elevation: 12,
                            surfaceTintColor: Colors.transparent,
                            shadowColor: Colors.black.withValues(alpha: 0.1),
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  layoutG,
                                  10,
                                  layoutG,
                                  pad + 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _saving
                                            ? null
                                            : () => Navigator.maybePop(context),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: FilledButton(
                                        onPressed: _saving
                                            ? null
                                            : () => _submit(context),
                                        child: _saving
                                            ? SizedBox(
                                                height: 24,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: 22,
                                                      width: 22,
                                                      child: Center(
                                                        child: PlantasticLoading
                                                            .inline,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      'Saving…',
                                                      style: Theme.of(
                                                        tc,
                                                      ).textTheme.labelLarge,
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Text(_isEdit ? 'Save' : 'Create'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_saving)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.34),
                        child: AdminBusyView(
                          message:
                              'Saving…\nPlease wait — uploading & syncing catalogue',
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
