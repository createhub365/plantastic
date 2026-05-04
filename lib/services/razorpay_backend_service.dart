import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Razorpay Orders API + HMAC verification via Supabase Edge Functions (secrets live on server).
class RazorpayBackendService {
  RazorpayBackendService._();

  /// Razorpay `order_*` id from `/v1/orders`, or `null` if the function failed / unavailable.
  static Future<String?> createOrder(int amountPaise) async {
    if (!AppConfig.supabaseReady) return null;
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'razorpay-create-order',
        body: <String, dynamic>{'amount_paise': amountPaise},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final id = data['order_id'];
        final s = id == null ? '' : '$id'.trim();
        if (s.isNotEmpty) return s;
      }
    } catch (e, st) {
      developer.log('razorpay-create-order failed', error: e, stackTrace: st);
    }
    return null;
  }

  /// Validates `razorpay_signature` for `order_id|payment_id` using Key Secret on the server.
  static Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    if (!AppConfig.supabaseReady) return false;
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'razorpay-verify-payment',
        body: <String, dynamic>{
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return data['valid'] == true;
      }
    } catch (e, st) {
      developer.log('razorpay-verify-payment failed', error: e, stackTrace: st);
    }
    return false;
  }
}
