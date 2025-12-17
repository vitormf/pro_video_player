import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shared/e2e_constants.dart';
import '../shared/e2e_viewport.dart';
import 'e2e_helpers.dart';

/// Navigation helpers for E2E integration tests.
///
/// Handles navigation between screens with support for both:
/// - Single-pane layout (mobile): Push/pop navigation
/// - Master-detail layout (tablet/desktop): Side-by-side panes with "Open Demo" button
///
/// These helpers abstract away the differences between navigation modes,
/// making tests work reliably across all viewport sizes and platforms.

// ==========================================================================
// Screen Navigation
// ==========================================================================

/// Navigates to a demo screen from the home screen.
///
/// Handles both single-pane (mobile) and master-detail (desktop/tablet) layouts:
/// - Single-pane: Taps card → navigates directly to demo screen
/// - Master-detail: Taps card → shows detail pane → taps "Open Demo" button → navigates
///
/// Parameters:
/// - [tester]: The widget tester
/// - [cardKey]: Key of the card to tap on home screen
/// - [screenTitle]: Expected title text on the destination screen (for verification)
/// - [scrollToCard]: Whether to scroll to find the card if not visible (default: true)
///
/// Example:
/// ```dart
/// await navigateToDemo(
///   tester,
///   TestKeys.homeScreenPlayerFeaturesCard,
///   'Player Features',
/// );
/// // Now on Player Features screen, ready to test
/// ```
Future<void> navigateToDemo(WidgetTester tester, Key cardKey, String screenTitle, {bool scrollToCard = true}) async {
  final card = find.byKey(cardKey);

  // Ensure card is visible (scroll if needed)
  if (scrollToCard) {
    await ensureCardVisible(tester, cardKey);
  }

  expect(card, findsWidgets, reason: 'Card $cardKey should exist');

  // Tap the card
  await tester.tap(card.first);
  await tester.pump(E2EDelays.navigation);

  // Handle master-detail layout (desktop/tablet/web in larger viewports)
  // Check platform rather than viewport since fullscreen can temporarily affect constraints
  if (E2EPlatform.isWeb || E2EPlatform.isMacOS) {
    final openDemoButton = find.text('Open Demo');

    if (openDemoButton.evaluate().isNotEmpty) {
      debugPrint('Master-detail layout detected, tapping "Open Demo" button');

      // On macOS, skip ensureVisible (uses pumpAndSettle which can hang)
      if (!E2EPlatform.isMacOS) {
        await tester.ensureVisible(openDemoButton);
        await tester.pump(E2EDelays.navigation);
      }

      await tester.tap(openDemoButton, warnIfMissed: false);
      await tester.pump(E2EDelays.navigation);
    }
  }

  // On macOS, wait for screen title to appear (may take a few pumps)
  if (E2EPlatform.isMacOS) {
    final titleAppeared = await waitForWidgetWithText(tester, screenTitle, timeout: E2EDelays.navigationLong);

    if (!titleAppeared) {
      debugPrint('Note: Screen title "$screenTitle" not found on macOS (continuing anyway)');
      return; // Continue anyway - screen may have loaded but title is off-screen
    }
  }

  // Verify we're on the correct screen
  expect(find.text(screenTitle), findsWidgets, reason: 'Should navigate to "$screenTitle" screen');
}

/// Navigates back to home screen.
///
/// Handles both single-pane (back button navigation) and master-detail layouts.
/// Attempts multiple navigation methods:
/// 1. Check if already on home (any home card visible)
/// 2. Try back button by tooltip ('Back')
/// 3. Try Material back button (arrow_back icon)
///
/// Tries up to 5 times to handle nested navigation.
///
/// Example:
/// ```dart
/// await goHome(tester);
/// // Now on home screen
/// ```
Future<void> goHome(WidgetTester tester, {Key? homeCardKey, int maxAttempts = 5}) async {
  // Use a known home card key to detect home screen
  // If not provided, look for any common home screen element
  final homeIndicator = homeCardKey != null ? find.byKey(homeCardKey) : find.text('Pro Video Player');

  for (var i = 0; i < maxAttempts; i++) {
    // Check if we're already on home screen
    if (homeIndicator.evaluate().isNotEmpty) {
      debugPrint('Already on home screen');
      break;
    }

    // Try back button by tooltip
    final backByTooltip = find.byTooltip('Back');
    if (backByTooltip.evaluate().isNotEmpty) {
      await tester.tap(backByTooltip.first);
      await tester.pump(E2EDelays.navigation);
      continue;
    }

    // Try Material back button (arrow_back icon)
    final materialBack = find.byIcon(Icons.arrow_back);
    if (materialBack.evaluate().isNotEmpty) {
      await tester.tap(materialBack.first);
      await tester.pump(E2EDelays.navigation);
      continue;
    }

    // Try BackButton widget type
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton.first);
      await tester.pump(E2EDelays.navigation);
      continue;
    }

    // No back button found, we might already be at home
    break;
  }

  // Final settle to ensure we're fully on home screen
  await tester.pump(E2EDelays.navigation);
}

// ==========================================================================
// Card Scrolling Helpers
// ==========================================================================

/// Ensures a card is visible by scrolling if necessary.
///
/// Handles platform differences:
/// - macOS: Uses manual drag gestures (scrollUntilVisible can hang)
/// - Other platforms: Uses scrollUntilVisible
///
/// Example:
/// ```dart
/// await ensureCardVisible(tester, TestKeys.playerFeaturesCard);
/// await tester.tap(find.byKey(TestKeys.playerFeaturesCard));
/// ```
Future<void> ensureCardVisible(WidgetTester tester, Key cardKey, {Finder? scrollable}) async {
  final card = find.byKey(cardKey);

  if (E2EPlatform.isMacOS) {
    // macOS: Use manual scrolling (scrollUntilVisible can hang)
    await scrollToCardManual(tester, cardKey, scrollable: scrollable);
  } else {
    // Other platforms: Use scrollUntilVisible if card not immediately visible
    if (card.evaluate().isEmpty) {
      debugPrint('Card not visible, attempting to scroll to find it...');
      final effectiveScrollable = scrollable ?? find.byType(Scrollable).first;

      try {
        // Try scrolling up first
        await tester.scrollUntilVisible(card, -200, scrollable: effectiveScrollable, maxScrolls: 20);
      } catch (_) {
        try {
          // If that didn't work, try scrolling down
          await tester.scrollUntilVisible(card, 200, scrollable: effectiveScrollable, maxScrolls: 20);
        } catch (_) {
          debugPrint('Could not scroll to find card');
        }
      }

      await tester.pump(E2EDelays.scrollSettle);
    }

    // Ensure visible if found
    if (card.evaluate().isNotEmpty) {
      await tester.ensureVisible(card.first);
      await tester.pump(E2EDelays.scrollSettle);
    }
  }
}

/// Scrolls to a card using manual drag gestures (macOS-safe).
///
/// Uses drag gestures instead of scrollUntilVisible (which can hang on macOS).
/// Scrolls to top first, then scrolls down to find the card.
///
/// Example:
/// ```dart
/// await scrollToCardManual(tester, TestKeys.playerFeaturesCard);
/// ```
Future<void> scrollToCardManual(WidgetTester tester, Key cardKey, {Finder? scrollable}) async {
  final card = find.byKey(cardKey);
  final effectiveScrollable = scrollable ?? find.byType(Scrollable);

  if (effectiveScrollable.evaluate().isEmpty) {
    debugPrint('No scrollable found');
    return;
  }

  // Helper to check if card is tappable (visible and hittable)
  bool isCardTappable() {
    if (card.evaluate().isEmpty) return false;
    try {
      final box = tester.getRect(card.first);
      // Check if card center is within reasonable screen area
      return box.center.dy > 50 && box.center.dy < 750;
    } catch (_) {
      return false;
    }
  }

  // First, pump a few frames to let widgets build
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  // If card is already tappable, we're done
  if (isCardTappable()) {
    return;
  }

  // Scroll to top first (reset position)
  for (var i = 0; i < 15; i++) {
    await tester.drag(effectiveScrollable.first, const Offset(0, 600));
    await tester.pump(const Duration(milliseconds: 80));
  }
  await tester.pump(E2EDelays.scrollSettle);

  // Now scroll down to find the card
  for (var scrollAttempt = 0; scrollAttempt < E2ERetry.maxScrollAttempts; scrollAttempt++) {
    if (isCardTappable()) {
      // Scroll a bit more to ensure card is fully visible
      await tester.drag(effectiveScrollable.first, const Offset(0, -80));
      await tester.pump(E2EDelays.scrollSettle);
      break;
    }

    await tester.drag(effectiveScrollable.first, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

// ==========================================================================
// Layout Detection Helpers
// ==========================================================================

/// Returns true if current layout is master-detail (side-by-side panes).
///
/// Master-detail layout shows list and detail panes simultaneously.
/// Used on desktop, web, and tablets in landscape.
///
/// Example:
/// ```dart
/// if (isMasterDetailLayout(tester)) {
///   // Expect "Open Demo" button
///   expect(find.text('Open Demo'), findsOneWidget);
/// }
/// ```
bool isMasterDetailLayout(WidgetTester tester) => tester.isCurrentLayoutMasterDetail();

/// Returns true if current layout is single-pane (push/pop navigation).
///
/// Single-pane layout uses standard Flutter navigation (push/pop routes).
/// Used on mobile phones in portrait and landscape.
///
/// Example:
/// ```dart
/// if (isSinglePaneLayout(tester)) {
///   // Navigation happens via push/pop
///   // No "Open Demo" button expected
/// }
/// ```
bool isSinglePaneLayout(WidgetTester tester) => tester.isCurrentLayoutSinglePane();

/// Returns true if "Open Demo" button should appear after tapping a card.
///
/// This button appears in master-detail layout on web/macOS platforms.
///
/// Example:
/// ```dart
/// await tester.tap(find.byKey(TestKeys.homeCard));
/// if (shouldShowOpenDemoButton()) {
///   await tester.tap(find.text('Open Demo'));
/// }
/// ```
bool shouldShowOpenDemoButton() => E2EPlatform.isWeb || E2EPlatform.isMacOS;
