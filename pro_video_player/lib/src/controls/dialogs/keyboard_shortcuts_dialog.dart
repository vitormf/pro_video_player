import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../video_player_theme.dart';

/// Represents a single keyboard shortcut entry.
class KeyboardShortcut {
  /// Creates a keyboard shortcut.
  const KeyboardShortcut({required this.keys, required this.description, this.platformSpecific = false});

  /// The key combination (e.g., ['Shift', 'Left Arrow']).
  final List<String> keys;

  /// Description of what the shortcut does.
  final String description;

  /// Whether this shortcut is platform-specific.
  final bool platformSpecific;
}

/// Category of keyboard shortcuts.
class ShortcutCategory {
  /// Creates a shortcut category.
  const ShortcutCategory({required this.name, required this.shortcuts});

  /// The category name (e.g., 'Playback Controls').
  final String name;

  /// The shortcuts in this category.
  final List<KeyboardShortcut> shortcuts;
}

/// A dialog that displays keyboard shortcuts for the video player.
///
/// On desktop/web, shows as a modal dialog.
/// On mobile, shows as a bottom sheet.
///
/// Example:
/// ```dart
/// KeyboardShortcutsDialog.show(
///   context: context,
///   theme: theme,
/// );
/// ```
class KeyboardShortcutsDialog {
  KeyboardShortcutsDialog._();

  /// Shows the keyboard shortcuts help dialog.
  ///
  /// The dialog adapts to the platform:
  /// - Desktop/web: modal dialog with 500px width
  /// - Mobile: bottom sheet
  static void show({required BuildContext context, required VideoPlayerTheme theme}) {
    final isDesktop =
        !kIsWeb &&
            (Theme.of(context).platform == TargetPlatform.macOS ||
                Theme.of(context).platform == TargetPlatform.windows ||
                Theme.of(context).platform == TargetPlatform.linux) ||
        kIsWeb;

    if (isDesktop) {
      // Desktop: show as modal dialog
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.backgroundColor,
            title: Row(
              children: [
                Icon(Icons.keyboard, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Keyboard Shortcuts',
                  style: TextStyle(color: theme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: getShortcutCategories()
                      .map((category) => _CategorySection(category: category, theme: theme))
                      .toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(color: theme.primaryColor)),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile: show as bottom sheet
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: theme.backgroundColor,
          builder: (context) => SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.keyboard, color: theme.primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Keyboard Shortcuts',
                          style: TextStyle(color: theme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...getShortcutCategories().map((category) => _CategorySection(category: category, theme: theme)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  /// Returns all shortcut categories with data.
  static List<ShortcutCategory> getShortcutCategories() => const [
    ShortcutCategory(
      name: 'Playback Controls',
      shortcuts: [
        KeyboardShortcut(keys: ['Space'], description: 'Play / Pause'),
        KeyboardShortcut(keys: ['Media Play/Pause'], description: 'Play / Pause'),
        KeyboardShortcut(keys: ['Media Stop'], description: 'Stop'),
      ],
    ),
    ShortcutCategory(
      name: 'Navigation',
      shortcuts: [
        KeyboardShortcut(keys: ['←'], description: 'Seek backward 5s'),
        KeyboardShortcut(keys: ['→'], description: 'Seek forward 5s'),
        KeyboardShortcut(keys: ['Shift', '←'], description: 'Seek backward 15s'),
        KeyboardShortcut(keys: ['Shift', '→'], description: 'Seek forward 15s'),
        KeyboardShortcut(keys: ['Media Previous'], description: 'Previous track (playlist)'),
        KeyboardShortcut(keys: ['Media Next'], description: 'Next track (playlist)'),
      ],
    ),
    ShortcutCategory(
      name: 'Volume & Speed',
      shortcuts: [
        KeyboardShortcut(keys: ['↑'], description: 'Increase volume'),
        KeyboardShortcut(keys: ['↓'], description: 'Decrease volume'),
        KeyboardShortcut(keys: ['Shift', '↑'], description: 'Increase speed'),
        KeyboardShortcut(keys: ['Shift', '↓'], description: 'Decrease speed'),
        KeyboardShortcut(keys: ['M'], description: 'Toggle mute'),
      ],
    ),
    ShortcutCategory(
      name: 'View',
      shortcuts: [
        KeyboardShortcut(keys: ['F'], description: 'Toggle fullscreen'),
        KeyboardShortcut(keys: ['Escape'], description: 'Exit fullscreen'),
        KeyboardShortcut(keys: ['?'], description: 'Show this help'),
      ],
    ),
  ];
}

/// Widget that displays a category section with header and shortcuts.
class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.theme});

  final ShortcutCategory category;
  final VideoPlayerTheme theme;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(
          category.name,
          style: TextStyle(color: theme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      ...category.shortcuts.map((shortcut) => _ShortcutRow(shortcut: shortcut, theme: theme)),
    ],
  );
}

/// Widget that displays a single shortcut row with key badge and description.
class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.shortcut, required this.theme});

  final KeyboardShortcut shortcut;
  final VideoPlayerTheme theme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        _KeyBadge(keys: shortcut.keys, theme: theme),
        const SizedBox(width: 16),
        Expanded(
          child: Text(shortcut.description, style: TextStyle(color: theme.secondaryColor, fontSize: 14)),
        ),
      ],
    ),
  );
}

/// Widget that displays keyboard keys in rounded rectangles.
class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.keys, required this.theme});

  final List<String> keys;
  final VideoPlayerTheme theme;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < keys.length; i++) ...[
        if (i > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('+', style: TextStyle(color: theme.primaryColor.withValues(alpha: 0.6), fontSize: 12)),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.3),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keys[i],
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ],
  );
}
