import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Battery Status API JS interop.
///
/// The Battery Status API provides information about the battery charge level
/// and whether the device is charging. This is used in the fullscreen status bar.
///
/// Browser support:
/// - Chrome/Edge: Supported
/// - Safari: Not supported
/// - Firefox: Deprecated, not recommended
///
/// Note: This API has been deprecated in some browsers due to privacy concerns
/// (fingerprinting). We use it when available but gracefully degrade when not.
///
/// Spec: https://w3c.github.io/battery/

/// Gets the current battery information.
///
/// Returns a Map with 'percentage' (int 0-100) and 'isCharging' (bool),
/// or null if the Battery Status API is not available.
Future<Map<String, dynamic>?> getBatteryInfo(web.Navigator navigator) async {
  try {
    // Return an array from JavaScript so we can access it reliably
    const code = '''
      (async function() {
        try {
          if (!navigator.getBattery) return null;
          const battery = await navigator.getBattery();
          if (!battery) return null;
          // Return as array: [percentage, isCharging]
          return [Math.floor(battery.level * 100), battery.charging];
        } catch (err) {
          return null;
        }
      })()
    ''';

    final promise = _jsEval(code) as JSPromise?;
    if (promise == null) return null;
    final result = await promise.toDart;
    if (result == null) return null;

    // Convert JS array to Dart list
    final jsArray = result as JSArray;
    final percentageJs = jsArray[0];
    final isChargingJs = jsArray[1];
    if (percentageJs == null || isChargingJs == null) return null;

    final percentage = (percentageJs as JSNumber).toDartInt;
    final isCharging = (isChargingJs as JSBoolean).toDart;

    return {'percentage': percentage, 'isCharging': isCharging};
  } catch (e) {
    // Battery API not available
    return null;
  }
}

/// Sets up battery event listeners.
///
/// Calls [onBatteryChange] when battery level or charging state changes.
/// Returns a cleanup function that removes the event listeners.
///
/// Returns null if the Battery Status API is not available.
Future<void Function()?> setupBatteryListeners(
  web.Navigator navigator,
  void Function(Map<String, dynamic>) onBatteryChange,
) async {
  try {
    const code = '''
      (async function() {
        try {
          if (!navigator.getBattery) return null;
          const battery = await navigator.getBattery();
          if (!battery) return null;
          return battery;
        } catch (err) {
          return null;
        }
      })()
    ''';

    final promise = _jsEval(code) as JSPromise?;
    if (promise == null) return null;
    final battery = await promise.toDart;
    if (battery == null) return null;

    // Create event handler that reads battery properties
    final batteryObj = battery as web.EventTarget;
    final handler = ((JSAny? event) {
      // Use eval to read battery properties as an array
      const code = '''
        (function() {
          try {
            const battery = arguments[0];
            return [Math.floor(battery.level * 100), battery.charging];
          } catch (err) {
            return null;
          }
        })
      ''';

      try {
        final fn = _jsEval(code) as JSFunction?;
        if (fn == null) return;

        final result = fn.callAsFunction(null, battery);
        if (result == null) return;

        final jsArray = result as JSArray;
        final percentageJs = jsArray[0];
        final isChargingJs = jsArray[1];
        if (percentageJs == null || isChargingJs == null) return;

        final percentage = (percentageJs as JSNumber).toDartInt;
        final isCharging = (isChargingJs as JSBoolean).toDart;

        onBatteryChange({'percentage': percentage, 'isCharging': isCharging});
      } catch (e) {
        // Ignore errors reading battery state
      }
    }).toJS;

    // Add event listeners
    batteryObj
      ..addEventListener('levelchange', handler)
      ..addEventListener('chargingchange', handler);

    // Return cleanup function
    return () {
      batteryObj
        ..removeEventListener('levelchange', handler)
        ..removeEventListener('chargingchange', handler);
    };
  } catch (e) {
    // Battery API not available
    return null;
  }
}

@JS('eval')
external JSAny? _jsEval(String code);
