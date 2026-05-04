/// Helpers for catalogue image refs (bundled [`Image.asset`] and remote `http(s)`).
///
/// Preferred order in shop UI: bundled paths first where present, otherwise Supabase/other URLs.
///
/// References:
/// - **`asset:`** prefix optional: `asset:assets/catalog/marigold.webp`
/// - **Plain path** (no URI scheme): `assets/catalog/foo.png`
/// - **Remote:** `https://…` uploads from admin
abstract final class CatalogAssets {
  CatalogAssets._();

  static bool looksLikeRemoteUrl(String raw) {
    final s = raw.trim().toLowerCase();
    return s.startsWith('http://') || s.startsWith('https://');
  }

  /// Sample / legacy Unsplash hotlinks in DB often 404; never prefetch or paint them.
  static bool isDroppedHotlinkCatalogUrl(String raw) {
    final u = Uri.tryParse(raw.trim());
    if (u == null || u.host.isEmpty) return false;
    final host = u.host.toLowerCase();
    return host == 'images.unsplash.com' ||
        host == 'cdn.unsplash.com' ||
        host.endsWith('.unsplash.com');
  }

  /// Remote URLs we load in shop UI (excludes [isDroppedHotlinkCatalogUrl]).
  static bool looksLikeUsableShopRemoteUrl(String raw) =>
      looksLikeRemoteUrl(raw) && !isDroppedHotlinkCatalogUrl(raw);

  static bool isBundledRef(String raw) {
    final s = raw.trim();
    return s.isNotEmpty && !looksLikeRemoteUrl(s);
  }

  /// Strip optional `asset:` for [Image.asset].
  static String assetPath(String raw) {
    var s = raw.trim();
    if (s.startsWith('asset:')) {
      s = s.substring('asset:'.length).trim();
    }
    return s;
  }

  static List<String> bundledPaths(Iterable<String> refs) => [
    for (final r in refs)
      if (isBundledRef(r)) assetPath(r),
  ];

  /// Grid + carousel: keep order; asset paths normalized, remote URLs kept as-is.
  static List<String> shopRenderableImageRefs(Iterable<String> refs) {
    final out = <String>[];
    for (final r in refs) {
      final t = r.trim();
      if (t.isEmpty) continue;
      if (looksLikeUsableShopRemoteUrl(t)) {
        out.add(t);
      } else if (isBundledRef(t)) {
        out.add(assetPath(t));
      }
    }
    return out;
  }
}
