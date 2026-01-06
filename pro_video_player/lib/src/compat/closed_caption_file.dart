/// ClosedCaptionFile classes for video_player API compatibility.
///
/// These classes match the exact signatures from Flutter's video_player library.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'package:flutter/foundation.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart' as platform;

import 'caption.dart';
import 'compat_annotation.dart';

/// A structured representation of a parsed closed caption file.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@immutable
@videoPlayerCompat
abstract class ClosedCaptionFile {
  /// Creates a ClosedCaptionFile.
  const ClosedCaptionFile();

  /// The full list of captions from a given file.
  List<Caption> get captions;
}

/// Parses SubRip (.srt) caption files.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@videoPlayerCompat
class SubRipCaptionFile extends ClosedCaptionFile {
  /// Parses a string into a ClosedCaptionFile, assuming [fileContents] is in
  /// the SubRip file format.
  ///
  /// Example SRT format:
  /// ```
  /// 1
  /// 00:00:01,000 --> 00:00:04,000
  /// Hello, world!
  ///
  /// 2
  /// 00:00:05,000 --> 00:00:08,000
  /// This is a subtitle.
  /// ```
  SubRipCaptionFile(this.fileContents) : _captions = _parseSrt(fileContents);

  /// The original file contents.
  final String fileContents;

  final List<Caption> _captions;

  @override
  List<Caption> get captions => _captions;

  /// Parses SRT file contents into a list of captions.
  static List<Caption> _parseSrt(String fileContents) {
    // Delegate to platform's SubtitleParser for actual parsing
    final cues = platform.SubtitleParser.parse(fileContents, platform.SubtitleFormat.srt);

    return cues.asMap().entries.map((entry) {
      final index = entry.key;
      final cue = entry.value;
      return Caption(number: index + 1, start: cue.start, end: cue.end, text: cue.text);
    }).toList();
  }
}

/// Parses WebVTT (.vtt) caption files.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@videoPlayerCompat
class WebVTTCaptionFile extends ClosedCaptionFile {
  /// Parses a string into a ClosedCaptionFile, assuming [fileContents] is in
  /// the WebVTT file format.
  ///
  /// Example WebVTT format:
  /// ```
  /// WEBVTT
  ///
  /// 00:00:01.000 --> 00:00:04.000
  /// Hello, world!
  ///
  /// 00:00:05.000 --> 00:00:08.000
  /// This is a subtitle.
  /// ```
  WebVTTCaptionFile(this.fileContents) : _captions = _parseVtt(fileContents);

  /// The original file contents.
  final String fileContents;

  final List<Caption> _captions;

  @override
  List<Caption> get captions => _captions;

  /// Parses WebVTT file contents into a list of captions.
  static List<Caption> _parseVtt(String fileContents) {
    // Delegate to platform's SubtitleParser for actual parsing
    final cues = platform.SubtitleParser.parse(fileContents, platform.SubtitleFormat.vtt);

    return cues.asMap().entries.map((entry) {
      final index = entry.key;
      final cue = entry.value;
      return Caption(number: index + 1, start: cue.start, end: cue.end, text: cue.text);
    }).toList();
  }
}
