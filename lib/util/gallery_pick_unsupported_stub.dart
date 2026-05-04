import 'gallery_pick_types.dart';

Future<List<GalleryPick>> pickGalleryImages() async {
  throw UnsupportedError(
    'Image picking is unavailable in this build (e.g. WASM web target). '
    'Use the default Flutter web (JavaScript / dart2js) build: '
    '`flutter run -d chrome` without --wasm, or rebuild without --wasm.',
  );
}
