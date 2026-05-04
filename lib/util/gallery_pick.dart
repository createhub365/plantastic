import 'gallery_pick_types.dart';

export 'gallery_pick_types.dart';

import 'gallery_pick_unsupported_stub.dart'
    if (dart.library.html) 'gallery_pick_web.dart'
    if (dart.library.io) 'gallery_pick_io.dart'
    as gallery_impl;

Future<List<GalleryPick>> pickGalleryImages() =>
    gallery_impl.pickGalleryImages();
