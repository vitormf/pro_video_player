import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Screen Wake Lock API JS interop.
///
/// The Screen Wake Lock API prevents the screen from turning off while video
/// is playing. This provides a better user experience by keeping the video
/// visible without requiring manual interaction.
///
/// Browser support:
/// - Chrome/Edge 84+
/// - Safari 16.4+
/// - Firefox: Not supported (as of 2025)
///
/// Spec: https://w3c.github.io/screen-wake-lock/

/// Requests a screen wake lock.
///
/// Returns a JSObject representing the WakeLockSentinel, or null if the
/// request failed or the API is not available.
///
/// The wake lock automatically releases when:
/// - The document becomes hidden (user switches tabs)
/// - The device battery is low
/// - release() is called on the sentinel
///
/// If the wake lock is released automatically, you need to request it again
/// when the document becomes visible.
Future<JSObject?> requestWakeLock(web.Navigator navigator) async {
  try {
    // Use eval to call the async wakeLock.request() method
    // The API will throw if not supported, which we catch and return null
    const code = '''
      (async function() {
        try {
          if (!navigator.wakeLock) return null;
          return await navigator.wakeLock.request('screen');
        } catch (err) {
          return null;
        }
      })()
    ''';

    final promise = _jsEval(code) as JSPromise?;
    if (promise == null) return null;
    final result = await promise.toDart;
    return result as JSObject?;
  } catch (e) {
    // Silently fail - wake lock is a nice-to-have feature
    return null;
  }
}

/// Releases a wake lock.
///
/// [sentinel] is the WakeLockSentinel object returned by requestWakeLock().
Future<void> releaseWakeLock(JSObject? sentinel) async {
  if (sentinel == null) return;

  try {
    // Call release() method on the sentinel
    const code = '''
      (async function(sentinel) {
        try {
          if (sentinel && typeof sentinel.release === 'function') {
            await sentinel.release();
          }
        } catch (err) {
          // Silently fail
        }
      })
    ''';

    final releaseFunc = _jsEval(code)! as JSFunction;
    final promise = releaseFunc.callAsFunction(releaseFunc, sentinel)! as JSPromise;
    await promise.toDart;
  } catch (e) {
    // Silently fail
  }
}

@JS('eval')
external JSAny? _jsEval(String code);
