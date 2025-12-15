/// Metadata for media playback that appears in platform media controls.
///
/// This metadata is displayed in:
/// - iOS/macOS: Control Center and Lock Screen (via MPNowPlayingInfoCenter)
/// - Android: Media notification and Lock Screen (via MediaSession)
/// - Web: Browser media controls (via Media Session API)
///
/// All fields are optional. The player will use available metadata from
/// the video source if not explicitly provided.
///
/// Example:
/// ```dart
/// const metadata = MediaMetadata(
///   title: 'My Video',
///   artist: 'Channel Name',
///   album: 'Video Series',
///   artworkUrl: 'https://example.com/thumbnail.jpg',
/// );
///
/// await controller.setMediaMetadata(metadata);
/// ```
class MediaMetadata {
  /// Creates media metadata with optional fields.
  ///
  /// All fields default to `null`, meaning the platform will use
  /// default values or extract metadata from the video source.
  const MediaMetadata({this.title, this.artist, this.album, this.artworkUrl});

  /// Creates a [MediaMetadata] from a map representation.
  ///
  /// Used for deserializing metadata from platform channels.
  factory MediaMetadata.fromMap(Map<String, dynamic> map) => MediaMetadata(
    title: map['title'] as String?,
    artist: map['artist'] as String?,
    album: map['album'] as String?,
    artworkUrl: map['artworkUrl'] as String?,
  );

  /// An empty metadata instance with all fields set to null.
  ///
  /// Use this to clear any previously set metadata:
  /// ```dart
  /// await controller.setMediaMetadata(MediaMetadata.empty);
  /// ```
  static const MediaMetadata empty = MediaMetadata();

  /// The title of the media (e.g., video title, episode name).
  ///
  /// Displayed as the primary text in media controls.
  final String? title;

  /// The artist, creator, or channel name.
  ///
  /// Displayed as secondary text in media controls.
  final String? artist;

  /// The album, series, or collection name.
  ///
  /// Displayed as tertiary text in media controls (platform-dependent).
  final String? album;

  /// URL to the artwork image (thumbnail, album art).
  ///
  /// Must be a valid HTTP/HTTPS URL. The image will be downloaded
  /// and displayed in media controls.
  ///
  /// Recommended dimensions: at least 512x512 pixels for best quality
  /// across all platforms.
  final String? artworkUrl;

  /// Returns `true` if all metadata fields are null.
  bool get isEmpty => title == null && artist == null && album == null && artworkUrl == null;

  /// Returns `true` if any metadata field is set.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy of this metadata with the given fields replaced.
  ///
  /// Fields that are not specified will retain their current values.
  MediaMetadata copyWith({String? title, String? artist, String? album, String? artworkUrl}) => MediaMetadata(
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    artworkUrl: artworkUrl ?? this.artworkUrl,
  );

  /// Converts this metadata to a map representation.
  ///
  /// Only includes non-null fields to minimize data transfer.
  Map<String, dynamic> toMap() => <String, dynamic>{
    if (title != null) 'title': title,
    if (artist != null) 'artist': artist,
    if (album != null) 'album': album,
    if (artworkUrl != null) 'artworkUrl': artworkUrl,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MediaMetadata) return false;
    return title == other.title && artist == other.artist && album == other.album && artworkUrl == other.artworkUrl;
  }

  @override
  int get hashCode => Object.hash(title, artist, album, artworkUrl);

  @override
  String toString() => 'MediaMetadata(title: $title, artist: $artist, album: $album, artworkUrl: $artworkUrl)';
}
