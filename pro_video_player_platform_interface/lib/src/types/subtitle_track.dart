/// Represents a subtitle/caption track.
class SubtitleTrack {
  /// Creates a subtitle track.
  const SubtitleTrack({required this.id, required this.label, this.language, this.isDefault = false});

  /// Unique identifier for this subtitle track.
  final String id;

  /// Human-readable label for this track.
  final String label;

  /// Language code (e.g., 'en', 'es', 'pt').
  final String? language;

  /// Whether this is the default track.
  final bool isDefault;

  /// Whether this is an external subtitle track.
  ///
  /// Returns `false` for embedded tracks, `true` for external tracks.
  bool get isExternal => false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubtitleTrack) return false;
    // Check exact type to distinguish embedded from external tracks
    if (runtimeType != other.runtimeType) return false;
    return id == other.id && label == other.label && language == other.language && isDefault == other.isDefault;
  }

  @override
  int get hashCode => Object.hash(id, label, language, isDefault);

  @override
  String toString() => 'SubtitleTrack(id: $id, label: $label, language: $language, isDefault: $isDefault)';
}
