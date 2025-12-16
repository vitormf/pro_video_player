import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button widget that displays the native casting interface.
///
/// On iOS/macOS, this shows the AVRoutePickerView (AirPlay button).
/// On Android, this shows the MediaRouteButton (Chromecast button).
/// On web, this uses the Remote Playback API (browser-dependent).
///
/// The button automatically detects available casting devices and shows
/// the appropriate UI for the platform.
///
/// ## Android Setup Requirements
///
/// Android Chromecast requires additional configuration:
///
/// ### 1. Use FlutterFragmentActivity
///
/// Your `MainActivity` must extend `FlutterFragmentActivity`:
///
/// ```kotlin
/// import io.flutter.embedding.android.FlutterFragmentActivity
///
/// class MainActivity : FlutterFragmentActivity()
/// ```
///
/// ### 2. Use AppCompat Themes with Opaque Background
///
/// Update your `styles.xml` to use AppCompat themes with opaque `colorBackground`:
///
/// ```xml
/// <!-- values/styles.xml -->
/// <style name="LaunchTheme" parent="Theme.AppCompat.Light.NoActionBar">
///     <item name="android:windowBackground">@drawable/launch_background</item>
///     <item name="android:colorBackground">@android:color/white</item>
/// </style>
///
/// <style name="NormalTheme" parent="Theme.AppCompat.Light.NoActionBar">
///     <item name="android:windowBackground">?android:colorBackground</item>
///     <item name="android:colorBackground">@android:color/white</item>
/// </style>
/// ```
///
/// For dark mode (`values-night/styles.xml`):
///
/// ```xml
/// <style name="LaunchTheme" parent="Theme.AppCompat.NoActionBar">
///     <item name="android:colorBackground">@android:color/black</item>
/// </style>
/// ```
///
/// Without these configurations, the app will crash with:
/// - "The activity must be a subclass of FragmentActivity"
/// - "background can not be translucent: #0"
///
/// ## Example
///
/// ```dart
/// CastButton(
///   tintColor: Colors.white,
///   activeTintColor: Colors.blue,
///   size: 24.0,
///   alwaysVisible: true,
///   onCastStateChanged: (state) {
///     print('Cast state: $state'); // noDevices, notConnected, connecting, connected
///   },
/// )
/// ```
///
/// ## Cast States
///
/// The [onCastStateChanged] callback receives these states:
/// - `noDevices` - No cast devices available on the network
/// - `notConnected` - Devices available but not connected
/// - `connecting` - Currently connecting to a device
/// - `connected` - Connected and ready to cast
///
/// See also:
/// - `ProVideoPlayerController.startCasting()` for programmatic casting
/// - `ProVideoPlayerController.isCasting` to check casting state
class CastButton extends StatefulWidget {
  /// Creates a cast button.
  const CastButton({
    super.key,
    this.tintColor,
    this.activeTintColor,
    this.size = 24.0,
    this.onCastStateChanged,
    this.onWillBeginPresentingRoutes,
    this.onDidEndPresentingRoutes,
    this.alwaysVisible = false,
    this.showBorder = false,
  });

  /// The tint color for the button when not connected.
  /// Defaults to the current icon theme color.
  final Color? tintColor;

  /// The tint color when connected to a device (iOS/macOS only).
  final Color? activeTintColor;

  /// The size of the button in logical pixels.
  final double size;

  /// Called when the cast state changes.
  final ValueChanged<String>? onCastStateChanged;

  /// Called when the route picker is about to be presented (iOS/macOS only).
  final VoidCallback? onWillBeginPresentingRoutes;

  /// Called when the route picker has been dismissed (iOS/macOS only).
  final VoidCallback? onDidEndPresentingRoutes;

  /// Whether to always show the button, even when no devices are available.
  /// Defaults to false.
  final bool alwaysVisible;

  /// Whether to show a border around the button (macOS only).
  ///
  /// On macOS, AVRoutePickerView can display a bordered button style.
  /// Set to `false` for a flat icon that matches other toolbar buttons.
  /// Defaults to `false`.
  final bool showBorder;

  @override
  State<CastButton> createState() => _CastButtonState();
}

class _CastButtonState extends State<CastButton> {
  late final String _viewType;
  MethodChannel? _channel;

  @override
  void initState() {
    super.initState();
    _viewType = _getViewType();
  }

  String _getViewType() {
    if (kIsWeb) {
      return 'dev.pro_video_player_web/cast_button';
    } else if (Platform.isIOS) {
      return 'dev.pro_video_player.ios/airplay_picker';
    } else if (Platform.isMacOS) {
      return 'dev.pro_video_player.macos/airplay_picker';
    } else if (Platform.isAndroid) {
      return 'dev.pro_video_player.android/cast_button';
    } else {
      return '';
    }
  }

  Map<String, dynamic> _buildCreationParams() {
    final params = <String, dynamic>{};

    if (widget.tintColor != null) {
      // Convert Color to ARGB int value
      params['tintColor'] = _colorToInt(widget.tintColor!);
    }

    if (widget.activeTintColor != null) {
      params['activeTintColor'] = _colorToInt(widget.activeTintColor!);
    }

    if (widget.alwaysVisible) {
      params['alwaysVisible'] = true;
    }

    // iOS-specific: prioritize video devices
    if (Platform.isIOS) {
      params['prioritizesVideoDevices'] = true;
    }

    // macOS-specific: show border around button
    if (Platform.isMacOS) {
      params['showBorder'] = widget.showBorder;
    }

    return params;
  }

  /// Convert a Color to an ARGB int value for native code.
  int _colorToInt(Color color) {
    final a = (color.a * 255).round();
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  void _onPlatformViewCreated(int viewId) {
    final channelName = _getChannelName(viewId);
    if (channelName.isEmpty) return;

    _channel = MethodChannel(channelName);
    _channel!.setMethodCallHandler(_handleMethodCall);
  }

  String _getChannelName(int viewId) {
    if (kIsWeb) {
      return 'dev.pro_video_player/cast_button_$viewId';
    } else if (Platform.isIOS) {
      return 'dev.pro_video_player/airplay_picker_$viewId';
    } else if (Platform.isMacOS) {
      return 'dev.pro_video_player/airplay_picker_$viewId';
    } else if (Platform.isAndroid) {
      return 'dev.pro_video_player.android/cast_button_$viewId';
    } else {
      return '';
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onCastStateChanged':
        final args = call.arguments as Map<Object?, Object?>?;
        final state = args?['state'] as String?;
        if (state != null) {
          widget.onCastStateChanged?.call(state);
        }
      case 'onWillBeginPresentingRoutes':
        widget.onWillBeginPresentingRoutes?.call();
      case 'onDidEndPresentingRoutes':
        widget.onDidEndPresentingRoutes?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unsupported platforms show a disabled cast icon
    if (_viewType.isEmpty || kIsWeb) {
      return _buildFallbackButton();
    }

    return SizedBox(width: widget.size, height: widget.size, child: _buildPlatformView());
  }

  Widget _buildPlatformView() {
    final params = _buildCreationParams();

    if (Platform.isIOS) {
      return UiKitView(
        viewType: _viewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(TapGestureRecognizer.new),
        },
      );
    } else if (Platform.isAndroid) {
      return AndroidView(
        viewType: _viewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(TapGestureRecognizer.new),
        },
      );
    } else if (Platform.isMacOS) {
      return AppKitView(
        viewType: _viewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(TapGestureRecognizer.new),
        },
      );
    }

    return _buildFallbackButton();
  }

  Widget _buildFallbackButton() {
    final color = widget.tintColor ?? IconTheme.of(context).color ?? Colors.grey;
    return Icon(Icons.cast, color: color.withValues(alpha: 0.5), size: widget.size);
  }

  /// Programmatically shows the route picker dialog.
  /// This is useful when you want to trigger the dialog from a custom UI.
  Future<void> showDialog() async {
    await _channel?.invokeMethod('showDialog');
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}
