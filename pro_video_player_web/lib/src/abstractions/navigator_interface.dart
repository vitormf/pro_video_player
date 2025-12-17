import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Interface for network state monitoring.
///
/// Abstracts network state checking and event listening to allow for testing
/// without actual browser APIs. Combines functionality from both Navigator
/// (for state) and Window (for events).
abstract interface class NavigatorInterface {
  /// Whether the browser is online.
  bool get onLine;

  /// Adds an event listener for network state changes.
  ///
  /// Events: 'online', 'offline'
  void addEventListener(String type, JSFunction listener);

  /// Removes an event listener for network state changes.
  void removeEventListener(String type, JSFunction listener);
}

/// Browser implementation of [NavigatorInterface].
///
/// Delegates to window for event listening and navigator for state.
/// In browsers, online/offline events are fired on window, while the current
/// state is available via navigator.onLine.
class BrowserNavigator implements NavigatorInterface {
  /// Creates a browser navigator wrapper.
  BrowserNavigator({required web.Navigator navigator, required web.Window window})
    : _navigator = navigator,
      _window = window;

  final web.Navigator _navigator;
  final web.Window _window;

  @override
  bool get onLine => _navigator.onLine;

  @override
  void addEventListener(String type, JSFunction listener) {
    // online/offline events are on window, not navigator
    _window.addEventListener(type, listener);
  }

  @override
  void removeEventListener(String type, JSFunction listener) {
    // online/offline events are on window, not navigator
    _window.removeEventListener(type, listener);
  }
}
