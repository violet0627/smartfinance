// ==============================================================================
// colors.dart - App Color Constants (Light & Dark Mode Colors)
// ==============================================================================
// This file defines all the colors used throughout the app.
// It has TWO types of colors:
//
// 1. Theme-INDEPENDENT colors (static const) - Same in light and dark mode
//    Examples: primary blue, success green, danger red
//    These never change once the app starts.
//
// 2. Theme-DEPENDENT colors (static, non-const) - Change with light/dark mode
//    Examples: background, surface, text colors
//    These are updated by updateTheme() when the user switches themes.
//
// Color values use hexadecimal format: Color(0xFF2196F3)
// - 0x = hex prefix
// - FF = alpha channel (FF = fully opaque, 00 = fully transparent)
// - 2196F3 = the actual color in RGB (21=red, 96=green, F3=blue)
//
// The updateTheme() method is called by ThemeProvider whenever the theme changes.
// ==============================================================================

import 'package:flutter/material.dart';   // For Color and Colors classes

class AppColors {
  // ==============================================================================
  // Theme-Independent Colors (Same for Light and Dark Mode)
  // ==============================================================================
  // These are "const" because they NEVER change after compilation.
  // Used for semantic colors that stay the same regardless of theme.
  // ==============================================================================
  static const Color primary = Color(0xFF2196F3);    // Main brand color (Material Blue)
  static const Color secondary = Color(0xFF9C27B0);  // Secondary accent (Purple)
  static const Color success = Color(0xFF4CAF50);    // Success/positive actions (Green)
  static const Color danger = Color(0xFFF44336);     // Error/destructive actions (Red)
  static const Color warning = Color(0xFFFF9800);    // Warnings/caution (Orange)
  static const Color info = Color(0xFF2196F3);       // Informational (Blue)
  static const Color income = Color(0xFF4CAF50);     // Income transactions (Green = money in)
  static const Color expense = Color(0xFFF44336);    // Expense transactions (Red = money out)

  // ==============================================================================
  // Theme-Dependent Colors (Change Between Light and Dark Mode)
  // ==============================================================================
  // These are NOT "const" because they change at runtime when the theme switches.
  // They start with light mode defaults and are updated by updateTheme().
  // ==============================================================================
  static Color background = const Color(0xFFF5F5F5);    // Screen background color
  static Color surface = Colors.white;                    // Card/surface background color
  static Color textPrimary = const Color(0xFF212121);    // Main text color (dark grey)
  static Color textSecondary = const Color(0xFF757575);  // Secondary/subtitle text color (medium grey)

  // ==============================================================================
  // updateTheme - Switch Colors Between Light and Dark Mode
  // ==============================================================================
  // Called by ThemeProvider whenever the user changes the theme.
  // Updates all theme-dependent colors to match the new mode.
  //
  // Light mode: Light backgrounds, dark text
  // Dark mode: Dark backgrounds, light text
  //
  // Args:
  //   isDark (bool): true for dark mode, false for light mode
  // ==============================================================================
  static void updateTheme(bool isDark) {
    if (isDark) {
      // --- Dark Mode Colors ---
      background = const Color(0xFF1A202C);    // Very dark blue-grey background
      surface = const Color(0xFF2D3748);       // Slightly lighter card background
      textPrimary = const Color(0xFFF7FAFC);   // Near-white text
      textSecondary = const Color(0xFFCBD5E0); // Light grey secondary text
    } else {
      // --- Light Mode Colors ---
      background = const Color(0xFFF5F5F5);    // Light grey background
      surface = Colors.white;                   // Pure white card background
      textPrimary = const Color(0xFF212121);   // Near-black text
      textSecondary = const Color(0xFF757575); // Medium grey secondary text
    }
  }
}
