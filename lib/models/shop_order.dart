/// Row from Supabase `orders` (customer + items snapshot).
class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.createdAt,
    required this.customerName,
    required this.phone,
    required this.addressLine1,
    required this.city,
    required this.postalCode,
    required this.total,
    required this.rawItems,
  });

  final String id;
  final DateTime? createdAt;
  final String customerName;
  final String phone;
  final String addressLine1;
  final String city;
  final String postalCode;
  final num total;
  final List<Map<String, dynamic>> rawItems;

  factory ShopOrder.fromMap(Map<String, dynamic> row) {
    final itemsDyn = row['items'];
    final List<Map<String, dynamic>> parsed = [];
    if (itemsDyn is List) {
      for (final e in itemsDyn) {
        if (e is Map<String, dynamic>) {
          parsed.add(e);
        } else if (e is Map) {
          parsed.add(Map<String, dynamic>.from(e));
        }
      }
    }

    DateTime? at;
    final rawAt = row['created_at'];
    if (rawAt is String) {
      at = DateTime.tryParse(rawAt);
    }

    return ShopOrder(
      id: row['id'] == null ? '' : '${row['id']}',
      createdAt: at,
      customerName: row['customer_name'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      addressLine1: row['address_line1'] as String? ?? '',
      city: row['city'] as String? ?? '',
      postalCode: row['postal_code'] as String? ?? '',
      total: row['total'] as num? ?? 0,
      rawItems: parsed,
    );
  }
}
