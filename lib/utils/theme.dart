// ==============================================================================
// theme.dart - App Theme Configuration (Light & Dark ThemeData)
// ==============================================================================
// This file defines the COMPLETE visual theme for the entire app.
// It creates TWO ThemeData objects: one for light mode, one for dark mode.
//
// ThemeData is Flutter's way of defining the visual properties of an app:
// - Colors (primary, background, text, etc.)
// - Typography (font family, sizes, weights)
// - Component styles (buttons, cards, text fields, app bars)
//
// These ThemeData objects are used in main.dart's MaterialApp:
//   MaterialApp(
//     theme: AppTheme.lightTheme,       // Light mode theme
//     darkTheme: AppTheme.darkTheme,    // Dark mode theme
//     themeMode: themeProvider.themeMode, // Current mode from ThemeProvider
//   )
//
// Google Fonts (Poppins) is used as the default font family for the entire app.
// ==============================================================================

import 'package:flutter/material.dart';          // For ThemeData, Colors, etc.
import 'package:google_fonts/google_fonts.dart'; // For Google Fonts (Poppins)

class AppTheme {
  // ==============================================================================
  // Color Constants - Light Theme
  // ==============================================================================
  // These define the color palette for light mode.
  // Hex color format: 0xFF + 6 hex digits (RRGGBB)
  // ==============================================================================
  static const Color lightPrimary = Color(0xFF6C63FF);         // Purple-blue primary color
  static const Color lightBackground = Color(0xFFF5F7FA);      // Light grey background
  static const Color lightCardBackground = Colors.white;        // White cards
  static const Color lightTextPrimary = Color(0xFF2D3748);     // Dark text
  static const Color lightTextSecondary = Color(0xFF718096);   // Grey secondary text

  // ==============================================================================
  // Color Constants - Dark Theme
  // ==============================================================================
  // Same roles as light colors but adjusted for dark backgrounds.
  // Lighter primary, darker backgrounds, lighter text.
  // ==============================================================================
  static const Color darkPrimary = Color(0xFF8B83FF);          // Lighter purple-blue for dark mode
  static const Color darkBackground = Color(0xFF1A202C);       // Very dark background
  static const Color darkCardBackground = Color(0xFF2D3748);   // Dark grey cards
  static const Color darkTextPrimary = Color(0xFFF7FAFC);      // Near-white text
  static const Color darkTextSecondary = Color(0xFFCBD5E0);    // Light grey secondary text

  // ==============================================================================
  // Semantic Colors (Same for Both Themes)
  // ==============================================================================
  // These colors convey meaning and stay the same regardless of theme.
  // ==============================================================================
  static const Color income = Color(0xFF10B981);     // Green - money coming in
  static const Color expense = Color(0xFFEF4444);    // Red - money going out
  static const Color success = Color(0xFF10B981);    // Green - positive actions
  static const Color warning = Color(0xFFF59E0B);    // Amber - caution
  static const Color danger = Color(0xFFEF4444);     // Red - errors/destructive
  static const Color info = Color(0xFF3B82F6);       // Blue - informational

  // ==============================================================================
  // LIGHT THEME - ThemeData for Light Mode
  // ==============================================================================
  // ThemeData configures every visual aspect of the app when in light mode.
  //
  // Key components configured:
  // 1. ColorScheme - The core color palette
  // 2. AppBarTheme - Top navigation bar appearance
  // 3. CardTheme - Card widget appearance
  // 4. ElevatedButtonTheme - Button appearance
  // 5. TextTheme - Typography (text sizes, weights, colors)
  // 6. InputDecorationTheme - Text field appearance
  // ==============================================================================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,                             // Use Material Design 3 (latest)
    brightness: Brightness.light,                   // Tell Flutter this is a light theme
    primaryColor: lightPrimary,                     // Main brand color
    scaffoldBackgroundColor: lightBackground,       // Default screen background
    fontFamily: GoogleFonts.poppins().fontFamily,   // Set Poppins as default font

    // --- Color Scheme ---
    // ColorScheme defines the color relationships for Material widgets
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,                        // Primary color (buttons, links, etc.)
      secondary: lightPrimary,                      // Secondary color (FABs, selections)
      surface: lightCardBackground,                 // Surface color (cards, dialogs)
      background: lightBackground,                  // Background color
      error: danger,                                // Error color (form validation, etc.)
    ),

    // --- App Bar Theme ---
    // Configures the top navigation bar appearance
    appBarTheme: AppBarTheme(
      backgroundColor: lightPrimary,                // Purple-blue background
      foregroundColor: Colors.white,                // White icons and back button
      elevation: 0,                                  // No shadow (flat design)
      centerTitle: true,                             // Center the title text
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,                // Semi-bold
        color: Colors.white,
      ),
    ),

    // --- Card Theme ---
    // Configures Card widget appearance (used for dashboard cards, list items, etc.)
    cardTheme: CardThemeData(
      color: lightCardBackground,                   // White background
      elevation: 4,                                  // Shadow depth
      shadowColor: Colors.black.withOpacity(0.1),   // Subtle shadow (10% opacity)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),    // Rounded corners (20px radius)
      ),
    ),

    // --- Elevated Button Theme ---
    // Configures ElevatedButton appearance (main action buttons)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,              // Purple-blue background
        foregroundColor: Colors.white,              // White text
        elevation: 0,                                // No shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),  // Rounded corners
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // --- Text Theme ---
    // Defines typography for different text roles
    // GoogleFonts.poppinsTextTheme() applies Poppins font to all text styles
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(                    // Page titles (32px, bold)
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          letterSpacing: -0.5,                       // Slightly tighter letter spacing
        ),
        headlineMedium: TextStyle(                   // Section titles (24px, bold)
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(                       // Card titles (20px, semi-bold)
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(                      // Sub-section titles (16px, semi-bold)
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(                        // Main body text (16px, regular)
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(                       // Secondary body text (14px, regular)
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,                 // Grey color for secondary text
        ),
      ),
    ),

    // --- Input Decoration Theme ---
    // Configures TextField and TextFormField appearance
    inputDecorationTheme: InputDecorationTheme(
      filled: true,                                  // Fill the background
      fillColor: Colors.white,                       // White fill color
      border: OutlineInputBorder(                    // Default border (unused due to none)
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,                 // No visible border
      ),
      enabledBorder: OutlineInputBorder(             // Normal state border
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(             // When user is typing
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightPrimary, width: 2),  // Purple-blue border
      ),
      errorBorder: OutlineInputBorder(               // When validation fails
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: danger, width: 1),        // Red border
      ),
    ),
  );

  // ==============================================================================
  // DARK THEME - ThemeData for Dark Mode
  // ==============================================================================
  // Same structure as lightTheme but with dark mode colors.
  // Dark backgrounds, lighter primary color, light text on dark surfaces.
  // ==============================================================================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,                     // Tell Flutter this is a dark theme
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: GoogleFonts.poppins().fontFamily,

    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkPrimary,
      surface: darkCardBackground,
      background: darkBackground,
      error: danger,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: darkCardBackground,           // Dark grey app bar (not primary color)
      foregroundColor: darkTextPrimary,              // Light text/icons
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
    ),

    cardTheme: CardThemeData(
      color: darkCardBackground,                     // Dark grey cards
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),   // More visible shadow for dark mode
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,                // Lighter purple for dark mode
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,                    // Light text on dark background
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardBackground,                // Dark fill for text fields
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: danger, width: 1),
      ),
    ),
  );
}
