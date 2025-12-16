// This file is deprecated. Use test/shared/test_setup.dart instead.
//
// All functionality has been moved to:
// - test/shared/mocks.dart - Mock classes
// - test/shared/test_setup.dart - registerVideoPlayerFallbackValues() and VideoPlayerTestFixture
//
// Migration guide:
// Old: import '../test_helpers.dart';
// New: import 'shared/test_setup.dart'; import 'shared/mocks.dart';
//
// Old: registerFallbackValues()
// New: registerVideoPlayerFallbackValues()
//
// Old: ControllerTestFixture
// New: VideoPlayerTestFixture (has all the same functionality plus more)

import 'shared/test_setup.dart' as setup;

export 'shared/mocks.dart';
export 'shared/test_setup.dart' show VideoPlayerTestFixture, registerVideoPlayerFallbackValues;

// For backwards compatibility, re-export with old names
void registerFallbackValues() => setup.registerVideoPlayerFallbackValues();
typedef ControllerTestFixture = setup.VideoPlayerTestFixture;
