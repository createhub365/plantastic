import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kit_preset.dart';

class KitPresetService {
  KitPresetService._();

  static const table = 'kit_presets';

  static Future<List<KitPreset>> fetchAllOrdered() async {
    final rows = await Supabase.instance.client
        .from(table)
        .select()
        .order('sort_order', ascending: true);
    final list = rows as List<dynamic>;
    return list.map((row) => KitPreset.fromMap(Map.from(row as Map))).toList();
  }

  static Future<KitPreset> create({
    required String name,
    required List<String> catalogIds,
    int? sortOrder,
  }) async {
    final res = await Supabase.instance.client
        .from(table)
        .insert({
          if (sortOrder != null) 'sort_order': sortOrder,
          'name': name.trim(),
          'catalog_ids': catalogIds,
        })
        .select()
        .single();
    return KitPreset.fromMap(Map<String, dynamic>.from(res));
  }

  static Future<void> updateFull(KitPreset p) async {
    await Supabase.instance.client
        .from(table)
        .update({
          'name': p.name.trim(),
          'catalog_ids': p.catalogIds,
          'sort_order': p.sortOrder,
        })
        .eq('id', p.id);
  }

  static Future<void> deleteById(String id) async {
    await Supabase.instance.client.from(table).delete().eq('id', id);
  }

  static Future<void> updateSortOrders(List<KitPreset> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      await Supabase.instance.client
          .from(table)
          .update({'sort_order': (i + 1) * 10})
          .eq('id', ordered[i].id);
    }
  }
}
