import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../catalog/catalog_assets.dart';
import 'plantastic_loading.dart';

/// Square image pager — [BoxFit.contain] taaki crop / hide na ho.
class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({
    super.key,
    required this.urls,
    required this.side,
    this.autoInterval = const Duration(seconds: 4),
    this.borderRadius,
    this.titleOverlay,
    this.categoryIconFallback,
    this.previewMemoryAtIndex,
  });

  /// Normalized asset paths and/or `https://…` strings (same order as gallery).
  final List<String> urls;

  /// Width and height of square viewport (logical pixels).
  final double side;
  final Duration autoInterval;
  final BorderRadius? borderRadius;
  final String? titleOverlay;
  final IconData? categoryIconFallback;

  /// Admin draft: in-memory images for [urls] indices (swipe still works).
  final Map<int, Uint8List>? previewMemoryAtIndex;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  late final PageController _page;
  int _index = 0;
  Timer? _timer;

  bool _mapEquals(Map<int, Uint8List>? a, Map<int, Uint8List>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final o = b[e.key];
      if (o == null || !listEquals(e.value, o)) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _armTimerIfNeeded();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _armTimerIfNeeded() {
    _cancelTimer();
    if (widget.urls.length < 2) return;
    _timer = Timer.periodic(widget.autoInterval, (_) {
      if (!mounted || widget.urls.length < 2 || !_page.hasClients) return;
      final len = widget.urls.length;
      var cur = (_page.page ?? _index.toDouble()).round();
      if (cur < 0) cur = 0;
      if (cur >= len) cur = len - 1;
      final next = (cur + 1) % len;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant ProductImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.urls, widget.urls) ||
        oldWidget.autoInterval != widget.autoInterval ||
        !_mapEquals(
          oldWidget.previewMemoryAtIndex,
          widget.previewMemoryAtIndex,
        )) {
      if (_index >= widget.urls.length && widget.urls.isNotEmpty) {
        _index = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_page.hasClients) _page.jumpToPage(0);
        });
      }
      _armTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    Widget body;
    if (urls.isEmpty) {
      body = _GradientPlaceholder(icon: widget.categoryIconFallback);
    } else if (urls.length == 1) {
      body = Stack(
        fit: StackFit.expand,
        children: [
          _CarouselSlideImage(urls.first, widget.previewMemoryAtIndex, 0),
          if (widget.titleOverlay != null &&
              widget.titleOverlay!.trim().isNotEmpty)
            _TitleOverlay(widget.titleOverlay!),
        ],
      );
    } else {
      body = Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) {
                _cancelTimer();
              } else if (n is ScrollEndNotification) {
                _armTimerIfNeeded();
              }
              return false;
            },
            child: PageView.builder(
              controller: _page,
              itemCount: urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (c, i) => Stack(
                fit: StackFit.expand,
                children: [
                  _CarouselSlideImage(urls[i], widget.previewMemoryAtIndex, i),
                  if (widget.titleOverlay != null &&
                      widget.titleOverlay!.trim().isNotEmpty)
                    _TitleOverlay(widget.titleOverlay!),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.side,
        height: widget.side,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: body,
        ),
      ),
    );
  }
}

class _TitleOverlay extends StatelessWidget {
  const _TitleOverlay(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      bottom: 14,
      right: 14,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
        ),
      ),
    );
  }
}

class _CarouselSlideImage extends StatelessWidget {
  const _CarouselSlideImage(this.src, this.previewMemory, this.index);

  final String src;
  final Map<int, Uint8List>? previewMemory;
  final int index;

  @override
  Widget build(BuildContext context) {
    final mem = previewMemory?[index];
    if (mem != null && mem.isNotEmpty) {
      return Image.memory(
        mem,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) =>
            const _GradientPlaceholder(),
      );
    }
    return _CarouselImage(src);
  }
}

class _CarouselImage extends StatelessWidget {
  const _CarouselImage(this.src);

  final String src;

  @override
  Widget build(BuildContext context) {
    final s = src.trim();
    if (CatalogAssets.isDroppedHotlinkCatalogUrl(s)) {
      return const _GradientPlaceholder();
    }
    if (CatalogAssets.looksLikeRemoteUrl(s)) {
      return Image.network(
        s,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: PlantasticLoading.thumbnail,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            const _GradientPlaceholder(),
      );
    }
    return Image.asset(
      s,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) =>
          const _GradientPlaceholder(),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hi = Theme.of(context).colorScheme.surfaceContainerHighest;
    final lo = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(hi, Colors.white, 0.35)!, hi, lo],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon ?? Icons.spa_outlined,
        size: 88,
        color: primary.withValues(alpha: 0.38),
      ),
    );
  }
}
