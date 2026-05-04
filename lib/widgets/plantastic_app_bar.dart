import 'package:flutter/material.dart';

import '../layout/plantastic_layout.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'glass_card.dart';

class PlantasticAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlantasticAppBar({
    super.key,
    this.actions,
    this.showBack = false,
    this.brandSubtitle,
    this.replacementTitle,
    this.replacementToolbarHeight,
    /// Shop home: blur panel behind toolbar over gradient (icons/title stay white).
    this.glassChrome = false,
  });

  final List<Widget>? actions;
  final bool showBack;
  final bool glassChrome;

  /// Shown directly under the logo + PLANTASTIC row when non-null (e.g. "Admin").
  final String? brandSubtitle;

  /// When set, replaces the logo + PLANTASTIC block. Do not use with [brandSubtitle].
  final Widget? replacementTitle;

  /// Toolbar height when using [replacementTitle]. Defaults to 76.
  final double? replacementToolbarHeight;

  static const double _logoMaxHeight = 56;
  static const double _brandRowHeight = _logoMaxHeight + 16;
  static const double _subtitleBlockHeight = 26;

  @override
  Size get preferredSize {
    if (replacementTitle != null) {
      return Size.fromHeight(replacementToolbarHeight ?? 76);
    }
    return Size.fromHeight(
      brandSubtitle != null
          ? _brandRowHeight + _subtitleBlockHeight
          : _brandRowHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = MaterialLocalizations.of(context);
    final onGlass = glassChrome;

    final chromeFg =
        onGlass ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.94);

    return AppBar(
      toolbarHeight: preferredSize.height,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      foregroundColor: onGlass ? Colors.white : theme.colorScheme.onSurface,
      iconTheme: IconThemeData(
        color: onGlass ? Colors.white : theme.colorScheme.onSurface,
        size: 24,
      ),
      titleSpacing: showBack ? 4 : 10,
      leadingWidth: showBack ? 48 : null,
      shape: Border(
        bottom: BorderSide(
          color: onGlass
              ? Colors.white.withValues(alpha: 0.28)
              : AppColors.border.withValues(alpha: 0.75),
        ),
      ),
      flexibleSpace: onGlass
          ? LayoutBuilder(
              builder: (context, constraints) {
                return GlassCard(
                  borderRadius: 0,
                  padding: EdgeInsets.zero,
                  sigma: 14,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                );
              },
            )
          : null,
      leading: showBack
          ? IconButton(
              tooltip: lang.backButtonTooltip,
              style:
                  IconButton.styleFrom(
                    foregroundColor: chromeFg,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.white.withValues(alpha: onGlass ? 0.22 : 0.08);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white.withValues(alpha: onGlass ? 0.12 : 0.05);
                      }
                      return null;
                    }),
                  ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: replacementTitle != null
          ? Align(
              alignment: Alignment.centerLeft,
              child: Semantics(header: true, child: replacementTitle),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final tw = constraints.maxWidth;
                final compactNav = PlantasticLayout.compactPhone(context);
                final logoDisplayH = compactNav ? 46.0 : _logoMaxHeight.toDouble();
                final brandGap = compactNav ? 8.0 : 12.0;
                final maxLogoW = (!tw.isFinite || tw <= 0)
                    ? 140.0
                    : (tw * (compactNav ? 0.4 : 0.44)).clamp(72.0, 190.0);

                Widget brandRow = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxLogoW),
                        child: Image.asset(
                          'assets/Logo.png',
                          height: logoDisplayH,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                          isAntiAlias: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.eco_rounded,
                              size: logoDisplayH * 0.76,
                              color: onGlass ? Colors.white : theme.colorScheme.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: brandGap),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Plantastic 🌿',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.heading.copyWith(
                            fontSize: compactNav ? 18 : 20,
                            color: onGlass ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (brandSubtitle == null) {
                  return Semantics(
                    header: true,
                    label: 'Plantastic',
                    child: brandRow,
                  );
                }

                return Semantics(
                  header: true,
                  label: 'Plantastic $brandSubtitle',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(child: brandRow),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          brandSubtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.06,
                            color: onGlass
                                ? Colors.white.withValues(alpha: 0.92)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      actions: actions,
    );
  }
}
