/// Represents an audio track.
class AudioTrack {
  /// Creates an audio track.
  const AudioTrack({required this.id, required this.label, this.language, this.isDefault = false});

  /// Unique identifier for this audio track.
  final String id;

  /// Human-readable label for this track (e.g., 'English', 'English (5.1)', 'Spanish (Stereo)').
  final String label;

  /// Language code (e.g., 'en', 'es', 'pt').
  final String? language;

  /// Whether this is the default track.
  final bool isDefault;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AudioTrack) return false;
    return id == other.id && label == other.label && language == other.language && isDefault == other.isDefault;
  }

  @override
  int get hashCode => Object.hash(id, label, language, isDefault);

  @override
  String toString() => 'AudioTrack(id: $id, label: $label, language: $language, isDefault: $isDefault)';
}
