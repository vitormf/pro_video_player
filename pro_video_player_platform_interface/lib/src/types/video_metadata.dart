import 'media_metadata.dart' show MediaMetadata;

/// Technical metadata extracted from a video file or stream.
///
/// This contains information about the video's encoding, resolution, bitrate,
/// and other technical details. This is different from [MediaMetadata], which
/// contains display metadata (title, artist) for media controls.
///
/// Video metadata is automatically extracted when a video is loaded and can
/// be accessed via the controller's `videoMetadata` property.
///
/// Example:
/// ```dart
/// // Access metadata after video is loaded
/// final metadata = controller.videoMetadata;
/// if (metadata != null) {
///   print('Codec: ${metadata.videoCodec}');
///   print('Resolution: ${metadata.resolution}');
///   print('Frame rate: ${metadata.frameRate} fps');
/// }
/// ```
class VideoMetadata {
  /// Creates video metadata with optional fields.
  ///
  /// All fields are optional since not all platforms can extract all metadata.
  const VideoMetadata({
    this.videoCodec,
    this.audioCodec,
    this.width,
    this.height,
    this.videoBitrate,
    this.audioBitrate,
    this.frameRate,
    this.duration,
    this.containerFormat,
  });

  /// Creates a [VideoMetadata] from a map representation.
  ///
  /// Used for deserializing metadata from platform channels.
  factory VideoMetadata.fromMap(Map<String, dynamic> map) => VideoMetadata(
    videoCodec: map['videoCodec'] as String?,
    audioCodec: map['audioCodec'] as String?,
    width: map['width'] as int?,
    height: map['height'] as int?,
    videoBitrate: map['videoBitrate'] as int?,
    audioBitrate: map['audioBitrate'] as int?,
    frameRate: (map['frameRate'] as num?)?.toDouble(),
    duration: map['durationMs'] != null ? Duration(milliseconds: map['durationMs'] as int) : null,
    containerFormat: map['containerFormat'] as String?,
  );

  /// An empty metadata instance with all fields set to null.
  static const VideoMetadata empty = VideoMetadata();

  /// The video codec (e.g., "h264", "hevc", "vp9", "av1").
  final String? videoCodec;

  /// The audio codec (e.g., "aac", "mp3", "opus", "ac3").
  final String? audioCodec;

  /// The video width in pixels.
  final int? width;

  /// The video height in pixels.
  final int? height;

  /// The video bitrate in bits per second.
  final int? videoBitrate;

  /// The audio bitrate in bits per second.
  final int? audioBitrate;

  /// The frame rate in frames per second (e.g., 29.97, 30.0, 60.0).
  final double? frameRate;

  /// The total duration of the video.
  final Duration? duration;

  /// The container format (e.g., "mp4", "mkv", "webm", "hls").
  final String? containerFormat;

  /// Returns `true` if all metadata fields are null.
  bool get isEmpty =>
      videoCodec == null &&
      audioCodec == null &&
      width == null &&
      height == null &&
      videoBitrate == null &&
      audioBitrate == null &&
      frameRate == null &&
      duration == null &&
      containerFormat == null;

  /// Returns `true` if any metadata field is set.
  bool get isNotEmpty => !isEmpty;

  /// The total bitrate (video + audio) in bits per second.
  ///
  /// Returns `null` if either bitrate is not available.
  int? get totalBitrate {
    if (videoBitrate == null || audioBitrate == null) return null;
    return videoBitrate! + audioBitrate!;
  }

  /// The aspect ratio (width / height).
  ///
  /// Returns `null` if dimensions are not available or height is zero.
  double? get aspectRatio {
    if (width == null || height == null || height == 0) return null;
    return width! / height!;
  }

  /// The resolution as a formatted string (e.g., "1920x1080").
  ///
  /// Returns `null` if dimensions are not available.
  String? get resolution {
    if (width == null || height == null) return null;
    return '${width}x$height';
  }

  /// Returns `true` if the video is HD quality (720p or higher).
  bool get isHD => height != null && height! >= 720;

  /// Returns `true` if the video is 4K quality (2160p or higher).
  bool get is4K => height != null && height! >= 2160;

  /// The video bitrate in megabits per second.
  ///
  /// Returns `null` if video bitrate is not available.
  double? get videoBitrateInMbps {
    if (videoBitrate == null) return null;
    return videoBitrate! / 1000000.0;
  }

  /// The audio bitrate in kilobits per second.
  ///
  /// Returns `null` if audio bitrate is not available.
  double? get audioBitrateInKbps {
    if (audioBitrate == null) return null;
    return audioBitrate! / 1000.0;
  }

  /// Creates a copy of this metadata with the given fields replaced.
  VideoMetadata copyWith({
    String? videoCodec,
    String? audioCodec,
    int? width,
    int? height,
    int? videoBitrate,
    int? audioBitrate,
    double? frameRate,
    Duration? duration,
    String? containerFormat,
  }) => VideoMetadata(
    videoCodec: videoCodec ?? this.videoCodec,
    audioCodec: audioCodec ?? this.audioCodec,
    width: width ?? this.width,
    height: height ?? this.height,
    videoBitrate: videoBitrate ?? this.videoBitrate,
    audioBitrate: audioBitrate ?? this.audioBitrate,
    frameRate: frameRate ?? this.frameRate,
    duration: duration ?? this.duration,
    containerFormat: containerFormat ?? this.containerFormat,
  );

  /// Converts this metadata to a map representation.
  ///
  /// Only includes non-null fields to minimize data transfer.
  Map<String, dynamic> toMap() => <String, dynamic>{
    if (videoCodec != null) 'videoCodec': videoCodec,
    if (audioCodec != null) 'audioCodec': audioCodec,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (videoBitrate != null) 'videoBitrate': videoBitrate,
    if (audioBitrate != null) 'audioBitrate': audioBitrate,
    if (frameRate != null) 'frameRate': frameRate,
    if (duration != null) 'durationMs': duration!.inMilliseconds,
    if (containerFormat != null) 'containerFormat': containerFormat,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VideoMetadata) return false;
    return videoCodec == other.videoCodec &&
        audioCodec == other.audioCodec &&
        width == other.width &&
        height == other.height &&
        videoBitrate == other.videoBitrate &&
        audioBitrate == other.audioBitrate &&
        frameRate == other.frameRate &&
        duration == other.duration &&
        containerFormat == other.containerFormat;
  }

  @override
  int get hashCode => Object.hash(
    videoCodec,
    audioCodec,
    width,
    height,
    videoBitrate,
    audioBitrate,
    frameRate,
    duration,
    containerFormat,
  );

  @override
  String toString() =>
      'VideoMetadata('
      'videoCodec: $videoCodec, '
      'audioCodec: $audioCodec, '
      'width: $width, '
      'height: $height, '
      'videoBitrate: $videoBitrate, '
      'audioBitrate: $audioBitrate, '
      'frameRate: $frameRate, '
      'duration: $duration, '
      'containerFormat: $containerFormat)';
}
