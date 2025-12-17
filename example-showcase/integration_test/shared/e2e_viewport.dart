import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_constants.dart';

/// Viewport size constants for E2E tests.
///
/// Provides standard viewport sizes for different device types and layouts.
/// E2E tests can set viewport size to test responsive layouts and behaviors.
class E2EViewport {
  E2EViewport._();

  // ==========================================================================
  // Mobile Phone Sizes (Portrait)
  // ==========================================================================

  /// iPhone 14 Pro size (portrait).
  ///
  /// 393×852 logical pixels
  /// Use for: Mobile phone portrait tests, single-pane navigation.
  static const Size iPhonePortrait = Size(393, 852);

  /// Standard mobile portrait size (generic).
  ///
  /// 375×667 logical pixels (iPhone 8 size)
  /// Use for: Generic mobile tests.
  static const Size mobilePortrait = Size(375, 667);

  /// Large mobile portrait (e.g., iPhone Pro Max).
  ///
  /// 428×926 logical pixels
  /// Use for: Testing on larger phones.
  static const Size largeMobilePortrait = Size(428, 926);

  // ==========================================================================
  // Mobile Phone Sizes (Landscape)
  // ==========================================================================

  /// iPhone 14 Pro size (landscape).
  ///
  /// 852×393 logical pixels
  /// Use for: Mobile landscape tests, fullscreen video.
  static const Size iPhoneLandscape = Size(852, 393);

  /// Standard mobile landscape size (generic).
  ///
  /// 667×375 logical pixels
  /// Use for: Generic mobile landscape tests.
  static const Size mobileLandscape = Size(667, 375);

  // ==========================================================================
  // Tablet Sizes
  // ==========================================================================

  /// iPad Pro 11" size (portrait).
  ///
  /// 834×1194 logical pixels
  /// Use for: Tablet portrait tests.
  static const Size tabletPortrait = Size(834, 1194);

  /// iPad Pro 11" size (landscape).
  ///
  /// 1194×834 logical pixels
  /// Use for: Tablet landscape tests, master-detail layout on tablets.
  static const Size tabletLandscape = Size(1194, 834);

  // ==========================================================================
  // Desktop/Web Sizes
  // ==========================================================================

  /// Standard desktop size for E2E tests.
  ///
  /// 1200×800 logical pixels
  /// Use for: Desktop tests, master-detail layout, web browser testing.
  /// This size triggers master-detail layout in the example app.
  static const Size desktop = Size(1200, 800);

  /// Large desktop size.
  ///
  /// 1920×1080 logical pixels (Full HD)
  /// Use for: Large screen tests, maximum content visibility.
  static const Size desktopLarge = Size(1920, 1080);

  /// Small desktop/large tablet size.
  ///
  /// 1024×768 logical pixels
  /// Use for: Testing responsive breakpoints between tablet and desktop.
  static const Size desktopSmall = Size(1024, 768);

  // ==========================================================================
  // Default Sizes by Platform
  // ==========================================================================

  /// Default phone viewport size (iPhone 14 Pro portrait).
  ///
  /// Use this for mobile E2E tests unless you need a specific size.
  static const Size defaultPhone = iPhonePortrait;

  /// Default tablet viewport size (iPad Pro 11" landscape).
  ///
  /// Use this for tablet E2E tests.
  static const Size defaultTablet = tabletLandscape;

  /// Default desktop viewport size (1200×800).
  ///
  /// Use this for desktop/web E2E tests.
  /// This size triggers master-detail layout in example app.
  static const Size defaultDesktop = desktop;

  // ==========================================================================
  // Layout Detection Breakpoints
  // ==========================================================================

  /// Width threshold for master-detail layout.
  ///
  /// Screens wider than this show master-detail layout (list + detail panes).
  /// Screens narrower use single-pane navigation (push/pop).
  ///
  /// Example app uses 600dp as breakpoint (Material Design medium breakpoint).
  static const double masterDetailBreakpoint = 600;

  /// Width threshold for compact video controls.
  ///
  /// Below this width, compact controls may be shown.
  static const double compactControlsBreakpoint = 400;

  // ==========================================================================
  // Helper Functions
  // ==========================================================================

  /// Returns true if the viewport size triggers master-detail layout.
  ///
  /// Master-detail layout shows both list and detail panes side-by-side.
  /// Used on tablets (landscape) and desktop/web.
  static bool isMasterDetailLayout(Size size) => size.width >= masterDetailBreakpoint;

  /// Returns true if the viewport size triggers single-pane navigation.
  ///
  /// Single-pane navigation uses push/pop routing.
  /// Used on phones (portrait and landscape).
  static bool isSinglePaneLayout(Size size) => size.width < masterDetailBreakpoint;

  /// Returns true if the viewport size should show compact controls.
  ///
  /// Compact controls show simplified UI for small players.
  static bool shouldShowCompactControls(Size size) => size.width < compactControlsBreakpoint;
}

/// Extension to set viewport size in E2E tests.
///
/// Provides convenient methods to set viewport size based on platform
/// or specific device types.
extension E2EViewportExtension on WidgetTester {
  /// Sets viewport to default size based on current platform.
  ///
  /// Mobile (iOS/Android): Phone portrait (393×852)
  /// Desktop (macOS/Windows/Linux): Desktop (1200×800)
  /// Web: Desktop (1200×800)
  ///
  /// Returns the size that was set.
  Future<Size> setDefaultViewportForPlatform() async {
    final size = E2EPlatform.isMobile ? E2EViewport.defaultPhone : E2EViewport.defaultDesktop;
    await binding.setSurfaceSize(size);
    return size;
  }

  /// Sets viewport to phone portrait size (393×852).
  Future<void> setPhonePortrait() async {
    await binding.setSurfaceSize(E2EViewport.iPhonePortrait);
  }

  /// Sets viewport to phone landscape size (852×393).
  Future<void> setPhoneLandscape() async {
    await binding.setSurfaceSize(E2EViewport.iPhoneLandscape);
  }

  /// Sets viewport to tablet landscape size (1194×834).
  Future<void> setTabletLandscape() async {
    await binding.setSurfaceSize(E2EViewport.tabletLandscape);
  }

  /// Sets viewport to desktop size (1200×800).
  Future<void> setDesktop() async {
    await binding.setSurfaceSize(E2EViewport.desktop);
  }

  /// Sets viewport to specified size.
  Future<void> setViewport(Size size) async {
    await binding.setSurfaceSize(size);
  }

  /// Gets the current viewport size.
  ///
  /// Returns the size set via setSurfaceSize(), or the default test size if not set.
  Size getViewportSize() => view.physicalSize / view.devicePixelRatio;

  /// Returns true if current viewport uses master-detail layout.
  bool isCurrentLayoutMasterDetail() => E2EViewport.isMasterDetailLayout(getViewportSize());

  /// Returns true if current viewport uses single-pane navigation.
  bool isCurrentLayoutSinglePane() => E2EViewport.isSinglePaneLayout(getViewportSize());
}
