import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

import 'helpers/e2e_platform.dart';

/// Integration tests for platform capability detection.
///
/// These tests verify that platform-specific features are correctly detected
/// across different platforms. All tests run without requiring player initialization
/// since capability checks are platform-level, not player-level.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Capabilities - PiP Support', () {
    late ProVideoPlayerController controller;

    setUp(() {
      // Create a controller but DO NOT initialize it
      // Capability checks should work without initialization
      controller = ProVideoPlayerController();
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('PiP should be supported on macOS', (tester) async {
      // Skip test if not on macOS
      if (!Platform.isMacOS) {
        printOnFailure('Skipping macOS-specific test (current platform: ${E2EPlatform.currentPlatformName})');
        return;
      }

      // Given: Controller is NOT initialized (testing capability check works before init)
      expect(controller.isInitialized, isFalse, reason: 'Controller should not be initialized for capability check');

      // When: Check if PiP is supported
      final pipSupported = await controller.isPipSupported();

      // Then: PiP should be supported on macOS 10.15+
      expect(
        pipSupported,
        isTrue,
        reason:
            'PiP should be supported on macOS 10.15+. '
            'Ensure the app has the com.apple.security.device.audio-video entitlement.',
      );

      debugPrint('✅ PiP capability correctly detected on macOS: supported=$pipSupported');
    });

    testWidgets('PiP should be supported on iOS', (tester) async {
      // Skip test if not on iOS
      if (!Platform.isIOS) {
        printOnFailure('Skipping iOS-specific test (current platform: ${E2EPlatform.currentPlatformName})');
        return;
      }

      // Given: Controller is NOT initialized
      expect(controller.isInitialized, isFalse, reason: 'Controller should not be initialized for capability check');

      // When: Check if PiP is supported
      final pipSupported = await controller.isPipSupported();

      // Then: PiP should be supported on iOS 14.0+
      expect(
        pipSupported,
        isTrue,
        reason:
            'PiP should be supported on iOS 14.0+. '
            'Ensure UIBackgroundModes includes "audio" in Info.plist.',
      );

      debugPrint('✅ PiP capability correctly detected on iOS: supported=$pipSupported');
    });

    testWidgets('PiP should be supported on Android 8.0+', (tester) async {
      // Skip test if not on Android
      if (!Platform.isAndroid) {
        printOnFailure('Skipping Android-specific test (current platform: ${E2EPlatform.currentPlatformName})');
        return;
      }

      // Given: Controller is NOT initialized
      expect(controller.isInitialized, isFalse, reason: 'Controller should not be initialized for capability check');

      // When: Check if PiP is supported
      final pipSupported = await controller.isPipSupported();

      // Then: PiP should be supported on Android 8.0+ (API 26+)
      // Note: This might be false if manifest is missing supportsPictureInPicture="true"
      if (pipSupported) {
        debugPrint('✅ PiP capability correctly detected on Android: supported=$pipSupported');
      } else {
        debugPrint('⚠️ PiP not supported on Android. Check AndroidManifest.xml for supportsPictureInPicture="true"');
      }

      // We don't assert true/false here because it depends on manifest configuration
      // Just verify the call doesn't throw
      expect(pipSupported, isA<bool>());
    });

    testWidgets('PiP should work on web if browser supports it', (tester) async {
      // Skip test if not on web
      if (!kIsWeb) {
        printOnFailure('Skipping web-specific test (current platform: ${E2EPlatform.currentPlatformName})');
        return;
      }

      // Given: Controller is NOT initialized
      expect(controller.isInitialized, isFalse, reason: 'Controller should not be initialized for capability check');

      // When: Check if PiP is supported
      final pipSupported = await controller.isPipSupported();

      // Then: PiP support on web depends on browser capabilities
      debugPrint('Web PiP capability: supported=$pipSupported');
      expect(pipSupported, isA<bool>());
    });

    testWidgets('PiP should not be supported on Windows/Linux', (tester) async {
      // Skip test if not on Windows or Linux
      if (!Platform.isWindows && !Platform.isLinux) {
        printOnFailure('Skipping Windows/Linux test (current platform: ${E2EPlatform.currentPlatformName})');
        return;
      }

      // Given: Controller is NOT initialized
      expect(controller.isInitialized, isFalse, reason: 'Controller should not be initialized for capability check');

      // When: Check if PiP is supported
      final pipSupported = await controller.isPipSupported();

      // Then: PiP should not be supported on Windows/Linux
      expect(pipSupported, isFalse, reason: 'PiP is not yet implemented on Windows/Linux platforms');

      debugPrint('✅ PiP capability correctly detected on ${E2EPlatform.currentPlatformName}: not supported');
    });
  });

  group('Platform Capabilities - Background Playback Support', () {
    late ProVideoPlayerController controller;

    setUp(() {
      controller = ProVideoPlayerController();
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('Background playback should be supported on macOS', (tester) async {
      if (!Platform.isMacOS) {
        printOnFailure('Skipping macOS-specific test');
        return;
      }

      // Given: Controller is NOT initialized
      expect(controller.isInitialized, isFalse);

      // When: Check if background playback is supported
      final backgroundSupported = await controller.isBackgroundPlaybackSupported();

      // Then: Background playback should always be supported on macOS
      expect(backgroundSupported, isTrue, reason: 'Background playback is always supported on macOS');

      debugPrint('✅ Background playback correctly detected on macOS: supported=$backgroundSupported');
    });

    testWidgets('Background playback should be supported on iOS', (tester) async {
      if (!Platform.isIOS) {
        printOnFailure('Skipping iOS-specific test');
        return;
      }

      // Given: Controller is NOT initialized
      expect(controller.isInitialized, isFalse);

      // When: Check if background playback is supported
      final backgroundSupported = await controller.isBackgroundPlaybackSupported();

      // Then: Background playback should be supported if UIBackgroundModes is configured
      expect(
        backgroundSupported,
        isTrue,
        reason: 'Background playback should be supported on iOS with proper Info.plist configuration',
      );

      debugPrint('✅ Background playback correctly detected on iOS: supported=$backgroundSupported');
    });

    testWidgets('Background playback should be supported on Android', (tester) async {
      if (!Platform.isAndroid) {
        printOnFailure('Skipping Android-specific test');
        return;
      }

      // Given: Controller is NOT initialized
      expect(controller.isInitialized, isFalse);

      // When: Check if background playback is supported
      final backgroundSupported = await controller.isBackgroundPlaybackSupported();

      // Then: Background playback should be supported on Android
      expect(backgroundSupported, isTrue, reason: 'Background playback should be supported on Android');

      debugPrint('✅ Background playback correctly detected on Android: supported=$backgroundSupported');
    });
  });

  group('Platform Capabilities - Can Check Before Initialization', () {
    testWidgets('isPipSupported works before player initialization', (tester) async {
      // Given: A fresh controller that has never been initialized
      final controller = ProVideoPlayerController();

      // Verify: Controller is definitely not initialized
      expect(controller.isInitialized, isFalse);
      expect(controller.playerId, isNull);

      // When: Call isPipSupported without initializing
      bool? pipSupported;
      try {
        pipSupported = await controller.isPipSupported();
      } catch (e) {
        fail('isPipSupported() should not throw when called before initialization. Error: $e');
      }

      // Then: Should return a boolean without throwing
      expect(pipSupported, isA<bool>(), reason: 'Should return a boolean value');

      debugPrint('✅ isPipSupported() works before initialization: $pipSupported');

      // Cleanup
      await controller.dispose();
    });

    testWidgets('isBackgroundPlaybackSupported works before player initialization', (tester) async {
      // Given: A fresh controller that has never been initialized
      final controller = ProVideoPlayerController();

      // Verify: Controller is definitely not initialized
      expect(controller.isInitialized, isFalse);
      expect(controller.playerId, isNull);

      // When: Call isBackgroundPlaybackSupported without initializing
      bool? backgroundSupported;
      try {
        backgroundSupported = await controller.isBackgroundPlaybackSupported();
      } catch (e) {
        fail('isBackgroundPlaybackSupported() should not throw when called before initialization. Error: $e');
      }

      // Then: Should return a boolean without throwing
      expect(backgroundSupported, isA<bool>(), reason: 'Should return a boolean value');

      debugPrint('✅ isBackgroundPlaybackSupported() works before initialization: $backgroundSupported');

      // Cleanup
      await controller.dispose();
    });
  });
}
