/// Shop home hero strip — backed by `shop_home_banner` (singleton id = 1).
enum HomeBannerMediaKind {
  gradient,
  image,
  video,
}

/// One carousel slide (image or video URL + caption).
class HomeBannerSlide {
  const HomeBannerSlide({
    required this.kind,
    required this.url,
    this.caption = '',
  });

  final HomeBannerMediaKind kind;
  final String url;
  final String caption;

  Map<String, dynamic> toJson() => {
        'kind': kind == HomeBannerMediaKind.video ? 'video' : 'image',
        'url': url,
        'caption': caption,
      };

  factory HomeBannerSlide.fromJson(Map<String, dynamic> m) {
    final kindStr = (m['kind'] as String? ?? 'image').trim().toLowerCase();
    final kind = kindStr == 'video' ? HomeBannerMediaKind.video : HomeBannerMediaKind.image;
    final url = (m['url'] as String? ?? '').trim();
    final caption = (m['caption'] as String? ?? '').trim();
    return HomeBannerSlide(kind: kind, url: url, caption: caption);
  }

  bool get hasUrl => url.trim().isNotEmpty;
}

class ShopHomeBannerConfig {
  const ShopHomeBannerConfig({
    required this.mediaKind,
    this.mediaUrl,
    required this.titleOverlay,
    this.slides = const [],
    this.carouselIntervalMs = 5000,
    this.bannerHeightPx = 160,
    this.bannerMinHeightPx = 120,
    this.bannerMaxHeightPx = 280,
    this.glassBlur = true,
    this.glassSigma = 14,
    this.glassFillAlpha = 0.10,
    this.glassBorderAlpha = 0.28,
  });

  final HomeBannerMediaKind mediaKind;
  final String? mediaUrl;
  final String titleOverlay;

  /// Stored carousel slides (`image` / `video` only). Empty → use legacy single asset or gradient.
  final List<HomeBannerSlide> slides;

  /// Auto-advance interval when multiple slides (milliseconds). Use ≥ [kCarouselMinIntervalMs] to enable.
  final int carouselIntervalMs;

  final int bannerHeightPx;
  final int bannerMinHeightPx;
  final int bannerMaxHeightPx;

  final bool glassBlur;
  final double glassSigma;
  final double glassFillAlpha;
  final double glassBorderAlpha;

  static const int kCarouselMinIntervalMs = 1500;
  static const int kCarouselMaxIntervalMs = 60000;

  static const ShopHomeBannerConfig fallback = ShopHomeBannerConfig(
    mediaKind: HomeBannerMediaKind.gradient,
    titleOverlay: 'Grow your own garden 🌱',
    slides: [],
  );

  double get resolvedBannerHeight {
    final h = bannerHeightPx.toDouble();
    final lo = bannerMinHeightPx.toDouble();
    final hi = bannerMaxHeightPx.toDouble();
    if (hi <= lo) return h.clamp(100.0, 400.0);
    return h.clamp(lo, hi);
  }

  /// Slides shown on the shop (JSON slides, else legacy single URL).
  List<HomeBannerSlide> get effectiveSlides {
    final fromDb = slides.where((s) => s.hasUrl).toList();
    if (fromDb.isNotEmpty) return fromDb;

    final url = mediaUrl?.trim();
    if (mediaKind == HomeBannerMediaKind.gradient || url == null || url.isEmpty) {
      return [];
    }
    return [
      HomeBannerSlide(
        kind: mediaKind == HomeBannerMediaKind.video ? HomeBannerMediaKind.video : HomeBannerMediaKind.image,
        url: url,
        caption: titleOverlay,
      ),
    ];
  }

  bool get showGradient => effectiveSlides.isEmpty;

  String captionForSlide(HomeBannerSlide s) {
    final c = s.caption.trim();
    if (c.isNotEmpty) return c;
    return titleOverlay.trim().isEmpty ? ShopHomeBannerConfig.fallback.titleOverlay : titleOverlay.trim();
  }

  static double _readDouble(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }

  static int _readInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is num) return v.round();
    return int.tryParse('$v') ?? fallback;
  }

  factory ShopHomeBannerConfig.fromRow(Map<String, dynamic> row) {
    final rawKind = (row['media_kind'] as String? ?? 'gradient').trim().toLowerCase();
    final HomeBannerMediaKind kind = switch (rawKind) {
      'image' => HomeBannerMediaKind.image,
      'video' => HomeBannerMediaKind.video,
      _ => HomeBannerMediaKind.gradient,
    };
    final url = row['media_url'] as String?;
    final trimmedUrl = url?.trim();
    final title =
        (row['title_overlay'] as String?)?.trim().isNotEmpty == true
            ? (row['title_overlay'] as String).trim()
            : fallback.titleOverlay;

    List<HomeBannerSlide> slides = [];
    final rawSlides = row['slides'];
    if (rawSlides is List) {
      for (final e in rawSlides) {
        if (e is Map<String, dynamic>) {
          slides.add(HomeBannerSlide.fromJson(e));
        } else if (e is Map) {
          slides.add(HomeBannerSlide.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return ShopHomeBannerConfig(
      mediaKind: kind,
      mediaUrl: trimmedUrl?.isEmpty ?? true ? null : trimmedUrl,
      titleOverlay: title,
      slides: slides,
      carouselIntervalMs: _readInt(row['carousel_interval_ms'], 5000).clamp(kCarouselMinIntervalMs, kCarouselMaxIntervalMs),
      bannerHeightPx: _readInt(row['banner_height_px'], 160).clamp(80, 480),
      bannerMinHeightPx: _readInt(row['banner_min_height_px'], 120).clamp(80, 480),
      bannerMaxHeightPx: _readInt(row['banner_max_height_px'], 280).clamp(80, 480),
      glassBlur: row['glass_blur'] is bool ? row['glass_blur'] as bool : true,
      glassSigma: _readDouble(row['glass_sigma'], 14).clamp(0.0, 40.0),
      glassFillAlpha: _readDouble(row['glass_fill_alpha'], 0.10).clamp(0.0, 0.6),
      glassBorderAlpha: _readDouble(row['glass_border_alpha'], 0.28).clamp(0.0, 0.8),
    ).normalizedDimensions();
  }

  static HomeBannerMediaKind mediaKindForFileName(String fileName) {
    final i = fileName.lastIndexOf('.');
    final ext = i >= 0 && i < fileName.length - 1 ? fileName.substring(i + 1).toLowerCase() : '';
    switch (ext) {
      case 'mp4':
      case 'webm':
      case 'mov':
      case 'm4v':
        return HomeBannerMediaKind.video;
      default:
        return HomeBannerMediaKind.image;
    }
  }

  /// Ensures min/max height order and clamps preferred height into range.
  ShopHomeBannerConfig normalizedDimensions() {
    var lo = bannerMinHeightPx.clamp(80, 480);
    var hi = bannerMaxHeightPx.clamp(80, 480);
    if (lo > hi) {
      final t = lo;
      lo = hi;
      hi = t;
    }
    final bh = bannerHeightPx.clamp(lo, hi);
    return ShopHomeBannerConfig(
      mediaKind: mediaKind,
      mediaUrl: mediaUrl,
      titleOverlay: titleOverlay,
      slides: slides,
      carouselIntervalMs: carouselIntervalMs,
      bannerHeightPx: bh,
      bannerMinHeightPx: lo,
      bannerMaxHeightPx: hi,
      glassBlur: glassBlur,
      glassSigma: glassSigma,
      glassFillAlpha: glassFillAlpha,
      glassBorderAlpha: glassBorderAlpha,
    );
  }

  Map<String, dynamic> toUpsertRow() {
    final n = normalizedDimensions();
    return {
      'id': 1,
      'media_kind': n.mediaKind.name,
      'media_url': n.mediaUrl,
      'title_overlay': n.titleOverlay,
      'slides': n.slides.map((e) => e.toJson()).toList(),
      'carousel_interval_ms': n.carouselIntervalMs.clamp(kCarouselMinIntervalMs, kCarouselMaxIntervalMs),
      'banner_height_px': n.bannerHeightPx.clamp(80, 480),
      'banner_min_height_px': n.bannerMinHeightPx.clamp(80, 480),
      'banner_max_height_px': n.bannerMaxHeightPx.clamp(80, 480),
      'glass_blur': n.glassBlur,
      'glass_sigma': n.glassSigma.clamp(0.0, 40.0),
      'glass_fill_alpha': n.glassFillAlpha.clamp(0.0, 0.6),
      'glass_border_alpha': n.glassBorderAlpha.clamp(0.0, 0.8),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
