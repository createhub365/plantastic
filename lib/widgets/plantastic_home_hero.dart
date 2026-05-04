import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plantastic/models/home_banner_config.dart';
import 'package:plantastic/notifiers/home_banner_notifier.dart';
import 'package:plantastic/theme/app_colors.dart';
import 'package:plantastic/widgets/glass_card.dart';
import 'package:video_player/video_player.dart';

BoxDecoration _heroGradientDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary,
        AppColors.primaryLight,
      ],
    ),
  );
}

/// Shop home hero — reads [HomeBannerNotifier]. Same widget tree as preview.
class PlantasticHomeHeroBanner extends StatelessWidget {
  const PlantasticHomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeBannerNotifier>(
      builder: (context, banner, _) => HomeBannerHeroPreview(config: banner.config),
    );
  }
}

/// Hero carousel + glass. Pass [previewSlides] / [slideMemoryImages] for unsaved admin preview.
class HomeBannerHeroPreview extends StatefulWidget {
  const HomeBannerHeroPreview({
    super.key,
    required this.config,
    this.previewSlides,
    this.slideMemoryImages,
  });

  final ShopHomeBannerConfig config;

  /// When non-null, replaces [ShopHomeBannerConfig.effectiveSlides] (admin preview).
  final List<HomeBannerSlide>? previewSlides;

  /// Same length as active slide list; image bytes for slides not uploaded yet.
  final List<Uint8List?>? slideMemoryImages;

  @override
  State<HomeBannerHeroPreview> createState() => _HomeBannerHeroPreviewState();
}

class _HomeBannerHeroPreviewState extends State<HomeBannerHeroPreview> {
  late PageController _pageController;
  Timer? _carouselTimer;
  int _page = 0;

  List<HomeBannerSlide> get _slides =>
      widget.previewSlides != null ? widget.previewSlides! : widget.config.effectiveSlides;

  Uint8List? _memoryForIndex(int index) {
    final m = widget.slideMemoryImages;
    if (m == null || index >= m.length) return null;
    return m[index];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartCarouselTimer());
  }

  @override
  void didUpdateWidget(covariant HomeBannerHeroPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLen = oldWidget.previewSlides != null
        ? oldWidget.previewSlides!.length
        : oldWidget.config.effectiveSlides.length;
    final newLen = widget.previewSlides != null
        ? widget.previewSlides!.length
        : widget.config.effectiveSlides.length;
    if (oldLen != newLen ||
        oldWidget.config.carouselIntervalMs != widget.config.carouselIntervalMs) {
      _restartCarouselTimer();
    }
    if (_page >= newLen && newLen > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _page = 0);
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  void _restartCarouselTimer() {
    _carouselTimer?.cancel();
    final slides = _slides;
    if (slides.length <= 1) return;
    final ms = widget.config.carouselIntervalMs;
    if (ms < ShopHomeBannerConfig.kCarouselMinIntervalMs) return;
    _carouselTimer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final n = slides.length;
      final next = ((_pageController.page ?? 0).round() + 1) % n;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final h = cfg.resolvedBannerHeight;
    final slides = _slides;

    if (slides.isEmpty) {
      return SizedBox(
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(decoration: _heroGradientDecoration()),
              _GlassCaptionLayer(
                config: cfg,
                caption: cfg.titleOverlay.trim().isEmpty
                    ? ShopHomeBannerConfig.fallback.titleOverlay
                    : cfg.titleOverlay.trim(),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: slides.length,
              onPageChanged: (i) {
                setState(() => _page = i);
                _restartCarouselTimer();
              },
              itemBuilder: (context, index) {
                final slide = slides[index];
                return _SlideBackdrop(
                  slide: slide,
                  memoryBytes: _memoryForIndex(index),
                  isActive: index == _page,
                );
              },
            ),
            _GlassCaptionLayer(
              config: cfg,
              caption: cfg.captionForSlide(slides[_page.clamp(0, slides.length - 1)]),
            ),
            if (slides.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < slides.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _page ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i == _page ? 0.92 : 0.42),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassCaptionLayer extends StatelessWidget {
  const _GlassCaptionLayer({
    required this.config,
    required this.caption,
  });

  final ShopHomeBannerConfig config;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 0,
      blur: config.glassBlur && config.glassSigma > 0.5,
      sigma: config.glassSigma.clamp(0.0, 40.0),
      fillColor: Colors.white.withValues(alpha: config.glassFillAlpha.clamp(0.0, 0.6)),
      borderColor: Colors.white.withValues(alpha: config.glassBorderAlpha.clamp(0.0, 0.8)),
      padding: const EdgeInsets.all(18),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          caption,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _SlideBackdrop extends StatelessWidget {
  const _SlideBackdrop({
    required this.slide,
    required this.isActive,
    this.memoryBytes,
  });

  final HomeBannerSlide slide;
  final bool isActive;
  final Uint8List? memoryBytes;

  @override
  Widget build(BuildContext context) {
    final url = slide.url.trim();

    if (memoryBytes != null && slide.kind == HomeBannerMediaKind.image) {
      return Image.memory(
        memoryBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => DecoratedBox(decoration: _heroGradientDecoration()),
      );
    }

    if (url.isEmpty) {
      if (slide.kind == HomeBannerMediaKind.video) {
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: _heroGradientDecoration()),
            Center(
              child: Icon(
                Icons.videocam_rounded,
                size: 56,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        );
      }
      return DecoratedBox(decoration: _heroGradientDecoration());
    }

    switch (slide.kind) {
      case HomeBannerMediaKind.video:
        return _HeroVideoBackdrop(uri: Uri.parse(url), isActive: isActive);
      case HomeBannerMediaKind.image:
      case HomeBannerMediaKind.gradient:
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => DecoratedBox(decoration: _heroGradientDecoration()),
        );
    }
  }
}

class _HeroVideoBackdrop extends StatefulWidget {
  const _HeroVideoBackdrop({required this.uri, required this.isActive});

  final Uri uri;
  final bool isActive;

  @override
  State<_HeroVideoBackdrop> createState() => _HeroVideoBackdropState();
}

class _HeroVideoBackdropState extends State<_HeroVideoBackdrop> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _attach(widget.uri);
  }

  @override
  void didUpdateWidget(covariant _HeroVideoBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      _disposeController();
      _attach(widget.uri);
      return;
    }
    if (oldWidget.isActive != widget.isActive) {
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.hasError) return;
    if (widget.isActive) {
      c.play();
    } else {
      c.pause();
    }
  }

  void _attach(Uri uri) {
    final c = VideoPlayerController.networkUrl(uri)
      ..setLooping(true)
      ..setVolume(0);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted || _controller != c) return;
      setState(() {});
      if (widget.isActive) {
        c.play();
      }
    }).catchError((Object _) {
      if (!mounted || _controller != c) return;
      setState(() {});
    });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.hasError) {
      return DecoratedBox(decoration: _heroGradientDecoration());
    }
    return ColoredBox(
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
