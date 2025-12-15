import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart' show ProVideoPlayer;

import '../utils/responsive_utils.dart';

/// A responsive layout widget that arranges video player and controls
/// based on screen size and orientation.
///
/// On compact screens (phones in portrait):
/// - Video on top with controls below in a scrollable column
///
/// On medium/expanded screens (landscape, tablets, desktop):
/// - Side-by-side layout with controls on left and video on right
class ResponsiveVideoLayout extends StatelessWidget {
  /// Creates a responsive video layout.
  ///
  /// The [videoPlayer] widget is typically a [ProVideoPlayer].
  /// The [controls] widget contains playback controls and other UI elements.
  const ResponsiveVideoLayout({
    required this.videoPlayer,
    required this.controls,
    super.key,
    this.videoAspectRatio = 16 / 9,
    this.maxVideoHeightFraction = 0.4,
    this.sideBySideVideoWidthFraction = 0.6,
  });

  /// The video player widget.
  final Widget videoPlayer;

  /// The controls and additional content widget.
  final Widget controls;

  /// Aspect ratio of the video (width / height).
  ///
  /// Defaults to 16:9.
  final double videoAspectRatio;

  /// Maximum fraction of screen height for video in stacked layout.
  ///
  /// Defaults to 0.4 (40% of screen height).
  final double maxVideoHeightFraction;

  /// Fraction of screen width for video in side-by-side layout.
  ///
  /// Defaults to 0.6 (60% of screen width).
  final double sideBySideVideoWidthFraction;

  /// Minimum width required for side-by-side layout.
  /// This is the controls panel minimum + video panel minimum.
  static const double _minSideBySideWidth = 500;

  /// Minimum width required for any layout.
  /// Below this, we show a placeholder to avoid layout errors during transitions.
  static const double _minLayoutWidth = 200;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // During fullscreen or orientation transitions, constraints can be very narrow.
      // Return a simple placeholder if width is too small to avoid layout errors.
      if (constraints.maxWidth < _minLayoutWidth) {
        return const ColoredBox(color: Colors.black);
      }

      // Check MediaQuery suggestion AND actual constraint width.
      // During fullscreen transitions, constraints can be much narrower than MediaQuery reports.
      final useSideBySide =
          ResponsiveUtils.shouldUseSideBySideLayout(context) && constraints.maxWidth >= _minSideBySideWidth;

      if (useSideBySide) {
        return _buildSideBySideLayout(constraints);
      } else {
        return _buildStackedLayout(constraints);
      }
    },
  );

  /// Builds the stacked layout for compact screens.
  ///
  /// Video on top with controls below in a scrollable area.
  Widget _buildStackedLayout(BoxConstraints constraints) {
    // Calculate video height: aspect ratio or max fraction, whichever is smaller
    final aspectRatioHeight = constraints.maxWidth / videoAspectRatio;
    final maxHeight = constraints.maxHeight * maxVideoHeightFraction;
    final videoHeight = aspectRatioHeight > maxHeight ? maxHeight : aspectRatioHeight;

    return Column(
      children: [
        // Video player with constrained height
        SizedBox(
          height: videoHeight,
          width: constraints.maxWidth,
          child: ColoredBox(color: Colors.black, child: videoPlayer),
        ),
        // Controls in scrollable area
        Expanded(child: SingleChildScrollView(child: controls)),
      ],
    );
  }

  /// Builds the side-by-side layout for larger screens.
  ///
  /// Controls on left, video on right.
  Widget _buildSideBySideLayout(BoxConstraints constraints) {
    final videoWidth = constraints.maxWidth * sideBySideVideoWidthFraction;
    final controlsWidth = constraints.maxWidth * (1 - sideBySideVideoWidthFraction);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls on the left
        SizedBox(
          width: controlsWidth,
          height: constraints.maxHeight,
          child: SingleChildScrollView(child: controls),
        ),
        // Video player on the right (vertically centered)
        SizedBox(
          width: videoWidth,
          height: constraints.maxHeight,
          child: Center(
            child: AspectRatio(
              aspectRatio: videoAspectRatio,
              child: ColoredBox(color: Colors.black, child: videoPlayer),
            ),
          ),
        ),
      ],
    );
  }
}
