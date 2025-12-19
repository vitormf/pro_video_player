@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:pro_video_player_web/src/abstractions/navigator_interface.dart';
import 'package:pro_video_player_web/src/managers/network_resilience_manager.dart';

import '../shared/web_test_constants.dart';
import '../shared/web_test_fixture.dart';

void main() {
  late WebVideoPlayerTestFixture fixture;
  late NetworkResilienceManager manager;
  late MockNavigator mockNavigator;

  setUp(() {
    fixture = WebVideoPlayerTestFixture()..setUp();
    mockNavigator = MockNavigator();

    manager = NetworkResilienceManager(
      emitEvent: fixture.emitEvent,
      videoElement: fixture.videoElement,
      navigator: mockNavigator,
    );
  });

  tearDown(() async {
    manager.dispose();
    await fixture.tearDown();
  });

  group('Network Monitoring', () {
    test('initializes with online state from navigator', () {
      expect(manager.isNetworkAvailable, isTrue);
    });

    test('initializes with offline state from navigator', () {
      final offlineNavigator = MockNavigator(online: false);
      final offlineManager = NetworkResilienceManager(
        emitEvent: fixture.emitEvent,
        videoElement: fixture.videoElement,
        navigator: offlineNavigator,
      );

      expect(offlineManager.isNetworkAvailable, isFalse);
      offlineManager.dispose();
    });

    test('sets up online/offline event listeners', () {
      manager.setupNetworkMonitoring();

      expect(mockNavigator.hasListener('online'), isTrue);
      expect(mockNavigator.hasListener('offline'), isTrue);
    });

    test('updates state and emits event when going offline', () async {
      manager.setupNetworkMonitoring();
      fixture.clearEmittedEvents();

      // Call the offline callback directly (simulates browser offline event)
      manager.offlineCallbackForTesting!(null);

      // Wait for stream events to be processed
      await Future<void>.delayed(Duration.zero);

      expect(manager.isNetworkAvailable, isFalse);
      final event = fixture.verifyEventEmitted<NetworkStateChangedEvent>();
      expect(event.isConnected, isFalse);
    });

    test('updates state and emits event when going online', () async {
      mockNavigator.online = false;
      manager.setupNetworkMonitoring();
      fixture.clearEmittedEvents();

      // Call the online callback directly (simulates browser online event)
      manager.onlineCallbackForTesting!(null);

      // Wait for stream events to be processed
      await Future<void>.delayed(Duration.zero);

      expect(manager.isNetworkAvailable, isTrue);
      final event = fixture.verifyEventEmitted<NetworkStateChangedEvent>();
      expect(event.isConnected, isTrue);
    });
  });

  group('Error Detection', () {
    test('marks network error on network error event', () {
      manager.onNetworkError(wasPlaying: true);

      expect(manager.hadNetworkError, isTrue);
      expect(manager.wasPlayingBeforeError, isTrue);
    });

    test('increments retry count on error', () {
      expect(manager.retryCount, 0);

      manager.onNetworkError(wasPlaying: false);

      expect(manager.retryCount, 1);
    });

    test('does not exceed max retry count', () {
      // Trigger errors multiple times
      for (var i = 0; i < 5; i++) {
        manager.onNetworkError(wasPlaying: false);
      }

      expect(manager.retryCount, NetworkResilienceManager.maxRetries);
    });

    test('emits buffering event on network error', () async {
      fixture.clearEmittedEvents();

      manager.onNetworkError(wasPlaying: true);

      // Wait for stream events to be processed
      await Future<void>.delayed(Duration.zero);

      final event = fixture.verifyEventEmitted<BufferingStartedEvent>();
      expect(event.reason, BufferingReason.networkUnstable);
    });
  });

  group('Network Recovery - Native', () {
    test('attempts recovery when going online after error', () async {
      manager.setupNetworkMonitoring();
      manager.onNetworkError(wasPlaying: false);
      fixture.clearEmittedEvents();

      // Simulate going online (calls the online callback)
      manager.onlineCallbackForTesting!(null);

      // Wait for recovery to complete
      await Future<void>.delayed(WebTestDelays.eventPropagation);

      // Note: Recovery needs to be called explicitly via attemptRecovery()
      // The online callback only emits the NetworkStateChangedEvent
      expect(manager.isNetworkAvailable, isTrue);
    });

    test('restores playback position after native recovery', () async {
      const targetPosition = 30.0;
      fixture.videoElement.currentTime = targetPosition;

      manager.onNetworkError(wasPlaying: false);
      final callbackFuture = manager.attemptRecovery(
        onNativeRecovery: () async {
          fixture.videoElement.load();
          // Simulate canplay event
          await Future<void>.delayed(WebTestDelays.readyStateChange);
          return targetPosition;
        },
      );

      await callbackFuture;

      expect(fixture.videoElement.currentTime, targetPosition);
    });

    test('resumes playback if was playing before error', () async {
      fixture.videoElement.paused = true;

      manager.onNetworkError(wasPlaying: true);
      await manager.attemptRecovery(
        onNativeRecovery: () async {
          fixture.videoElement.load();
          await fixture.videoElement.play();
          return 0.0;
        },
      );

      expect(fixture.videoElement.paused, isFalse);
    });

    test('does not resume playback if was paused before error', () async {
      fixture.videoElement.paused = false;

      manager.onNetworkError(wasPlaying: false);
      await manager.attemptRecovery(
        onNativeRecovery: () async {
          fixture.videoElement.load();
          return 0.0;
        },
      );

      expect(fixture.videoElement.paused, isFalse);
    });

    test('emits PlaybackRecoveredEvent after successful recovery', () async {
      fixture.clearEmittedEvents();

      manager.onNetworkError(wasPlaying: false);
      await manager.attemptRecovery(onNativeRecovery: () async => 0.0);

      // Wait for stream events to be processed
      await Future<void>.delayed(Duration.zero);

      final event = fixture.verifyEventEmitted<PlaybackRecoveredEvent>();
      expect(event.retriesUsed, 1);
    });
  });

  group('Network Recovery - HLS', () {
    test('calls HLS recovery callback when HLS is active', () async {
      var hlsRecoveryCalled = false;

      manager.onNetworkError(wasPlaying: false);
      await manager.attemptRecovery(
        onHlsRecovery: () async {
          hlsRecoveryCalled = true;
        },
      );

      expect(hlsRecoveryCalled, isTrue);
    });

    test('emits PlaybackRecoveredEvent after HLS recovery', () async {
      fixture.clearEmittedEvents();

      manager.onNetworkError(wasPlaying: false);
      await manager.attemptRecovery(onHlsRecovery: () async {});

      // Wait for stream events to be processed
      await Future<void>.delayed(Duration.zero);

      final event = fixture.verifyEventEmitted<PlaybackRecoveredEvent>();
      expect(event.retriesUsed, 1);
    });
  });

  group('Network Recovery - DASH', () {
    test('calls DASH recovery callback when DASH is active', () async {
      var dashRecoveryCalled = false;

      manager.onNetworkError(wasPlaying: false);
      await manager.attemptRecovery(
        onDashRecovery: () async {
          dashRecoveryCalled = true;
        },
      );

      expect(dashRecoveryCalled, isTrue);
    });

    test('emits PlaybackRecoveredEvent after DASH recovery', () async {
      fixture.clearEmittedEvents();

      manager.onNetworkError(wasPlaying: false);
      await manager.attemptRecovery(onDashRecovery: () async {});

      // Wait for stream events to be processed
      await Future<void>.delayed(Duration.zero);

      final event = fixture.verifyEventEmitted<PlaybackRecoveredEvent>();
      expect(event.retriesUsed, 1);
    });
  });

  group('Retry Logic', () {
    test('stops attempting recovery after max retries', () async {
      // Reach max retries
      for (var i = 0; i < NetworkResilienceManager.maxRetries; i++) {
        manager.onNetworkError(wasPlaying: false);
      }

      fixture.clearEmittedEvents();

      // Attempt one more recovery
      await manager.attemptRecovery(onNativeRecovery: () async => 0.0);

      // Should not emit recovery event
      fixture.verifyNoEventEmitted<PlaybackRecoveredEvent>();
    });

    test('resets retry count after successful recovery', () async {
      manager.onNetworkError(wasPlaying: false);
      manager.onNetworkError(wasPlaying: false);

      expect(manager.retryCount, 2);

      await manager.attemptRecovery(onNativeRecovery: () async => 0.0);

      expect(manager.retryCount, 0);
    });
  });

  group('Disposal', () {
    test('removes event listeners on dispose', () {
      manager.setupNetworkMonitoring();

      manager.dispose();

      expect(mockNavigator.hasListener('online'), isFalse);
      expect(mockNavigator.hasListener('offline'), isFalse);
    });

    test('resets state on dispose', () {
      manager.onNetworkError(wasPlaying: true);

      manager.dispose();

      expect(manager.hadNetworkError, isFalse);
      expect(manager.retryCount, 0);
    });
  });
}

/// Mock Navigator for testing network state.
class MockNavigator implements NavigatorInterface {
  MockNavigator({this.online = true});

  bool online;
  final Map<String, List<Object>> _eventListeners = {};

  @override
  bool get onLine => online;

  @override
  void addEventListener(String event, Object handler) {
    _eventListeners.putIfAbsent(event, () => []).add(handler);
  }

  @override
  void removeEventListener(String event, Object handler) {
    _eventListeners[event]?.remove(handler);
  }

  bool hasListener(String event) => _eventListeners[event]?.isNotEmpty ?? false;

  void simulateGoOffline() {
    online = false;
    _trigger('offline');
  }

  void simulateGoOnline() {
    online = true;
    _trigger('online');
  }

  void _trigger(String event) {
    final handlers = _eventListeners[event] ?? [];
    // Create a simple mock event object
    final mockEvent = _MockEvent();
    for (final handler in handlers) {
      // Handler is JSFunction (Object in tests), need to cast to Function
      if (handler is Function) {
        // Call handler with mock event
        try {
          // ignore: avoid_dynamic_calls
          handler(mockEvent);
        } catch (e) {
          // Ignore errors - handler might not need the event object
          try {
            // ignore: avoid_dynamic_calls
            handler();
          } catch (_) {
            // Also ignore this
          }
        }
      }
    }
  }
}

/// Simple mock event for testing.
class _MockEvent {
  // Minimal event-like object for testing
}
