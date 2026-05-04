import 'razorpay_checkout_types.dart';

/// Fallback when neither `dart.library.html` nor `dart.library.io` applies.
Future<RazorpayCheckoutResult> presentPlantasticRazorpayCheckout({
  required String keyId,
  required int amountPaise,
  required String customerName,
  required String customerPhone,
  String? serverOrderId,
}) async {
  return RazorpayCheckoutResult.skipped();
}
