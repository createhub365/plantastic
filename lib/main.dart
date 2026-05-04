import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_notifier.dart';
import 'screens/admin/admin_gate_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/catalog_loading_overlay.dart';
import 'widgets/plantastic_scroll_behavior.dart';

String _stripEnvQuotes(String raw) {
  var s = raw.trim();
  if (s.length >= 2) {
    final q = s[0];
    if ((q == '"' || q == "'") && s[s.length - 1] == q) {
      s = s.substring(1, s.length - 1).trim();
    }
  }
  return s;
}

String? _pickNonEmpty(Map<String, String> m, Iterable<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && v.trim().isNotEmpty) return v;
  }
  return null;
}

/// Prefer compile-time [--dart-define] (CI / Netlify); else bundled `.env`.
String _effectiveSupabaseUrl(Map<String, String> env) {
  final define =
      _stripEnvQuotes(String.fromEnvironment('SUPABASE_URL', defaultValue: ''))
          .trim();
  if (define.isNotEmpty) return define;
  final picked =
      _pickNonEmpty(env, ['SUPABASE_URL', 'NEXT_PUBLIC_SUPABASE_URL']);
  return picked != null ? _stripEnvQuotes(picked).trim() : '';
}

/// Prefer compile-time [--dart-define]; else bundled `.env`.
String _effectiveSupabaseAnonKey(Map<String, String> env) {
  final define =
      _stripEnvQuotes(
            String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
          )
          .trim();
  if (define.isNotEmpty) return define;
  final picked = _pickNonEmpty(env, [
    'SUPABASE_ANON_KEY',
    'NEXT_PUBLIC_SUPABASE_ANON_KEY',
    'PUBLIC_SUPABASE_ANON_KEY',
  ]);
  return picked != null ? _stripEnvQuotes(picked) : '';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF0F7F4),
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Color(0xFFE0EBE6),
    ),
  );

  AppConfig.envLoadError = null;
  AppConfig.supabaseInitError = null;
  AppConfig.anonKeyLength = 0;
  AppConfig.anonKeyProblemHint = null;
  AppConfig.supabaseUrlMissing = false;

  try {
    var raw = await rootBundle.loadString('.env');
    if (raw.isNotEmpty && raw.codeUnitAt(0) == 0xFEFF) {
      raw = raw.substring(1);
    }
    dotenv.testLoad(fileInput: raw);
  } catch (e, st) {
    AppConfig.envLoadError = '$e';
    if (kDebugMode) {
      debugPrint('dotenv failed: $e\n$st');
    }
  }

  final env = dotenv.isInitialized ? dotenv.env : <String, String>{};
  final url = _effectiveSupabaseUrl(env);
  AppConfig.supabaseUrlMissing = url.isEmpty;

  final key = _effectiveSupabaseAnonKey(env);
  AppConfig.anonKeyLength = key.trim().length;

  if (key.trim().isEmpty) {
    const anonNames = [
      'SUPABASE_ANON_KEY',
      'NEXT_PUBLIC_SUPABASE_ANON_KEY',
      'PUBLIC_SUPABASE_ANON_KEY',
    ];
    final present = anonNames.where((n) => env.containsKey(n)).toList();
    final emptyNamed = anonNames.any(
      (n) => env.containsKey(n) && env[n]!.trim().isEmpty,
    );
    AppConfig.anonKeyProblemHint = emptyNamed
        ? 'empty'
        : (present.isEmpty ? 'missing' : null);
  }

  AppConfig.supabaseReady = false;
  final trimmedKey = key.trim();
  if (url.isNotEmpty && trimmedKey.length > 20) {
    try {
      await Supabase.initialize(url: url, anonKey: trimmedKey);
      AppConfig.supabaseReady = true;
    } catch (e, st) {
      AppConfig.supabaseInitError = '$e';
      if (kDebugMode) {
        debugPrint('Supabase.initialize failed: $e\n$st');
      }
      AppConfig.supabaseReady = false;
    }
  } else if (kDebugMode) {
    debugPrint(
      'Supabase skipped: need SUPABASE_URL + anon key. '
      'urlLen=${url.length} keyLen=${trimmedKey.length}',
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartNotifier()),
        ChangeNotifierProvider(create: (_) => CatalogNotifier()),
      ],
      child: const PlantasticApp(),
    ),
  );
}

/// Web: `/admin`, `/#/admin`, or path ending with `admin` → admin gate.
String _resolvedInitialRoute() {
  if (!kIsWeb) return '/';
  final uri = Uri.base;
  var path = uri.path;
  if (path.endsWith('/') && path.length > 1) {
    path = path.substring(0, path.length - 1);
  }
  if (path == '/admin' || path.endsWith('/admin')) return '/admin';
  final fragment = uri.fragment.trim();
  if (fragment.isNotEmpty) {
    final norm = fragment.startsWith('/') ? fragment : '/$fragment';
    if (norm == '/admin' || norm.endsWith('/admin')) return '/admin';
  }
  return '/';
}

class PlantasticApp extends StatelessWidget {
  const PlantasticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: const PlantasticScrollBehavior(),
      title: 'Plantastic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: _resolvedInitialRoute(),
      routes: {
        '/': (_) => const HomeScreen(),
        '/cart': (_) => const CartScreen(),
        '/admin': (_) => const AdminGateScreen(),
      },
      builder: (context, child) {
        return Consumer<CatalogNotifier>(
          builder: (context, catalog, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                if (child != null) Positioned.fill(child: child),
                if (catalog.loading)
                  const Positioned.fill(child: CatalogLoadingOverlay()),
              ],
            );
          },
        );
      },
    );
  }
}
