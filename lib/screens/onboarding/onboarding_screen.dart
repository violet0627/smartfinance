// ==============================================================================
// onboarding_screen.dart - First-Time User Onboarding Experience
// ==============================================================================
// This screen shows a series of introductory pages when the user first opens
// the app. It highlights the main features of SmartFinance using swipeable
// pages with icons, titles, and descriptions.
//
// Flow:
// 1. User sees 6 onboarding pages (swipeable left/right)
// 2. Each page showcases a feature (wallet, transactions, budgets, etc.)
// 3. User can skip at any time or go through all pages
// 4. On completion → saves "onboarding_completed" flag in SharedPreferences
// 5. Navigates to LoginScreen (replaces current route)
//
// The onboarding is shown only once. After completion, the app skips straight
// to login on future launches (checked via SharedPreferences in main.dart).
//
// Usage: OnboardingScreen() — shown as initial route for first-time users
// ==============================================================================

import 'package:flutter/material.dart';           // For StatefulWidget, PageView, etc.
import 'package:shared_preferences/shared_preferences.dart'; // For saving onboarding completion flag
import '../../utils/colors.dart';                   // For AppColors (primary, textPrimary, etc.)
import '../auth/login_screen.dart';                 // For LoginScreen (destination after onboarding)

// ==============================================================================
// OnboardingScreen - StatefulWidget for Onboarding Flow
// ==============================================================================
// StatefulWidget because it manages:
// - PageController for swiping between pages
// - Current page index (for indicators and button states)
// ==============================================================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // PageController manages which page is visible in the PageView
  // It also handles animated page transitions (swiping)
  final PageController _pageController = PageController();

  // Tracks the currently visible page index (0-based)
  int _currentPage = 0;

  // ==============================================================================
  // Onboarding Pages Data
  // ==============================================================================
  // List of OnboardingPage objects, each representing one screen in the flow.
  // Each page has a title, description, icon, and accent color.
  // ==============================================================================
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to SmartFinance',
      description: 'Your personal financial companion for managing income, expenses, and achieving your financial goals.',
      icon: Icons.account_balance_wallet,      // Wallet icon for the welcome page
      color: AppColors.primary,                // Primary purple/blue color
    ),
    OnboardingPage(
      title: 'Track Your Transactions',
      description: 'Easily add income and expenses. Search and filter to find any transaction. Get AI-powered financial insights from your spending data.',
      icon: Icons.receipt_long,                // Receipt icon for transactions
      color: AppColors.info,                   // Blue info color
    ),
    OnboardingPage(
      title: 'Set Budget & Goals',
      description: 'Create monthly budgets for different categories. Set financial goals and track your progress towards achieving them.',
      icon: Icons.trending_up,                 // Upward trend icon for budgets
      color: AppColors.success,                // Green success color
    ),
    OnboardingPage(
      title: 'Bill Reminders',
      description: 'Never miss a payment! Set up recurring transactions and get notified before bills are due.',
      icon: Icons.notifications_active,        // Bell icon for reminders
      color: AppColors.warning,                // Orange/yellow warning color
    ),
    OnboardingPage(
      title: 'Analytics & Reports',
      description: 'Visualize your spending patterns with charts. Export reports as CSV or PDF for your records.',
      icon: Icons.bar_chart,                   // Chart icon for analytics
      color: AppColors.expense,                // Red expense color
    ),
    OnboardingPage(
      title: 'Investment Tracking',
      description: 'Monitor your investment portfolio. Track stocks, crypto, and other assets in one place.',
      icon: Icons.show_chart,                  // Line chart icon for investments
      color: AppColors.income,                 // Green income color
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();                 // Clean up the PageController
    super.dispose();
  }

  // ==============================================================================
  // _completeOnboarding - Mark Onboarding as Done and Navigate to Login
  // ==============================================================================
  // Saves a flag in SharedPreferences so the app knows not to show onboarding
  // again on the next launch. Then navigates to the LoginScreen.
  // ==============================================================================
  Future<void> _completeOnboarding() async {
    // Get the SharedPreferences instance (local key-value storage)
    final prefs = await SharedPreferences.getInstance();
    // Save the flag — main.dart checks this to decide whether to show onboarding
    await prefs.setBool('onboarding_completed', true);

    // Safety check: if the widget was removed during the async operation, stop
    if (!mounted) return;

    // Navigate to LoginScreen, replacing the onboarding screen
    // pushReplacement means the user can't swipe/press back to return here
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ==============================================================================
  // _nextPage - Go to Next Page or Complete Onboarding
  // ==============================================================================
  // If not on the last page, animate to the next page.
  // If on the last page, complete onboarding and go to login.
  // ==============================================================================
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      // Animate to the next page with a smooth ease-in-out curve
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),   // Animation takes 300ms
        curve: Curves.easeInOut,                       // Smooth acceleration/deceleration
      );
    } else {
      // On the last page → complete onboarding
      _completeOnboarding();
    }
  }

  // ==============================================================================
  // _previousPage - Go to Previous Page
  // ==============================================================================
  // Animates back to the previous page (only if not on the first page).
  // ==============================================================================
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ==============================================================================
  // build - Render the Onboarding Screen UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea prevents content from overlapping with system UI (notch, status bar)
      body: SafeArea(
        child: Column(
          children: [
            // --- Skip Button (top-right) ---
            // Only shown if not on the last page (last page has "Get Started" instead)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,   // Align to the right
                children: [
                  // Conditionally show the Skip button
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,       // Skip → go straight to login
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,    // Grey text
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- PageView (swipeable pages) ---
            // Expanded makes the PageView fill all remaining vertical space
            Expanded(
              child: PageView.builder(
                controller: _pageController,                // Controls which page is shown
                // onPageChanged fires whenever the user swipes to a new page
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;                   // Update the current page index
                  });
                },
                itemCount: _pages.length,                   // Total number of pages (6)
                // itemBuilder creates each page widget on demand
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);         // Build the page content
                },
              ),
            ),

            // --- Page Indicator Dots ---
            // Shows which page the user is currently on
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                // List.generate creates a dot for each page
                children: List.generate(
                  _pages.length,
                  (index) => _buildPageIndicator(index == _currentPage),
                ),
              ),
            ),

            // --- Navigation Buttons (Back / Next or Get Started) ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (only shown after the first page)
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back),   // Left arrow icon
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    )
                  else
                    const SizedBox(width: 100),             // Empty spacer on first page

                  // Next / Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),  // Pill-shaped button
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,        // Shrink-wrap the row
                      children: [
                        Text(
                          // Show "Get Started" on last page, "Next" on others
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          // Show check icon on last page, arrow on others
                          _currentPage == _pages.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // _buildPage - Render a Single Onboarding Page
  // ==============================================================================
  // Creates the content for one onboarding page: a circular icon container,
  // title text, and description text, all vertically centered.
  // ==============================================================================
  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,   // Vertically center content
        children: [
          // --- Circular Icon Container ---
          // A large circle with a semi-transparent colored background
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),       // Very light version of the color
              shape: BoxShape.circle,                   // Makes the container circular
            ),
            child: Icon(
              page.icon,
              size: 80,                                 // Large icon
              color: page.color,                        // Full color for the icon
            ),
          ),

          const SizedBox(height: 50),

          // --- Title ---
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // --- Description ---
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,                              // Line height for readability
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // _buildPageIndicator - Render a Single Page Indicator Dot
  // ==============================================================================
  // Creates an animated dot that changes size and color based on whether
  // it represents the currently active page.
  //
  // AnimatedContainer automatically animates between its old and new properties
  // (width, color) when they change, providing a smooth transition effect.
  // ==============================================================================
  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),      // Animation duration
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8,
      width: isActive ? 24 : 8,                        // Active dot is wider (pill shape)
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.shade300,  // Active = colored
        borderRadius: BorderRadius.circular(4),         // Rounded corners
      ),
    );
  }
}

// ==============================================================================
// OnboardingPage - Data Class for Onboarding Page Content
// ==============================================================================
// A simple data holder class that stores the content for a single onboarding
// page. This is not a widget — it just holds the data that _buildPage() uses
// to render the page.
// ==============================================================================
class OnboardingPage {
  final String title;           // Page title text
  final String description;     // Page description text
  final IconData icon;          // Material icon to display
  final Color color;            // Accent color for the icon and background

  // Constructor with required named parameters
  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
