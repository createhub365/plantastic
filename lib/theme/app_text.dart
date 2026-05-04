import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Poppins-based marketing / emphasis styles (pair with [ThemeData.textTheme]).
abstract final class AppText {
  static TextStyle get heading => _poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get subHeading => _poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => _poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get price => _poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      );

  /// Soft pill label for highlights / tags (light green fill).
  static TextStyle get tagLabel => _poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  static TextStyle _poppins({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    if (kIsWeb) {
      return TextStyle(
        fontFamily: 'Poppins',
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color,
        height: height,
      );
    }
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
    );
  }
}
