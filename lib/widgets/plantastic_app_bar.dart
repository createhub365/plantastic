import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PlantasticAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlantasticAppBar({
    super.key,
    this.actions,
    this.showBack = false,
    this.brandSubtitle,
    this.replacementTitle,
    this.replacementToolbarHeight,
  });

  final List<Widget>? actions;
  final bool showBack;

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
    final brandGreen = AppTheme.forest;
    final brandBright = AppTheme.forestBright;

    return AppBar(
      toolbarHeight: preferredSize.height,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      foregroundColor: theme.colorScheme.onSurface,
      titleSpacing: showBack ? 4 : 10,
      leadingWidth: showBack ? 48 : null,
      shape: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      leading: showBack
          ? IconButton(
              tooltip: lang.backButtonTooltip,
              style:
                  IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.94,
                    ),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return AppTheme.mintGlow.withValues(alpha: 0.12);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return AppTheme.mintGlow.withValues(alpha: 0.06);
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
                final w = constraints.maxWidth;
                final maxLogoW = (!w.isFinite || w <= 0)
                    ? 140.0
                    : (w * 0.44).clamp(88.0, 190.0);

                Widget brandRow = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxLogoW),
                        child: Image.asset(
                          'assets/Logo.png',
                          height: _logoMaxHeight,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                          isAntiAlias: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.eco_rounded,
                              size: _logoMaxHeight * 0.76,
                              color: theme.colorScheme.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [brandGreen, brandBright],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            );
                          },
                          child: Text(
                            'PLANTASTIC',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.serifDisplay(
                              fontSize: 26.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.38,
                              height: 1.05,
                              color: Colors.white,
                            ),
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
                            color: AppTheme.forestBright,
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
