import 'package:flutter/widgets.dart';

/// Vertical position for subtitle display.
enum SubtitlePosition {
  /// Display subtitles at the top of the video.
  top,

  /// Display subtitles in the middle of the video.
  middle,

  /// Display subtitles at the bottom of the video (default).
  bottom,
}

/// Horizontal alignment for subtitle text.
enum SubtitleTextAlignment {
  /// Align subtitle text to the left.
  left,

  /// Align subtitle text to the center (default).
  center,

  /// Align subtitle text to the right.
  right,
}

/// Defines the visual styling for subtitle display.
///
/// This class provides comprehensive control over how subtitles are rendered,
/// including text appearance, container styling, and positioning.
///
/// Font size is automatically scaled based on the video player height using
/// [fontSizePercent], ensuring subtitles remain readable across different
/// screen sizes.
///
/// Example:
/// ```dart
/// const style = SubtitleStyle(
///   fontSizePercent: 1.2, // 120% of default size (slightly larger)
///   textColor: Colors.yellow,
///   backgroundColor: Colors.black54,
///   position: SubtitlePosition.bottom,
///   textAlignment: SubtitleTextAlignment.center,
///   strokeColor: Colors.black,
///   strokeWidth: 2.0,
/// );
/// ```
class SubtitleStyle {
  /// Creates a subtitle style with the specified options.
  const SubtitleStyle({
    this.fontSizePercent = 1.0,
    this.fontFamily,
    this.fontWeight,
    this.textColor,
    this.backgroundColor,
    this.strokeColor,
    this.strokeWidth,
    this.position = SubtitlePosition.bottom,
    this.textAlignment = SubtitleTextAlignment.center,
    this.containerBorderRadius = 4.0,
    this.containerPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.marginFromEdge = 48.0,
    this.horizontalMargin = 16.0,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Text Styling
  // ─────────────────────────────────────────────────────────────────────────

  /// Font size as a percentage of the default subtitle size.
  ///
  /// The default size (1.0 = 100%) is optimized for readability across
  /// different player sizes. Subtitles automatically scale with the
  /// video player dimensions.
  ///
  /// Examples:
  /// - `0.5` = 50% of default (smaller)
  /// - `1.0` = 100% default size
  /// - `1.5` = 150% of default (larger)
  /// - `2.0` = 200% of default (much larger)
  ///
  /// Typical values range from 0.5 to 2.0.
  final double fontSizePercent;

  /// Font family for subtitle text.
  ///
  /// If not specified, uses the default system font.
  final String? fontFamily;

  /// Font weight for subtitle text.
  ///
  /// Defaults to [FontWeight.w500] if not specified.
  final FontWeight? fontWeight;

  /// Color of the subtitle text.
  ///
  /// Defaults to white if not specified.
  final Color? textColor;

  // ─────────────────────────────────────────────────────────────────────────
  // Text Stroke/Outline
  // ─────────────────────────────────────────────────────────────────────────

  /// Color of the text stroke/outline.
  ///
  /// Set this along with [strokeWidth] to add an outline around subtitle text.
  /// This improves readability over varying backgrounds.
  ///
  /// If null, no stroke is rendered.
  final Color? strokeColor;

  /// Width of the text stroke/outline in pixels.
  ///
  /// Only has effect if [strokeColor] is also set.
  /// Typical values are 1.0 to 3.0 pixels.
  ///
  /// If null or zero, no stroke is rendered.
  final double? strokeWidth;

  // ─────────────────────────────────────────────────────────────────────────
  // Container Styling
  // ─────────────────────────────────────────────────────────────────────────

  /// Background color of the subtitle container.
  ///
  /// Defaults to transparent if not specified.
  /// Set to a semi-transparent color (e.g., `Colors.black54`) for a background box.
  final Color? backgroundColor;

  /// Border radius of the subtitle container corners.
  ///
  /// Defaults to 4.0 pixels.
  final double containerBorderRadius;

  /// Inner padding of the subtitle container.
  ///
  /// Defaults to 12px horizontal and 6px vertical padding.
  final EdgeInsets containerPadding;

  // ─────────────────────────────────────────────────────────────────────────
  // Position & Alignment
  // ─────────────────────────────────────────────────────────────────────────

  /// Vertical position of the subtitle on the video.
  ///
  /// Defaults to [SubtitlePosition.bottom].
  final SubtitlePosition position;

  /// Horizontal alignment of the subtitle text.
  ///
  /// Defaults to [SubtitleTextAlignment.center].
  final SubtitleTextAlignment textAlignment;

  /// Distance from the edge of the video (top or bottom depending on [position]).
  ///
  /// For [SubtitlePosition.bottom], this is the distance from the bottom edge.
  /// For [SubtitlePosition.top], this is the distance from the top edge.
  /// For [SubtitlePosition.middle], this value is ignored.
  ///
  /// Defaults to 48.0 pixels to avoid overlapping with player controls.
  final double marginFromEdge;

  /// Horizontal margin around the subtitle container.
  ///
  /// Prevents subtitles from extending to the very edge of the video.
  /// Defaults to 16.0 pixels on each side.
  final double horizontalMargin;

  /// Creates a copy of this style with the given fields replaced.
  SubtitleStyle copyWith({
    double? fontSizePercent,
    String? fontFamily,
    FontWeight? fontWeight,
    Color? textColor,
    Color? backgroundColor,
    Color? strokeColor,
    double? strokeWidth,
    SubtitlePosition? position,
    SubtitleTextAlignment? textAlignment,
    double? containerBorderRadius,
    EdgeInsets? containerPadding,
    double? marginFromEdge,
    double? horizontalMargin,
  }) => SubtitleStyle(
    fontSizePercent: fontSizePercent ?? this.fontSizePercent,
    fontFamily: fontFamily ?? this.fontFamily,
    fontWeight: fontWeight ?? this.fontWeight,
    textColor: textColor ?? this.textColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    strokeColor: strokeColor ?? this.strokeColor,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    position: position ?? this.position,
    textAlignment: textAlignment ?? this.textAlignment,
    containerBorderRadius: containerBorderRadius ?? this.containerBorderRadius,
    containerPadding: containerPadding ?? this.containerPadding,
    marginFromEdge: marginFromEdge ?? this.marginFromEdge,
    horizontalMargin: horizontalMargin ?? this.horizontalMargin,
  );

  /// Converts [textAlignment] to Flutter's [TextAlign].
  TextAlign toTextAlign() => switch (textAlignment) {
    SubtitleTextAlignment.left => TextAlign.left,
    SubtitleTextAlignment.center => TextAlign.center,
    SubtitleTextAlignment.right => TextAlign.right,
  };

  /// Returns whether text stroke should be rendered.
  bool get hasStroke => strokeColor != null && strokeWidth != null && strokeWidth! > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubtitleStyle &&
        other.fontSizePercent == fontSizePercent &&
        other.fontFamily == fontFamily &&
        other.fontWeight == fontWeight &&
        other.textColor == textColor &&
        other.backgroundColor == backgroundColor &&
        other.strokeColor == strokeColor &&
        other.strokeWidth == strokeWidth &&
        other.position == position &&
        other.textAlignment == textAlignment &&
        other.containerBorderRadius == containerBorderRadius &&
        other.containerPadding == containerPadding &&
        other.marginFromEdge == marginFromEdge &&
        other.horizontalMargin == horizontalMargin;
  }

  @override
  int get hashCode => Object.hash(
    fontSizePercent,
    fontFamily,
    fontWeight,
    textColor,
    backgroundColor,
    strokeColor,
    strokeWidth,
    position,
    textAlignment,
    containerBorderRadius,
    containerPadding,
    marginFromEdge,
    horizontalMargin,
  );

  @override
  String toString() =>
      'SubtitleStyle('
      'fontSizePercent: $fontSizePercent, '
      'fontFamily: $fontFamily, '
      'fontWeight: $fontWeight, '
      'textColor: $textColor, '
      'backgroundColor: $backgroundColor, '
      'strokeColor: $strokeColor, '
      'strokeWidth: $strokeWidth, '
      'position: $position, '
      'textAlignment: $textAlignment, '
      'containerBorderRadius: $containerBorderRadius, '
      'containerPadding: $containerPadding, '
      'marginFromEdge: $marginFromEdge, '
      'horizontalMargin: $horizontalMargin)';
}
