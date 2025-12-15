import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../pro_video_player_controller.dart';
import '../video_player_theme.dart';

/// A persistent status bar displayed at the top of fullscreen mode.
///
/// Layout:
/// - **Left**: Current video position and total duration (e.g., "12:34 / 1:23:45")
/// - **Right**: System time in 12-hour format (e.g., "2:30 PM") and battery level with charging indicator (when available)
///
/// The status bar uses small, unobtrusive text (11px) and automatically hides
/// when the system status bar is visible (not in true fullscreen mode). It does
/// not auto-hide with playback controls, providing persistent contextual information.
///
/// ## Platform-specific behavior
///
/// Battery information availability:
/// - **iOS**: Full support via UIDevice
/// - **Android**: Full support via BatteryManager
/// - **macOS**: Supported on MacBooks (null on desktops)
/// - **Web**: Supported in Battery Status API browsers (Chrome, Edge)
/// - **Windows/Linux**: Not implemented, battery section hidden
///
/// When battery info is unavailable, the battery section is gracefully hidden.
class FullscreenStatusBar extends StatefulWidget {
  /// Creates a fullscreen status bar.
  const FullscreenStatusBar({
    required this.controller,
    super.key,
    this.enableTimeUpdates = true,
    this.enableBatteryMonitoring = true,
    this.testBatteryInfo,
  });

  /// The video player controller.
  final ProVideoPlayerController controller;

  /// Whether to enable time updates via Timer.periodic.
  ///
  /// This should only be set to false in tests to avoid hanging.
  @visibleForTesting
  final bool enableTimeUpdates;

  /// Whether to enable battery monitoring.
  ///
  /// This should only be set to false in tests to avoid async issues.
  @visibleForTesting
  final bool enableBatteryMonitoring;

  /// Test-only: Directly inject battery info instead of subscribing.
  ///
  /// When provided, bypasses async battery subscription for testing.
  @visibleForTesting
  final BatteryInfo? testBatteryInfo;

  @override
  State<FullscreenStatusBar> createState() => _FullscreenStatusBarState();
}

class _FullscreenStatusBarState extends State<FullscreenStatusBar> {
  Timer? _timeUpdateTimer;
  StreamSubscription<BatteryInfo>? _batterySubscription;
  DateTime _currentTime = DateTime.now();
  BatteryInfo? _batteryInfo;

  @override
  void initState() {
    super.initState();
    _startTimeUpdates();

    // Use test battery info if provided (test-only path)
    if (widget.testBatteryInfo != null) {
      _batteryInfo = widget.testBatteryInfo;
    } else if (widget.enableBatteryMonitoring) {
      unawaited(_subscribeToBatteryUpdates());
    }
  }

  @override
  void didUpdateWidget(FullscreenStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update battery info if test data changed
    if (widget.testBatteryInfo != oldWidget.testBatteryInfo) {
      setState(() {
        _batteryInfo = widget.testBatteryInfo;
      });
    }
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    unawaited(_batterySubscription?.cancel());
    super.dispose();
  }

  void _startTimeUpdates() {
    if (!widget.enableTimeUpdates) {
      // For tests: don't start the timer, just use current time
      _currentTime = DateTime.now();
      return;
    }

    // Update time every second
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> _subscribeToBatteryUpdates() async {
    try {
      final batteryUpdates = widget.controller.batteryUpdates;
      _batterySubscription = batteryUpdates.listen((batteryInfo) {
        if (mounted) {
          setState(() {
            _batteryInfo = batteryInfo;
          });
        }
      });

      // Also get initial battery info
      final initialBattery = await widget.controller.getBatteryInfo();
      if (mounted && initialBattery != null) {
        setState(() {
          _batteryInfo = initialBattery;
        });
      }
    } catch (e) {
      // Battery API not available on this platform
      // Gracefully degrade by not showing battery section
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;

    // Convert to 12-hour format
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';

    // Format with leading zero for minutes
    final minuteStr = minute.toString().padLeft(2, '0');

    return '$hour12:$minuteStr $period';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = VideoPlayerThemeData.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    // Hide our status bar when system status bar is visible
    // System status bar is visible when top padding > 0 (not in true fullscreen)
    if (topPadding > 0) {
      return const SizedBox.shrink();
    }

    return Container(
      // Gradient background for readability over video
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.black.withValues(alpha: 0)],
        ),
      ),
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Video position / duration (left aligned)
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              final position = value.position;
              final duration = value.duration;

              return Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 3)],
                ),
              );
            },
          ),

          // Clock and battery (right aligned)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // System time (12-hour format)
              Text(
                _formatTime(_currentTime),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 3)],
                ),
              ),

              // Battery info (if available)
              if (_batteryInfo != null) ...[
                const SizedBox(width: 8),
                Icon(
                  _getBatteryIcon(_batteryInfo!.percentage, _batteryInfo!.isCharging),
                  color: theme.primaryColor,
                  size: 14,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 3)],
                ),
                const SizedBox(width: 3),
                Text(
                  '${_batteryInfo!.percentage}%',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 3)],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getBatteryIcon(int percentage, bool isCharging) {
    if (isCharging) {
      return Icons.battery_charging_full;
    }

    // Select icon based on charge level
    if (percentage >= 90) {
      return Icons.battery_full;
    } else if (percentage >= 70) {
      return Icons.battery_6_bar;
    } else if (percentage >= 50) {
      return Icons.battery_5_bar;
    } else if (percentage >= 30) {
      return Icons.battery_3_bar;
    } else if (percentage >= 10) {
      return Icons.battery_2_bar;
    } else {
      return Icons.battery_1_bar;
    }
  }
}
