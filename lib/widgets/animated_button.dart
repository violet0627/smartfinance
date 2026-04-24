// ==============================================================================
// animated_button.dart - Animated Button Widgets with Scale Effects
// ==============================================================================
// This file provides three types of animated button widgets:
//
// 1. AnimatedButton: A filled button with gradient/color background.
//    Scales down to 95% when pressed and springs back on release.
//    Supports loading state (shows spinner instead of text).
//
// 2. AnimatedOutlineButton: An outlined (bordered) button with transparent
//    background. Same scale animation as AnimatedButton.
//
// 3. AnimatedIconButton: A circular icon-only button that scales to 90%
//    on tap. Uses a simpler animation pattern (forward then auto-reverse).
//
// All three use Flutter's animation system:
// - AnimationController: Drives the animation over time
// - SingleTickerProviderStateMixin: Provides frame-by-frame updates (Ticker)
// - ScaleTransition: Applies the animated scale value to the widget
// - CurvedAnimation: Adds easing (smooth acceleration/deceleration)
//
// Usage:
//   AnimatedButton(text: 'Login', onPressed: () => handleLogin())
//   AnimatedOutlineButton(text: 'Cancel', borderColor: Colors.red, ...)
//   AnimatedIconButton(icon: Icons.add, onPressed: () => addItem())
// ==============================================================================

import 'package:flutter/material.dart';          // For StatefulWidget, AnimationController, etc.
import 'package:google_fonts/google_fonts.dart'; // For Poppins font styling

// ==============================================================================
// AnimatedButton - Filled Button with Scale Animation
// ==============================================================================
// StatefulWidget because it manages an AnimationController for the
// press/release scale animation.
// ==============================================================================
class AnimatedButton extends StatefulWidget {
  final String text;                // Button label text
  final VoidCallback onPressed;     // Callback when button is tapped
  final Color? backgroundColor;     // Background color (if no gradient)
  final Color? textColor;           // Text/icon color (default: white)
  final IconData? icon;             // Optional icon shown before text
  final bool isLoading;             // When true, shows spinner instead of text
  final Gradient? gradient;         // Optional gradient background (overrides backgroundColor)
  final double? width;              // Width (default: full width)
  final double? height;             // Height (default: 56px)
  final EdgeInsetsGeometry? padding; // Custom padding

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isLoading = false,         // Default: not loading
    this.gradient,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

// ==============================================================================
// _AnimatedButtonState - State for AnimatedButton
// ==============================================================================
// SingleTickerProviderStateMixin provides a Ticker needed by AnimationController.
// "Single" because we only need one AnimationController.
// ==============================================================================
class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;       // Controls animation timing
  late Animation<double> _scaleAnimation;     // Provides current scale value

  @override
  void initState() {
    super.initState();

    // Create controller: 100ms for snappy button feedback
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,                            // Frame sync from mixin
    );

    // Tween: maps controller 0.0->1.0 to scale 1.0->0.95
    // CurvedAnimation adds smooth easing
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();                    // Clean up animation resources
    super.dispose();
  }

  // Finger pressed down → shrink button
  void _handleTapDown(TapDownDetails details) {
    _controller.forward();                    // Animate 1.0 → 0.95
  }

  // Finger lifted → grow back and fire callback
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();                    // Animate 0.95 → 1.0
    // Only fire callback if not in loading state
    if (!widget.isLoading) {
      widget.onPressed();
    }
  }

  // Tap cancelled (finger dragged away) → grow back, no callback
  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector captures press/release/cancel events
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      // ScaleTransition applies the animated scale to its child
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          // double.infinity = take all available width
          width: widget.width ?? double.infinity,
          height: widget.height ?? 56,                // Default height: 56px
          padding: widget.padding,
          decoration: BoxDecoration(
            // If gradient is null, use backgroundColor (or theme primary as fallback)
            color: widget.gradient == null ? (widget.backgroundColor ?? Theme.of(context).primaryColor) : null,
            gradient: widget.gradient,                // Gradient overrides solid color
            borderRadius: BorderRadius.circular(16),  // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),           // Shadow below button
              ),
            ],
          ),
          child: Center(
            // Show spinner OR text based on loading state
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,               // Thin spinner
                      // AlwaysStoppedAnimation provides a fixed color for the spinner
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,    // Don't expand row
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Optional icon before text
                      // "if (condition) ...[widgets]" conditionally adds widgets
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.textColor ?? Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),     // Space between icon and text
                      ],
                      // Button label text
                      Text(
                        widget.text,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600, // Semi-bold
                          color: widget.textColor ?? Colors.white,
                          letterSpacing: 0.5,          // Slight letter spacing
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// AnimatedOutlineButton - Bordered Button with Scale Animation
// ==============================================================================
// Similar to AnimatedButton but with:
// - Transparent background (no fill)
// - Visible colored border
// - No loading state support
//
// Used for secondary/cancel actions.
// ==============================================================================
class AnimatedOutlineButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color borderColor;          // Color of the border (required)
  final Color textColor;            // Color of text and icon (required)
  final IconData? icon;             // Optional icon before text
  final double? width;
  final double? height;

  const AnimatedOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.borderColor,
    required this.textColor,
    this.icon,
    this.width,
    this.height,
  });

  @override
  State<AnimatedOutlineButton> createState() => _AnimatedOutlineButtonState();
}

class _AnimatedOutlineButtonState extends State<AnimatedOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Same animation setup as AnimatedButton
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();               // Always fire callback (no loading check)
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 56,
          decoration: BoxDecoration(
            color: Colors.transparent,                // No background fill
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.borderColor,              // Visible colored border
              width: 2,                               // 2px border width
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Optional icon
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.textColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// AnimatedIconButton - Circular Icon Button with Scale Animation
// ==============================================================================
// A round button containing only an icon (no text).
// Scales to 90% on tap with a simpler animation pattern:
// - forward() runs the shrink animation
// - .then((_) => ...) waits for it to finish, then reverses and fires callback
//
// This creates a "bounce" effect: press → shrink → spring back → action
// ==============================================================================
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;                // The icon to display
  final VoidCallback onPressed;       // Callback when tapped
  final Color? backgroundColor;       // Circle background (default: primary at 10%)
  final Color? iconColor;             // Icon color (default: primary)
  final double size;                  // Circle diameter (default: 50px)

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 50,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    // Scales to 90% (slightly more dramatic than the 95% used in other buttons)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==============================================================================
  // _handleTap - Bounce Animation Pattern
  // ==============================================================================
  // Different from the other buttons:
  // 1. forward() - shrinks the button
  // 2. .then((_) => ...) - when shrink finishes, reverse AND fire callback
  //
  // This creates a complete "bounce" animation before the action happens.
  // ==============================================================================
  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();         // Spring back to full size
      widget.onPressed();            // Fire the tap callback
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,                     // Simple tap (no separate down/up)
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            // Default: primary color at 10% opacity (subtle tint)
            color: widget.backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,           // Perfect circle
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor ?? Theme.of(context).primaryColor,
            size: widget.size * 0.5,          // Icon is half the circle's diameter
          ),
        ),
      ),
    );
  }
}
