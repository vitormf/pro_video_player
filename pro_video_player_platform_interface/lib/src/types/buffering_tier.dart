/// Buffering tier that controls how much video content is buffered ahead.
///
/// Different tiers provide different trade-offs between memory usage,
/// startup time, and playback smoothness. Platform implementations map
/// these tiers to platform-specific buffer configurations.
///
/// ## Platform-Specific Behavior
///
/// **Android (ExoPlayer):**
/// Tiers map to `DefaultLoadControl` buffer durations:
/// - [min]: Minimal buffers (~500ms min, ~2s max)
/// - [low]: Light buffers (~1s min, ~5s max)
/// - [medium]: Balanced buffers (~2.5s min, ~15s max) - default
/// - [high]: Heavy buffers (~5s min, ~30s max)
/// - [max]: Maximum buffers (~10s min, ~60s max)
///
/// **iOS/macOS (AVPlayer):**
/// Tiers map to `preferredForwardBufferDuration`:
/// - [min]: ~2 seconds
/// - [low]: ~5 seconds
/// - [medium]: ~0 (automatic, system decides) - default
/// - [high]: ~30 seconds
/// - [max]: ~60 seconds
///
/// **Web (HTML5 Video):**
/// Limited control via `preload` attribute:
/// - [min], [low]: `metadata` preload
/// - [medium], [high], [max]: `auto` preload (browser decides)
///
/// ## Usage Guidelines
///
/// - **[min]**: Use for bandwidth-constrained scenarios or when memory is limited
/// - **[low]**: Use for fast networks where quick startup is preferred
/// - **[medium]**: Default choice, works well for most scenarios
/// - **[high]**: Use for unreliable networks to reduce rebuffering
/// - **[max]**: Use for offline-first or extreme network conditions
enum BufferingTier {
  /// Minimal buffering for lowest memory footprint.
  ///
  /// Best for: bandwidth-constrained scenarios, limited memory devices.
  /// Trade-off: May cause more rebuffering on slower networks.
  min,

  /// Light buffering for quick startup.
  ///
  /// Best for: fast, reliable networks where responsiveness is prioritized.
  /// Trade-off: Less buffer safety margin for network fluctuations.
  low,

  /// Balanced buffering for most use cases.
  ///
  /// Best for: general use, provides good balance of startup time and smoothness.
  /// This is the default tier.
  medium,

  /// Heavy buffering for improved playback smoothness.
  ///
  /// Best for: unreliable networks, streaming long-form content.
  /// Trade-off: Higher memory usage, longer initial load time.
  high,

  /// Maximum buffering for extreme conditions.
  ///
  /// Best for: very unreliable networks, offline-first scenarios.
  /// Trade-off: Highest memory usage, longest initial load time.
  max,
}
