/// Outcome of attempting Razorpay Standard Checkout (mobile only).
enum RazorpayCheckoutStatus {
  success,
  cancelled,
  error,
  skipped,
}

class RazorpayCheckoutResult {
  const RazorpayCheckoutResult._({
    required this.status,
    this.paymentId,
    this.orderId,
    this.signature,
    this.message,
  });

  factory RazorpayCheckoutResult.success({
    required String? paymentId,
    String? orderId,
    String? signature,
  }) {
    return RazorpayCheckoutResult._(
      status: RazorpayCheckoutStatus.success,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  factory RazorpayCheckoutResult.cancelled() {
    return const RazorpayCheckoutResult._(status: RazorpayCheckoutStatus.cancelled);
  }

  factory RazorpayCheckoutResult.error(String message) {
    return RazorpayCheckoutResult._(
      status: RazorpayCheckoutStatus.error,
      message: message,
    );
  }

  factory RazorpayCheckoutResult.skipped() {
    return const RazorpayCheckoutResult._(status: RazorpayCheckoutStatus.skipped);
  }

  final RazorpayCheckoutStatus status;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? message;

  bool get blocksOrder =>
      status == RazorpayCheckoutStatus.cancelled ||
      status == RazorpayCheckoutStatus.error;
}
