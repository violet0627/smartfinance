// ==============================================================================
// theme_provider.dart - Theme State Manager (Light/Dark Mode Controller)
// ==============================================================================
// This file manages the app's theme (light mode vs dark mode).
// It uses the "Provider" pattern - a way to share state across the entire app.
//
// How Provider works:
// 1. ThemeProvider holds the current theme mode (light/dark/system)
// 2. When the theme changes, it calls notifyListeners()
// 3. All widgets that "listen" to ThemeProvider automatically rebuild
// 4. This means changing the theme instantly updates the ENTIRE app's appearance
//
// The theme preference is saved to SharedPreferences (device storage) so
// it persists between app restarts.
// ==============================================================================

import 'package:flutter/material.dart';                     // For ThemeMode enum
import 'package:shared_preferences/shared_preferences.dart'; // For saving theme preference locally
import '../utils/colors.dart';                               // For updating AppColors based on theme

// ==============================================================================
// ThemeProvider class
// ==============================================================================
// "with ChangeNotifier" is a Dart mixin that adds the ability to notify listeners.
// When we call notifyListeners(), any widget using Provider.of<ThemeProvider>
// or Consumer<ThemeProvider> will automatically rebuild.
// ==============================================================================
class ThemeProvider with ChangeNotifier {
  // --- Private state ---
  ThemeMode _themeMode = ThemeMode.light;   // Default theme is light mode
  // The underscore (_) makes this private - only accessible within this class

  // Key used to store the theme preference in SharedPreferences
  static const String _themePrefKey = 'theme_mode';

  // --- Getters (public access to private state) ---
  // These allow other widgets to READ the theme but not directly WRITE it.
  ThemeMode get themeMode => _themeMode;                    // Get current theme mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;      // Quick check: is it dark mode?

  // ==============================================================================
  // Constructor - Runs when ThemeProvider is created
  // ==============================================================================
  // Called once when the app starts (in main.dart's ChangeNotifierProvider).
  // Immediately loads the saved theme preference from device storage.
  // ==============================================================================
  ThemeProvider() {
    _loadThemeMode();   // Load saved theme preference on creation
  }

  // ==============================================================================
  // _loadThemeMode - Load Saved Theme from Device Storage
  // ==============================================================================
  // Reads the theme preference that was previously saved to SharedPreferences.
  // If no preference was saved (first app launch), defaults to system theme.
  // ==============================================================================
  Future<void> _loadThemeMode() async {
    // Get SharedPreferences instance (local key-value storage)
    final prefs = await SharedPreferences.getInstance();

    // Read the saved theme string ("light", "dark", or "system")
    final savedTheme = prefs.getString(_themePrefKey);

    // Set the theme based on saved value
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;   // Follow the device's system setting
    }

    // Update the AppColors class to use the correct colors for this theme
    // (some colors change between light and dark mode)
    AppColors.updateTheme(_themeMode == ThemeMode.dark);

    // Notify all listening widgets to rebuild with the new theme
    notifyListeners();
  }

  // ==============================================================================
  // setThemeMode - Change the Theme and Save the Preference
  // ==============================================================================
  // Called when the user changes the theme in the Settings screen.
  // Updates the theme immediately AND saves it for future app launches.
  //
  // Args:
  //     mode (ThemeMode): The new theme mode (ThemeMode.light, .dark, or .system)
  // ==============================================================================
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;    // Update the current theme

    // Update AppColors to match the new theme
    AppColors.updateTheme(mode == ThemeMode.dark);

    // Notify all listening widgets to rebuild (this triggers the visual change)
    notifyListeners();

    // Save the preference to device storage (persists between app restarts)
    final prefs = await SharedPreferences.getInstance();

    // Convert ThemeMode enum to a string for storage
    String modeString;
    switch (mode) {
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }

    await prefs.setString(_themePrefKey, modeString);   // Save to device storage
  }

  // ==============================================================================
  // toggleTheme - Quick Toggle Between Light and Dark Mode
  // ==============================================================================
  // A convenience method that switches between light and dark mode.
  // If currently light -> switch to dark.
  // If currently dark (or system) -> switch to light.
  // ==============================================================================
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);    // Light -> Dark
    } else {
      await setThemeMode(ThemeMode.light);   // Dark -> Light
    }
  }
}
