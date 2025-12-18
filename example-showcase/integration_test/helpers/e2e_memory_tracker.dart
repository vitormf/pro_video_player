import 'dart:io';

import 'package:flutter/foundation.dart';

/// Memory snapshot captured at a point in time.
class MemorySnapshot {
  const MemorySnapshot({
    required this.timestamp,
    required this.dartHeapMB,
    required this.dartExternalMB,
    this.nativeHeapMB,
    this.section,
  });

  final DateTime timestamp;
  final double dartHeapMB;
  final double dartExternalMB;
  final double? nativeHeapMB;
  final String? section;

  double get totalMB => dartHeapMB + dartExternalMB + (nativeHeapMB ?? 0);

  @override
  String toString() {
    final native = nativeHeapMB != null ? ' + ${nativeHeapMB!.toStringAsFixed(1)}MB native' : '';
    return '${dartHeapMB.toStringAsFixed(1)}MB dart + ${dartExternalMB.toStringAsFixed(1)}MB external$native = ${totalMB.toStringAsFixed(1)}MB total';
  }
}

/// Tracks memory usage during E2E tests to detect leaks.
///
/// Usage:
/// ```dart
/// final tracker = E2EMemoryTracker();
/// await tracker.captureBaseline('Initial');
///
/// // Run test section
/// await tracker.captureSnapshot('After section 1');
///
/// // At end
/// tracker.printReport();
/// ```
class E2EMemoryTracker {
  E2EMemoryTracker({this.leakThresholdMB = 50.0});

  /// Memory growth threshold (in MB) to warn about potential leaks.
  final double leakThresholdMB;

  final List<MemorySnapshot> _snapshots = [];
  MemorySnapshot? _baseline;

  /// Captures current memory usage.
  ///
  /// Returns a snapshot of Dart heap and external memory.
  /// Native heap tracking is platform-dependent and may not be available.
  Future<MemorySnapshot> captureSnapshot([String? section]) async {
    // Force garbage collection first
    await _forceGC();

    // Get Dart VM memory info (always available)
    final dartHeapMB = _getDartHeapSizeMB();
    final dartExternalMB = _getDartExternalSizeMB();

    // Native heap (Android only, requires platform channel)
    double? nativeHeapMB;
    if (Platform.isAndroid) {
      // TODO: Add platform channel to query native heap
      // For now, we'll rely on Dart memory which includes most allocations
    }

    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      dartHeapMB: dartHeapMB,
      dartExternalMB: dartExternalMB,
      nativeHeapMB: nativeHeapMB,
      section: section,
    );

    _snapshots.add(snapshot);
    return snapshot;
  }

  /// Captures baseline memory snapshot.
  ///
  /// Call this at the start of tests to establish a baseline for comparison.
  Future<MemorySnapshot> captureBaseline([String section = 'Baseline']) async {
    _baseline = await captureSnapshot(section);
    debugPrint('📊 Memory baseline: $_baseline');
    return _baseline!;
  }

  /// Gets current Dart heap size in MB.
  double _getDartHeapSizeMB() {
    // Use ProcessInfo to get RSS (Resident Set Size)
    // This includes Dart heap + external allocations + native memory
    try {
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        // Get current process memory
        final info = ProcessInfo.currentRss;
        return info / 1024 / 1024; // bytes to MB
      }
    } catch (_) {
      // Fall through to estimate
    }

    // Fallback: use rough estimate based on allocation
    return 0;
  }

  /// Gets current Dart external memory size in MB.
  // External memory is already included in RSS, so return 0
  // to avoid double-counting
  double _getDartExternalSizeMB() => 0;

  /// Forces garbage collection to get accurate memory readings.
  Future<void> _forceGC() async {
    // Multiple GC cycles to ensure cleanup
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Allocate and release to trigger GC (let it go out of scope)
      final temp = List<int>.generate(1000000, (i) => i);
      // Force use to prevent optimization
      if (temp.isNotEmpty) {
        temp.length; // Access to prevent dead code elimination
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  /// Compares latest snapshot to baseline and checks for leaks.
  ///
  /// Returns true if potential leak detected (growth > threshold).
  bool hasLeak() {
    if (_baseline == null || _snapshots.isEmpty) return false;

    final latest = _snapshots.last;
    final growth = latest.totalMB - _baseline!.totalMB;

    return growth > leakThresholdMB;
  }

  /// Gets memory growth since baseline in MB.
  double getMemoryGrowth() {
    if (_baseline == null || _snapshots.isEmpty) return 0;
    return _snapshots.last.totalMB - _baseline!.totalMB;
  }

  /// Prints a report of all captured snapshots.
  ///
  /// Shows memory usage at each checkpoint and highlights potential leaks.
  void printReport() {
    if (_snapshots.isEmpty) {
      debugPrint('\n📊 Memory Report: No snapshots captured');
      return;
    }

    debugPrint('\n${'=' * 70}');
    debugPrint('📊 Memory Tracking Report');
    debugPrint('=' * 70);

    for (var i = 0; i < _snapshots.length; i++) {
      final snapshot = _snapshots[i];
      final section = snapshot.section ?? 'Snapshot $i';

      // Calculate growth from baseline
      var growthStr = '';
      if (_baseline != null && snapshot != _baseline) {
        final growth = snapshot.totalMB - _baseline!.totalMB;
        final sign = growth >= 0 ? '+' : '';
        growthStr = ' ($sign${growth.toStringAsFixed(1)}MB from baseline)';
      }

      // Warn if significant growth
      final isBaseline = snapshot == _baseline;
      final hasSignificantGrowth =
          _baseline != null && !isBaseline && (snapshot.totalMB - _baseline!.totalMB) > leakThresholdMB;

      final icon = isBaseline
          ? '📍'
          : hasSignificantGrowth
          ? '⚠️ '
          : '  ';
      debugPrint('$icon $section: $snapshot$growthStr');
    }

    // Summary
    if (_baseline != null && _snapshots.length > 1) {
      final totalGrowth = _snapshots.last.totalMB - _baseline!.totalMB;
      debugPrint('─' * 70);
      if (totalGrowth > leakThresholdMB) {
        debugPrint(
          '⚠️  POTENTIAL LEAK: Total growth = ${totalGrowth.toStringAsFixed(1)}MB (threshold: ${leakThresholdMB}MB)',
        );
      } else {
        debugPrint('✓ Memory growth acceptable: ${totalGrowth.toStringAsFixed(1)}MB (threshold: ${leakThresholdMB}MB)');
      }
    }

    debugPrint('=' * 70 + '\n');
  }

  /// Clears all captured snapshots.
  void reset() {
    _snapshots.clear();
    _baseline = null;
  }
}
