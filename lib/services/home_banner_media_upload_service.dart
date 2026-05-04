import 'dart:math';
import 'dart:typed_data';

import 'package:plantastic/services/product_image_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads raw banner image/video bytes to the same public bucket as product photos,
/// under `site/home-banner/` (no square JPEG normalization).
class HomeBannerMediaUploadService {
  HomeBannerMediaUploadService._();

  /// Matches [supabase/migrations/20260504240000_storage_product_images_file_size_limit.sql].
  static const int maxBannerUploadBytes = 100 * 1024 * 1024;

  static String get maxBannerUploadLabel => '100 MB';

  /// Throws [Exception] if [byteLength] exceeds [maxBannerUploadBytes].
  static void assertBannerFileSizeOk(int byteLength) {
    if (byteLength <= maxBannerUploadBytes) return;
    final mb = (byteLength / (1024 * 1024)).toStringAsFixed(1);
    throw Exception(
      'File too large ($mb MB). Banner uploads must be at most $maxBannerUploadLabel. '
      'Compress the video or use a smaller image.',
    );
  }

  static String _extFrom(String pathLower) {
    final i = pathLower.lastIndexOf('.');
    if (i < 0 || i >= pathLower.length - 1) return 'bin';
    return pathLower.substring(i + 1);
  }

  static String _contentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      default:
        return 'application/octet-stream';
    }
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
        'Run migrations in plantastic/supabase/migrations. '
        'Original: ${e.error ?? e.statusCode}: ${e.message}',
      );

  /// Returns **public** URL for the uploaded object.
  static Future<String> uploadBannerBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    assertBannerFileSizeOk(bytes.length);

    final ext = _extFrom(fileName.toLowerCase());
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}.$ext';
    final path = 'site/home-banner/$name';

    final client = Supabase.instance.client.storage.from(ProductImageUploadService.bucket);

    const maxAttempts = 4;
    StorageException? last;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await client.uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(ext),
          ),
        );
        return client.getPublicUrl(path);
      } on StorageException catch (e) {
        last = e;
        if (_schemaMismatch(e)) {
          throw _wrappedSchemaError(e);
        }
        final code = e.statusCode ?? '';
        final errStr = (e.error?.toString() ?? '').toLowerCase();
        if (code == '413' ||
            e.message.toLowerCase().contains('maximum allowed size') ||
            errStr.contains('payload')) {
          throw Exception(
            'Upload too large for Storage (413). Use a file under $maxBannerUploadLabel, '
            'or raise `file_size_limit` on the `product-images` bucket (see migration '
            '20260504240000_storage_product_images_file_size_limit.sql).',
          );
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
          'Home banner upload failed after retries.',
          statusCode: 'unknown',
        );
  }
}
