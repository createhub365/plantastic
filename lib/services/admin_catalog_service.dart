import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class AdminCatalogService {
  AdminCatalogService._();

  static Future<bool> fetchIsAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      final row = await Supabase.instance.client
          .from('plantastic_staff')
          .select('is_admin')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) return false;
      return row['is_admin'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Product>> fetchAllProducts() async {
    final data = await Supabase.instance.client
        .from('products')
        .select()
        .order('created_at', ascending: false);
    final out = <Product>[];
    for (final row in _asMaps(data)) {
      out.add(Product.fromMap(row));
    }
    return out;
  }

  static Future<Product> createProduct(
    Product draft, {
    required List<String> starterLabelSnapshot,
    required List<String> deluxeLabelSnapshot,
  }) async {
    final res = await Supabase.instance.client
        .from('products')
        .insert(
          draft.toInsertMap(
            includeId: false,
            starterLabelSnapshot: starterLabelSnapshot,
            deluxeLabelSnapshot: deluxeLabelSnapshot,
          ),
        )
        .select()
        .single();
    return Product.fromMap(_asJsonMap(res));
  }

  static Future<Product> updateProduct(
    Product p, {
    required List<String> starterLabelSnapshot,
    required List<String> deluxeLabelSnapshot,
  }) async {
    final res = await Supabase.instance.client
        .from('products')
        .update(
          p.toInsertMap(
            includeId: false,
            starterLabelSnapshot: starterLabelSnapshot,
            deluxeLabelSnapshot: deluxeLabelSnapshot,
          ),
        )
        .eq('id', p.id)
        .select()
        .single();
    return Product.fromMap(_asJsonMap(res));
  }

  static Future<void> setInStock({
    required String id,
    required bool inStock,
  }) async {
    await Supabase.instance.client
        .from('products')
        .update({'in_stock': inStock})
        .eq('id', id);
  }

  static Future<void> setVisibleInShop({
    required String id,
    required bool visible,
  }) async {
    await Supabase.instance.client
        .from('products')
        .update({'visible_in_shop': visible})
        .eq('id', id);
  }

  static Future<void> deleteProduct(String id) async {
    await Supabase.instance.client.from('products').delete().eq('id', id);
  }

  static Iterable<Map<String, dynamic>> _asMaps(dynamic data) sync* {
    if (data == null) return;
    final list = data is List ? data : const [];
    for (final row in list) {
      yield _asJsonMap(row);
    }
  }

  static Map<String, dynamic> _asJsonMap(dynamic row) {
    final m = Map<String, dynamic>.from(row as Map);
    return m;
  }
}
