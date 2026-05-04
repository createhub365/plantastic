import 'razorpay_checkout_types.dart';
export 'razorpay_checkout_types.dart';
import 'razorpay_checkout_stub.dart'
    if (dart.library.html) 'razorpay_checkout_web.dart'
    if (dart.library.io) 'razorpay_checkout_io.dart' as razorpay_impl;

/// Opens Razorpay: **web** uses Checkout JS; **Android/iOS** uses `razorpay_flutter`.
/// Pass [serverOrderId] from the Orders Edge Function when available.
Future<RazorpayCheckoutResult> presentPlantasticRazorpayCheckout({
  required String keyId,
  required int amountPaise,
  required String customerName,
  required String customerPhone,
  String? serverOrderId,
}) =>
    razorpay_impl.presentPlantasticRazorpayCheckout(
      keyId: keyId,
      amountPaise: amountPaise,
      customerName: customerName,
      customerPhone: customerPhone,
      serverOrderId: serverOrderId,
    );
