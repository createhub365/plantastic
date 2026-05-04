class KitCatalogItem {
  const KitCatalogItem({
    required this.id,
    required this.label,
    required this.sortOrder,
  });

  final String id;
  final String label;
  final int sortOrder;

  factory KitCatalogItem.fromMap(Map<String, dynamic> map) {
    final idRaw = map['id'];
    final ord = map['sort_order'];
    return KitCatalogItem(
      id: idRaw == null ? '' : '$idRaw',
      label: map['label'] as String? ?? '',
      sortOrder: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap({bool includeId = false}) => {
    if (includeId && id.isNotEmpty) 'id': id,
    'label': label.trim(),
    'sort_order': sortOrder,
  };

  KitCatalogItem copyWith({String? id, String? label, int? sortOrder}) {
    return KitCatalogItem(
      id: id ?? this.id,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
