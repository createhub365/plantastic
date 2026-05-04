import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../layout/plantastic_layout.dart';
import '../../services/admin_catalog_service.dart';
import '../../theme/admin_shell.dart';
import '../../widgets/plantastic_app_bar.dart';
import '../../widgets/plantastic_loading.dart';
import 'admin_home_screen.dart';

class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  late bool _staffLoading;

  bool _isAdmin = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _recheck() async {
    if (!mounted) return;
    if (!AppConfig.supabaseReady) return;
    if (Supabase.instance.client.auth.currentUser == null) return;
    setState(() => _staffLoading = true);
    try {
      final ok = await AdminCatalogService.fetchIsAdmin();
      if (!mounted) return;
      setState(() => _isAdmin = ok);
    } finally {
      if (mounted) setState(() => _staffLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (!AppConfig.supabaseReady) {
      _staffLoading = false;
      return;
    }
    final u = Supabase.instance.client.auth.currentUser;
    _staffLoading = u != null;
    if (u != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recheck());
    }
  }

  Future<void> _signIn() async {
    if (!AppConfig.supabaseReady) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      setState(() => _staffLoading = true);
      final admin = await AdminCatalogService.fetchIsAdmin();
      if (!mounted) return;
      setState(() {
        _isAdmin = admin;
        _staffLoading = false;
      });
      if (admin && mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const AdminHomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = kReleaseMode
          ? 'Sign-in failed. Check email and password.'
          : '$e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    if (!AppConfig.supabaseReady) return;
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    setState(() {
      _staffLoading = false;
      _isAdmin = false;
    });
  }

  Widget _chrome(Widget child) {
    return Theme(
      data: AdminShell.themeShopperChrome(),
      child: DecoratedBox(
        decoration: AdminShell.shopperBackground,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = PlantasticLayout.gutter(context);

    if (!AppConfig.supabaseReady) {
      return _chrome(
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PlantasticAppBar(
            showBack: true,
            replacementToolbarHeight: 56,
            replacementTitle: Text(
              'Admin login',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(g, 20, g, 20),
              child: Center(
                child: PlantasticLayout.constrainedBody(
                  context,
                  child: Builder(
                    builder: (ctx) {
                      final scheme = Theme.of(ctx).colorScheme;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 40,
                                color: scheme.primary.withValues(alpha: 0.9),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sign-in unavailable',
                                textAlign: TextAlign.center,
                                style: Theme.of(ctx).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'The app could not reach the backend.',
                                textAlign: TextAlign.center,
                                style: Theme.of(ctx).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                              ),
                              if (kDebugMode &&
                                  AppConfig.supabaseInitError != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  AppConfig.supabaseInitError!,
                                  style: Theme.of(ctx).textTheme.bodySmall
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                        color: scheme.outline,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final user = AppConfig.supabaseReady
        ? Supabase.instance.client.auth.currentUser
        : null;

    return _chrome(
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PlantasticAppBar(
          showBack: true,
          replacementToolbarHeight: 56,
          replacementTitle: Text(
            'Admin login',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(g, 20, g, 20),
              child: PlantasticLayout.constrainedBody(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user == null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.verified_user_outlined,
                                  size: 40,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.95),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Plantastic',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      letterSpacing: 1.8,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                'Admin access',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      height: 1.25,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                              const SizedBox(height: 22),
                              TextField(
                                controller: _email,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _password,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                                obscureText: true,
                                onSubmitted: (_) {
                                  if (!_busy) _signIn();
                                },
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _busy ? null : _signIn,
                                child: _busy
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: Center(
                                          child: PlantasticLoading.inline,
                                        ),
                                      )
                                    : const Text('Sign in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Signed in: ${user.email ?? user.id}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_staffLoading)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: PlantasticLoading.compact,
                          ),
                        )
                      else if (!_isAdmin)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'This account does not have admin access.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _recheck,
                                  child: const Text('Check again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        FilledButton(
                          onPressed: () async {
                            await Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const AdminHomeScreen(),
                              ),
                            );
                          },
                          child: const Text('Open dashboard'),
                        ),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign out'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
