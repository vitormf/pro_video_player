import 'subtitle_cue.dart';
import 'subtitle_format.dart';
import 'subtitle_track.dart';

/// An external subtitle track loaded from a URL, file, or asset.
///
/// Extends [SubtitleTrack] with information about the external
/// subtitle source, format, and parsed cues.
class ExternalSubtitleTrack extends SubtitleTrack {
  /// Creates an external subtitle track.
  ///
  /// The [path] is the source path (URL, file path, or asset path).
  /// The [sourceType] indicates the type of source ('network', 'file', 'asset').
  /// The [format] specifies the subtitle file format.
  /// The [cues] contains parsed subtitle entries (optional until loaded).
  const ExternalSubtitleTrack({
    required super.id,
    required super.label,
    required this.path,
    required this.sourceType,
    required this.format,
    super.language,
    super.isDefault,
    this.cues,
  });

  /// The path to the external subtitle file.
  ///
  /// This can be a URL (for network sources), a file path (for local files),
  /// or an asset path (for Flutter assets).
  final String path;

  /// The type of subtitle source.
  ///
  /// One of: 'network', 'file', 'asset'.
  final String sourceType;

  /// The format of the subtitle file.
  final SubtitleFormat format;

  /// The parsed subtitle cues.
  ///
  /// This is `null` until the subtitle file is loaded and parsed.
  final List<SubtitleCue>? cues;

  /// Always returns `true` for external subtitle tracks.
  @override
  bool get isExternal => true;

  /// Creates a copy with the given cues.
  ///
  /// Used after parsing the subtitle file to create a track
  /// with the loaded cues.
  ExternalSubtitleTrack copyWithCues(List<SubtitleCue> cues) => ExternalSubtitleTrack(
    id: id,
    label: label,
    path: path,
    sourceType: sourceType,
    format: format,
    language: language,
    isDefault: isDefault,
    cues: cues,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExternalSubtitleTrack) return false;
    return id == other.id &&
        label == other.label &&
        language == other.language &&
        isDefault == other.isDefault &&
        path == other.path &&
        sourceType == other.sourceType &&
        format == other.format;
  }

  @override
  int get hashCode => Object.hash(id, label, language, isDefault, path, sourceType, format);

  @override
  String toString() =>
      'ExternalSubtitleTrack(id: $id, label: $label, sourceType: $sourceType, path: $path, format: ${format.name}, language: $language)';
}
