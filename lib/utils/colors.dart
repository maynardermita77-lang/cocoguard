import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Green - from PCA branding)
  static const Color primaryGreen = Color(0xFF2d7a3e);
  static const Color primaryGreenLight = Color(0xFF4caf50);
  static const Color primaryGreenDark = Color(0xFF246632);

  // Secondary Colors (Gold/Yellow - from PCA branding)
  static const Color secondaryGold = Color(0xFFc6a030);
  static const Color secondaryGoldLight = Color(0xFFd4af37);
  static const Color secondaryGoldDark = Color(0xFFb8941f);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF666666);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF333333);

  // Background Colors
  static const Color backgroundLight = Color(0xFFf0f8f0);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF8F8F8);

  // Status Colors
  static const Color success = Color(0xFF4caf50);
  static const Color error = Color(0xFFdc3545);
  static const Color warning = Color(0xFFffc107);
  static const Color info = Color(0xFF2196f3);

  // Text Colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, primaryGreenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryGold, secondaryGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow
  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
}
