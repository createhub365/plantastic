import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'razorpay_checkout_types.dart';

Future<RazorpayCheckoutResult> presentPlantasticRazorpayCheckout({
  required String keyId,
  required int amountPaise,
  required String customerName,
  required String customerPhone,
  String? serverOrderId,
}) async {
  if (kIsWeb) {
    return RazorpayCheckoutResult.skipped();
  }
  final mobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!mobile) {
    return RazorpayCheckoutResult.skipped();
  }

  final completer = Completer<RazorpayCheckoutResult>();
  final razorpay = Razorpay();

  void finish(RazorpayCheckoutResult r) {
    if (!completer.isCompleted) {
      completer.complete(r);
    }
    razorpay.clear();
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
    finish(
      RazorpayCheckoutResult.success(
        paymentId: response.paymentId,
        orderId: response.orderId,
        signature: response.signature,
      ),
    );
  });

  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    final code = response.code;
    final msg = response.message ?? 'Payment failed';
    if (code == Razorpay.PAYMENT_CANCELLED) {
      finish(RazorpayCheckoutResult.cancelled());
    } else {
      finish(RazorpayCheckoutResult.error(msg));
    }
  });

  final trimmedServerOrder = serverOrderId?.trim();
  final options = <String, dynamic>{
    'key': keyId,
    'amount': amountPaise,
    'currency': 'INR',
    'name': 'Plantastic',
    'description': 'Plant order',
    'prefill': <String, String>{
      'contact': customerPhone,
      'name': customerName,
    },
    'theme': <String, String>{'color': '#2E7D32'},
  };
  if (trimmedServerOrder != null && trimmedServerOrder.isNotEmpty) {
    options['order_id'] = trimmedServerOrder;
  }
  razorpay.open(options);

  return completer.future;
}
