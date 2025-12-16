import 'caption.dart';

/// A file containing closed captions.
///
/// This class is provided for compatibility with Flutter's video_player library.
/// For new code, prefer using SubtitleSource which provides more features
/// and format support.
class ClosedCaptionFile {
  /// Creates a [ClosedCaptionFile] with the given captions.
  const ClosedCaptionFile({required this.captions});

  /// The list of captions in this file.
  final List<Caption> captions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClosedCaptionFile && runtimeType == other.runtimeType && _listEquals(captions, other.captions);

  @override
  int get hashCode => Object.hashAll(captions);

  @override
  String toString() => 'ClosedCaptionFile(${captions.length} captions)';

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
