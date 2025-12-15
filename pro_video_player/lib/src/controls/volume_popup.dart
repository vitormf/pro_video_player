import 'dart:async';

import 'package:flutter/material.dart';

import '../pro_video_player_controller.dart';
import '../video_player_theme.dart';

/// Volume popup content with slider and mute button.
///
/// This widget is displayed in a popup menu when the user clicks on the
/// volume button on desktop platforms.
class VolumePopupContent extends StatefulWidget {
  /// Creates a volume popup content widget.
  const VolumePopupContent({required this.controller, required this.theme, super.key});

  /// The video player controller.
  final ProVideoPlayerController controller;

  /// The theme to use for styling.
  final VideoPlayerTheme theme;

  @override
  State<VolumePopupContent> createState() => _VolumePopupContentState();
}

class _VolumePopupContentState extends State<VolumePopupContent> {
  double _volume = 1;
  double? _volumeBeforeMute;

  @override
  void initState() {
    super.initState();
    _volume = widget.controller.value.volume;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        _volume = widget.controller.value.volume;
      });
    }
  }

  void _toggleMute() {
    if (_volume > 0) {
      // Mute - save current volume and set to 0
      _volumeBeforeMute = _volume;
      unawaited(widget.controller.setVolume(0));
    } else {
      // Unmute - restore previous volume or default to 1.0
      unawaited(widget.controller.setVolume(_volumeBeforeMute ?? 1.0));
      _volumeBeforeMute = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isMuted = _volume == 0;

    return SizedBox(
      width: 40,
      height: 140,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mute button at top
          IconButton(
            icon: Icon(
              isMuted ? Icons.volume_off : ((_volume > 0.5) ? Icons.volume_up : Icons.volume_down),
              color: theme.primaryColor,
            ),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
            onPressed: _toggleMute,
          ),
          // Vertical slider
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: theme.progressBarActiveColor,
                  inactiveTrackColor: theme.progressBarInactiveColor,
                  thumbColor: theme.progressBarActiveColor,
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                ),
                child: Slider(
                  value: _volume,
                  onChanged: (value) {
                    setState(() => _volume = value);
                    unawaited(widget.controller.setVolume(value));
                  },
                ),
              ),
            ),
          ),
          // Volume percentage
          Text('${(_volume * 100).round()}%', style: TextStyle(color: theme.secondaryColor, fontSize: 10)),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
