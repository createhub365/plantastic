import 'package:flutter/material.dart';

/// Fit policy for normalized shop artwork vs arbitrary uploads:
///
/// When [alwaysContain] is false:
/// **Decoded 1080×1080** → [BoxFit.cover] … **else** → [BoxFit.contain].
///
/// [canonicalSide] matches your pipeline’s normalized square master.
class DecodeAwareProductImage extends StatefulWidget {
  const DecodeAwareProductImage({
    super.key,
    required this.image,
    this.width = double.infinity,
    this.height = double.infinity,
    this.alignment = Alignment.center,
    this.color,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = true,

    /// When true, always [BoxFit.contain] so nothing is cropped (e.g. shop cards).
    this.alwaysContain = false,
  });

  static const int canonicalSide = 1080;

  final ImageProvider image;
  final double width;
  final double height;
  final Alignment alignment;
  final Color? color;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final String? semanticLabel;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final bool alwaysContain;

  @override
  State<DecodeAwareProductImage> createState() =>
      _DecodeAwareProductImageState();
}

class _DecodeAwareProductImageState extends State<DecodeAwareProductImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;

  BoxFit _fit = BoxFit.contain;
  bool _resolved = false;
  bool _isCanonicalSquare = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToStream(widget.image);
  }

  @override
  void didUpdateWidget(covariant DecodeAwareProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _stopListening();
      setState(() {
        _resolved = false;
        _fit = BoxFit.contain;
        _isCanonicalSquare = false;
      });
      _listenToStream(widget.image);
    } else if (oldWidget.alwaysContain != widget.alwaysContain && _resolved) {
      setState(() {
        _fit = widget.alwaysContain
            ? BoxFit.contain
            : (_isCanonicalSquare ? BoxFit.cover : BoxFit.contain);
      });
    }
  }

  void _listenToStream(ImageProvider provider) {
    if (_resolved || _listener != null) return;

    final configuration = createLocalImageConfiguration(context);
    final stream = provider.resolve(configuration);
    _stream = stream;

    _listener = ImageStreamListener(
      _onFrame,
      onError: (Object exception, StackTrace? stackTrace) {
        if (!mounted) return;
        _stopListening();
        setState(() {
          _fit = BoxFit.contain;
          _isCanonicalSquare = false;
          _resolved = true;
        });
      },
    );
    stream.addListener(_listener!);
  }

  void _onFrame(ImageInfo info, bool synchronousCall) {
    if (!mounted) return;
    _stopListening();

    final w = info.image.width;
    final h = info.image.height;
    final canonical =
        w == DecodeAwareProductImage.canonicalSide &&
        h == DecodeAwareProductImage.canonicalSide;

    setState(() {
      _isCanonicalSquare = canonical;
      _fit = widget.alwaysContain
          ? BoxFit.contain
          : (canonical ? BoxFit.cover : BoxFit.contain);
      _resolved = true;
    });
  }

  void _stopListening() {
    if (_listener != null && _stream != null) {
      _stream!.removeListener(_listener!);
    }
    _listener = null;
    _stream = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return ColoredBox(color: Colors.grey.shade100);
    }

    return Image(
      image: widget.image,
      fit: _fit,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      color: widget.color,
      errorBuilder: widget.errorBuilder,
      semanticLabel: widget.semanticLabel,
      filterQuality: widget.filterQuality,
      gaplessPlayback: widget.gaplessPlayback,
      loadingBuilder: widget.loadingBuilder,
    );
  }
}
