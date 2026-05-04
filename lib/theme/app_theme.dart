import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette — forest shop: depth, moss highlights, soft gold accents.
abstract final class AppTheme {
  static const Color forest = Color(0xFF143D1A);
  static const Color forestBright = Color(0xFF1B5E20);
  static const Color leaf = Color(0xFF66BB6A);
  static const Color leafDim = Color(0xFF4CAF50);
  static const Color mintGlow = Color(0xFF81C784);
  static const Color goldAccent = Color(0xFFD4AF6A);
  static const Color goldMuted = Color(0xFFA67C52);

  /// Deep backdrop (not pure black — less eye strain).
  static const Color darkBg = Color(0xFF0A0F0E);
  static const Color darkBgElevated = Color(0xFF0F1714);

  static const Color cardBg = Color(0xFF141E1B);
  static const Color cardBgHover = Color(0xFF1A2622);
  static const Color surfaceBorder = Color(0xFF2A3D34);
  static const Color surfaceBorderSoft = Color(0xFF24332C);

  static const Color textPrimary = Color(0xFFE8F5E9);
  static const Color textSecondary = Color(0xFFB2C9B8);
  static const Color textMuted = Color(0xFF7A9588);

  /// Page backdrop — white / barely-tinted (light UI).
  static const LinearGradient scaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 0.85, 1.0],
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAFBFA),
      Color(0xFFF5FAF8),
      Color(0xFFF0F7F4),
    ],
  );

  static List<Shadow> leafyGlow(Color c, {double blur = 12}) => [
    Shadow(color: c.withValues(alpha: 0.35), blurRadius: blur),
  ];

  /// Plus Jakarta where supported; Flutter web uses system/UI stack (no google_fonts fetch).
  static TextStyle sans({
    required Color color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    List<FontFeature>? fontFeatures,
  }) {
    if (!kIsWeb) {
      return GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: fontFeatures,
      );
    }
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: fontFeatures,
    );
  }

  static TextStyle serifDisplay({
    required Color color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    if (!kIsWeb) {
      return GoogleFonts.dmSerifDisplay(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        shadows: shadows,
      );
    }
    return TextStyle(
      inherit: true,
      fontFamily: 'Georgia',
      fontFamilyFallback: const [
        'Palatino Linotype',
        'Book Antiqua',
        'Palatino',
        'Times New Roman',
        'serif',
      ],
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: mintGlow,
      onPrimary: Color(0xFF061208),
      secondary: goldAccent,
      onSecondary: Color(0xFF0D1110),
      surface: darkBgElevated,
      onSurface: textPrimary,
      primaryContainer: forestBright,
      onPrimaryContainer: Color(0xFFC8E6C9),
      outline: surfaceBorderSoft,
      surfaceContainerHighest: cardBg,
    );

    final textTheme =
        GoogleFonts.plusJakartaSansTextTheme(
          Typography.material2021(
            platform: TargetPlatform.android,
          ).black.apply(bodyColor: textPrimary, displayColor: textPrimary),
        ).copyWith(
          displaySmall: GoogleFonts.dmSerifDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          titleSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.35,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            height: 1.45,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            height: 1.42,
            color: textSecondary,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            color: textMuted,
            height: 1.35,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBg,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      splashColor: mintGlow.withValues(alpha: 0.18),
      highlightColor: mintGlow.withValues(alpha: 0.06),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: darkBg.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        centerTitle: false,
        shadowColor: Colors.black45,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: Border(
          bottom: BorderSide(
            color: surfaceBorder.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        titleSpacing: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shadowColor: Colors.black54,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: surfaceBorder.withValues(alpha: 0.75)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: leafDim.withValues(alpha: 0.55),
          backgroundColor: mintGlow,
          foregroundColor: forest,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: leafDim.withValues(alpha: 0.5),
          backgroundColor: forestBright,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: mintGlow,
          side: BorderSide(color: mintGlow.withValues(alpha: 0.85)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: surfaceBorder.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: surfaceBorder.withValues(alpha: 0.85)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: mintGlow, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        backgroundColor: cardBg,
        selectedColor: forestBright.withValues(alpha: 0.9),
        secondarySelectedColor: forestBright.withValues(alpha: 0.9),
        disabledColor: cardBg.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(color: textPrimary),
        brightness: Brightness.dark,
        side: BorderSide(color: surfaceBorder.withValues(alpha: 0.9)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: surfaceBorder.withValues(alpha: 0.95)),
          ),
          visualDensity: VisualDensity.standard,
          animationDuration: const Duration(milliseconds: 280),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return forestBright.withValues(alpha: 0.95);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return mintGlow.withValues(alpha: 0.98);
            }
            return textSecondary;
          }),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: mintGlow.withValues(alpha: 0.9),
        linearTrackColor: surfaceBorder.withValues(alpha: 0.45),
        circularTrackColor: surfaceBorder.withValues(alpha: 0.35),
      ),
      dividerTheme: DividerThemeData(
        color: surfaceBorderSoft.withValues(alpha: 0.55),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 24),
      listTileTheme: ListTileThemeData(
        tileColor: cardBg.withValues(alpha: 0),
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        backgroundColor: cardBgHover,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        elevation: 12,
        backgroundColor: cardBg,
        shadowColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: surfaceBorder.withValues(alpha: 0.6)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 520),
        textStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 12,
        ),
        decoration: BoxDecoration(
          color: forest.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: mintGlow.withValues(alpha: 0.25)),
        ),
      ),
    );
  }

  /// Light UI — white scaffold, dark type, green primaries.
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: forestBright,
          brightness: Brightness.light,
        ).copyWith(
          primary: forestBright,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFC8E6C9),
          onPrimaryContainer: forest,
          secondary: goldAccent,
          onSecondary: const Color(0xFF1F1A12),
          surface: Colors.white,
          onSurface: const Color(0xFF122419),
          surfaceContainerHighest: const Color(0xFFE7F3ED),
          onSurfaceVariant: const Color(0xFF4A6257),
          outline: const Color(0xFFB8D0C4),
          outlineVariant: const Color(0xFFD6E8DF),
        );

    const onInk = Color(0xFF122419);
    final textTheme = kIsWeb
        ? Typography.material2021(platform: TargetPlatform.android).black
              .apply(bodyColor: onInk, displayColor: onInk)
              .copyWith(
                displaySmall: serifDisplay(
                  color: onInk,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
                titleLarge: sans(
                  color: onInk,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                titleMedium: sans(
                  color: onInk,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
                titleSmall: sans(color: onInk, fontWeight: FontWeight.w600),
                headlineSmall: sans(
                  color: onInk,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.35,
                ),
                bodyLarge: sans(
                  color: const Color(0xFF2F4A3E),
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
                bodyMedium: sans(color: const Color(0xFF2F4A3E), height: 1.42),
                bodySmall: sans(color: const Color(0xFF5B7568), height: 1.35),
                labelLarge: sans(
                  color: onInk,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                labelMedium: sans(
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  color: onInk,
                ),
              )
        : GoogleFonts.plusJakartaSansTextTheme(
            Typography.material2021(
              platform: TargetPlatform.android,
            ).black.apply(bodyColor: onInk, displayColor: onInk),
          ).copyWith(
            displaySmall: GoogleFonts.dmSerifDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: onInk,
              letterSpacing: -0.5,
            ),
            titleLarge: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: onInk,
            ),
            titleMedium: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: onInk,
            ),
            titleSmall: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: onInk,
            ),
            headlineSmall: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.35,
              color: onInk,
            ),
            bodyLarge: GoogleFonts.plusJakartaSans(
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2F4A3E),
            ),
            bodyMedium: GoogleFonts.plusJakartaSans(
              height: 1.42,
              color: const Color(0xFF2F4A3E),
            ),
            bodySmall: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF5B7568),
              height: 1.35,
            ),
            labelLarge: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: onInk,
            ),
            labelMedium: GoogleFonts.plusJakartaSans(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      splashColor: mintGlow.withValues(alpha: 0.22),
      highlightColor: mintGlow.withValues(alpha: 0.09),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        foregroundColor: onInk,
        centerTitle: false,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        systemOverlayStyle: kIsWeb ? null : SystemUiOverlayStyle.dark,
        shape: Border(
          bottom: BorderSide(
            color: scheme.outline.withValues(alpha: 0.38),
            width: 1,
          ),
        ),
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D4A3C), size: 24),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: leafDim.withValues(alpha: 0.35),
          backgroundColor: mintGlow,
          foregroundColor: forest,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: leafDim.withValues(alpha: 0.4),
          backgroundColor: forestBright,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestBright,
          side: BorderSide(color: mintGlow.withValues(alpha: 0.9)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.75)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: forestBright, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: forestBright.withValues(alpha: 0.9),
        secondarySelectedColor: forestBright.withValues(alpha: 0.9),
        disabledColor: Colors.grey.shade200,
        labelStyle: sans(
          color: onInk,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: sans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        brightness: Brightness.light,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: scheme.outline.withValues(alpha: 0.75)),
          ),
          visualDensity: VisualDensity.standard,
          animationDuration: const Duration(milliseconds: 280),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return forestBright.withValues(alpha: 0.94);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF3D5A4D);
          }),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: forestBright,
        linearTrackColor: scheme.outline.withValues(alpha: 0.35),
        circularTrackColor: scheme.outline.withValues(alpha: 0.28),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.45),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF486A5A), size: 24),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: const Color(0xFF486A5A),
        textColor: onInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        backgroundColor: const Color(0xFF203C2E),
        contentTextStyle: sans(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        elevation: 12,
        backgroundColor: Colors.white,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 520),
        textStyle: sans(color: Colors.white, fontSize: 12),
        decoration: BoxDecoration(
          color: forest.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: mintGlow.withValues(alpha: 0.25)),
        ),
      ),
    );
  }

  /// Shared [Hero] tag for product square cover (shop grid → detail).
  static String heroProductCover(String productId) =>
      'plantastic_product_cover_$productId';
}
