import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../layout/plantastic_layout.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../services/razorpay_backend_service.dart';
import '../services/razorpay_checkout.dart';
import '../widgets/plantastic_app_bar.dart';
import '../widgets/plantastic_loading.dart';
import 'order_success_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  bool _submitting = false;

  static const double _fieldRadius = 12;

  InputDecoration _fieldDecoration(BuildContext context, String label,
      {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.55)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: cs.error.withValues(alpha: 0.9)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _city.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final cart = context.read<CartNotifier>();

    setState(() => _submitting = true);

    final totalRupee =
        cart.lines.fold<int>(0, (s, line) => s + line.lineTotal);
    final amountPaise = totalRupee * 100;
    final keyId = AppConfig.razorpayKeyId.trim();
    final useRazorpay = keyId.isNotEmpty &&
        totalRupee > 0 &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    String? serverRzpOrderId;
    if (useRazorpay && AppConfig.supabaseReady) {
      serverRzpOrderId = await RazorpayBackendService.createOrder(amountPaise);
    }

    RazorpayCheckoutResult paymentOutcome =
        RazorpayCheckoutResult.skipped();
    if (useRazorpay) {
      paymentOutcome = await presentPlantasticRazorpayCheckout(
        keyId: keyId,
        amountPaise: amountPaise,
        customerName: _name.text.trim(),
        customerPhone: _phone.text.trim(),
        serverOrderId: serverRzpOrderId,
      );
      if (!mounted) return;

      if (paymentOutcome.blocksOrder) {
        setState(() => _submitting = false);
        final msg = paymentOutcome.status == RazorpayCheckoutStatus.cancelled
            ? 'Payment cancelled'
            : (paymentOutcome.message ?? 'Payment failed');
        messenger.showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
        return;
      }

      final pid = paymentOutcome.paymentId?.trim();
      if (pid == null || pid.isEmpty) {
        setState(() => _submitting = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Payment did not return an id. Try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final serverFlow =
          serverRzpOrderId != null && serverRzpOrderId.trim().isNotEmpty;
      if (serverFlow) {
        final oid = paymentOutcome.orderId?.trim();
        final sig = paymentOutcome.signature?.trim();
        if (oid == null ||
            oid.isEmpty ||
            sig == null ||
            sig.isEmpty) {
          setState(() => _submitting = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Incomplete payment response. Try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        final verified = await RazorpayBackendService.verifyPayment(
          orderId: oid,
          paymentId: pid,
          signature: sig,
        );
        if (!mounted) return;
        if (!verified) {
          setState(() => _submitting = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Payment could not be verified. If money was deducted, contact support.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    final result = await OrderService.placeOrder(
      lines: cart.lines,
      customerName: _name.text,
      phone: _phone.text,
      addressLine1: _line1.text,
      city: _city.text,
      postalCode: _postal.text,
      razorpayPaymentId: paymentOutcome.paymentId,
      razorpayOrderId: paymentOutcome.orderId,
      razorpaySignature: paymentOutcome.signature,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      cart.clear();
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => OrderSuccessScreen(orderId: result.orderId),
        ),
        (_) => false,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Something went wrong'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _checkoutButtonLabel(CartNotifier cart) {
    final totalRupee =
        cart.lines.fold<int>(0, (s, line) => s + line.lineTotal);
    final keyId = AppConfig.razorpayKeyId.trim();
    final pay = keyId.isNotEmpty &&
        totalRupee > 0 &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return pay ? 'Pay & place order' : 'Place order';
  }

  @override
  Widget build(BuildContext context) {
    final configured = AppConfig.supabaseReady;
    final cart = context.watch<CartNotifier>();
    final g = PlantasticLayout.gutter(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const PlantasticAppBar(showBack: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PlantasticLayout.constrainedBody(
              context,
              child: ListView(
                padding: EdgeInsets.fromLTRB(g, 16, g, 16),
                children: [
                  Text(
                    'Delivery details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Step 2 of 3',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (!configured)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        color: const Color(0xFF3E2723),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFFFFB74D),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Add SUPABASE_ANON_KEY to .env so orders reach your dashboard.',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (configured &&
                      kIsWeb &&
                      AppConfig.razorpayKeyId.trim().isEmpty &&
                      cart.lines.fold<int>(0, (s, l) => s + l.lineTotal) > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        color: const Color(0xFFE65100),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.payment_rounded,
                                color: Color(0xFFFFE0B2),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Razorpay is off in this build (no RAZORPAY_KEY_ID). '
                                  'Add RAZORPAY_KEY_ID under Vercel → Environment Variables '
                                  'and redeploy so Pay & place order opens checkout.',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          decoration:
                              _fieldDecoration(context, 'Full name'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          decoration: _fieldDecoration(
                            context,
                            'Phone',
                            hint: '10-digit mobile',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              (v == null || v.trim().length < 10)
                                  ? 'Enter a valid phone number'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _line1,
                          decoration: _fieldDecoration(
                            context,
                            'Address line',
                            hint: 'House / street',
                          ),
                          maxLines: 2,
                          validator: (v) =>
                              (v == null || v.trim().length < 5)
                                  ? 'Enter delivery address'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _city,
                          decoration: _fieldDecoration(context, 'City'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter city'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _postal,
                          decoration:
                              _fieldDecoration(context, 'Postal code'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.trim().length < 6)
                                  ? 'Enter postal code'
                                  : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: cs.primary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your data is secure',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.75),
                                    height: 1.35,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            maintainBottomViewPadding: true,
            child: Material(
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              color: cs.surface,
              child: Padding(
                padding: EdgeInsets.fromLTRB(g, 12, g, 12),
                child: FilledButton(
                  onPressed:
                      _submitting ? null : () => _placeOrder(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: Center(child: PlantasticLoading.inline),
                        )
                      : Text(_checkoutButtonLabel(cart)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
