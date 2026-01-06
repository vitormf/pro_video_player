/// Caption classes for video_player API compatibility.
///
/// These classes match the exact signatures from Flutter's video_player library.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'package:flutter/foundation.dart';

import 'compat_annotation.dart';

/// A caption to be displayed at a specific time during video playback.
///
/// [video_player compatibility] This class matches the video_player API exactly.
/// The key difference from pro_video_player's Caption is the required [number] property.
@immutable
@videoPlayerCompat
class Caption {
  /// Creates a caption with the given properties.
  const Caption({required this.number, required this.start, required this.end, required this.text});

  /// The sequential number of this caption in the caption file.
  final int number;

  /// The time at which this caption should start being displayed.
  final Duration start;

  /// The time at which this caption should stop being displayed.
  final Duration end;

  /// The text content of this caption.
  final String text;

  /// A caption with no content, used as a placeholder when no caption is active.
  static const Caption none = Caption(number: 0, start: Duration.zero, end: Duration.zero, text: '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Caption &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          start == other.start &&
          end == other.end &&
          text == other.text;

  @override
  int get hashCode => Object.hash(number, start, end, text);

  @override
  String toString() => 'Caption(number: $number, start: $start, end: $end, text: $text)';
}
