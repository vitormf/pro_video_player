/// Represents a video quality/bitrate option for adaptive streams.
///
/// This is used for HLS and DASH streams where multiple quality levels
/// are available and the user can manually select a preferred quality.
///
/// Example:
/// ```dart
/// // A typical 1080p quality track
/// const track = VideoQualityTrack(
///   id: '0:2',
///   bitrate: 5000000,  // 5 Mbps
///   width: 1920,
///   height: 1080,
///   frameRate: 30.0,
/// );
///
/// // Select this quality
/// await controller.setVideoQuality(track);
/// ```
class VideoQualityTrack {
  /// Creates a video quality track.
  const VideoQualityTrack({
    required this.id,
    required this.bitrate,
    required this.width,
    required this.height,
    this.frameRate,
    this.label = '',
    this.isDefault = false,
  });

  /// Creates a [VideoQualityTrack] from a map representation.
  factory VideoQualityTrack.fromMap(Map<String, dynamic> map) => VideoQualityTrack(
    id: map['id'] as String,
    bitrate: map['bitrate'] as int,
    width: map['width'] as int,
    height: map['height'] as int,
    frameRate: map['frameRate'] as double?,
    label: map['label'] as String? ?? '',
    isDefault: map['isDefault'] as bool? ?? false,
  );

  /// Represents automatic quality selection (adaptive bitrate).
  ///
  /// Use this to let the player automatically select the best quality
  /// based on network conditions.
  static const VideoQualityTrack auto = VideoQualityTrack(id: 'auto', bitrate: 0, width: 0, height: 0, label: 'Auto');

  /// Unique identifier for this track.
  ///
  /// Format: "groupIndex:trackIndex" (e.g., "0:1")
  /// For auto quality, the id is "auto".
  final String id;

  /// Bitrate in bits per second.
  ///
  /// For example, 5000000 represents 5 Mbps.
  final int bitrate;

  /// Video width in pixels.
  final int width;

  /// Video height in pixels.
  final int height;

  /// Frame rate in frames per second (optional).
  final double? frameRate;

  /// Human-readable label (e.g., "1080p HD").
  ///
  /// If empty, use [displayLabel] to get an auto-generated label.
  final String label;

  /// Whether this is the default quality track.
  final bool isDefault;

  /// Returns `true` if this represents automatic quality selection.
  bool get isAuto => id == 'auto';

  /// Bitrate in megabits per second.
  double get bitrateInMbps => bitrate / 1000000.0;

  /// Resolution as a formatted string (e.g., "1920x1080").
  String get resolution => '${width}x$height';

  /// Returns `true` if this is HD quality (720p or higher).
  bool get isHD => height >= 720;

  /// Returns `true` if this is 4K quality (2160p or higher).
  bool get is4K => height >= 2160;

  /// Returns a human-readable label for this quality.
  ///
  /// If [label] is set, returns it. Otherwise, generates a label
  /// from the height and bitrate (e.g., "1080p (5.0 Mbps)").
  String get displayLabel {
    if (label.isNotEmpty) return label;
    if (isAuto) return 'Auto';

    final heightLabel = '${height}p';
    final frameRateLabel = frameRate != null ? '${frameRate!.round()}' : '';
    final bitrateLabel = '(${bitrateInMbps.toStringAsFixed(1)} Mbps)';

    if (frameRateLabel.isNotEmpty && frameRate! > 30) {
      return '$heightLabel$frameRateLabel $bitrateLabel';
    }
    return '$heightLabel $bitrateLabel';
  }

  /// Converts this track to a map representation.
  Map<String, dynamic> toMap() => {
    'id': id,
    'bitrate': bitrate,
    'width': width,
    'height': height,
    if (frameRate != null) 'frameRate': frameRate,
    'label': label,
    'isDefault': isDefault,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VideoQualityTrack) return false;
    return id == other.id && bitrate == other.bitrate && width == other.width && height == other.height;
  }

  @override
  int get hashCode => Object.hash(id, bitrate, width, height);

  @override
  String toString() => 'VideoQualityTrack(id: $id, ${width}x$height @ ${bitrateInMbps.toStringAsFixed(1)}Mbps)';
}
