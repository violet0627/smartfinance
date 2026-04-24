// ==============================================================================
// gradient_card.dart - Gradient and Glass Effect Card Widgets
// ==============================================================================
// This file provides three types of decorative card widgets:
//
// 1. GradientCard: A card with a gradient background and optional shadow.
//    Can optionally be tapped (wraps in GestureDetector if onTap provided).
//
// 2. AnimatedGradientCard: Same as GradientCard but with a press animation.
//    When the user presses down, the card scales to 95% and springs back on release.
//    Uses AnimationController + ScaleTransition for the effect.
//
// 3. GlassCard: A "glassmorphism" card with semi-transparent white background,
//    a white border, and shadow. Creates a frosted glass appearance.
//
// All three are reusable container widgets that accept a "child" widget
// to display inside them.
//
// Usage:
//   GradientCard(gradient: AppGradients.primaryGradient, child: Text('Hello'))
//   AnimatedGradientCard(gradient: myGradient, onTap: doSomething, child: myWidget)
//   GlassCard(child: Text('Glass effect'))
// ==============================================================================

import 'package:flutter/material.dart';   // For all widget classes, Colors, BoxDecoration, etc.

// ==============================================================================
// GradientCard - Static Gradient Background Card
// ==============================================================================
// A StatelessWidget that wraps content in a gradient-filled container.
// If onTap is provided, it wraps the card in a GestureDetector for tap handling.
//
// StatelessWidget because there's no animation or state to manage.
// ==============================================================================
class GradientCard extends StatelessWidget {
  final Widget child;                    // Content to display inside the card
  final Gradient gradient;               // The gradient to use as background
  final EdgeInsetsGeometry? padding;     // Inner spacing (default: 20 all sides)
  final EdgeInsetsGeometry? margin;      // Outer spacing
  final double? width;                   // Fixed width (null = auto)
  final double? height;                  // Fixed height (null = auto)
  final VoidCallback? onTap;             // Optional tap handler
  final BorderRadius? borderRadius;      // Corner roundness (default: 20px)
  final List<BoxShadow>? boxShadow;      // Custom shadows (default: subtle shadow)

  const GradientCard({
    super.key,
    required this.child,                 // Must provide content
    required this.gradient,              // Must provide gradient
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    // Build the gradient container
    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),    // Default: 20px padding
      decoration: BoxDecoration(
        gradient: gradient,                            // Gradient background
        borderRadius: borderRadius ?? BorderRadius.circular(20),  // Default: 20px corners
        boxShadow: boxShadow ??
            [
              // Default shadow: subtle, offset downward
              BoxShadow(
                color: Colors.black.withOpacity(0.1),  // 10% black = subtle
                blurRadius: 20,                        // How soft/spread the shadow is
                offset: const Offset(0, 10),           // 10px below the card
              ),
            ],
      ),
      child: child,                                    // User's content inside
    );

    // If onTap is provided, wrap the card in a GestureDetector
    // GestureDetector detects taps, swipes, and other gestures
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    // If no onTap, return the card directly (no gesture handling)
    return card;
  }
}

// ==============================================================================
// AnimatedGradientCard - Gradient Card with Press Scale Animation
// ==============================================================================
// StatefulWidget because it manages an AnimationController for the
// press/release scale animation.
//
// Animation behavior:
// - User presses down: card scales to 95% (shrinks slightly)
// - User releases: card scales back to 100% (original size)
// - If onTap is provided, the callback fires on release
//
// SingleTickerProviderStateMixin provides a Ticker (frame callback)
// required by AnimationController. "Single" means only one controller.
// ==============================================================================
class AnimatedGradientCard extends StatefulWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AnimatedGradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  // "late" means initialized in initState, not at declaration
  late AnimationController _controller;       // Drives the animation
  late Animation<double> _scaleAnimation;     // Current scale value (1.0 -> 0.95)

  @override
  void initState() {
    super.initState();

    // Create controller with 150ms duration (quick, responsive feel)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,                            // "this" is the TickerProvider
    );

    // Tween maps the controller's 0.0-1.0 to our scale range 1.0-0.95
    // CurvedAnimation adds easing for smooth start/stop
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();                    // Free animation resources
    super.dispose();
  }

  // Called when user presses down on the card
  void _handleTapDown(TapDownDetails details) {
    _controller.forward();                    // Animate from 1.0 to 0.95 (shrink)
  }

  // Called when user lifts finger
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();                    // Animate from 0.95 back to 1.0 (grow)
    if (widget.onTap != null) {
      widget.onTap!();                        // Fire the tap callback
    }
  }

  // Called when the tap gesture is cancelled (e.g., finger dragged away)
  void _handleTapCancel() {
    _controller.reverse();                    // Spring back to full size
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,              // Register press handlers
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      // ScaleTransition animates the size of its child based on the animation value
      child: ScaleTransition(
        scale: _scaleAnimation,               // Links to the 1.0 <-> 0.95 animation
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: widget.child,                // User's content
        ),
      ),
    );
  }
}

// ==============================================================================
// GlassCard - Glassmorphism Effect Card
// ==============================================================================
// Creates a "frosted glass" (glassmorphism) visual effect:
// - Semi-transparent white background (20% opacity by default)
// - White border (30% opacity) for the glass edge effect
// - Subtle shadow for depth
//
// This is a design trend where UI elements look like frosted glass panels.
//
// StatelessWidget because there's no animation or state.
// ==============================================================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? backgroundColor;             // Custom glass color (default: white 20%)
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Semi-transparent background creates the "glass" look
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        // White border simulates light reflecting off the glass edge
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    // Wrap in GestureDetector only if onTap is provided
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
