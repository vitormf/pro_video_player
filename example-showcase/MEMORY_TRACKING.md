# Memory Leak Detection in E2E Tests

This project includes automatic memory leak detection for integration tests.

## Quick Start

Enable memory tracking in any E2E test:

```dart
testWidgets('My E2E test with memory tracking', (tester) async {
  // Enable memory tracking
  final fixture = E2ETestFixture(
    trackMemory: true,              // Enable memory tracking
    memoryLeakThresholdMB: 50.0,    // Warn if growth > 50MB
  );

  app.main();
  await tester.pumpAndSettle();
  await fixture.setUp(tester);  // Captures baseline memory

  // Your test code...
  fixture.startSection('Player Features');
  await nav.navigateToDemo(tester, cardKey, 'Player Features');
  await fixture.endSection('Player Features');  // Auto-captures memory

  // Report printed automatically on tearDown
  fixture.tearDown();
});
```

## What It Does

### Automatic Tracking
- **Baseline capture**: Records memory at test start
- **Section snapshots**: Captures memory at end of each `endSection()`
- **Final report**: Prints complete memory timeline on `tearDown()`
- **Leak detection**: Warns if total growth exceeds threshold

### Example Output

```
======================================================================
📊 Memory Tracking Report
======================================================================
📍 Test setUp: 45.2MB total
   End of Player Features: 78.5MB total (+33.3MB from baseline)
   End of Advanced Features: 52.1MB total (+6.9MB from baseline)
   End of Video Sources: 81.2MB total (+36.0MB from baseline)
───────────────────────────────────────────────────────────────────
✓ Memory growth acceptable: 36.0MB (threshold: 50.0MB)
======================================================================
```

### Leak Detection

If memory growth exceeds threshold:

```
⚠️  WARNING: Potential memory leak detected!
   Memory grew by 65.3MB during test execution.
   Review the memory report above for details.
```

## Manual Snapshots

Capture memory at specific points:

```dart
await fixture.captureMemorySnapshot('After video loaded');
await fixture.captureMemorySnapshot('After playback started');
```

## How It Works

Uses `ProcessInfo.currentRss` to measure Resident Set Size (RSS), which includes:
- Dart heap memory
- Native allocations (video decoders, textures, buffers)
- External memory (platform resources)

### Memory Measurement
1. Forces garbage collection (3 cycles)
2. Waits 500ms for GC to complete
3. Captures RSS in megabytes
4. Compares to baseline

### What's Normal?

**Per video player initialization**: 30-40MB
- Video buffers, decoded frames, textures
- Native codec allocations
- Platform view overhead

**After navigation back**: Should drop close to baseline
- Indicates proper `dispose()` cleanup
- Some overhead is normal (cached resources)

**Cumulative growth**: <50MB over entire test run
- Normal for long-running tests
- Operating system buffers and caches

### What Indicates a Leak?

- Memory keeps growing on repeated screen visits
- Memory doesn't drop after navigation back
- Growth >100MB for simple navigation tests
- Linear growth proportional to iterations

## Integration with Main E2E Test

Add to `e2e_ui_test.dart`:

```dart
// At top of file
const bool enableMemoryTracking = bool.fromEnvironment('TRACK_MEMORY', defaultValue: false);

testWidgets('E2E UI Tests - Complete flow', (tester) async {
  final fixture = E2ETestFixture(
    trackMemory: enableMemoryTracking,
    memoryLeakThresholdMB: 100.0,  // Higher threshold for full test
  );

  // ... rest of test ...
});
```

Run with tracking:

```bash
# Enable memory tracking
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/e2e_ui_test.dart \
  --dart-define=TRACK_MEMORY=true \
  -d emulator-5554
```

## Standalone Memory Tests

Run dedicated memory leak tests:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/memory_leak_detection_example.dart \
  -d "iPhone 16"
```

## Interpreting Results

### Good Patterns ✅
```
📍 Baseline: 45MB
   After screen 1: 78MB (+33MB)  ← Normal spike
   Back to home: 52MB (+7MB)     ← Dropped back down
   After screen 2: 81MB (+36MB)  ← Similar spike
   Back to home: 54MB (+9MB)     ← Dropped again
Final: 54MB (+9MB total)         ← Minimal growth
```

### Leak Pattern ⚠️
```
📍 Baseline: 45MB
   After screen 1: 78MB (+33MB)
   Back to home: 75MB (+30MB)    ← Didn't drop!
   After screen 2: 108MB (+63MB) ← Growing...
   Back to home: 105MB (+60MB)   ← Still high!
Final: 105MB (+60MB total)       ← LEAK!
```

## Limitations

- **Emulator differences**: Emulators show higher memory than real devices
- **GC timing**: Memory may take time to release (not instant)
- **OS caching**: Platform may cache resources (not a leak)
- **Precision**: RSS includes OS overhead, not frame-perfect

## Best Practices

1. **Set appropriate thresholds**: 50MB for small tests, 100MB+ for full E2E
2. **Run on real devices**: More accurate than emulators
3. **Look for patterns**: Repeated growth is more concerning than one-time spikes
4. **Check disposal**: Ensure `dispose()` called on controllers
5. **Profile suspected leaks**: Use Android Studio/Xcode profiler for deep analysis

## When to Investigate

- Memory grows >150MB in basic navigation tests
- Memory never drops after navigation back
- Emulator crashes with "device offline"
- App becomes sluggish after extended use
- Test reports leak warning consistently

## Tools for Deep Investigation

If memory tracker detects a leak:

1. **Android Studio Profiler**: Heap dump analysis
2. **Xcode Instruments**: Allocations and Leaks
3. **Flutter DevTools**: Memory timeline
4. **LeakCanary**: Automatic leak detection (Android)

## See Also

- `integration_test/helpers/e2e_memory_tracker.dart` - Implementation
- `integration_test/memory_leak_detection_example.dart` - Example tests
- `integration_test/shared/e2e_test_fixture.dart` - Fixture integration
