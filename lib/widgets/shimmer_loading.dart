// ==============================================================================
// shimmer_loading.dart - Shimmer Loading Effect (Skeleton Screens)
// ==============================================================================
// This file provides shimmer loading animations - the shiny "sweeping light"
// effect you see on placeholder content while real data is loading.
//
// How shimmer works:
// 1. An AnimationController continuously oscillates a value from -2 to 2
// 2. This value is used to translate (slide) a gradient across the widget
// 3. The gradient goes: baseColor -> highlightColor -> baseColor
// 4. The sliding gradient creates the "gleaming" shimmer effect
//
// Components in this file:
// 1. ShimmerLoading: The animated shimmer effect wrapper (wraps any child)
// 2. _SlidingGradientTransform: Custom gradient transform for the slide animation
// 3. SkeletonBox: A rectangular placeholder (for text, images, etc.)
// 4. SkeletonCircle: A circular placeholder (for avatars, icons)
// 5. TransactionListSkeleton: Pre-built skeleton for transaction list
// 6. DashboardCardSkeleton: Pre-built skeleton for dashboard cards
//
// Usage: ShimmerLoading(child: SkeletonBox(width: 200, height: 20))
// ==============================================================================

import 'package:flutter/material.dart';   // For StatefulWidget, AnimationController, etc.

// ==============================================================================
// ShimmerLoading - Animated Shimmer Effect Wrapper
// ==============================================================================
// StatefulWidget because it manages an AnimationController that continuously
// animates the shimmer gradient position.
//
// "SingleTickerProviderStateMixin" is required for AnimationController -
// it provides a "Ticker" that fires once per frame (typically 60fps).
// ==============================================================================
class ShimmerLoading extends StatefulWidget {
  final Widget child;             // The widget to apply shimmer effect to
  final Color? baseColor;         // Base color of the shimmer (default: grey)
  final Color? highlightColor;    // Highlight color (the "shine" - default: lighter grey)
  final Duration period;          // How long one shimmer cycle takes (default: 1.5 seconds)

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),  // 1.5 second cycle
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  // AnimationController drives the shimmer animation over time
  // "late" means it will be initialized before use (in initState)
  late AnimationController _controller;

  // Animation<double> provides the current animated value at any point
  late Animation<double> _animation;

  // ==============================================================================
  // initState - Initialize Animation When Widget is Created
  // ==============================================================================
  @override
  void initState() {
    super.initState();

    // Create the animation controller
    // "vsync: this" links to SingleTickerProviderStateMixin for frame timing
    // "duration" sets how long one cycle takes
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();  // ".." cascade operator - calls repeat() on the controller
    // repeat() makes the animation loop forever

    // Create a tween that maps the controller's 0.0-1.0 range to -2 to 2
    // This range controls how far the gradient slides:
    // -2 = gradient is fully off-screen to the left
    // +2 = gradient is fully off-screen to the right
    _animation = Tween<double>(begin: -2, end: 2).animate(
      // CurvedAnimation adds easing (smooth start/stop)
      // Curves.easeInOutSine = smooth sine wave acceleration
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  // ==============================================================================
  // dispose - Clean Up Animation Resources
  // ==============================================================================
  // MUST dispose the AnimationController to prevent memory leaks.
  // The controller allocates resources (ticker) that need to be freed.
  // ==============================================================================
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==============================================================================
  // build - Apply Shimmer Effect Using ShaderMask
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    // Check if current theme is dark mode (affects default colors)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use provided colors or defaults based on theme
    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade300);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey.shade700 : Colors.grey.shade100);

    // AnimatedBuilder rebuilds the widget tree every time the animation value changes
    // This is what makes the shimmer "move"
    return AnimatedBuilder(
      animation: _animation,                     // Listen to animation changes
      builder: (context, child) {
        // ShaderMask applies a shader (gradient) as a mask over the child widget
        // This is what creates the shimmer visual effect
        return ShaderMask(
          // shaderCallback receives the widget bounds and returns a shader
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,                       // Left side: base grey
                highlightColor,                  // Center: light "shine"
                baseColor,                       // Right side: base grey
              ],
              stops: [
                0.0,                             // Base color at 0%
                0.5,                             // Highlight at 50% (center)
                1.0,                             // Base color at 100%
              ],
              // Custom transform that slides the gradient based on animation value
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ).createShader(bounds);              // Convert gradient to shader
          },
          // BlendMode.srcATop: The gradient colors only show where the child is drawn
          // This means the shimmer only appears on the skeleton shapes, not transparent areas
          blendMode: BlendMode.srcATop,
          child: widget.child,                   // The skeleton placeholder widgets
        );
      },
    );
  }
}

// ==============================================================================
// _SlidingGradientTransform - Custom Gradient Transform for Shimmer Slide
// ==============================================================================
// Extends GradientTransform to create a sliding effect.
// This transforms (moves) the gradient horizontally based on the animation value.
//
// Matrix4.translationValues(x, y, z) creates a translation matrix:
// - x = horizontal offset (bounds.width * slidePercent moves the gradient)
// - y = 0.0 (no vertical movement)
// - z = 0.0 (no depth movement)
//
// When slidePercent goes from -2 to 2, the gradient slides across the widget
// from left to right, creating the shimmer sweep effect.
// ==============================================================================
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;  // Current animation value (-2 to 2)

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    // Translate the gradient horizontally by (width * slidePercent)
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

// ==============================================================================
// SkeletonBox - Rectangular Loading Placeholder
// ==============================================================================
// A simple grey rectangle that represents content that hasn't loaded yet.
// Used for text lines, images, buttons, etc.
//
// StatelessWidget because it's just a colored box with no changing state.
// ==============================================================================
class SkeletonBox extends StatelessWidget {
  final double? width;              // Width (null = size to parent)
  final double? height;             // Height (null = size to parent)
  final BorderRadius? borderRadius; // Corner roundness (default: 4px)

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Check theme for appropriate grey shade
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Darker grey for dark mode, lighter grey for light mode
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

// ==============================================================================
// SkeletonCircle - Circular Loading Placeholder
// ==============================================================================
// A grey circle that represents an avatar, icon, or profile picture.
// ==============================================================================
class SkeletonCircle extends StatelessWidget {
  final double size;  // Diameter of the circle (default: 50px)

  const SkeletonCircle({
    super.key,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        shape: BoxShape.circle,    // Makes the container a perfect circle
      ),
    );
  }
}

// ==============================================================================
// TransactionListSkeleton - Pre-built Skeleton for Transaction Lists
// ==============================================================================
// Renders a list of placeholder "transaction items" with shimmer effect.
// Each item has a circle (category icon), two lines (title + subtitle),
// and a box on the right (amount).
//
// This is shown while transaction data is loading from the API.
// ==============================================================================
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;  // Number of placeholder items (default: 5)

  const TransactionListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the list in ShimmerLoading to apply the shimmer animation
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,                      // Number of skeleton items
        // separatorBuilder creates the space between items
        // (_ , __) means we don't need the context or index parameters
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // Each skeleton item mimics a real transaction card layout
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Circle placeholder (category icon)
                  const SkeletonCircle(size: 40),
                  const SizedBox(width: 12),

                  // Two line placeholders (title + subtitle)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title line (full width, 16px tall)
                        SkeletonBox(
                          width: double.infinity,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle line (100px wide, 12px tall)
                        SkeletonBox(
                          width: 100,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Amount placeholder (right side, 80px wide)
                  SkeletonBox(
                    width: 80,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==============================================================================
// DashboardCardSkeleton - Pre-built Skeleton for Dashboard Summary Cards
// ==============================================================================
// Renders a placeholder dashboard card with shimmer effect.
// Mimics the layout of a DashboardSummaryCard with a title bar
// and two columns of label + value pairs.
// ==============================================================================
class DashboardCardSkeleton extends StatelessWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title placeholder (150px wide, 20px tall)
            SkeletonBox(
              width: 150,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),

            // Two-column layout (mimics income/expense side by side)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left column (label + value)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 60,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        width: 100,
                        height: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),

                // Right column (label + value)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 60,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        width: 100,
                        height: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
