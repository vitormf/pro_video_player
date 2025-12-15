/// Logger for test diagnostic output.
///
/// Can be enabled/disabled by setting [isEnabled] to true.
/// Usage:
/// ```dart
/// TestLogger.log('Message');
/// TestLogger.success('✓ File parsed: 10 cues');
/// TestLogger.error('✗ File failed: error message');
/// TestLogger.summary('Summary: 20/20 files passed');
/// ```
///
/// Set [isEnabled] to true to see verbose test output.
mixin TestLogger {
  /// Whether verbose test output is enabled.
  ///
  /// Set to true to enable verbose output for debugging.
  static const bool isEnabled = false;

  /// Logs a message if verbose output is enabled.
  static void log(String message) {
    if (isEnabled) {
      // ignore: avoid_print
      print(message);
    }
  }

  /// Logs a success message (with checkmark).
  static void success(String message) {
    log('✓ $message');
  }

  /// Logs an error message (with X mark).
  static void error(String message) {
    log('✗ $message');
  }

  /// Logs a summary message.
  static void summary(String message) {
    log('\n$message\n');
  }

  /// Logs a section header.
  static void header(String message) {
    log('\n=== $message ===');
  }

  /// Logs a section footer.
  static void footer(String message) {
    log('$message\n');
  }
}

/// Helper class to track parsing results for comprehensive validation tests.
class ParseResult {
  ParseResult({required this.success, required this.cueCount, this.error});

  final bool success;
  final int cueCount;
  final String? error;
}
