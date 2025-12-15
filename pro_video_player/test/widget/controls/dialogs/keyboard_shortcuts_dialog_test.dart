import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/src/controls/dialogs/keyboard_shortcuts_dialog.dart';
import 'package:pro_video_player/src/video_player_theme.dart';

void main() {
  group('KeyboardShortcut model', () {
    test('creates with required fields', () {
      const shortcut = KeyboardShortcut(keys: ['Space'], description: 'Play / Pause');

      expect(shortcut.keys, equals(['Space']));
      expect(shortcut.description, equals('Play / Pause'));
      expect(shortcut.platformSpecific, isFalse);
    });

    test('creates with platform-specific flag', () {
      const shortcut = KeyboardShortcut(keys: ['Cmd', 'Q'], description: 'Quit', platformSpecific: true);

      expect(shortcut.platformSpecific, isTrue);
    });

    test('handles multiple keys', () {
      const shortcut = KeyboardShortcut(keys: ['Shift', 'Left Arrow'], description: 'Seek backward 15s');

      expect(shortcut.keys, hasLength(2));
      expect(shortcut.keys, equals(['Shift', 'Left Arrow']));
    });

    test('default platformSpecific is false', () {
      const shortcut = KeyboardShortcut(keys: ['M'], description: 'Mute');

      expect(shortcut.platformSpecific, isFalse);
    });
  });

  group('ShortcutCategory model', () {
    test('creates with name and shortcuts list', () {
      const category = ShortcutCategory(
        name: 'Playback',
        shortcuts: [
          KeyboardShortcut(keys: ['Space'], description: 'Play / Pause'),
        ],
      );

      expect(category.name, equals('Playback'));
      expect(category.shortcuts, hasLength(1));
      expect(category.shortcuts.first.keys, equals(['Space']));
    });

    test('can contain multiple shortcuts', () {
      const category = ShortcutCategory(
        name: 'Navigation',
        shortcuts: [
          KeyboardShortcut(keys: ['←'], description: 'Seek backward'),
          KeyboardShortcut(keys: ['→'], description: 'Seek forward'),
          KeyboardShortcut(keys: ['Shift', '←'], description: 'Seek backward 15s'),
        ],
      );

      expect(category.shortcuts, hasLength(3));
      expect(category.name, equals('Navigation'));
    });
  });

  group('KeyboardShortcutsDialog.getShortcutCategories', () {
    test('returns 4 categories', () {
      final categories = KeyboardShortcutsDialog.getShortcutCategories();

      expect(categories, hasLength(4));
    });

    test('includes Playback Controls category', () {
      final categories = KeyboardShortcutsDialog.getShortcutCategories();
      final playback = categories.firstWhere((c) => c.name == 'Playback Controls');

      expect(playback.shortcuts, isNotEmpty);
      expect(playback.shortcuts.any((s) => s.keys.contains('Space') && s.description.contains('Play')), isTrue);
    });

    test('includes Navigation category with arrow keys', () {
      final categories = KeyboardShortcutsDialog.getShortcutCategories();
      final navigation = categories.firstWhere((c) => c.name == 'Navigation');

      expect(navigation.shortcuts, isNotEmpty);
      expect(navigation.shortcuts.any((s) => s.keys.contains('←')), isTrue);
      expect(navigation.shortcuts.any((s) => s.keys.contains('→')), isTrue);
      expect(navigation.shortcuts.any((s) => s.keys.contains('Shift') && s.keys.contains('←')), isTrue);
    });

    test('includes Volume & Speed category', () {
      final categories = KeyboardShortcutsDialog.getShortcutCategories();
      final volumeSpeed = categories.firstWhere((c) => c.name == 'Volume & Speed');

      expect(volumeSpeed.shortcuts, isNotEmpty);
      expect(volumeSpeed.shortcuts.any((s) => s.keys.contains('↑')), isTrue);
      expect(volumeSpeed.shortcuts.any((s) => s.keys.contains('M') && s.description.contains('mute')), isTrue);
    });

    test('includes View category with fullscreen and help', () {
      final categories = KeyboardShortcutsDialog.getShortcutCategories();
      final view = categories.firstWhere((c) => c.name == 'View');

      expect(view.shortcuts, isNotEmpty);
      expect(view.shortcuts.any((s) => s.keys.contains('F') && s.description.contains('fullscreen')), isTrue);
      expect(view.shortcuts.any((s) => s.keys.contains('Escape')), isTrue);
      expect(view.shortcuts.any((s) => s.keys.contains('?') && s.description.contains('help')), isTrue);
    });

    test('shortcuts have accurate descriptions', () {
      final categories = KeyboardShortcutsDialog.getShortcutCategories();
      final allShortcuts = categories.expand((c) => c.shortcuts).toList();

      // Check some key shortcuts
      final spaceShortcut = allShortcuts.firstWhere((s) => s.keys.contains('Space'));
      expect(spaceShortcut.description, contains('Play'));

      final muteShortcut = allShortcuts.firstWhere((s) => s.keys.contains('M'));
      expect(muteShortcut.description.toLowerCase(), contains('mute'));

      final helpShortcut = allShortcuts.firstWhere((s) => s.keys.contains('?'));
      expect(helpShortcut.description.toLowerCase(), contains('help'));
    });
  });

  group('KeyboardShortcutsDialog UI', () {
    late VideoPlayerTheme theme;

    setUp(() {
      theme = VideoPlayerTheme.dark();
    });

    Widget buildTestApp({required Widget child, TargetPlatform platform = TargetPlatform.macOS}) => MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(body: child),
    );

    testWidgets('shows as AlertDialog on desktop platforms (macOS)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard), findsOneWidget);
    });

    testWidgets('shows as AlertDialog on desktop platforms (Windows)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          platform: TargetPlatform.windows,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    });

    testWidgets('shows as AlertDialog on desktop platforms (Linux)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          platform: TargetPlatform.linux,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    });

    testWidgets('shows as bottom sheet on mobile platforms (iOS)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          platform: TargetPlatform.iOS,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard), findsOneWidget);
    });

    testWidgets('shows as bottom sheet on mobile platforms (Android)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          platform: TargetPlatform.android,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    });

    testWidgets('displays all category names', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Playback Controls'), findsOneWidget);
      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('Volume & Speed'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    });

    testWidgets('displays shortcut descriptions', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Play / Pause'), findsWidgets);
      expect(find.text('Seek backward 5s'), findsOneWidget);
      expect(find.text('Seek forward 5s'), findsOneWidget);
      expect(find.text('Increase volume'), findsOneWidget);
      expect(find.text('Toggle mute'), findsOneWidget);
      expect(find.text('Toggle fullscreen'), findsOneWidget);
      expect(find.text('Show this help'), findsOneWidget);
    });

    testWidgets('displays key badges with proper formatting', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Find individual key text elements (they're in Container widgets)
      expect(find.text('Space'), findsWidgets);
      expect(find.text('←'), findsWidgets);
      expect(find.text('→'), findsWidgets);
      expect(find.text('Shift'), findsWidgets);
      expect(find.text('M'), findsWidgets);
      expect(find.text('F'), findsWidgets);
    });

    testWidgets('close button dismisses dialog on desktop', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('dialog uses theme colors', (tester) async {
      final customTheme = VideoPlayerTheme.light();

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: customTheme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.backgroundColor, equals(customTheme.backgroundColor));
    });

    testWidgets('dialog is scrollable when content is long', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('bottom sheet has SafeArea on mobile', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          platform: TargetPlatform.iOS,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('displays media key shortcuts', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Media Play/Pause'), findsOneWidget);
      expect(find.text('Media Stop'), findsOneWidget);
      expect(find.text('Media Previous'), findsOneWidget);
      expect(find.text('Media Next'), findsOneWidget);
    });

    testWidgets('escape key description is present', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Escape'), findsOneWidget);
      expect(find.text('Exit fullscreen'), findsOneWidget);
    });

    testWidgets('shift modifier shortcuts are displayed', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Seek backward 15s'), findsOneWidget);
      expect(find.text('Seek forward 15s'), findsOneWidget);
      expect(find.text('Increase speed'), findsOneWidget);
      expect(find.text('Decrease speed'), findsOneWidget);
    });

    testWidgets('dialog has proper width constraint on desktop', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Find the SizedBox that contains the width constraint by checking all SizedBoxes
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(of: find.byType(AlertDialog), matching: find.byType(SizedBox)),
      );

      final widthConstrainedBox = sizedBoxes.firstWhere(
        (box) => box.width == 500,
        orElse: () => throw TestFailure('No SizedBox with width 500 found'),
      );

      expect(widthConstrainedBox.width, equals(500));
    });

    testWidgets('tapping outside bottom sheet dismisses it on mobile', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          platform: TargetPlatform.iOS,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context: context, theme: theme),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Keyboard Shortcuts'), findsOneWidget);

      // Tap outside the bottom sheet (on the barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Keyboard Shortcuts'), findsNothing);
    });
  });
}
