import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_assets.dart';
import '../data/seed_products.dart';
import '../models/highlight_tag.dart';
import '../models/product.dart';
import '../providers/catalog_notifier.dart';
import '../layout/responsive.dart';
import '../theme/app_theme.dart';
import '../theme/highlight_detail_theme.dart';
import '../theme/highlight_icons.dart';
import 'decode_aware_product_image.dart';
import 'plantastic_loading.dart';

/// Radii tuned for a calmer, store-grade shop tile (see home polish).
const double _kShopCardRadius = 16;
const double _kShopHeroRadius = 12;

/// Space kept for title/price/footer below the **square** hero in grid cells.
const double _kShopHeroFooterReserve = 100;

Widget _brightenHero(Widget child) {
  const matrix = <double>[
    1.07,
    0.0,
    0.0,
    0.0,
    9.0,
    0.0,
    1.05,
    0.0,
    0.0,
    7.0,
    0.0,
    0.0,
    1.038,
    0.0,
    6.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
  ];
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(matrix),
    child: child,
  );
}

/// Shop grid card and admin mini preview (same layout).
class ProductShopCard extends StatefulWidget {
  const ProductShopCard({
    super.key,
    required this.product,
    this.onTap,
    this.compact = false,
    this.heroImageOverride,
    this.heroTag,
    this.previewWatermark = false,
  });

  final Product product;
  final VoidCallback? onTap;
  final bool compact;

  /// Editor-only watermark on the hero image.
  final bool previewWatermark;

  /// Optional [Hero] tag (shop → detail image transition).
  final String? heroTag;

  /// When set (admin live preview): full-bleed hero — [Image.memory] / network / asset.
  final Widget? heroImageOverride;

  @override
  State<ProductShopCard> createState() => _ProductShopCardState();
}

class _ProductShopCardState extends State<ProductShopCard> {
  bool _hover = false;

  bool get _hasHero =>
      widget.heroTag != null && widget.heroTag!.trim().isNotEmpty;

  void _setHover(bool v) {
    if (_hover != v) setState(() => _hover = v);
  }

  @override
  Widget build(BuildContext context) {
    final fallbackIcon = widget.product.category == kCategoryFlowerSeed
        ? Icons.local_florist_outlined
        : Icons.spa_outlined;
    final priceMuted = !widget.product.availableForPurchase;
    final compact = widget.compact;

    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final lifted = _hover && !compact;
    final baseShadowA = lifted ? 0.09 : 0.06;
    final blur = lifted ? 16.0 : 12.0;
    final dy = lifted ? 6.0 : 4.0;

    Widget heroArea() {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.heroImageOverride != null)
            Positioned.fill(child: _brightenHero(widget.heroImageOverride!))
          else
            Positioned.fill(
              child: _HeroImage(
                assetPath: widget.product.effectiveBundledCoverPath,
                networkUrl: widget.product.effectiveNetworkCoverUrl,
                fallbackIcon: fallbackIcon,
                tintSurface: cs.surfaceContainerHighest,
                deepSurface: cs.onSurface.withValues(alpha: .04),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.38, 1.0],
                    colors: [
                      Colors.white.withValues(alpha: compact ? 0.16 : 0.2),
                      Colors.white.withValues(alpha: compact ? 0.04 : 0.05),
                      Colors.black.withValues(alpha: compact ? 0.02 : 0.025),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_hover && !priceMuted && !compact)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.35, 0.65, 1],
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
          if (priceMuted)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.32),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.previewWatermark)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.52),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: compact ? 20 : 28,
                      bottom: compact ? 6 : 8,
                    ),
                    child: Text(
                      'PREVIEW',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (priceMuted)
            Positioned(
              right: compact ? 6 : 8,
              top: compact ? 6 : 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: compact ? 0.93 : 0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black45,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 3 : 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.product.visibleInShop
                            ? Icons.inventory_2_outlined
                            : Icons.visibility_off_outlined,
                        size: compact ? 11 : 12,
                        color: Colors.black87,
                      ),
                      SizedBox(width: compact ? 3 : 4),
                      Text(
                        widget.product.visibleInShop
                            ? 'Out of stock'
                            : 'Hidden',
                        style: TextStyle(
                          fontSize: compact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.35,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    final heroBg = cs.surfaceContainerHighest;

    Widget heroBlock() {
      Widget core = ColoredBox(color: heroBg, child: heroArea());

      final kenBurnsActive =
          _hover &&
          !compact &&
          !_hasHero &&
          widget.onTap != null &&
          !priceMuted;

      core = AnimatedScale(
        scale: kenBurnsActive ? 1.035 : 1.0,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        child: core,
      );

      if (compact || !_hasHero) return core;
      return Hero(
        tag: widget.heroTag!,
        child: Material(type: MaterialType.transparency, child: core),
      );
    }

    final subtitle = priceMuted
        ? 'Details only · checkout disabled'
        : 'View details →';

    final highlights = context.watch<CatalogNotifier>().highlightsForProduct(
      widget.product,
    );

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      opaque: false,
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kShopCardRadius),
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: baseShadowA),
              blurRadius: blur,
              offset: Offset(0, dy),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kShopCardRadius),
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            child: InkWell(
              splashColor: accent.withValues(alpha: 0.14),
              highlightColor: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(_kShopCardRadius),
              onTap: widget.onTap,
              mouseCursor: widget.onTap != null
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  if (!w.isFinite || w <= 0) {
                    return const SizedBox.shrink();
                  }
                  final mh = constraints.maxHeight;
                  /// Grid / fixed-height parents give a finite max height; lay out with
                  /// flex + scroll so the footer never overflows (see home SliverGrid).
                  final boundedHeight = mh.isFinite && mh > 0;

                  final footer = DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFE8F0EB), width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 6,
                          offset: Offset(0, -1.5),
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 10 : 16,
                        compact ? 8 : 14,
                        compact ? 10 : 16,
                        compact ? 10 : 14,
                      ),
                      child: _CardBody(
                        accent: accent,
                        cs: cs,
                        compact: compact,
                        muted: priceMuted,
                        hover: _hover && !compact,
                        title: widget.product.title,
                        product: widget.product,
                        subtitle: subtitle,
                        highlights: highlights,
                      ),
                    ),
                  );

                  if (boundedHeight) {
                    final maxSquareByHeight =
                        math.max(64.0, mh - _kShopHeroFooterReserve);
                    final heroSide = math.min(w, maxSquareByHeight);
                    return SizedBox(
                      width: w,
                      height: mh,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(_kShopHeroRadius),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ColoredBox(
                              color: heroBg,
                              child: SizedBox(
                                height: heroSide,
                                width: w,
                                child: Center(
                                  child: SizedBox.square(
                                    dimension: heroSide,
                                    child: heroBlock(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRect(
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: footer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(_kShopHeroRadius),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ColoredBox(
                          color: heroBg,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: heroBlock(),
                          ),
                        ),
                      ),
                      footer,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.accent,
    required this.cs,
    required this.compact,
    required this.muted,
    required this.hover,
    required this.title,
    required this.product,
    required this.subtitle,
    required this.highlights,
  });

  final Color accent;
  final ColorScheme cs;
  final bool compact;
  final bool muted;
  final bool hover;
  final String title;
  final Product product;
  final String subtitle;
  final List<HighlightTag> highlights;

  @override
  Widget build(BuildContext context) {
    final lowPrice = product.lowestKitPriceInr;

    final titleGreen = muted
        ? AppTheme.forest.withValues(alpha: 0.42)
        : AppTheme.forest;

    final lineHighlights = highlights.take(3).toList(growable: false);

    final kitsLabel =
        product.kits.length == 1 ? '1 kit' : '${product.kits.length} kits';

    final dimGrey = cs.onSurfaceVariant;

    final showDesktopHint =
        Responsive.isDesktop(context) && hover && !muted && !compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CategoryPill(category: product.category, compact: compact),
        SizedBox(height: compact ? 6 : 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.serifDisplay(
                  fontSize: compact ? 15.5 : 17,
                  fontWeight: FontWeight.w600,
                  height: compact ? 1.22 : 1.14,
                  letterSpacing: -0.42,
                  color: titleGreen,
                ),
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
            Padding(
              padding: EdgeInsets.only(top: compact ? 1 : 2),
              child: Text(
                kitsLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  height: 1.2,
                  color: dimGrey.withValues(alpha: 0.82),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: muted
                  ? Text(
                      'From ₹$lowPrice · Unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(
                        fontSize: compact ? 10.75 : 12.85,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06,
                        height: 1.06,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: AppTheme.textMuted,
                      ),
                    )
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'From ',
                            style: AppTheme.sans(
                              fontSize: compact ? 10.25 : 11.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.28,
                              height: 1.06,
                              color: dimGrey.withValues(alpha: 0.55),
                            ),
                          ),
                          TextSpan(
                            text: '₹$lowPrice',
                            style: AppTheme.sans(
                              fontSize: compact ? 12.25 : 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.35,
                              height: 1.06,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (!compact && muted)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.block_rounded,
                  size: 20,
                  color: Colors.orange.withValues(alpha: 0.9),
                ),
              ),
          ],
        ),
        if (lineHighlights.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 8),
          Wrap(
            spacing: compact ? 5 : 6,
            runSpacing: compact ? 5 : 6,
            children: [
              for (final h in lineHighlights)
                _SubtitleHighlightIcon(
                  tag: h,
                  compact: compact,
                ),
            ],
          ),
        ],
        SizedBox(height: compact ? 8 : 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.35,
                  height: 1.35,
                  color: dimGrey.withValues(alpha: 0.62),
                ),
              ),
            ),
            if (showDesktopHint)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      'View details',
                      style: AppTheme.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Small highlight badge on shop card “N kits” subtitle — per [iconKey] colors.
class _SubtitleHighlightIcon extends StatelessWidget {
  const _SubtitleHighlightIcon({
    required this.tag,
    required this.compact,
  });

  final HighlightTag tag;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tip = tag.title.trim().isEmpty ? tag.pillText : tag.title.trim();
    final dim = compact ? 16.0 : 18.5;
    final iconSz = compact ? 10.0 : 11.5;
    final deco = highlightDetailDecoration(tag.iconKey);

    return Tooltip(
      waitDuration: const Duration(milliseconds: 420),
      message: tip,
      child: Container(
        width: dim,
        height: dim,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: deco.gradient(),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: compact ? 0.95 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: deco.colorBottom.withValues(alpha: 0.38),
              blurRadius: compact ? 4 : 5,
              offset: Offset(0, compact ? 1 : 1.5),
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          highlightIcon(tag.iconKey),
          size: iconSz,
          color: Colors.white.withValues(alpha: 0.96),
        ),
      ),
    );
  }
}

/// Colorful category chip on product imagery (readable on busy photos).
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category, required this.compact});

  final String category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final flower = category == kCategoryFlowerSeed;

    final gradient = flower
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B9A), Color(0xFFFF9EC0), Color(0xFFFFD4B8)],
            stops: [0.0, 0.48, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.forestBright, AppTheme.leafDim, AppTheme.leaf],
            stops: const [0.0, 0.55, 1.0],
          );

    final shadowColor = flower
        ? const Color(0xFFE91E63).withValues(alpha: 0.45)
        : AppTheme.forest.withValues(alpha: 0.4);

    final icon = flower ? Icons.local_florist_rounded : Icons.eco_rounded;

    final hPad = compact ? 4.5 : 5.5;
    final vPad = compact ? 1.75 : 2.25;
    final iconSize = compact ? 9.0 : 10.0;
    final gap = compact ? 2.0 : 2.75;
    final fontSize = compact ? 7.5 : 8.25;

    final textShadows = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.26),
        offset: const Offset(0, 0.5),
        blurRadius: 1,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: gradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.58),
          width: compact ? 0.65 : 0.75,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: flower ? (compact ? 4 : 5.5) : (compact ? 3.5 : 4.5),
            offset: Offset(0, flower ? 1.5 : 1),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 2,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, vPad, hPad + 0.5, vPad),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.white.withValues(alpha: 0.96),
              shadows: textShadows,
            ),
            SizedBox(width: gap),
            Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.12,
                color: Colors.white,
                height: 1,
                shadows: textShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.assetPath,
    required this.networkUrl,
    required this.fallbackIcon,
    required this.tintSurface,
    required this.deepSurface,
  });

  final String? assetPath;
  final String? networkUrl;
  final IconData fallbackIcon;
  final Color tintSurface;
  final Color deepSurface;

  Widget _fallback(BuildContext context) {
    final ph = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(tintSurface, Colors.white, 0.25)!,
            Color.lerp(tintSurface, deepSurface, 0.6)!,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: 52, color: ph.withValues(alpha: 0.45)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = assetPath?.trim();
    if (ap != null && ap.isNotEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: _brightenHero(
          DecodeAwareProductImage(
            image: AssetImage(ap),
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              final nw = networkUrl?.trim();
              if (nw != null &&
                  nw.isNotEmpty &&
                  CatalogAssets.looksLikeUsableShopRemoteUrl(nw)) {
                return DecodeAwareProductImage(
                  image: NetworkImage(nw),
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return ColoredBox(
                      color: Colors.grey.shade100,
                      child: Center(
                        child: PlantasticLoading.thumbnail,
                      ),
                    );
                  },
                  errorBuilder: (c, e, s) => _fallback(context),
                );
              }
              return _fallback(context);
            },
          ),
        ),
      );
    }
    final nu = networkUrl?.trim();
    if (nu != null &&
        nu.isNotEmpty &&
        CatalogAssets.looksLikeUsableShopRemoteUrl(nu)) {
      return DecoratedBox(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: _brightenHero(
          DecodeAwareProductImage(
            image: NetworkImage(nu),
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return ColoredBox(
                color: Colors.grey.shade100,
                child: Center(
                  child: PlantasticLoading.thumbnail,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                _fallback(context),
          ),
        ),
      );
    }
    return _fallback(context);
  }
}
