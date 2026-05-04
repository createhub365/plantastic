import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/cart_item.dart';

class OrderService {
  static Future<OrderResult> placeOrder({
    required List<CartLine> lines,
    required String customerName,
    required String phone,
    required String addressLine1,
    required String city,
    required String postalCode,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    if (!AppConfig.supabaseReady) {
      return OrderResult.failure(
        'Supabase is not configured. Add SUPABASE_ANON_KEY to your .env file.',
      );
    }

    final total = lines.fold<int>(0, (s, line) => s + line.lineTotal);
    final items = lines
        .map(
          (line) => {
            'productId': line.product.id,
            'title': line.product.title,
            'kit_line_id': line.kitLineId,
            'kit_label': line.kitLabel,
            // Human-readable slug for spreadsheets / backward compat:
            'kit': line.kitLabel,
            'unitPrice': line.unitPrice,
            'qty': line.quantity,
          },
        )
        .toList();

    try {
      final row = <String, dynamic>{
        'customer_name': customerName.trim(),
        'phone': phone.trim(),
        'address_line1': addressLine1.trim(),
        'city': city.trim(),
        'postal_code': postalCode.trim(),
        'items': items,
        'total': total,
      };
      final payId = razorpayPaymentId?.trim();
      if (payId != null && payId.isNotEmpty) {
        row['razorpay_payment_id'] = payId;
      }
      final oid = razorpayOrderId?.trim();
      if (oid != null && oid.isNotEmpty) {
        row['razorpay_order_id'] = oid;
      }
      final sig = razorpaySignature?.trim();
      if (sig != null && sig.isNotEmpty) {
        row['razorpay_signature'] = sig;
      }

      // Guest checkout runs as Supabase `anon`. RLS allows INSERT but not SELECT on
      // `orders`, so `.select()` after insert fails (RETURNING triggers SELECT policies).
      await Supabase.instance.client.from('orders').insert(row);

      return OrderResult.success(orderId: null);
    } catch (e, st) {
      developer.log('placeOrder failed', error: e, stackTrace: st);
      return OrderResult.failure('$e');
    }
  }
}

class OrderResult {
  OrderResult._({this.success = false, this.orderId, this.message});

  factory OrderResult.success({String? orderId}) =>
      OrderResult._(success: true, orderId: orderId);

  factory OrderResult.failure(String message) =>
      OrderResult._(success: false, message: message);

  final bool success;
  final String? orderId;
  final String? message;
}
