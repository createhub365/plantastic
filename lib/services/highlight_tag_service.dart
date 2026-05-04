import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/highlight_tag.dart';

class HighlightTagService {
  HighlightTagService._();

  static const table = 'highlight_tags';

  static Future<List<HighlightTag>> fetchAllOrdered() async {
    final rows = await Supabase.instance.client
        .from(table)
        .select()
        .order('sort_order', ascending: true);
    final list = rows as List<dynamic>;
    return list
        .map((row) => HighlightTag.fromMap(Map.from(row as Map)))
        .toList();
  }

  static Future<HighlightTag> create({
    required String title,
    String label = '',
    String iconKey = 'eco',
    String body = '',
    int? sortOrder,
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'label': label.trim(),
      'icon_key': iconKey.trim(),
      'body': body,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
    final res = await Supabase.instance.client
        .from(table)
        .insert(payload)
        .select()
        .single();
    return HighlightTag.fromMap(Map<String, dynamic>.from(res));
  }

  static Future<void> deleteById(String id) async {
    await Supabase.instance.client.from(table).delete().eq('id', id);
  }

  static Future<void> update({
    required String id,
    required String title,
    required String label,
    required String iconKey,
    required String body,
  }) async {
    await Supabase.instance.client
        .from(table)
        .update({
          'title': title.trim(),
          'label': label.trim(),
          'icon_key': iconKey.trim(),
          'body': body,
        })
        .eq('id', id);
  }

  static Future<void> updateSortOrders(List<HighlightTag> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      await Supabase.instance.client
          .from(table)
          .update({'sort_order': (i + 1) * 10})
          .eq('id', ordered[i].id);
    }
  }
}
