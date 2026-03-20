// ==============================================================================
// main.dart - Application Entry Point (The Starting Point of SmartFinance)
// ==============================================================================
// This is the FIRST file that runs when the SmartFinance app launches.
// It sets up the app's theme system and determines which screen to show first.
//
// App Launch Flow:
// 1. main() runs -> creates ThemeProvider -> creates MyApp
// 2. MyApp creates MaterialApp with theme settings
// 3. SplashScreen shows (loading screen with logo)
// 4. SplashScreen checks: Has user completed onboarding?
//    - NO  -> Show OnboardingScreen (first-time tutorial)
//    - YES -> Is user logged in?
//      - YES -> Show DashboardScreen (main app)
//      - NO  -> Show LoginScreen
// ==============================================================================

import 'package:flutter/material.dart';                    // Flutter's Material Design widgets (buttons, text, layouts, etc.)
import 'package:shared_preferences/shared_preferences.dart'; // Local storage (saves settings on the device)
import 'screens/auth/login_screen.dart';                    // Login screen widget
import 'screens/dashboard/dashboard_screen.dart';           // Dashboard (main app) screen widget
import 'screens/onboarding/onboarding_screen.dart';         // First-time tutorial screen widget
import 'services/api_service.dart';                         // API service (communicates with backend server)
import 'utils/colors.dart';                                 // App color definitions
import 'utils/theme.dart';                                  // App theme definitions (light/dark)

// ==============================================================================
// main() - The entry point of the entire Flutter application
// ==============================================================================
// This is like the "main" function in Python - it's the first thing that runs.
// SmartFinance is a Malaysia-only app, so the theme is always Light mode.
// ==============================================================================
void main() {
  runApp(const MyApp()); // Create and run the root widget
}

// ==============================================================================
// MyApp - The Root Widget of the Application
// ==============================================================================
// StatelessWidget means this widget doesn't have its own state that changes.
// It builds the MaterialApp which is the foundation of any Material Design app.
// ==============================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});   // Constructor with optional key parameter

  @override
  Widget build(BuildContext context) {
    // --- MaterialApp is the root widget for Material Design apps ---
    // SmartFinance always uses Light mode — dark mode is not supported.
    return MaterialApp(
      title: 'SmartFinance',                      // App title (shown in task manager/recent apps)
      debugShowCheckedModeBanner: false,           // Hide the red "DEBUG" banner in top-right corner
      theme: AppTheme.lightTheme,                  // Light theme definition (from utils/theme.dart)
      themeMode: ThemeMode.light,                  // Always use light mode — no theme switching
      home: const SplashScreen(),                  // The first screen to show (splash/loading screen)
    );
  }
}

// ==============================================================================
// SplashScreen - The Loading Screen (Shown While App Decides Where to Go)
// ==============================================================================
// This is the first thing the user sees - a green screen with the app logo
// and a loading spinner. While showing, it checks in the background:
// 1. Has the user seen the onboarding tutorial?
// 2. Is the user already logged in?
// Then it navigates to the appropriate screen.
//
// StatefulWidget is used because this screen has state that changes (it performs
// async operations and navigates away).
// ==============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// ==============================================================================
// _SplashScreenState - The State (Logic) for SplashScreen
// ==============================================================================
// In Flutter, UI (Widget) and logic (State) are separated.
// The Widget defines WHAT to show, the State defines HOW it behaves.
// ==============================================================================
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();       // Always call super.initState() first
    _checkLoginStatus();     // Start checking login status as soon as the screen loads
  }

  // ==============================================================================
  // _checkLoginStatus - Determines Which Screen to Navigate To
  // ==============================================================================
  // This is an async function (runs in the background without freezing the UI).
  // "Future<void>" means it returns nothing but runs asynchronously.
  // "await" pauses execution until the async operation completes.
  // ==============================================================================
  Future<void> _checkLoginStatus() async {
    // Wait 1 second (so the user can see the splash screen briefly)
    await Future.delayed(const Duration(seconds: 1));

    // --- Check if onboarding tutorial has been completed ---
    // SharedPreferences stores simple data on the device (like a mini database).
    // 'onboarding_completed' is a boolean flag saved when the user finishes onboarding.
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    // ?? false means: if the value is null (never set), use false as default

    // Safety check: if the widget was disposed (user left the screen), don't navigate
    if (!mounted) return;

    // If onboarding hasn't been completed, show the onboarding screen
    if (!onboardingCompleted) {
      Navigator.of(context).pushReplacement(
        // pushReplacement replaces the current screen (can't go back to splash)
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;  // Stop here, don't check login status
    }

    // --- Check if the user is already logged in ---
    // ApiService.isLoggedIn() checks if there's a valid access token stored
    final isLoggedIn = await ApiService.isLoggedIn();

    if (!mounted) return;  // Safety check again (async gap)

    // Navigate to Dashboard if logged in, or Login screen if not
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Build the splash screen UI ---
    return Scaffold(
      backgroundColor: AppColors.primary,   // Green background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  // Center everything vertically
          children: [
            // App icon (wallet icon)
            Icon(
              Icons.account_balance_wallet,   // Material Design wallet icon
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),   // Spacer (24 pixels of empty space)

            // App title
            const Text(
              'SmartFinance',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Your Financial Journey Starts Here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,   // 70% opacity white (slightly transparent)
              ),
            ),
            const SizedBox(height: 48),

            // Loading spinner (circular progress indicator)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),  // White spinner
            ),
          ],
        ),
      ),
    );
  }
}
