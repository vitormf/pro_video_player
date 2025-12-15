import 'package:flutter/foundation.dart';

import 'pro_video_player_platform.dart';

/// Logger for the pro video player.
///
/// Provides verbose logging capabilities that can be enabled for debugging purposes.
class ProVideoPlayerLogger {
  ProVideoPlayerLogger._();

  static bool _verboseLoggingEnabled = false;

  /// Whether verbose logging is currently enabled.
  static bool get isVerboseLoggingEnabled => _verboseLoggingEnabled;

  /// Enables or disables verbose logging for the pro video player.
  ///
  /// When enabled, detailed logs will be printed to help debug issues.
  /// This affects both Dart-side and native platform code logging.
  ///
  /// Verbose logging is disabled by default for performance reasons.
  ///
  /// Example:
  /// ```dart
  /// ProVideoPlayerLogger.setVerboseLogging(enabled: true);
  /// ```
  static Future<void> setVerboseLogging({required bool enabled}) async {
    _verboseLoggingEnabled = enabled;
    if (enabled) {
      log('Verbose logging enabled for ProVideoPlayer');
    }

    // Propagate to native platforms via method channel
    try {
      await ProVideoPlayerPlatform.instance.setVerboseLogging(enabled: enabled);
    } catch (e) {
      // Silently catch errors as some platforms might not implement this yet
      debugPrint('[ProVideoPlayer] Note: Platform does not support setVerboseLogging: $e');
    }
  }

  /// Logs a verbose message if verbose logging is enabled.
  ///
  /// Messages are only printed when [isVerboseLoggingEnabled] is true.
  static void log(String message, {String? tag}) {
    if (_verboseLoggingEnabled) {
      final prefix = tag != null ? '[$tag]' : '[ProVideoPlayer]';
      debugPrint('$prefix $message');
    }
  }

  /// Logs an error message regardless of verbose logging setting.
  ///
  /// Error messages are always printed to help identify issues.
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final prefix = tag != null ? '[$tag]' : '[ProVideoPlayer]';
    debugPrint('$prefix ERROR: $message');
    if (error != null) {
      debugPrint('$prefix Error details: $error');
    }
    if (stackTrace != null && _verboseLoggingEnabled) {
      debugPrint('$prefix Stack trace:\n$stackTrace');
    }
  }
}
