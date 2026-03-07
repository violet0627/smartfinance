// ==============================================================================
// app_gradients.dart - Gradient Color Definitions for Modern UI
// ==============================================================================
// This file defines all the gradient color presets used throughout the app.
// Gradients create smooth color transitions that give the UI a modern,
// polished look (instead of flat single colors).
//
// What is a LinearGradient?
// - A smooth transition between two or more colors in a straight line
// - Defined by: colors (what colors), begin/end (direction of transition)
// - Example: topLeft -> bottomRight creates a diagonal gradient
//
// Gradient categories in this file:
// 1. Primary gradients (brand colors)
// 2. Income/Expense gradients (green for income, red for expense)
// 3. Status gradients (success, warning, danger)
// 4. Card gradients (for decorative card backgrounds)
// 5. Background gradients (for screen backgrounds)
// 6. Dashboard-specific gradients (for dashboard summary cards)
// 7. Loading shimmer gradient (for skeleton loading animations)
// 8. Glass effect gradient (for frosted glass/glassmorphism effects)
//
// Usage: Container(decoration: BoxDecoration(gradient: AppGradients.primaryGradient))
// ==============================================================================

import 'package:flutter/material.dart';   // For LinearGradient, Alignment, Color, Colors

class AppGradients {
  // ==============================================================================
  // Primary Gradients - Brand Colors
  // ==============================================================================
  // These are the main gradients used for key UI elements like headers and buttons.
  //
  // Alignment.topLeft -> Alignment.bottomRight creates a diagonal gradient
  // that flows from the top-left corner to the bottom-right corner.
  // ==============================================================================

  // Main brand gradient: Purple-blue to purple
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],   // Blue-purple -> Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Blue gradient: Blue shades
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],   // Light blue -> Dark blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Purple gradient: Purple shades
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],   // Purple -> Deep purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==============================================================================
  // Financial Gradients - Income and Expense
  // ==============================================================================
  // Green gradients for income (money in), red gradients for expense (money out).
  // These color associations are intuitive: green = good/profit, red = cost/loss.
  // ==============================================================================

  // Income gradient: Teal to green (money coming in)
  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],   // Teal -> Bright green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Green gradient: Standard green shades
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],   // Green -> Light green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Expense gradient: Pink-red (money going out)
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],   // Pink -> Red-orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Red gradient: Standard red shades
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFE53935)],   // Red -> Darker red
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==============================================================================
  // Status Gradients - Success, Warning, Danger
  // ==============================================================================
  // Used for status indicators, alerts, and feedback elements.
  // ==============================================================================

  // Success gradient: Blue shades (positive outcomes)
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],   // Light blue -> Medium blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warning gradient: Amber/orange shades (caution)
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],   // Light amber -> Dark amber
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Danger gradient: Red shades (errors, destructive actions)
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFF44336)],   // Light red -> Red
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==============================================================================
  // Card Gradients - Decorative Card Backgrounds
  // ==============================================================================
  // These provide variety when showing multiple cards (e.g., goals, achievements).
  // Each card gets a different gradient to make the UI more visually interesting.
  // ==============================================================================

  static const LinearGradient cardGradient1 = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],   // Blue-purple -> Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient2 = LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],   // Light pink -> Coral
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient3 = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],   // Blue -> Cyan
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient4 = LinearGradient(
    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],   // Green -> Cyan-green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==============================================================================
  // Background Gradients - Screen Backgrounds
  // ==============================================================================
  // Subtle gradients for full-screen backgrounds (light and dark versions).
  // These use topCenter -> bottomCenter for a vertical gradient.
  // ==============================================================================

  // Light mode background: Very subtle grey gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF5F7FA), Color(0xFFE8EBF0)],   // Light grey -> Slightly darker grey
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark mode background: Dark blue-grey gradient
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF1A202C), Color(0xFF2D3748)],   // Very dark -> Dark grey
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ==============================================================================
  // Dashboard Card Gradients
  // ==============================================================================
  // Specific gradients for the dashboard's summary cards:
  // - Balance card: Total balance display
  // - Income card: Total income display
  // - Expense card: Total expense display
  // - Savings card: Total savings display
  // ==============================================================================

  static const LinearGradient balanceCardGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],   // Purple-blue (matches primary)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeCardGradient = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],   // Teal -> Green (matches income)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseCardGradient = LinearGradient(
    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],   // Pink -> Red (matches expense)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient savingsCardGradient = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],   // Blue -> Cyan
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==============================================================================
  // Shimmer Gradient - Loading Skeleton Animation
  // ==============================================================================
  // Used for "shimmer" loading effects (skeleton screens).
  // Creates a light-dark-light pattern that sweeps across the loading placeholder.
  //
  // "stops" control where each color starts in the gradient:
  // - 0.1: First grey starts at 10%
  // - 0.3: White/light peak at 30%
  // - 0.4: Second grey starts at 40%
  //
  // The Alignment values create a slight diagonal sweep effect.
  // This gradient is animated to move across the widget for the shimmer effect.
  // ==============================================================================
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFEBEBF4),    // Light grey (base)
      Color(0xFFF4F4F4),    // Near-white (shimmer highlight)
      Color(0xFFEBEBF4),    // Light grey (base)
    ],
    stops: [0.1, 0.3, 0.4],                           // Color transition positions
    begin: Alignment(-1.0, -0.3),                      // Slightly off-axis start
    end: Alignment(1.0, 0.3),                          // Slightly off-axis end
  );

  // ==============================================================================
  // Glass Effect Gradient - Glassmorphism Overlay
  // ==============================================================================
  // Creates a frosted glass effect by overlaying semi-transparent white.
  // Applied ON TOP of another gradient to create depth.
  //
  // Not "const" because withOpacity() is a runtime method call.
  //
  // Example: Stack a glass gradient on top of a colored gradient to
  // create a translucent, frosted glass card effect.
  // ==============================================================================
  static LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.2),   // 20% white (more visible)
      Colors.white.withOpacity(0.1),   // 10% white (more transparent)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
