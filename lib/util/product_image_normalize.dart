import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Server + shop ke liye square asset; poora image dikhta hai (letterbox), crop nahi.
const int kProductImageSquarePx = 1080;

/// Letterbox / card surface (matches light theme).
const int _kLetterboxR = 238;
const int _kLetterboxG = 243;
const int _kLetterboxB = 241;

/// Decode → 1080×1080 JPEG (fit contain), ya `null` agar decode fail (caller bytes chhod sakta hai).
Uint8List? normalizeProductImageToSquare1080Jpeg(
  Uint8List bytes, {
  int jpegQuality = 88,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final w = decoded.width;
  final h = decoded.height;
  if (w < 1 || h < 1) return null;

  const side = kProductImageSquarePx;
  final bg = img.ColorRgb8(_kLetterboxR, _kLetterboxG, _kLetterboxB);
  final canvas = img.Image(width: side, height: side, numChannels: 3);
  img.fill(canvas, color: bg);

  var s = side / w;
  if (side / h < s) s = side / h;
  final nw = (w * s).round().clamp(1, side);
  final nh = (h * s).round().clamp(1, side);

  final fitted = img.copyResize(
    decoded,
    width: nw,
    height: nh,
    interpolation: img.Interpolation.linear,
  );

  img.compositeImage(
    canvas,
    fitted,
    dstX: (side - nw) ~/ 2,
    dstY: (side - nh) ~/ 2,
  );

  return Uint8List.fromList(img.encodeJpg(canvas, quality: jpegQuality));
}
