import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/home_banner_config.dart';
import '../../notifiers/home_banner_notifier.dart';
import '../../services/home_banner_media_upload_service.dart';
import '../../services/home_banner_service.dart';
import '../../theme/admin_shell.dart';
import '../../widgets/admin/admin_widgets.dart';
import '../../widgets/plantastic_home_hero.dart';

class _DraftSlide {
  _DraftSlide({
    required this.id,
    required this.kind,
    this.url,
    this.caption = '',
    this.pendingBytes,
    this.pendingName,
  });

  final String id;
  HomeBannerMediaKind kind;
  String? url;
  String caption;
  Uint8List? pendingBytes;
  String? pendingName;

  bool get hasAsset =>
      (url != null && url!.trim().isNotEmpty) || pendingBytes != null;
}

/// Carousel hero: multi image/video, per-slide text, glass + sizing, live preview.
class AdminHomeBannerPanel extends StatefulWidget {
  const AdminHomeBannerPanel({super.key});

  static const int maxSlides = 12;

  @override
  State<AdminHomeBannerPanel> createState() => _AdminHomeBannerPanelState();
}

class _AdminHomeBannerPanelState extends State<AdminHomeBannerPanel>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _fallbackTitleCtrl = TextEditingController();

  final Map<String, TextEditingController> _captionCtrls = {};

  ShopHomeBannerConfig _config = ShopHomeBannerConfig.fallback;
  List<_DraftSlide> _drafts = [];

  double _carouselIntervalMs = 5000;
  double _bannerHeightPx = 160;
  double _bannerMinPx = 120;
  double _bannerMaxPx = 280;
  bool _glassBlur = true;
  double _glassSigma = 14;
  double _glassFillAlpha = 0.10;
  double _glassBorderAlpha = 0.28;

  bool _loading = true;
  String? _error;
  bool _saving = false;

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(1 << 22)}';

  @override
  bool get wantKeepAlive => true;

  void _disposeCaptionCtrls() {
    for (final c in _captionCtrls.values) {
      c.dispose();
    }
    _captionCtrls.clear();
  }

  @override
  void dispose() {
    _disposeCaptionCtrls();
    _fallbackTitleCtrl.dispose();
    super.dispose();
  }

  TextEditingController _captionController(_DraftSlide d) {
    return _captionCtrls.putIfAbsent(
      d.id,
      () => TextEditingController(text: d.caption),
    );
  }

  void _removeDraft(String id) {
    _captionCtrls.remove(id)?.dispose();
    setState(() => _drafts.removeWhere((e) => e.id == id));
  }

  void _populateDraftsFromConfig() {
    _disposeCaptionCtrls();
    _fallbackTitleCtrl.text = _config.titleOverlay;

    final stored = _config.slides.where((s) => s.hasUrl).toList();
    if (stored.isNotEmpty) {
      _drafts = [
        for (final s in stored)
          _DraftSlide(
            id: _newId(),
            kind: s.kind,
            url: s.url,
            caption: s.caption,
          ),
      ];
    } else {
      final legacyUrl = _config.mediaUrl?.trim();
      if (_config.mediaKind != HomeBannerMediaKind.gradient &&
          legacyUrl != null &&
          legacyUrl.isNotEmpty) {
        _drafts = [
          _DraftSlide(
            id: _newId(),
            kind: _config.mediaKind == HomeBannerMediaKind.video
                ? HomeBannerMediaKind.video
                : HomeBannerMediaKind.image,
            url: legacyUrl,
            caption: _config.titleOverlay,
          ),
        ];
      } else {
        _drafts = [];
      }
    }

    for (final d in _drafts) {
      _captionCtrls[d.id] = TextEditingController(text: d.caption);
    }

    _carouselIntervalMs = _config.carouselIntervalMs.toDouble();
    _bannerHeightPx = _config.bannerHeightPx.toDouble();
    _bannerMinPx = _config.bannerMinHeightPx.toDouble();
    _bannerMaxPx = _config.bannerMaxHeightPx.toDouble();
    _glassBlur = _config.glassBlur;
    _glassSigma = _config.glassSigma;
    _glassFillAlpha = _config.glassFillAlpha;
    _glassBorderAlpha = _config.glassBorderAlpha;
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!AppConfig.supabaseReady) {
        _error = 'Supabase is not configured.';
        _config = ShopHomeBannerConfig.fallback;
      } else {
        _config = await HomeBannerService.fetchCurrent();
      }
      _populateDraftsFromConfig();
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  ShopHomeBannerConfig _glassSizingConfig() {
    final title = _fallbackTitleCtrl.text.trim().isEmpty
        ? ShopHomeBannerConfig.fallback.titleOverlay
        : _fallbackTitleCtrl.text.trim();
    return ShopHomeBannerConfig(
      mediaKind: HomeBannerMediaKind.gradient,
      mediaUrl: null,
      titleOverlay: title,
      slides: const [],
      carouselIntervalMs: _carouselIntervalMs.round().clamp(
        ShopHomeBannerConfig.kCarouselMinIntervalMs,
        ShopHomeBannerConfig.kCarouselMaxIntervalMs,
      ),
      bannerHeightPx: _bannerHeightPx.round(),
      bannerMinHeightPx: _bannerMinPx.round(),
      bannerMaxHeightPx: _bannerMaxPx.round(),
      glassBlur: _glassBlur,
      glassSigma: _glassSigma,
      glassFillAlpha: _glassFillAlpha,
      glassBorderAlpha: _glassBorderAlpha,
    ).normalizedDimensions();
  }

  ({List<HomeBannerSlide> slides, List<Uint8List?> memory}) _previewPayload() {
    final slides = <HomeBannerSlide>[];
    final memory = <Uint8List?>[];
    for (final d in _drafts) {
      final cap = _captionCtrls[d.id]?.text ?? d.caption;
      final net = d.url?.trim() ?? '';
      final hasNet = net.isNotEmpty;
      final hasPending = d.pendingBytes != null;

      if (hasNet) {
        slides.add(
          HomeBannerSlide(kind: d.kind, url: net, caption: cap.trim()),
        );
        memory.add(null);
      } else if (hasPending && d.kind == HomeBannerMediaKind.image) {
        slides.add(
          HomeBannerSlide(kind: HomeBannerMediaKind.image, url: '', caption: cap.trim()),
        );
        memory.add(d.pendingBytes);
      } else if (hasPending && d.kind == HomeBannerMediaKind.video) {
        slides.add(
          HomeBannerSlide(kind: HomeBannerMediaKind.video, url: '', caption: cap.trim()),
        );
        memory.add(null);
      }
    }
    return (slides: slides, memory: memory);
  }

  Future<void> _pickMedia({bool multiple = false}) async {
    if (_drafts.length >= AdminHomeBannerPanel.maxSlides) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${AdminHomeBannerPanel.maxSlides} slides.'),
        ),
      );
      return;
    }

    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'webm', 'mov', 'm4v',
      ],
      withData: true,
      allowMultiple: multiple,
    );
    if (pick == null || pick.files.isEmpty) return;

    var added = 0;
    for (final f in pick.files) {
      if (_drafts.length >= AdminHomeBannerPanel.maxSlides) break;

      Uint8List? bytes;
      final direct = f.bytes;
      if (direct != null && direct.isNotEmpty) {
        bytes = Uint8List.fromList(direct);
      }
      if (bytes == null || bytes.isEmpty) continue;

      if (bytes.length > HomeBannerMediaUploadService.maxBannerUploadBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Skipped ${f.name}: larger than ${HomeBannerMediaUploadService.maxBannerUploadLabel}.',
              ),
            ),
          );
        }
        continue;
      }

      final name = f.name.trim().isEmpty ? 'banner.jpg' : f.name.trim();
      final kind = ShopHomeBannerConfig.mediaKindForFileName(name);

      final slide = _DraftSlide(
        id: _newId(),
        kind: kind,
        pendingBytes: bytes,
        pendingName: name,
      );
      _captionCtrls[slide.id] = TextEditingController();
      setState(() {
        _drafts.add(slide);
        added++;
      });
    }

    if (added == 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No files added — check size or try again.'),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!AppConfig.supabaseReady || _saving) return;

    final title = _fallbackTitleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a default title (used when a slide has no text).')),
      );
      return;
    }

    final readyDrafts = _drafts.where((d) => d.hasAsset).toList();
    if (readyDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one slide, or use “Gradient only”.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final builtSlides = <HomeBannerSlide>[];

      for (final d in readyDrafts) {
        String url = (d.url ?? '').trim();
        if (d.pendingBytes != null && d.pendingName != null) {
          url = await HomeBannerMediaUploadService.uploadBannerBytes(
            bytes: d.pendingBytes!,
            fileName: d.pendingName!,
          );
          d.url = url;
          d.pendingBytes = null;
          d.pendingName = null;
        }
        if (url.isEmpty) continue;

        final capt = (_captionCtrls[d.id]?.text ?? d.caption).trim();
        builtSlides.add(
          HomeBannerSlide(
            kind: d.kind,
            url: url,
            caption: capt,
          ),
        );
      }

      if (builtSlides.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No slides with valid URLs to save.')),
          );
        }
        return;
      }

      final cfg = ShopHomeBannerConfig(
        mediaKind: HomeBannerMediaKind.gradient,
        mediaUrl: null,
        titleOverlay: title,
        slides: builtSlides,
        carouselIntervalMs: _carouselIntervalMs.round().clamp(
          ShopHomeBannerConfig.kCarouselMinIntervalMs,
          ShopHomeBannerConfig.kCarouselMaxIntervalMs,
        ),
        bannerHeightPx: _bannerHeightPx.round(),
        bannerMinHeightPx: _bannerMinPx.round(),
        bannerMaxHeightPx: _bannerMaxPx.round(),
        glassBlur: _glassBlur,
        glassSigma: _glassSigma,
        glassFillAlpha: _glassFillAlpha,
        glassBorderAlpha: _glassBorderAlpha,
      ).normalizedDimensions();

      await HomeBannerService.upsert(cfg);

      await _reload();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final bannerNotifier = context.read<HomeBannerNotifier>();
      await bannerNotifier.refresh();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Home banner saved.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _useGradient() async {
    if (!AppConfig.supabaseReady || _saving) return;
    setState(() => _saving = true);
    try {
      await HomeBannerService.resetToGradient(
        titleOverlay: _fallbackTitleCtrl.text.trim(),
      );
      await _reload();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final bannerNotifier = context.read<HomeBannerNotifier>();
      await bannerNotifier.refresh();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Banner set to green gradient only.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reset: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const AdminBusyView(message: 'Loading home banner…');
    }

    if (_error != null) {
      return AdminErrorView(message: _error!, onRetry: _reload);
    }

    final preview = _previewPayload();
    final bhLo = math.min(_bannerMinPx, _bannerMaxPx);
    final bhHi = math.max(_bannerMinPx, _bannerMaxPx);

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: AdminShell.cardDecoration(cs),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live preview (shop hero)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColoredBox(
                          color: AdminShell.dashboardCanvas,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: HomeBannerHeroPreview(
                              config: _glassSizingConfig(),
                              previewSlides: preview.slides,
                              slideMemoryImages:
                                  preview.slides.isEmpty ? null : preview.memory,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: AdminShell.cardDecoration(cs),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Slides',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Drag ⋮⋮ to reorder. Each slide can be an image or video with its own text.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _drafts.removeAt(oldIndex);
                            _drafts.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (var i = 0; i < _drafts.length; i++)
                            Card(
                              key: ValueKey(_drafts[i].id),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: ReorderableDragStartListener(
                                  index: i,
                                  child: Icon(Icons.drag_handle_rounded, color: cs.outline),
                                ),
                                title: TextField(
                                  controller: _captionController(_drafts[i]),
                                  decoration: InputDecoration(
                                    labelText: 'Slide ${i + 1} text',
                                    hintText: 'Shown on this slide',
                                    isDense: true,
                                  ),
                                  maxLines: 2,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _drafts[i].pendingBytes != null
                                            ? 'Ready to upload: ${_drafts[i].pendingName ?? "file"} (${_drafts[i].kind.name})'
                                            : (_drafts[i].url?.trim().isNotEmpty == true
                                                ? _drafts[i].url!.trim()
                                                : 'No media'),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Remove',
                                  icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                                  onPressed: _saving ? null : () => _removeDraft(_drafts[i].id),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: _saving ? null : () => _pickMedia(multiple: false),
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Add one file'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : () => _pickMedia(multiple: true),
                            icon: const Icon(Icons.library_add_outlined),
                            label: const Text('Add multiple'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _fallbackTitleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Default title',
                          hintText: 'Shown when a slide’s text is empty',
                          helperText: 'Also used on the plain gradient banner.',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Carousel speed (${(_carouselIntervalMs / 1000).toStringAsFixed(1)} s)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Slider(
                        value: _carouselIntervalMs.clamp(
                          ShopHomeBannerConfig.kCarouselMinIntervalMs.toDouble(),
                          ShopHomeBannerConfig.kCarouselMaxIntervalMs.toDouble(),
                        ),
                        min: ShopHomeBannerConfig.kCarouselMinIntervalMs.toDouble(),
                        max: 15000,
                        divisions: 27,
                        label: '${(_carouselIntervalMs / 1000).toStringAsFixed(1)} s',
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _carouselIntervalMs = v),
                      ),
                      Text(
                        'Banner height (${_bannerHeightPx.round()} px) — min ${_bannerMinPx.round()} / max ${_bannerMaxPx.round()}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Slider(
                        value: _bannerMinPx.clamp(80, 400),
                        min: 80,
                        max: 400,
                        divisions: 32,
                        label: '${_bannerMinPx.round()} px',
                        onChanged: _saving
                            ? null
                            : (v) => setState(() {
                                  _bannerMinPx = v;
                                  _bannerMaxPx = math.max(_bannerMinPx, _bannerMaxPx);
                                  _bannerHeightPx = _bannerHeightPx.clamp(_bannerMinPx, _bannerMaxPx);
                                }),
                      ),
                      const Text('Minimum height'),
                      Slider(
                        value: _bannerMaxPx.clamp(80, 400),
                        min: 80,
                        max: 400,
                        divisions: 32,
                        label: '${_bannerMaxPx.round()} px',
                        onChanged: _saving
                            ? null
                            : (v) => setState(() {
                                  _bannerMaxPx = v;
                                  _bannerMinPx = math.min(_bannerMinPx, _bannerMaxPx);
                                  _bannerHeightPx = _bannerHeightPx.clamp(_bannerMinPx, _bannerMaxPx);
                                }),
                      ),
                      const Text('Maximum height'),
                      const Text('Preferred height (between min and max)'),
                      if (bhHi > bhLo + 4)
                        Slider(
                          value: _bannerHeightPx.clamp(bhLo, bhHi),
                          min: bhLo,
                          max: bhHi,
                          divisions: math.min(80, (bhHi - bhLo).round()).clamp(1, 80),
                          label: '${_bannerHeightPx.round()} px',
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _bannerHeightPx = v),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Set max height higher than min to choose a preferred height.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Glass overlay',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Blur (backdrop filter)'),
                        value: _glassBlur,
                        onChanged: _saving ? null : (v) => setState(() => _glassBlur = v),
                      ),
                      Text('Blur strength (${_glassSigma.toStringAsFixed(0)})'),
                      Slider(
                        value: _glassSigma.clamp(0, 30),
                        min: 0,
                        max: 30,
                        divisions: 30,
                        onChanged:
                            _saving ? null : (v) => setState(() => _glassSigma = v),
                      ),
                      Text('Tint opacity (${_glassFillAlpha.toStringAsFixed(2)})'),
                      Slider(
                        value: _glassFillAlpha.clamp(0.0, 0.45),
                        min: 0,
                        max: 0.45,
                        divisions: 45,
                        onChanged:
                            _saving ? null : (v) => setState(() => _glassFillAlpha = v),
                      ),
                      Text('Border opacity (${_glassBorderAlpha.toStringAsFixed(2)})'),
                      Slider(
                        value: _glassBorderAlpha.clamp(0.0, 0.65),
                        min: 0,
                        max: 0.65,
                        divisions: 65,
                        onChanged:
                            _saving ? null : (v) => setState(() => _glassBorderAlpha = v),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save to shop'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _useGradient,
                            icon: const Icon(Icons.gradient_rounded),
                            label: const Text('Gradient only (clear slides)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Formats: JPG, PNG, WebP, GIF, MP4, WebM, MOV — max ${HomeBannerMediaUploadService.maxBannerUploadLabel} each. '
                        'Videos are muted and loop.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
