import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../layout/plantastic_layout.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
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

    final result = await OrderService.placeOrder(
      lines: cart.lines,
      customerName: _name.text,
      phone: _phone.text,
      addressLine1: _line1.text,
      city: _city.text,
      postalCode: _postal.text,
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

  @override
  Widget build(BuildContext context) {
    final configured = AppConfig.supabaseReady;
    final g = PlantasticLayout.gutter(context);

    return Scaffold(
      appBar: const PlantasticAppBar(showBack: true),
      body: PlantasticLayout.constrainedBody(
        context,
        child: ListView(
          padding: EdgeInsets.fromLTRB(g, 16, g, 24),
          children: [
            Text(
              'Delivery address',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
                            style: Theme.of(context).textTheme.bodySmall,
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
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: '10-digit mobile',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Enter a valid phone number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _line1,
                    decoration: const InputDecoration(
                      labelText: 'Address line',
                      hintText: 'House / street',
                    ),
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().length < 5)
                        ? 'Enter delivery address'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: 'City'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postal,
                    decoration: const InputDecoration(labelText: 'Postal code'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().length < 6)
                        ? 'Enter postal code'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitting ? null : () => _placeOrder(context),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: Center(child: PlantasticLoading.inline),
                          )
                        : const Text('Place order'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
