import 'package:flutter/material.dart';

import '../pro_video_player.dart' show VideoPlayerControls;
import 'video_player_controls.dart' show VideoPlayerControls;

/// Formats a [Duration] as a string in "m:ss" format.
///
/// Example: Duration(minutes: 5, seconds: 30) -> "5:30"
String formatVideoDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Defines the visual theme for video player controls.
///
/// This class provides a comprehensive theming system for the video player
/// controls, allowing full customization of colors, sizes, and spacing to match
/// your app's brand and design language.
///
/// ## Predefined Themes
///
/// Several predefined themes are available as starting points:
/// - [VideoPlayerTheme()] - Default dark theme
/// - [VideoPlayerTheme.dark()] - Dark theme (same as default)
/// - [VideoPlayerTheme.light()] - Light theme for bright backgrounds
/// - [VideoPlayerTheme.christmas()] - Festive Christmas theme
/// - [VideoPlayerTheme.halloween()] - Spooky Halloween theme
///
/// ## Creating Custom Themes
///
/// ### Option 1: Create a completely custom theme
///
/// ```dart
/// final myBrandTheme = VideoPlayerTheme(
///   primaryColor: Color(0xFF0066CC),      // Your brand blue
///   secondaryColor: Color(0xFF6699CC),
///   backgroundColor: Color(0xCC001A33),
///   progressBarActiveColor: Color(0xFFFF6600),  // Your brand orange
///   progressBarInactiveColor: Colors.white24,
///   progressBarBufferedColor: Color(0x66FF6600),
///   iconSize: 36.0,
///   seekIconSize: 52.0,
///   borderRadius: 12.0,
///   controlsPadding: EdgeInsets.all(20.0),
/// );
/// ```
///
/// ### Option 2: Modify an existing theme
///
/// ```dart
/// final customLight = VideoPlayerTheme.light().copyWith(
///   primaryColor: Colors.deepPurple,
///   progressBarActiveColor: Colors.purpleAccent,
///   iconSize: 40.0,
/// );
/// ```
///
/// ## Applying Themes
///
/// Use [VideoPlayerThemeData] to apply a theme to your video player:
///
/// ```dart
/// VideoPlayerThemeData(
///   theme: myBrandTheme,
///   child: ProVideoPlayer(
///     controller: controller,
///     controlsBuilder: (context, controller) =>
///       VideoPlayerControls(controller: controller),
///   ),
/// )
/// ```
///
/// Or pass directly to [VideoPlayerControls]:
///
/// ```dart
/// VideoPlayerControls(
///   controller: controller,
///   theme: myBrandTheme,
/// )
/// ```
///
/// ## Customizable Properties
///
/// All visual aspects can be customized:
/// - **Colors**: primary, secondary, background, progress bar colors
/// - **Sizes**: icon sizes, seek icon sizes, border radius
/// - **Spacing**: controls padding
///
/// See individual property documentation for details.
class VideoPlayerTheme {
  /// Creates a video player theme with the specified properties.
  ///
  /// If no properties are specified, uses default dark theme values.
  const VideoPlayerTheme({
    this.primaryColor = Colors.white,
    this.secondaryColor = Colors.white70,
    this.backgroundColor = const Color(0xCC000000),
    this.progressBarActiveColor = Colors.white,
    this.progressBarInactiveColor = Colors.white24,
    this.progressBarBufferedColor = Colors.white38,
    this.iconSize = 32.0,
    this.seekIconSize = 48.0,
    this.borderRadius = 8.0,
    this.controlsPadding = const EdgeInsets.all(16),
  });

  /// Creates a dark theme (same as default).
  factory VideoPlayerTheme.dark() => const VideoPlayerTheme();

  /// Creates a light theme suitable for bright backgrounds.
  factory VideoPlayerTheme.light() => const VideoPlayerTheme(
    primaryColor: Colors.black87,
    secondaryColor: Colors.black54,
    backgroundColor: Color(0xCCFFFFFF),
    progressBarActiveColor: Colors.blue,
    progressBarInactiveColor: Colors.black26,
    progressBarBufferedColor: Colors.black12,
  );

  /// Creates a festive Christmas theme with red and green colors.
  factory VideoPlayerTheme.christmas() => VideoPlayerTheme(
    backgroundColor: const Color(0xCC0D4D0D),
    progressBarInactiveColor: Colors.green.shade200,
    progressBarBufferedColor: Colors.red.shade200,
  );

  /// Creates a spooky Halloween theme with orange and dark colors.
  factory VideoPlayerTheme.halloween() => const VideoPlayerTheme(
    primaryColor: Colors.orange,
    secondaryColor: Color(0xFFFF6B1A),
    backgroundColor: Color(0xCC1A0A00),
    progressBarActiveColor: Colors.deepOrange,
    progressBarInactiveColor: Color(0x33FF6B1A),
    progressBarBufferedColor: Color(0x66FF6B1A),
  );

  /// Primary color used for main icons and text.
  final Color primaryColor;

  /// Secondary color used for less prominent text and icons.
  final Color secondaryColor;

  /// Background color for control overlays.
  final Color backgroundColor;

  /// Color for the active (played) portion of the progress bar.
  final Color progressBarActiveColor;

  /// Color for the inactive (unplayed) portion of the progress bar.
  final Color progressBarInactiveColor;

  /// Color for the buffered portion of the progress bar.
  final Color progressBarBufferedColor;

  /// Size of standard control icons.
  final double iconSize;

  /// Size of seek gesture feedback icons.
  final double seekIconSize;

  /// Border radius for rounded UI elements.
  final double borderRadius;

  /// Padding around control groups.
  final EdgeInsets controlsPadding;

  /// Creates a copy of this theme with the given fields replaced.
  VideoPlayerTheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? progressBarActiveColor,
    Color? progressBarInactiveColor,
    Color? progressBarBufferedColor,
    double? iconSize,
    double? seekIconSize,
    double? borderRadius,
    EdgeInsets? controlsPadding,
  }) => VideoPlayerTheme(
    primaryColor: primaryColor ?? this.primaryColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    progressBarActiveColor: progressBarActiveColor ?? this.progressBarActiveColor,
    progressBarInactiveColor: progressBarInactiveColor ?? this.progressBarInactiveColor,
    progressBarBufferedColor: progressBarBufferedColor ?? this.progressBarBufferedColor,
    iconSize: iconSize ?? this.iconSize,
    seekIconSize: seekIconSize ?? this.seekIconSize,
    borderRadius: borderRadius ?? this.borderRadius,
    controlsPadding: controlsPadding ?? this.controlsPadding,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VideoPlayerTheme &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.backgroundColor == backgroundColor &&
        other.progressBarActiveColor == progressBarActiveColor &&
        other.progressBarInactiveColor == progressBarInactiveColor &&
        other.progressBarBufferedColor == progressBarBufferedColor &&
        other.iconSize == iconSize &&
        other.seekIconSize == seekIconSize &&
        other.borderRadius == borderRadius &&
        other.controlsPadding == controlsPadding;
  }

  @override
  int get hashCode => Object.hash(
    primaryColor,
    secondaryColor,
    backgroundColor,
    progressBarActiveColor,
    progressBarInactiveColor,
    progressBarBufferedColor,
    iconSize,
    seekIconSize,
    borderRadius,
    controlsPadding,
  );
}

/// An inherited widget that provides a [VideoPlayerTheme] to its descendants.
///
/// This widget should wrap video player controls to apply a theme:
///
/// ```dart
/// VideoPlayerThemeData(
///   theme: VideoPlayerTheme.light(),
///   child: VideoPlayerControls(controller: controller),
/// )
/// ```
///
/// Access the theme using [VideoPlayerThemeData.of]:
///
/// ```dart
/// final theme = VideoPlayerThemeData.of(context);
/// ```
class VideoPlayerThemeData extends InheritedWidget {
  /// Creates a theme data widget.
  const VideoPlayerThemeData({required this.theme, required super.child, super.key});

  /// The theme to provide to descendants.
  final VideoPlayerTheme theme;

  /// Returns the [VideoPlayerTheme] from the closest [VideoPlayerThemeData] ancestor.
  ///
  /// If no ancestor is found, returns a default theme.
  static VideoPlayerTheme of(BuildContext context) {
    final themeData = context.dependOnInheritedWidgetOfExactType<VideoPlayerThemeData>();
    return themeData?.theme ?? const VideoPlayerTheme();
  }

  @override
  bool updateShouldNotify(VideoPlayerThemeData oldWidget) => theme != oldWidget.theme;
}
