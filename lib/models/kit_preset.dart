import '../data/kit_catalog_ids.dart';
import '../data/kit_preset_ids.dart';

class KitPreset {
  const KitPreset({
    required this.id,
    required this.name,
    required this.catalogIds,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final List<String> catalogIds;
  final int sortOrder;

  factory KitPreset.fromMap(Map<String, dynamic> map) {
    final idRaw = map['id'];
    final ord = map['sort_order'];
    return KitPreset(
      id: idRaw == null ? '' : '$idRaw',
      name: (map['name'] as String? ?? '').trim(),
      catalogIds: _uuidList(map['catalog_ids']),
      sortOrder: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap({bool includeId = false}) => {
    if (includeId && id.isNotEmpty) 'id': id,
    'name': name.trim(),
    'catalog_ids': catalogIds,
    'sort_order': sortOrder,
  };

  KitPreset copyWith({
    String? id,
    String? name,
    List<String>? catalogIds,
    int? sortOrder,
  }) {
    return KitPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      catalogIds: catalogIds ?? this.catalogIds,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static List<String> _uuidList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  /// Offline defaults (matches migration `plantastic_kit_presets` seed IDs).
  static List<KitPreset> seededDefaults() => [
    KitPreset(
      id: KitPresetIds.starterBundle,
      name: 'Starter bundle',
      catalogIds: List<String>.from(KitCatalogIds.defaultStarterIds),
      sortOrder: 10,
    ),
    KitPreset(
      id: KitPresetIds.deluxeBundle,
      name: 'Deluxe bundle',
      catalogIds: List<String>.from(KitCatalogIds.defaultDeluxeIds),
      sortOrder: 20,
    ),
  ];
}
