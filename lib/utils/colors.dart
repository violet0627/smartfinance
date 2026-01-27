import 'package:flutter/material.dart';

class AppColors {
  // Theme-independent colors (same for light and dark mode)
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFF44336);

  // Theme-dependent colors - use these with context
  static Color background = const Color(0xFFF5F5F5);
  static Color surface = Colors.white;
  static Color textPrimary = const Color(0xFF212121);
  static Color textSecondary = const Color(0xFF757575);

  // Update colors based on theme
  static void updateTheme(bool isDark) {
    if (isDark) {
      background = const Color(0xFF1A202C);
      surface = const Color(0xFF2D3748);
      textPrimary = const Color(0xFFF7FAFC);
      textSecondary = const Color(0xFFCBD5E0);
    } else {
      background = const Color(0xFFF5F5F5);
      surface = Colors.white;
      textPrimary = const Color(0xFF212121);
      textSecondary = const Color(0xFF757575);
    }
  }
}
