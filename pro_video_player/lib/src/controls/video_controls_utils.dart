import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Utility functions for video player controls.
///
/// Contains pure helper functions used by VideoPlayerControls for labels,
/// icons, and data transformations.
class VideoControlsUtils {
  /// Private constructor to prevent instantiation.
  VideoControlsUtils._();

  /// Gets a label suffix for the current repeat mode.
  ///
  /// Returns an empty string for none, " (All)" for all, and " (One)" for one.
  static String getRepeatModeLabel(PlaylistRepeatMode mode) {
    switch (mode) {
      case PlaylistRepeatMode.none:
        return '';
      case PlaylistRepeatMode.all:
        return ' (All)';
      case PlaylistRepeatMode.one:
        return ' (One)';
    }
  }

  /// Gets the next repeat mode in the cycle: none → all → one → none.
  static PlaylistRepeatMode getNextRepeatMode(PlaylistRepeatMode current) {
    switch (current) {
      case PlaylistRepeatMode.none:
        return PlaylistRepeatMode.all;
      case PlaylistRepeatMode.all:
        return PlaylistRepeatMode.one;
      case PlaylistRepeatMode.one:
        return PlaylistRepeatMode.none;
    }
  }

  /// Returns the appropriate backward skip icon based on the skip duration.
  ///
  /// - 5 seconds or less: replay_5
  /// - 6-10 seconds: replay_10
  /// - More than 10 seconds: replay_30
  static IconData getSkipBackwardIcon(Duration skipDuration) {
    final seconds = skipDuration.inSeconds;
    if (seconds <= 5) return Icons.replay_5;
    if (seconds <= 10) return Icons.replay_10;
    return Icons.replay_30;
  }

  /// Returns the appropriate forward skip icon based on the skip duration.
  ///
  /// - 5 seconds or less: forward_5
  /// - 6-10 seconds: forward_10
  /// - More than 10 seconds: forward_30
  static IconData getSkipForwardIcon(Duration skipDuration) {
    final seconds = skipDuration.inSeconds;
    if (seconds <= 5) return Icons.forward_5;
    if (seconds <= 10) return Icons.forward_10;
    return Icons.forward_30;
  }

  /// Sorts quality tracks by height descending and filters out auto tracks.
  ///
  /// Returns a list of non-auto tracks sorted from highest to lowest resolution.
  static List<VideoQualityTrack> sortedQualityTracks(List<VideoQualityTrack> tracks) {
    final nonAutoTracks = tracks.where((t) => !t.isAuto).toList()..sort((a, b) => b.height.compareTo(a.height));
    return nonAutoTracks;
  }

  /// Returns a human-readable label for the scaling mode.
  static String getScalingModeLabel(VideoScalingMode mode) {
    switch (mode) {
      case VideoScalingMode.fit:
        return 'Fit (Letterbox)';
      case VideoScalingMode.fill:
        return 'Fill (Crop)';
      case VideoScalingMode.stretch:
        return 'Stretch';
    }
  }

  /// Returns a description of what the scaling mode does.
  static String getScalingModeDescription(VideoScalingMode mode) {
    switch (mode) {
      case VideoScalingMode.fit:
        return 'Show entire video with black bars';
      case VideoScalingMode.fill:
        return 'Fill screen, may crop edges';
      case VideoScalingMode.stretch:
        return 'Stretch to fill screen';
    }
  }
}
