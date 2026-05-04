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
    required this.status,
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

  /// Raw DB value (e.g. `pending`, `shipped`). Defaults when column absent.
  final String status;

  ShopOrder copyWith({String? status}) {
    return ShopOrder(
      id: id,
      createdAt: createdAt,
      customerName: customerName,
      phone: phone,
      addressLine1: addressLine1,
      city: city,
      postalCode: postalCode,
      total: total,
      rawItems: rawItems,
      status: status ?? this.status,
    );
  }

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

    final rawStatus = row['status'] ?? row['fulfillment_status'];
    final statusStr = rawStatus == null
        ? 'pending'
        : '$rawStatus'.trim().toLowerCase();

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
      status: statusStr.isEmpty ? 'pending' : statusStr,
    );
  }
}
