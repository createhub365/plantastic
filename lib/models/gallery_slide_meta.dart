/// Per-image label stored parallel to [Product.galleryUrls] / gallery order.
class GallerySlideMeta {
  GallerySlideMeta({required this.flowerName, this.snippet = ''});

  final String flowerName;
  final String snippet;

  factory GallerySlideMeta.fromMap(Map<String, dynamic> map) {
    final n = map['flower_name'] ?? map['flowerName'];
    final s = map['snippet'];
    return GallerySlideMeta(
      flowerName: n == null ? '' : '$n'.trim(),
      snippet: s == null ? '' : '$s'.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'flower_name': flowerName.trim(),
    if (snippet.trim().isNotEmpty) 'snippet': snippet.trim(),
  };
}
