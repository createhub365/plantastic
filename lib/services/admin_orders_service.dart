import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shop_order.dart';

class AdminOrdersService {
  AdminOrdersService._();

  static Future<List<ShopOrder>> fetchOrders() async {
    final rows = await Supabase.instance.client
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    final list = <ShopOrder>[];
    for (final row in rows as List<dynamic>) {
      list.add(ShopOrder.fromMap(Map<String, dynamic>.from(row as Map)));
    }
    return list;
  }

  /// Persists fulfilment status when `orders.status` (or DB policy) allows it.
  static Future<void> updateOrderStatus({
    required String id,
    required String status,
  }) async {
    await Supabase.instance.client.from('orders').update({
      'status': status,
    }).eq('id', id);
  }
}
