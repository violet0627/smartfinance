import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);

  // Theme-dependent colors — initialized to light mode defaults
  static Color background = const Color(0xFFF5F5F5);
  static Color surface = Colors.white;
  static Color textPrimary = const Color(0xFF212121);
  static Color textSecondary = const Color(0xFF757575);

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
