// ==============================================================================
// dashboard_summary_card.dart - Dashboard Summary and Quick Action Cards
// ==============================================================================
// This file provides three dashboard card widgets:
//
// 1. DashboardSummaryCard: A gradient card showing a financial summary
//    (e.g., Total Balance, Income, Expenses). Displays an icon, title,
//    amount, and optional subtitle.
//
// 2. AnimatedDashboardCard: Same as DashboardSummaryCard but with an
//    entrance animation - it scales up from 80% to 100% and fades in
//    when first built. Uses elasticOut curve for a bouncy spring effect.
//
// 3. QuickActionCard: A tappable card for dashboard shortcuts
//    (e.g., "Add Expense", "View Goals"). Shows an icon and label
//    in a lightly tinted container.
//
// Usage:
//   DashboardSummaryCard(
//     title: 'Total Balance',
//     amount: 'RM 5,000.00',
//     icon: Icons.account_balance_wallet,
//     gradient: AppGradients.balanceCardGradient,
//   )
// ==============================================================================

import 'package:flutter/material.dart';          // For widgets, Colors, BoxDecoration, etc.
import 'package:google_fonts/google_fonts.dart'; // For Poppins font styling

// ==============================================================================
// DashboardSummaryCard - Static Gradient Summary Card
// ==============================================================================
// StatelessWidget because there's no animation or state.
// Displays financial data in a visually appealing gradient card.
//
// The card has a consistent layout:
// Top row: [Icon container] .............. [Forward arrow if tappable]
// Middle: Title text
// Bottom: Amount text (large, bold)
// Optional: Subtitle text
// ==============================================================================
class DashboardSummaryCard extends StatelessWidget {
  final String title;            // Card title (e.g., "Total Balance")
  final String amount;           // Amount to display (e.g., "RM 5,000.00")
  final String? subtitle;        // Optional subtitle (e.g., "This month")
  final IconData icon;           // Icon to show in the top-left
  final Gradient gradient;       // Gradient background
  final VoidCallback? onTap;     // Optional tap handler (navigation)

  const DashboardSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // GestureDetector wraps the card for tap handling
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,                          // Gradient background
          borderRadius: BorderRadius.circular(20),     // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),              // Shadow below card
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Left-align all children
          children: [
            // --- Top Row: Icon + Optional Arrow ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon in a semi-transparent white container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),  // 20% white = subtle glass
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,                   // White icon on gradient
                    size: 24,
                  ),
                ),
                // Show forward arrow only if card is tappable
                // "if (condition)" inside a list conditionally includes the widget
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),  // Semi-transparent arrow
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Title ---
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,            // Medium weight
                color: Colors.white.withOpacity(0.9),   // Slightly transparent white
              ),
            ),
            const SizedBox(height: 4),

            // --- Amount (large, bold) ---
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,                    // Solid white for emphasis
                letterSpacing: -0.5,                    // Tighter spacing for large text
              ),
            ),

            // --- Optional Subtitle ---
            // "if (condition) ...[widgets]" conditionally inserts widgets
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,                              // ! asserts subtitle is not null
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,           // Regular weight
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// AnimatedDashboardCard - Summary Card with Entrance Animation
// ==============================================================================
// StatefulWidget that wraps DashboardSummaryCard with a scale+fade animation.
// When the card first appears, it:
// 1. Starts at 80% size and 0% opacity (invisible)
// 2. Scales up to 100% with an elastic bounce (Curves.elasticOut)
// 3. Fades in from 0% to 100% opacity (Curves.easeIn)
//
// The animation plays once automatically on widget creation (forward() in initState).
//
// SingleTickerProviderStateMixin provides the Ticker for AnimationController.
// ==============================================================================
class AnimatedDashboardCard extends StatefulWidget {
  final String title;
  final String amount;
  final String? subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  const AnimatedDashboardCard({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  State<AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<AnimatedDashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;     // Scale: 0.8 → 1.0
  late Animation<double> _opacityAnimation;   // Opacity: 0.0 → 1.0

  @override
  void initState() {
    super.initState();

    // 600ms duration for a noticeable but not slow entrance
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Scale animation: 80% → 100% with elastic bounce
    // Curves.elasticOut creates a spring/bounce overshoot effect
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,             // Bouncy spring curve
      ),
    );

    // Opacity animation: invisible → fully visible
    // Curves.easeIn starts slow and accelerates
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // Start the animation immediately when the widget is created
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ScaleTransition handles the size animation
    return ScaleTransition(
      scale: _scaleAnimation,
      // FadeTransition handles the opacity animation
      // Both transitions wrap the same child and animate simultaneously
      child: FadeTransition(
        opacity: _opacityAnimation,
        // Reuse the static DashboardSummaryCard for the actual content
        child: DashboardSummaryCard(
          title: widget.title,
          amount: widget.amount,
          subtitle: widget.subtitle,
          icon: widget.icon,
          gradient: widget.gradient,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

// ==============================================================================
// QuickActionCard - Dashboard Shortcut Card
// ==============================================================================
// A simple tappable card for quick actions on the dashboard.
// Shows a colored icon in a circle and a label below it.
//
// Used in a grid layout for actions like "Add Transaction", "Set Budget", etc.
//
// StatelessWidget because there's no animation or state.
// ==============================================================================
class QuickActionCard extends StatelessWidget {
  final String title;            // Action label (e.g., "Add Expense")
  final IconData icon;           // Action icon
  final Color color;             // Theme color for icon and tints
  final VoidCallback onTap;      // Callback when tapped

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),                // Light tinted background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),              // Subtle colored border
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  // Center content vertically
          children: [
            // Icon in a tinted circle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),          // Slightly darker tint than background
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,                          // Solid color icon
                size: 28,
              ),
            ),
            const SizedBox(height: 8),

            // Action label
            Text(
              title,
              textAlign: TextAlign.center,             // Center multiline text
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,            // Semi-bold
                color: color,                          // Matching color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
