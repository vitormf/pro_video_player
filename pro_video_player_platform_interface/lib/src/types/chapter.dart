/// Represents a chapter/section within a video.
///
/// Chapters are time-marked sections of a video with titles, commonly used
/// for navigation (e.g., "Introduction", "Chapter 1: Setup", etc.).
///
/// Chapters can be extracted from:
/// - MP4 chapter atoms
/// - MKV chapter markers
/// - HLS/DASH manifest metadata
/// - External chapter files (VTT with kind="chapters")
class Chapter {
  /// Creates a chapter.
  ///
  /// The [id] should be unique within the video.
  /// The [title] is the human-readable chapter name.
  /// The [startTime] defines when this chapter begins.
  /// The [endTime] is optional and defines when this chapter ends.
  /// The [thumbnailUrl] is optional and provides a preview image.
  const Chapter({required this.id, required this.title, required this.startTime, this.endTime, this.thumbnailUrl});

  /// Creates a chapter from a map.
  ///
  /// Used for deserializing chapters from method channels.
  factory Chapter.fromMap(Map<dynamic, dynamic> map) => Chapter(
    id: map['id'] as String,
    title: map['title'] as String,
    startTime: Duration(milliseconds: map['startTimeMs'] as int),
    endTime: map['endTimeMs'] != null ? Duration(milliseconds: map['endTimeMs'] as int) : null,
    thumbnailUrl: map['thumbnailUrl'] as String?,
  );

  /// Unique identifier for this chapter.
  ///
  /// Format is typically "chap-{index}" (e.g., "chap-0", "chap-1").
  final String id;

  /// Human-readable title for this chapter.
  final String title;

  /// The time when this chapter starts.
  final Duration startTime;

  /// The time when this chapter ends.
  ///
  /// This may be `null` if:
  /// - This is the last chapter (ends when video ends)
  /// - The source doesn't provide end times
  final Duration? endTime;

  /// Optional URL to a thumbnail image for this chapter.
  ///
  /// Some video formats (like HLS with I-frame playlists) can provide
  /// thumbnail images at chapter points.
  final String? thumbnailUrl;

  /// The duration of this chapter.
  ///
  /// Returns `null` if [endTime] is not set.
  Duration? get duration => endTime != null ? endTime! - startTime : null;

  /// Whether this chapter is active at the given [position].
  ///
  /// Returns `true` if [position] is >= [startTime] and < [endTime].
  /// If [endTime] is `null`, returns `true` if [position] >= [startTime].
  bool isActiveAt(Duration position) {
    if (position < startTime) return false;
    if (endTime == null) return true;
    return position < endTime!;
  }

  /// Returns the start time formatted as a string (e.g., "1:30" or "1:05:30").
  ///
  /// Format:
  /// - Less than 1 hour: "M:SS" (e.g., "5:03")
  /// - 1 hour or more: "H:MM:SS" (e.g., "1:05:30")
  String get formattedStartTime {
    final hours = startTime.inHours;
    final minutes = startTime.inMinutes % 60;
    final seconds = startTime.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Creates a copy of this chapter with the given fields replaced.
  Chapter copyWith({
    String? id,
    String? title,
    Duration? startTime,
    Duration? endTime,
    String? thumbnailUrl,
    bool clearEndTime = false,
    bool clearThumbnailUrl = false,
  }) => Chapter(
    id: id ?? this.id,
    title: title ?? this.title,
    startTime: startTime ?? this.startTime,
    endTime: clearEndTime ? null : (endTime ?? this.endTime),
    thumbnailUrl: clearThumbnailUrl ? null : (thumbnailUrl ?? this.thumbnailUrl),
  );

  /// Converts this chapter to a map for serialization.
  ///
  /// Used for sending chapters over method channels.
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'startTimeMs': startTime.inMilliseconds,
    if (endTime != null) 'endTimeMs': endTime!.inMilliseconds,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Chapter) return false;
    return id == other.id &&
        title == other.title &&
        startTime == other.startTime &&
        endTime == other.endTime &&
        thumbnailUrl == other.thumbnailUrl;
  }

  @override
  int get hashCode => Object.hash(id, title, startTime, endTime, thumbnailUrl);

  @override
  String toString() =>
      'Chapter(id: $id, title: $title, startTime: $startTime, '
      'endTime: $endTime, thumbnailUrl: $thumbnailUrl)';
}
