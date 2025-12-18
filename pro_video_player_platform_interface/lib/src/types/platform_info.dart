/// Platform information containing static metadata.
///
/// This class provides basic information about the platform and native player
/// that doesn't require async capability checks.
class PlatformInfo {
  /// Creates a [PlatformInfo] instance.
  const PlatformInfo({required this.platformName, required this.nativePlayerType, this.additionalInfo});

  /// The name of the platform (e.g., "iOS", "Android", "Web").
  final String platformName;

  /// The type of native player being used (e.g., "AVPlayer", "ExoPlayer", "HTML5").
  final String nativePlayerType;

  /// Additional platform-specific information as key-value pairs.
  ///
  /// May include:
  /// - OS version
  /// - SDK version
  /// - Browser user agent
  /// - Hardware capabilities
  final Map<String, dynamic>? additionalInfo;

  @override
  String toString() => 'PlatformInfo(platform: $platformName, player: $nativePlayerType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlatformInfo && other.platformName == platformName && other.nativePlayerType == nativePlayerType;
  }

  @override
  int get hashCode => Object.hash(platformName, nativePlayerType);
}
