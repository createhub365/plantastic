import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kit_catalog_item.dart';

class KitCatalogService {
  KitCatalogService._();

  static const table = 'kit_catalog_items';

  static Future<List<KitCatalogItem>> fetchAllOrdered() async {
    final rows = await Supabase.instance.client
        .from(table)
        .select()
        .order('sort_order', ascending: true);
    final list = rows as List<dynamic>;
    return list
        .map((row) => KitCatalogItem.fromMap(Map.from(row as Map)))
        .toList();
  }

  static Future<KitCatalogItem> createLabelOnly({
    required String label,
    int? sortOrder,
  }) async {
    final res = await Supabase.instance.client
        .from(table)
        .insert({
          if (sortOrder != null) 'sort_order': sortOrder,
          'label': label.trim(),
        })
        .select()
        .single();
    return KitCatalogItem.fromMap(Map<String, dynamic>.from(res));
  }

  static Future<void> deleteById(String id) async {
    await Supabase.instance.client.from(table).delete().eq('id', id);
  }

  static Future<void> updateLabel({
    required String id,
    required String label,
  }) async {
    await Supabase.instance.client
        .from(table)
        .update({'label': label.trim()})
        .eq('id', id);
  }

  /// Move one row relative to current list (persist sort_order gaps).
  static Future<void> updateSortOrders(List<KitCatalogItem> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      await Supabase.instance.client
          .from(table)
          .update({'sort_order': (i + 1) * 10})
          .eq('id', ordered[i].id);
    }
  }
}
