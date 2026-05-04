class HighlightTag {
  const HighlightTag({
    required this.id,
    required this.title,
    required this.label,
    required this.iconKey,
    required this.body,
    required this.sortOrder,
  });

  final String id;
  final String title;

  /// Short pill text; empty means use [title] truncated in UI.
  final String label;
  final String iconKey;
  final String body;
  final int sortOrder;

  String get pillText {
    final l = label.trim();
    if (l.isNotEmpty) return l;
    final t = title.trim();
    return t.length > 28 ? '${t.substring(0, 25)}…' : t;
  }

  factory HighlightTag.fromMap(Map<String, dynamic> map) {
    final idRaw = map['id'];
    final ord = map['sort_order'];
    return HighlightTag(
      id: idRaw == null ? '' : '$idRaw',
      title: map['title'] as String? ?? '',
      label: map['label'] as String? ?? '',
      iconKey: map['icon_key'] as String? ?? 'eco',
      body: map['body'] as String? ?? '',
      sortOrder: ord is int ? ord : int.tryParse('$ord') ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap({bool includeId = false}) => {
    if (includeId && id.isNotEmpty) 'id': id,
    'title': title.trim(),
    'label': label.trim(),
    'icon_key': iconKey.trim(),
    'body': body,
    'sort_order': sortOrder,
  };

  HighlightTag copyWith({
    String? id,
    String? title,
    String? label,
    String? iconKey,
    String? body,
    int? sortOrder,
  }) {
    return HighlightTag(
      id: id ?? this.id,
      title: title ?? this.title,
      label: label ?? this.label,
      iconKey: iconKey ?? this.iconKey,
      body: body ?? this.body,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
