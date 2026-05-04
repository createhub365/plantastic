import 'package:flutter/material.dart';

import '../../layout/plantastic_layout.dart';
import '../../theme/admin_shell.dart';
import '../../theme/app_theme.dart';
import '../plantastic_loading.dart';

class AdminBusyView extends StatelessWidget {
  const AdminBusyView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: AnimatedOpacity(
        duration: AdminShell.motionMedium,
        curve: AdminShell.motionCurve,
        opacity: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.995),
                    AppTheme.mintGlow.withValues(alpha: 0.07),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(AdminShell.cardRadius),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.42),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forest.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.055),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 38),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 44,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: PlantasticLoading.inline,
                      ),
                    ),
                    if (message != null && message!.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.94),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
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

class AdminErrorView extends StatelessWidget {
  const AdminErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: AdminShell.cardDecoration(scheme),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 42,
                        color: scheme.error.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Something went wrong',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.22,
                      color: scheme.onSurface.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.52,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.93),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminEmptyView extends StatelessWidget {
  const AdminEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: AnimatedOpacity(
          duration: AdminShell.motionMedium,
          curve: AdminShell.motionCurve,
          opacity: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.mintGlow.withValues(alpha: 0.28),
                      AppTheme.mintGlow.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forest.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Icon(
                    icon,
                    size: 44,
                    color: AppTheme.forestBright.withValues(alpha: 0.92),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                  color: scheme.onSurface.withValues(alpha: 0.95),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.52,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 22), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal inset + surfaced card — used for catalogue rows.
class AdminInsetCard extends StatelessWidget {
  const AdminInsetCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hPad = PlantasticLayout.gutter(context).clamp(10.0, 22.0);
    final radius = BorderRadius.circular(AdminShell.cardRadiusSm);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: 6,
      ),
      child: Material(
        elevation: 0.9,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppTheme.forest.withValues(alpha: 0.1),
        color: Colors.white.withValues(alpha: 0.985),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.42)),
        ),
        child: child,
      ),
    );
  }
}
