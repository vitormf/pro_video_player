import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../wake_lock_interop.dart' as wake_lock;

/// Interface for Screen Wake Lock API.
///
/// Abstracts the browser Screen Wake Lock API to allow for testing without
/// actual browser APIs. The Screen Wake Lock API prevents the screen from
/// turning off while video is playing.
abstract interface class WakeLockInterface {
  /// Whether the Wake Lock API is available.
  bool get isAvailable;

  /// Requests a wake lock. Returns true if successful.
  Future<bool> request();

  /// Releases the wake lock.
  Future<void> release();
}

/// Browser implementation of [WakeLockInterface].
///
/// Wraps the real Screen Wake Lock API via JS interop.
class BrowserWakeLock implements WakeLockInterface {
  /// Creates a browser wake lock wrapper.
  BrowserWakeLock({required web.Navigator navigator}) : _navigator = navigator;

  final web.Navigator _navigator;
  JSObject? _wakeLockSentinel;

  // Wake lock availability is checked during request() which handles errors gracefully.
  // We return true here since the actual availability check requires async JS interop.
  // If the API is unavailable, request() will return false.
  @override
  bool get isAvailable => true;

  @override
  Future<bool> request() async {
    try {
      _wakeLockSentinel = await wake_lock.requestWakeLock(_navigator);
      return _wakeLockSentinel != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> release() async {
    if (_wakeLockSentinel == null) return;

    try {
      await wake_lock.releaseWakeLock(_wakeLockSentinel);
    } catch (_) {
      // Silently fail
    } finally {
      _wakeLockSentinel = null;
    }
  }
}
