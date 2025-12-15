import 'package:flutter/material.dart';

import '../../cast_button.dart';
import '../../video_player_theme.dart';

/// A button that opens the native casting device picker.
///
/// This button wraps the platform-specific CastButton widget (MediaRouteButton
/// on Android, AVRoutePickerView on iOS/macOS). The button automatically shows
/// when cast devices are nearby and hides when none are available.
///
/// Example:
/// ```dart
/// CastingButton(
///   theme: VideoPlayerTheme.light(),
///   isCasting: controller.value.isCasting,
/// )
/// ```
class CastingButton extends StatelessWidget {
  /// Creates a casting button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [isCasting] determines whether to use active or inactive color.
  const CastingButton({required this.theme, required this.isCasting, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// Whether casting is currently active.
  final bool isCasting;

  @override
  Widget build(BuildContext context) => CastButton(
    tintColor: isCasting ? theme.progressBarActiveColor : theme.primaryColor,
    activeTintColor: theme.progressBarActiveColor,
  );
}
