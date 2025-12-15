import 'package:flutter/widgets.dart';

/// Screen size categories based on Material Design 3 breakpoints.
///
/// - [compact]: < 600px (phones in portrait)
/// - [medium]: 600-839px (phones in landscape, small tablets)
/// - [expanded]: >= 840px (tablets, desktop, web)
enum ScreenSize {
  /// Compact screens: phones in portrait mode (< 600px).
  compact(maxWidth: 599),

  /// Medium screens: phones in landscape, small tablets (600-839px).
  medium(maxWidth: 839),

  /// Expanded screens: tablets, desktop, web (>= 840px).
  expanded(maxWidth: double.infinity);

  const ScreenSize({required this.maxWidth});

  /// The maximum width for this screen size category.
  final double maxWidth;
}

/// Utility class for responsive layout decisions.
///
/// Provides helper methods to determine the current screen size category
/// and make layout decisions based on available space.
class ResponsiveUtils {
  ResponsiveUtils._();

  /// Breakpoint for compact to medium transition.
  static const double compactBreakpoint = 600;

  /// Breakpoint for medium to expanded transition.
  static const double mediumBreakpoint = 840;

  /// Returns the [ScreenSize] category based on the current screen width.
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return getScreenSizeFromWidth(width);
  }

  /// Returns the [ScreenSize] category for a given width.
  ///
  /// This is useful for testing or when you have the width directly.
  static ScreenSize getScreenSizeFromWidth(double width) {
    if (width < compactBreakpoint) {
      return ScreenSize.compact;
    } else if (width < mediumBreakpoint) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.expanded;
    }
  }

  /// Returns true if the screen is compact (< 600px).
  static bool isCompact(BuildContext context) => getScreenSize(context) == ScreenSize.compact;

  /// Returns true if the screen is medium (600-839px).
  static bool isMedium(BuildContext context) => getScreenSize(context) == ScreenSize.medium;

  /// Returns true if the screen is expanded (>= 840px).
  static bool isExpanded(BuildContext context) => getScreenSize(context) == ScreenSize.expanded;

  /// Returns the recommended grid cross-axis count for the current screen size.
  ///
  /// - Compact: 1 column (full-width items)
  /// - Medium: 2 columns
  /// - Expanded: 3 columns
  static int getGridCrossAxisCount(BuildContext context) {
    final screenSize = getScreenSize(context);
    return switch (screenSize) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 3,
    };
  }

  /// Returns true if a side-by-side layout should be used for video + controls.
  ///
  /// Side-by-side layout is recommended when:
  /// - Screen is expanded (tablets, desktop)
  /// - Screen is medium AND in landscape orientation
  static bool shouldUseSideBySideLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenSize = getScreenSizeFromWidth(size.width);

    if (screenSize == ScreenSize.expanded) {
      return true;
    }

    if (screenSize == ScreenSize.medium) {
      // Use side-by-side in landscape
      return size.width > size.height;
    }

    return false;
  }
}
