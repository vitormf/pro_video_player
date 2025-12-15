/// Adaptive Bitrate (ABR) selection mode for video streaming.
///
/// Controls whether the player automatically adjusts video quality based on
/// network conditions or allows manual quality selection only.
///
/// ## Platform-Specific Behavior
///
/// **Android (ExoPlayer):**
/// - [auto]: ExoPlayer's adaptive track selection is enabled (default behavior)
/// - [manual]: Auto quality switching is disabled; use `setVideoQuality()` to change
///
/// **iOS/macOS (AVPlayer):**
/// - [auto]: AVPlayer manages quality automatically (default behavior)
/// - [manual]: Not directly supported by AVPlayer. Quality preferences can be set
///   via `setVideoQuality()` but AVPlayer may still adjust based on conditions
///
/// **Web (HLS.js/dash.js):**
/// - [auto]: Adaptive bitrate switching enabled
/// - [manual]: Auto switching disabled; use `setVideoQuality()` to change
///
/// ## Usage Guidelines
///
/// - **[auto]** (default): Best for most use cases. The player optimizes quality
///   based on available bandwidth and device capabilities.
/// - **[manual]**: Use when you want users to explicitly choose quality, or when
///   you need consistent quality regardless of network conditions.
///
/// ## Example
///
/// ```dart
/// // Auto quality selection with bitrate constraints
/// const options = VideoPlayerOptions(
///   abrMode: AbrMode.auto,
///   minBitrate: 500000,  // At least 500 kbps
///   maxBitrate: 5000000, // At most 5 Mbps
/// );
///
/// // Manual quality selection only
/// const manualOptions = VideoPlayerOptions(
///   abrMode: AbrMode.manual,
/// );
/// ```
enum AbrMode {
  /// Automatic quality selection based on network conditions.
  ///
  /// The player will automatically switch between quality levels to optimize
  /// playback smoothness while maximizing video quality for the available
  /// bandwidth.
  ///
  /// This is the default mode and recommended for most use cases.
  auto,

  /// Manual quality selection only.
  ///
  /// The player will not automatically switch quality levels. Use
  /// `setVideoQuality()` to change the quality manually.
  ///
  /// Note: On iOS/macOS (AVPlayer), this mode sets quality preferences but
  /// AVPlayer may still adjust quality in extreme network conditions.
  manual,
}
