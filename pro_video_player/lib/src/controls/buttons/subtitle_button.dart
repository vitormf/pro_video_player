import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// A button that opens the subtitle track picker.
///
/// This button displays different icons based on whether a subtitle is selected:
/// - Subtitle selected: closed_caption icon
/// - No subtitle: closed_caption_off icon
///
/// Example:
/// ```dart
/// SubtitleButton(
///   theme: VideoPlayerTheme.light(),
///   hasSelectedSubtitle: controller.value.selectedSubtitleTrack != null,
///   onPressed: () => showSubtitlePicker(...),
/// )
/// ```
class SubtitleButton extends StatelessWidget {
  /// Creates a subtitle button.
  ///
  /// The [theme] defines the visual appearance.
  /// The [hasSelectedSubtitle] determines which icon to show.
  /// The [onPressed] callback is called when the button is tapped.
  const SubtitleButton({required this.theme, required this.hasSelectedSubtitle, required this.onPressed, super.key});

  /// The theme for styling the button.
  final VideoPlayerTheme theme;

  /// Whether a subtitle track is currently selected.
  final bool hasSelectedSubtitle;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('toolbar_subtitle_button'),
    icon: Icon(hasSelectedSubtitle ? Icons.closed_caption : Icons.closed_caption_off, color: theme.primaryColor),
    iconSize: 20,
    tooltip: 'Subtitles',
    onPressed: onPressed,
  );
}
