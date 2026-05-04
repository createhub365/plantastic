import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:plantastic/providers/cart_provider.dart';

import 'package:plantastic/providers/catalog_notifier.dart';

import 'package:plantastic/screens/home_screen.dart';

import 'package:plantastic/theme/app_theme.dart';

void main() {
  testWidgets('Home loads seed grid and catalogue text', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartNotifier()),

          ChangeNotifierProvider(create: (_) => CatalogNotifier()),
        ],

        child: MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
      ),
    );

    expect(find.text('PLANTASTIC'), findsOneWidget);

    expect(find.text('From ₹499'), findsWidgets);

    expect(find.textContaining('multiple kits'), findsWidgets);
  });
}
