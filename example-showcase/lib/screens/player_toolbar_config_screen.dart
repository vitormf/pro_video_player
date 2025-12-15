import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../test_keys.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates configurable player toolbar actions in Flutter controls.
///
/// This screen showcases:
/// - Custom action selection and ordering via [PlayerToolbarAction]
/// - Maximum visible actions with overflow menu
/// - Dynamic action visibility based on conditions
class PlayerToolbarConfigScreen extends StatefulWidget {
  const PlayerToolbarConfigScreen({super.key});

  @override
  State<PlayerToolbarConfigScreen> createState() => _PlayerToolbarConfigScreenState();
}

class _PlayerToolbarConfigScreenState extends State<PlayerToolbarConfigScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;

  // Configuration state - include all common actions to showcase the feature
  final Set<PlayerToolbarAction> _selectedActions = {
    PlayerToolbarAction.subtitles,
    PlayerToolbarAction.audio,
    PlayerToolbarAction.quality,
    PlayerToolbarAction.speed,
    PlayerToolbarAction.scalingMode,
    PlayerToolbarAction.pip,
    PlayerToolbarAction.fullscreen,
  };
  int? _maxActions;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      // Use HLS stream with multiple quality levels to showcase quality selection
      await _controller.initialize(source: const VideoSource.network(VideoUrls.bitmovinSintelHls));
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Player Toolbar Configuration')),
    body: _error != null
        ? _buildErrorState()
        : !_isInitialized
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
  );

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isInitialized = false;
              });
              unawaited(_initializePlayer());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildContent() => ResponsiveVideoLayout(
    videoPlayer: ColoredBox(
      key: TestKeys.playerToolbarVideoPlayer,
      color: Colors.black,
      child: ProVideoPlayer(
        key: ValueKey('player_toolbar_${_selectedActions.hashCode}_$_maxActions'),
        controller: _controller,
        controlsBuilder: (context, ctrl) => VideoPlayerControls(
          controller: ctrl,
          playerToolbarActions: _selectedActions.toList(),
          maxPlayerToolbarActions: _maxActions,
        ),
      ),
    ),
    controls: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionSelector(),
          const SizedBox(height: 24),
          _buildMaxActionsSlider(),
          const SizedBox(height: 24),
          _buildPresetButtons(),
          const SizedBox(height: 24),
          _buildInfoCard(),
        ],
      ),
    ),
  );

  Widget _buildActionSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Select Actions', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text('Choose which actions to show in the player toolbar:'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: PlayerToolbarAction.values
            .map(
              (action) => FilterChip(
                key: Key('action_${action.name}'),
                label: Text(_getActionLabel(action)),
                selected: _selectedActions.contains(action),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedActions.add(action);
                    } else {
                      _selectedActions.remove(action);
                    }
                  });
                },
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _buildMaxActionsSlider() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text('Max Visible Actions', style: Theme.of(context).textTheme.titleMedium)),
          Switch(
            key: TestKeys.playerToolbarMaxActionsSwitch,
            value: _maxActions != null,
            onChanged: (enabled) {
              setState(() {
                _maxActions = enabled ? 3 : null;
              });
            },
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        _maxActions != null
            ? 'Limit to $_maxActions visible actions. Extra actions go to overflow menu.'
            : 'No limit. All actions are shown directly.',
      ),
      if (_maxActions != null) ...[
        const SizedBox(height: 8),
        Slider(
          key: TestKeys.playerToolbarMaxActionsSlider,
          value: _maxActions!.toDouble(),
          min: 1,
          max: 6,
          divisions: 5,
          label: '$_maxActions',
          onChanged: (value) {
            setState(() => _maxActions = value.round());
          },
        ),
      ],
    ],
  );

  Widget _buildPresetButtons() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Presets', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            key: TestKeys.playerToolbarPresetMinimal,
            onPressed: _applyMinimalPreset,
            child: const Text('Minimal'),
          ),
          OutlinedButton(
            key: TestKeys.playerToolbarPresetPlayback,
            onPressed: _applyPlaybackPreset,
            child: const Text('Playback'),
          ),
          OutlinedButton(key: TestKeys.playerToolbarPresetFull, onPressed: _applyFullPreset, child: const Text('Full')),
          OutlinedButton(
            key: TestKeys.playerToolbarPresetOverflow,
            onPressed: _applyOverflowPreset,
            child: const Text('With Overflow'),
          ),
        ],
      ),
    ],
  );

  Widget _buildInfoCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Configuration', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text('Selected: ${_selectedActions.length} actions'),
          Text('Max visible: ${_maxActions ?? "unlimited"}'),
          if (_maxActions != null && _selectedActions.length > _maxActions!)
            Text(
              'Overflow: ${_selectedActions.length - _maxActions!} actions in menu',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
        ],
      ),
    ),
  );

  void _applyMinimalPreset() {
    setState(() {
      _selectedActions
        ..clear()
        ..addAll([PlayerToolbarAction.fullscreen]);
      _maxActions = null;
    });
  }

  void _applyPlaybackPreset() {
    setState(() {
      _selectedActions
        ..clear()
        ..addAll([PlayerToolbarAction.speed, PlayerToolbarAction.fullscreen]);
      _maxActions = null;
    });
  }

  void _applyFullPreset() {
    setState(() {
      _selectedActions
        ..clear()
        ..addAll(PlayerToolbarAction.values);
      _maxActions = null;
    });
  }

  void _applyOverflowPreset() {
    setState(() {
      _selectedActions
        ..clear()
        ..addAll([
          PlayerToolbarAction.speed,
          PlayerToolbarAction.scalingMode,
          PlayerToolbarAction.pip,
          PlayerToolbarAction.fullscreen,
          PlayerToolbarAction.backgroundPlayback,
        ]);
      _maxActions = 3;
    });
  }

  String _getActionLabel(PlayerToolbarAction action) {
    switch (action) {
      case PlayerToolbarAction.shuffle:
        return 'Shuffle';
      case PlayerToolbarAction.repeatMode:
        return 'Repeat';
      case PlayerToolbarAction.subtitles:
        return 'Subtitles';
      case PlayerToolbarAction.audio:
        return 'Audio';
      case PlayerToolbarAction.quality:
        return 'Quality';
      case PlayerToolbarAction.speed:
        return 'Speed';
      case PlayerToolbarAction.scalingMode:
        return 'Scaling';
      case PlayerToolbarAction.backgroundPlayback:
        return 'Background';
      case PlayerToolbarAction.pip:
        return 'PiP';
      case PlayerToolbarAction.casting:
        return 'Cast';
      case PlayerToolbarAction.orientationLock:
        return 'Orientation';
      case PlayerToolbarAction.chapters:
        return 'Chapters';
      case PlayerToolbarAction.fullscreen:
        return 'Fullscreen';
    }
  }
}
