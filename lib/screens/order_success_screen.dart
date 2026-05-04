import 'package:flutter/material.dart';

import '../layout/plantastic_layout.dart';
import '../widgets/plantastic_app_bar.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, this.orderId});

  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final g = PlantasticLayout.gutter(context);
    return Scaffold(
      appBar: const PlantasticAppBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(g, 24, g, 24),
          child: PlantasticLayout.constrainedBody(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Thank you!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Plantastic order has been placed.'
                  '${orderId != null ? '\nReference: ${orderId!}' : ''}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (_) => false);
                  },
                  child: const Text('Back to shop'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
