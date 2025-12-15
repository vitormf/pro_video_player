import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Global verbose logging flag for web video player.
bool isVerboseLoggingEnabled = false;

/// Helper function for verbose logging to browser console.
void verboseLog(String message, {String tag = 'VideoPlayer'}) {
  if (isVerboseLoggingEnabled) {
    web.console.log('[$tag] $message'.toJS);
  }
}
