import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/product_image_normalize.dart';

/// Uploads JPEG/PNG/WebP bytes to Supabase Storage and returns **public** URL.
class ProductImageUploadService {
  ProductImageUploadService._();

  static String get bucket =>
      _pickBucket([
        'SUPABASE_PRODUCT_IMAGES_BUCKET',
        'PRODUCT_IMAGES_BUCKET',
      ]) ??
      'product-images';

  static String? _pickBucket(List<String> keys) {
    if (!dotenv.isInitialized) return null;
    for (final k in keys) {
      final v = dotenv.env[k]?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static String _guessContentType(String ext) {
    final e = ext.toLowerCase();
    switch (e) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  static String _extFrom(String pathLower) {
    final i = pathLower.lastIndexOf('.');
    if (i < 0 || i >= pathLower.length - 1) return 'jpg';
    return pathLower.substring(i + 1);
  }

  static bool _schemaMismatch(StorageException e) =>
      e.error == 'DatabaseSchemaMismatch' ||
      (e.message.toLowerCase().contains('schema') &&
          e.message.toLowerCase().contains('out of sync'));

  static bool _transientUpload(StorageException e) {
    final c = e.statusCode ?? '';
    if (c == '503' || c == '429' || c == '504' || c == '423') return true;
    return e.message.toLowerCase().contains('slow down');
  }

  static Exception _wrappedSchemaError(StorageException e) => Exception(
    'Plantastic Supabase: database/storage schema mismatch. '
    'Run every SQL file in plantastic/supabase/migrations (in filename order), '
    'via Dashboard → SQL or `supabase db push`. '
    'If it still fails, pause/resume project or contact Supabase support. '
    'Original: ${e.error ?? e.statusCode}: ${e.message}',
  );

  static Future<String> uploadProductBytes({
    required String productId,
    required Uint8List bytes,
    required String suggestedPath,
    String preferredExt = 'jpg',
  }) async {
    var ext = suggestedPath.contains('.')
        ? _extFrom(suggestedPath.toLowerCase())
        : preferredExt;
    final safePid = productId.replaceAll(RegExp(r'[^\w\-]'), '');
    var uploadBytes = bytes;
    // Decode + resize JPEG is CPU-heavy — keep UI responsive during admin Save.
    final normalized = await compute(
      normalizeProductImageToSquare1080Jpeg,
      bytes,
    );
    if (normalized != null) {
      uploadBytes = normalized;
      ext = 'jpg';
    }

    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}.$ext';
    final path = '${safePid.isEmpty ? 'orphan' : safePid}/$name';

    final client = Supabase.instance.client.storage.from(bucket);

    const maxAttempts = 4;
    StorageException? last;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await client.uploadBinary(
          path,
          uploadBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _guessContentType(ext),
          ),
        );
        return client.getPublicUrl(path);
      } on StorageException catch (e) {
        last = e;
        if (_schemaMismatch(e)) {
          throw _wrappedSchemaError(e);
        }
        if (!_transientUpload(e)) {
          rethrow;
        }
        if (attempt >= maxAttempts - 1) break;
        await Future<void>.delayed(
          Duration(milliseconds: 350 * (1 << attempt)),
        );
      }
    }

    throw last ??
        StorageException(
          'Product image upload failed after retries.',
          statusCode: 'unknown',
        );
  }
}
