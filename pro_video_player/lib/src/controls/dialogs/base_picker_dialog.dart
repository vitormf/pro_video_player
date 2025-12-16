import 'dart:async';

import 'package:flutter/material.dart';

import '../../video_player_theme.dart';
import 'picker_dialog_utils.dart';

/// Base class for picker dialogs that show a list of selectable items.
///
/// Automatically adapts to platform:
/// - Desktop/web with context menu: popup menu at specified position
/// - Mobile or no context menu: bottom sheet
///
/// Type parameter [T] is the type of items in the picker list.
class BasePickerDialog<T> {
  BasePickerDialog._();

  /// Shows a picker dialog with a list of items.
  ///
  /// The dialog adapts to the platform:
  /// - Desktop/web with [lastContextMenuPosition]: popup menu at that position
  /// - Mobile or no context menu position: bottom sheet
  ///
  /// Parameters:
  /// - [context]: The build context
  /// - [theme]: Theme for styling the dialog
  /// - [title]: Title displayed in the dialog (mobile only)
  /// - [items]: List of items to display
  /// - [itemLabelBuilder]: Function that returns the display label for an item
  /// - [isItemSelected]: Function that checks if an item is currently selected
  /// - [onItemSelected]: Callback when an item is tapped
  /// - [onDismiss]: Callback when the dialog is dismissed
  /// - [lastContextMenuPosition]: Optional position for popup menu (desktop)
  /// - [showCheckIcon]: Whether to show a check icon for selected items (default: true)
  static void show<T>({
    required BuildContext context,
    required VideoPlayerTheme theme,
    required String title,
    required List<T> items,
    required String Function(T item) itemLabelBuilder,
    required bool Function(T item) isItemSelected,
    required void Function(T item) onItemSelected,
    required VoidCallback onDismiss,
    Offset? lastContextMenuPosition,
    bool showCheckIcon = true,
  }) {
    final isDesktop = isDesktopPlatform(context);

    // Desktop/web: show as popup menu continuation
    if (isDesktop && lastContextMenuPosition != null) {
      final position = lastContextMenuPosition;
      unawaited(
        showMenu<T>(
          context: context,
          position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
          items: items
              .map(
                (item) => PopupMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      if (showCheckIcon) Icon(isItemSelected(item) ? Icons.check : null, size: 20),
                      if (showCheckIcon) const SizedBox(width: 12),
                      Text(itemLabelBuilder(item)),
                    ],
                  ),
                ),
              )
              .toList(),
        ).then((selectedItem) {
          if (selectedItem != null) {
            onItemSelected(selectedItem);
          }
          onDismiss();
        }),
      );
      return;
    }

    // Mobile: show as bottom sheet
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: theme.backgroundColor,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...items.map((item) {
                  final isSelected = isItemSelected(item);
                  return ListTile(
                    title: Text(
                      itemLabelBuilder(item),
                      style: TextStyle(
                        color: isSelected ? theme.progressBarActiveColor : theme.primaryColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: showCheckIcon && isSelected
                        ? Icon(Icons.check, color: theme.progressBarActiveColor)
                        : null,
                    onTap: () {
                      onItemSelected(item);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ).then((_) => onDismiss()),
    );
  }
}
