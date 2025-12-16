/// Platform-specific feature capabilities reported by native implementations.
///
/// This class provides information about which features are supported on the
/// current platform, allowing the Dart layer to adapt UI and functionality
/// accordingly.
///
/// Each capability property indicates whether a specific feature is available
/// on the native platform. Features may be unavailable due to:
/// - Platform limitations (e.g., Web doesn't support background playback)
/// - Missing native dependencies (e.g., Chromecast SDK not integrated)
/// - Runtime conditions (e.g., PiP disabled in system settings)
///
/// Example usage:
/// ```dart
/// final capabilities = await controller.getPlatformCapabilities();
///
/// // Only show cast button if casting is supported
/// if (capabilities.supportsCasting) {
///   CastButton(controller: controller);
/// }
///
/// // Adapt UI based on available features
/// if (!capabilities.supportsBackgroundPlayback) {
///   showWarning('Background playback not available on this platform');
/// }
/// ```
class PlatformCapabilities {
  /// Creates a [PlatformCapabilities] instance.
  const PlatformCapabilities({
    required this.supportsPictureInPicture,
    required this.supportsFullscreen,
    required this.supportsBackgroundPlayback,
    required this.supportsCasting,
    required this.supportsAirPlay,
    required this.supportsChromecast,
    required this.supportsRemotePlayback,
    required this.supportsQualitySelection,
    required this.supportsPlaybackSpeedControl,
    required this.supportsSubtitles,
    required this.supportsExternalSubtitles,
    required this.supportsAudioTrackSelection,
    required this.supportsChapters,
    required this.supportsVideoMetadataExtraction,
    required this.supportsNetworkMonitoring,
    required this.supportsBandwidthEstimation,
    required this.supportsAdaptiveBitrate,
    required this.supportsHLS,
    required this.supportsDASH,
    required this.supportsDeviceVolumeControl,
    required this.supportsScreenBrightnessControl,
    this.platformName,
    this.nativePlayerType,
    this.additionalInfo,
  });

  /// Creates a [PlatformCapabilities] from a map.
  factory PlatformCapabilities.fromMap(Map<dynamic, dynamic> map) => PlatformCapabilities(
    supportsPictureInPicture: map['supportsPictureInPicture'] as bool? ?? false,
    supportsFullscreen: map['supportsFullscreen'] as bool? ?? false,
    supportsBackgroundPlayback: map['supportsBackgroundPlayback'] as bool? ?? false,
    supportsCasting: map['supportsCasting'] as bool? ?? false,
    supportsAirPlay: map['supportsAirPlay'] as bool? ?? false,
    supportsChromecast: map['supportsChromecast'] as bool? ?? false,
    supportsRemotePlayback: map['supportsRemotePlayback'] as bool? ?? false,
    supportsQualitySelection: map['supportsQualitySelection'] as bool? ?? false,
    supportsPlaybackSpeedControl: map['supportsPlaybackSpeedControl'] as bool? ?? false,
    supportsSubtitles: map['supportsSubtitles'] as bool? ?? false,
    supportsExternalSubtitles: map['supportsExternalSubtitles'] as bool? ?? false,
    supportsAudioTrackSelection: map['supportsAudioTrackSelection'] as bool? ?? false,
    supportsChapters: map['supportsChapters'] as bool? ?? false,
    supportsVideoMetadataExtraction: map['supportsVideoMetadataExtraction'] as bool? ?? false,
    supportsNetworkMonitoring: map['supportsNetworkMonitoring'] as bool? ?? false,
    supportsBandwidthEstimation: map['supportsBandwidthEstimation'] as bool? ?? false,
    supportsAdaptiveBitrate: map['supportsAdaptiveBitrate'] as bool? ?? false,
    supportsHLS: map['supportsHLS'] as bool? ?? false,
    supportsDASH: map['supportsDASH'] as bool? ?? false,
    supportsDeviceVolumeControl: map['supportsDeviceVolumeControl'] as bool? ?? false,
    supportsScreenBrightnessControl: map['supportsScreenBrightnessControl'] as bool? ?? false,
    platformName: map['platformName'] as String?,
    nativePlayerType: map['nativePlayerType'] as String?,
    additionalInfo: map['additionalInfo'] as Map<String, dynamic>?,
  );

  /// Creates desktop platform capabilities (Linux/Windows placeholder).
  ///
  /// This factory provides common capabilities for desktop platforms (Linux/Windows)
  /// that haven't yet implemented full native player functionality.
  ///
  /// Currently all advanced features are disabled as placeholders, with only
  /// playback speed control supported as it's available in both GStreamer and
  /// Media Foundation.
  factory PlatformCapabilities.desktop({required String platformName, required String nativePlayerType}) =>
      PlatformCapabilities(
        supportsPictureInPicture: false, // Not implemented yet
        supportsFullscreen: false, // Not implemented yet
        supportsBackgroundPlayback: false, // Not implemented yet
        supportsCasting: false, // Could support DLNA/UPnP in future
        supportsAirPlay: false, // AirPlay is iOS/macOS only
        supportsChromecast: false, // Android only
        supportsRemotePlayback: false, // Web only
        supportsQualitySelection: false, // Not implemented yet
        supportsPlaybackSpeedControl: true, // GStreamer/Media Foundation supports this
        supportsSubtitles: false, // Not implemented yet
        supportsExternalSubtitles: false, // Not implemented yet
        supportsAudioTrackSelection: false, // Not implemented yet
        supportsChapters: false, // Not implemented yet
        supportsVideoMetadataExtraction: false, // Not implemented yet
        supportsNetworkMonitoring: false, // Not implemented yet
        supportsBandwidthEstimation: false, // Not implemented yet
        supportsAdaptiveBitrate: false, // Not implemented yet
        supportsHLS: false, // Not implemented yet
        supportsDASH: false, // Not implemented yet
        supportsDeviceVolumeControl: false, // Not implemented yet
        supportsScreenBrightnessControl: false, // Not supported on desktop
        platformName: platformName,
        nativePlayerType: nativePlayerType,
      );

  // ==================== Core Playback Features ====================

  /// Whether Picture-in-Picture mode is supported.
  ///
  /// - **iOS**: Always `true` (AVPictureInPictureController)
  /// - **Android**: `true` if Android 8.0+ (PictureInPictureParams)
  /// - **macOS**: Always `true` (AVPictureInPictureController)
  /// - **Web**: `true` if browser supports Picture-in-Picture API
  /// - **Windows/Linux**: Always `false`
  final bool supportsPictureInPicture;

  /// Whether fullscreen mode is supported.
  ///
  /// - **iOS**: Always `true` (UIWindowScene)
  /// - **Android**: Always `true` (immersive mode)
  /// - **macOS**: Always `true` (NSWindow fullscreen)
  /// - **Web**: `true` if browser supports Fullscreen API
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsFullscreen;

  /// Whether background audio playback is supported.
  ///
  /// - **iOS**: `true` if UIBackgroundModes configured in Info.plist
  /// - **Android**: Always `true` (MediaSession)
  /// - **macOS**: Always `true`
  /// - **Web/Windows/Linux**: Always `false`
  final bool supportsBackgroundPlayback;

  // ==================== Casting Features ====================

  /// Whether any form of casting is supported on this platform.
  ///
  /// This is a convenience property that returns `true` if any of:
  /// - [supportsAirPlay]
  /// - [supportsChromecast]
  /// - [supportsRemotePlayback]
  ///
  /// is `true`.
  final bool supportsCasting;

  /// Whether AirPlay casting is supported.
  ///
  /// - **iOS**: Always `true` (AVRoutePickerView)
  /// - **macOS**: Always `true` (AVRoutePickerView)
  /// - **Android/Web/Windows/Linux**: Always `false`
  final bool supportsAirPlay;

  /// Whether Chromecast is supported.
  ///
  /// - **Android**: `true` if Google Cast SDK is integrated
  /// - **iOS**: `true` if Google Cast SDK is integrated (future)
  /// - **macOS/Web/Windows/Linux**: Always `false`
  final bool supportsChromecast;

  /// Whether Remote Playback API (Web casting) is supported.
  ///
  /// - **Web**: `true` if browser supports Remote Playback API
  /// - **iOS/Android/macOS/Windows/Linux**: Always `false`
  final bool supportsRemotePlayback;

  // ==================== Media Track Features ====================

  /// Whether video quality/bitrate selection is supported.
  ///
  /// - **iOS**: Always `true` for HLS streams (AVPlayerItemAccessLog)
  /// - **Android**: Always `true` for HLS/DASH streams (ExoPlayer TrackSelector)
  /// - **macOS**: Always `true` for HLS streams (AVPlayerItemAccessLog)
  /// - **Web**: `true` for HLS/DASH with media library support
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsQualitySelection;

  /// Whether playback speed control is supported.
  ///
  /// - **iOS/Android/macOS/Web**: Always `true`
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsPlaybackSpeedControl;

  /// Whether embedded subtitle track selection is supported.
  ///
  /// - **iOS**: Always `true` (AVMediaSelectionGroup)
  /// - **Android**: Always `true` (ExoPlayer TextRenderer)
  /// - **macOS**: Always `true` (AVMediaSelectionGroup)
  /// - **Web**: `true` if video has TextTrack support
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsSubtitles;

  /// Whether external subtitle file loading is supported.
  ///
  /// - **iOS/Android/macOS/Web**: Always `true`
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsExternalSubtitles;

  /// Whether audio track selection is supported.
  ///
  /// - **iOS**: Always `true` (AVMediaSelectionGroup)
  /// - **Android**: Always `true` (ExoPlayer AudioRenderer)
  /// - **macOS**: Always `true` (AVMediaSelectionGroup)
  /// - **Web**: `true` if video has AudioTrack support
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsAudioTrackSelection;

  /// Whether chapter markers are supported.
  ///
  /// - **iOS**: Always `true` (AVTimedMetadataGroup)
  /// - **Android**: Always `true` (ExoPlayer Timeline)
  /// - **macOS**: Always `true` (AVTimedMetadataGroup)
  /// - **Web**: Limited (custom implementation)
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsChapters;

  // ==================== Metadata & Diagnostics ====================

  /// Whether video metadata extraction is supported.
  ///
  /// This includes extracting codec, resolution, bitrate, frame rate, etc.
  ///
  /// - **iOS**: Always `true` (AVAssetTrack)
  /// - **Android**: Always `true` (ExoPlayer Format)
  /// - **macOS**: Always `true` (AVAssetTrack)
  /// - **Web**: Limited (MediaSource API)
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsVideoMetadataExtraction;

  /// Whether network connectivity monitoring is supported.
  ///
  /// - **iOS**: Always `true` (NWPathMonitor)
  /// - **Android**: Always `true` (ConnectivityManager)
  /// - **macOS**: Always `true` (NWPathMonitor)
  /// - **Web**: `true` (Navigator.connection)
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsNetworkMonitoring;

  /// Whether bandwidth estimation is supported.
  ///
  /// - **iOS**: Always `true` (AVPlayerItemAccessLog)
  /// - **Android**: Always `true` (ExoPlayer BandwidthMeter)
  /// - **macOS**: Always `true` (AVPlayerItemAccessLog)
  /// - **Web**: Limited
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsBandwidthEstimation;

  // ==================== Streaming Format Features ====================

  /// Whether adaptive bitrate configuration is supported.
  ///
  /// This allows setting min/max bitrate constraints for ABR streams.
  ///
  /// - **iOS**: Partial (maxBitrate only via AVPlayer)
  /// - **Android**: Always `true` (ExoPlayer TrackSelector)
  /// - **macOS**: Partial (maxBitrate only via AVPlayer)
  /// - **Web**: Limited
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsAdaptiveBitrate;

  /// Whether HLS (HTTP Live Streaming) is supported.
  ///
  /// - **iOS/macOS**: Always `true` (native AVPlayer support)
  /// - **Android**: Always `true` (ExoPlayer HlsMediaSource)
  /// - **Web**: `true` if browser has native HLS or hls.js loaded
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsHLS;

  /// Whether DASH (Dynamic Adaptive Streaming over HTTP) is supported.
  ///
  /// - **iOS/macOS**: Always `false` (AVPlayer doesn't support DASH)
  /// - **Android**: Always `true` (ExoPlayer DashMediaSource)
  /// - **Web**: `true` if dash.js library is loaded
  /// - **Windows/Linux**: Implementation dependent
  final bool supportsDASH;

  // ==================== System Integration ====================

  /// Whether device volume control is supported.
  ///
  /// - **iOS/Android/macOS**: Always `true`
  /// - **Web/Windows/Linux**: Implementation dependent
  final bool supportsDeviceVolumeControl;

  /// Whether screen brightness control is supported.
  ///
  /// - **iOS/Android**: Always `true`
  /// - **macOS/Web/Windows/Linux**: Always `false`
  final bool supportsScreenBrightnessControl;

  // ==================== Platform Information ====================

  /// The name of the platform (e.g., "iOS", "Android", "Web").
  ///
  /// This is informational and helps with debugging. May be `null` on some
  /// implementations.
  final String? platformName;

  /// The type of native player being used (e.g., "AVPlayer", "ExoPlayer", "HTML5").
  ///
  /// This is informational and helps with debugging. May be `null` on some
  /// implementations.
  final String? nativePlayerType;

  /// Additional platform-specific information as key-value pairs.
  ///
  /// This can include:
  /// - OS version
  /// - Player library version
  /// - Hardware codec support
  /// - DRM capabilities
  /// - etc.
  final Map<String, dynamic>? additionalInfo;

  /// Creates a copy of this [PlatformCapabilities] with the given fields replaced.
  PlatformCapabilities copyWith({
    bool? supportsPictureInPicture,
    bool? supportsFullscreen,
    bool? supportsBackgroundPlayback,
    bool? supportsCasting,
    bool? supportsAirPlay,
    bool? supportsChromecast,
    bool? supportsRemotePlayback,
    bool? supportsQualitySelection,
    bool? supportsPlaybackSpeedControl,
    bool? supportsSubtitles,
    bool? supportsExternalSubtitles,
    bool? supportsAudioTrackSelection,
    bool? supportsChapters,
    bool? supportsVideoMetadataExtraction,
    bool? supportsNetworkMonitoring,
    bool? supportsBandwidthEstimation,
    bool? supportsAdaptiveBitrate,
    bool? supportsHLS,
    bool? supportsDASH,
    bool? supportsDeviceVolumeControl,
    bool? supportsScreenBrightnessControl,
    String? platformName,
    String? nativePlayerType,
    Map<String, dynamic>? additionalInfo,
  }) => PlatformCapabilities(
    supportsPictureInPicture: supportsPictureInPicture ?? this.supportsPictureInPicture,
    supportsFullscreen: supportsFullscreen ?? this.supportsFullscreen,
    supportsBackgroundPlayback: supportsBackgroundPlayback ?? this.supportsBackgroundPlayback,
    supportsCasting: supportsCasting ?? this.supportsCasting,
    supportsAirPlay: supportsAirPlay ?? this.supportsAirPlay,
    supportsChromecast: supportsChromecast ?? this.supportsChromecast,
    supportsRemotePlayback: supportsRemotePlayback ?? this.supportsRemotePlayback,
    supportsQualitySelection: supportsQualitySelection ?? this.supportsQualitySelection,
    supportsPlaybackSpeedControl: supportsPlaybackSpeedControl ?? this.supportsPlaybackSpeedControl,
    supportsSubtitles: supportsSubtitles ?? this.supportsSubtitles,
    supportsExternalSubtitles: supportsExternalSubtitles ?? this.supportsExternalSubtitles,
    supportsAudioTrackSelection: supportsAudioTrackSelection ?? this.supportsAudioTrackSelection,
    supportsChapters: supportsChapters ?? this.supportsChapters,
    supportsVideoMetadataExtraction: supportsVideoMetadataExtraction ?? this.supportsVideoMetadataExtraction,
    supportsNetworkMonitoring: supportsNetworkMonitoring ?? this.supportsNetworkMonitoring,
    supportsBandwidthEstimation: supportsBandwidthEstimation ?? this.supportsBandwidthEstimation,
    supportsAdaptiveBitrate: supportsAdaptiveBitrate ?? this.supportsAdaptiveBitrate,
    supportsHLS: supportsHLS ?? this.supportsHLS,
    supportsDASH: supportsDASH ?? this.supportsDASH,
    supportsDeviceVolumeControl: supportsDeviceVolumeControl ?? this.supportsDeviceVolumeControl,
    supportsScreenBrightnessControl: supportsScreenBrightnessControl ?? this.supportsScreenBrightnessControl,
    platformName: platformName ?? this.platformName,
    nativePlayerType: nativePlayerType ?? this.nativePlayerType,
    additionalInfo: additionalInfo ?? this.additionalInfo,
  );

  /// Converts this [PlatformCapabilities] to a map for serialization.
  Map<String, dynamic> toMap() => {
    'supportsPictureInPicture': supportsPictureInPicture,
    'supportsFullscreen': supportsFullscreen,
    'supportsBackgroundPlayback': supportsBackgroundPlayback,
    'supportsCasting': supportsCasting,
    'supportsAirPlay': supportsAirPlay,
    'supportsChromecast': supportsChromecast,
    'supportsRemotePlayback': supportsRemotePlayback,
    'supportsQualitySelection': supportsQualitySelection,
    'supportsPlaybackSpeedControl': supportsPlaybackSpeedControl,
    'supportsSubtitles': supportsSubtitles,
    'supportsExternalSubtitles': supportsExternalSubtitles,
    'supportsAudioTrackSelection': supportsAudioTrackSelection,
    'supportsChapters': supportsChapters,
    'supportsVideoMetadataExtraction': supportsVideoMetadataExtraction,
    'supportsNetworkMonitoring': supportsNetworkMonitoring,
    'supportsBandwidthEstimation': supportsBandwidthEstimation,
    'supportsAdaptiveBitrate': supportsAdaptiveBitrate,
    'supportsHLS': supportsHLS,
    'supportsDASH': supportsDASH,
    'supportsDeviceVolumeControl': supportsDeviceVolumeControl,
    'supportsScreenBrightnessControl': supportsScreenBrightnessControl,
    'platformName': platformName,
    'nativePlayerType': nativePlayerType,
    'additionalInfo': additionalInfo,
  };

  @override
  String toString() =>
      'PlatformCapabilities('
      'platform: $platformName, '
      'player: $nativePlayerType, '
      'pip: $supportsPictureInPicture, '
      'fullscreen: $supportsFullscreen, '
      'background: $supportsBackgroundPlayback, '
      'casting: $supportsCasting, '
      'airplay: $supportsAirPlay, '
      'chromecast: $supportsChromecast, '
      'quality: $supportsQualitySelection, '
      'HLS: $supportsHLS, '
      'DASH: $supportsDASH'
      ')';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlatformCapabilities &&
        other.supportsPictureInPicture == supportsPictureInPicture &&
        other.supportsFullscreen == supportsFullscreen &&
        other.supportsBackgroundPlayback == supportsBackgroundPlayback &&
        other.supportsCasting == supportsCasting &&
        other.supportsAirPlay == supportsAirPlay &&
        other.supportsChromecast == supportsChromecast &&
        other.supportsRemotePlayback == supportsRemotePlayback &&
        other.supportsQualitySelection == supportsQualitySelection &&
        other.supportsPlaybackSpeedControl == supportsPlaybackSpeedControl &&
        other.supportsSubtitles == supportsSubtitles &&
        other.supportsExternalSubtitles == supportsExternalSubtitles &&
        other.supportsAudioTrackSelection == supportsAudioTrackSelection &&
        other.supportsChapters == supportsChapters &&
        other.supportsVideoMetadataExtraction == supportsVideoMetadataExtraction &&
        other.supportsNetworkMonitoring == supportsNetworkMonitoring &&
        other.supportsBandwidthEstimation == supportsBandwidthEstimation &&
        other.supportsAdaptiveBitrate == supportsAdaptiveBitrate &&
        other.supportsHLS == supportsHLS &&
        other.supportsDASH == supportsDASH &&
        other.supportsDeviceVolumeControl == supportsDeviceVolumeControl &&
        other.supportsScreenBrightnessControl == supportsScreenBrightnessControl &&
        other.platformName == platformName &&
        other.nativePlayerType == nativePlayerType;
  }

  @override
  int get hashCode => Object.hashAll([
    supportsPictureInPicture,
    supportsFullscreen,
    supportsBackgroundPlayback,
    supportsCasting,
    supportsAirPlay,
    supportsChromecast,
    supportsRemotePlayback,
    supportsQualitySelection,
    supportsPlaybackSpeedControl,
    supportsSubtitles,
    supportsExternalSubtitles,
    supportsAudioTrackSelection,
    supportsChapters,
    supportsVideoMetadataExtraction,
    supportsNetworkMonitoring,
    supportsBandwidthEstimation,
    supportsAdaptiveBitrate,
    supportsHLS,
    supportsDASH,
    supportsDeviceVolumeControl,
    supportsScreenBrightnessControl,
    platformName,
    nativePlayerType,
  ]);
}
