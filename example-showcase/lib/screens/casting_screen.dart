import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../constants/video_constants.dart';
import '../test_keys.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates casting functionality (AirPlay, Chromecast, Remote Playback).
///
/// Shows how to:
/// - Check if casting is supported
/// - Start and stop casting
/// - Display casting state and connected device
/// - React to casting state changes
class CastingScreen extends StatefulWidget {
  const CastingScreen({super.key});

  @override
  State<CastingScreen> createState() => _CastingScreenState();
}

class _CastingScreenState extends State<CastingScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _castingSupported = false;
  final List<String> _eventLog = [];

  /// Returns true if running on an Apple platform (iOS/macOS).
  bool get _isApplePlatform => !kIsWeb && (Platform.isIOS || Platform.isMacOS);
  StreamSubscription<VideoPlayerEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      await _controller.initialize(
        source: const VideoSource.network(VideoUrls.bigBuckBunny),
        options: const VideoPlayerOptions(autoPlay: true),
      );

      final castingSupported = await _controller.isCastingSupported();

      setState(() {
        _isInitialized = true;
        _castingSupported = castingSupported;
      });

      _listenForCastingEvents();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _listenForCastingEvents() {
    final playerId = _controller.playerId;
    if (playerId == null) return;

    _eventSubscription = ProVideoPlayerPlatform.instance.events(playerId).listen((event) {
      switch (event) {
        case CastStateChangedEvent(:final state, :final device):
          _addToLog('Cast state: ${state.name}${device != null ? ' (${device.name})' : ''}');
          setState(() {});
        case CastDevicesChangedEvent(:final devices):
          _addToLog('Available devices: ${devices.length}');
        default:
          break;
      }
    });
  }

  void _addToLog(String message) {
    setState(() {
      _eventLog.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_eventLog.length > 20) {
        _eventLog.removeLast();
      }
    });
  }

  Future<void> _toggleCasting() async {
    if (_controller.isCasting) {
      final success = await _controller.stopCasting();
      _addToLog(success ? 'Stopped casting' : 'Failed to stop casting');
    } else {
      final success = await _controller.startCasting();
      _addToLog(success ? 'Started casting prompt' : 'Failed to start casting');
    }
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Casting')),
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
    videoPlayer: ProVideoPlayer(
      key: TestKeys.castingVideoPlayer,
      controller: _controller,
      placeholder: const Center(child: CircularProgressIndicator()),
    ),
    controls: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCastingStatus(),
          const SizedBox(height: 16),
          _buildCastingControls(),
          const SizedBox(height: 16),
          _buildPlatformInfo(),
          const SizedBox(height: 16),
          _buildEventLog(),
        ],
      ),
    ),
  );

  Widget _buildCastingStatus() {
    final castState = _controller.castState;
    final device = _controller.currentCastDevice;

    return Card(
      key: TestKeys.castingStatusCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _controller.isCasting ? Icons.cast_connected : Icons.cast,
                  color: _controller.isCasting ? Colors.green : null,
                ),
                const SizedBox(width: 12),
                Text('Casting Status', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _buildStatusRow('State', castState.name.toUpperCase()),
            if (device != null) ...[
              _buildStatusRow('Device', device.name),
              _buildStatusRow('Type', device.type.name),
              _buildStatusRow('ID', device.id),
            ],
            _buildStatusRow('Supported', _castingSupported ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _buildCastingControls() => Card(
    key: TestKeys.castingControlsCard,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Casting Controls', style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          if (!_castingSupported)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Casting is not supported on this platform or device.\n\n'
                '• iOS/macOS: AirPlay is built-in\n'
                '• Android: Requires Google Cast SDK setup\n'
                '• Web: Requires browser Remote Playback API support',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Column(
              children: [
                // Native Cast Button - this is the primary way to cast on iOS/macOS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Tap to cast: '),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: CastButton(
                        size: 32,
                        tintColor: Colors.white,
                        activeTintColor: Colors.blue,
                        onCastStateChanged: (state) => _addToLog('CastButton state: $state'),
                        onWillBeginPresentingRoutes: () => _addToLog('Route picker opening'),
                        onDidEndPresentingRoutes: () => _addToLog('Route picker closed'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isApplePlatform
                      ? 'Tap the AirPlay button above to select a device'
                      : 'Tap the cast button above to select a device',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Programmatic stop button (only useful when already casting)
                if (_controller.isCasting) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: TestKeys.castingToggleButton,
                      onPressed: _toggleCasting,
                      icon: const Icon(Icons.cast_connected),
                      label: const Text('Stop Casting'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to disconnect from the cast device',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
        ],
      ),
    ),
  );

  Widget _buildPlatformInfo() => Card(
    key: TestKeys.castingPlatformInfoCard,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Support', style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          const Text(
            '• iOS/macOS: AirPlay (built-in)\n'
            '• Android: Chromecast via Google Cast SDK\n'
            '• Web: Remote Playback API (browser-dependent)\n'
            '• Windows/Linux: Not supported',
          ),
        ],
      ),
    ),
  );

  Widget _buildEventLog() => Card(
    key: TestKeys.castingEventLogCard,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Event Log', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                key: TestKeys.castingClearLogButton,
                onPressed: () => setState(_eventLog.clear),
                child: const Text('Clear'),
              ),
            ],
          ),
          const Divider(),
          if (_eventLog.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No events yet. Start/stop casting to see events.', style: TextStyle(color: Colors.grey)),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _eventLog.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(_eventLog[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
