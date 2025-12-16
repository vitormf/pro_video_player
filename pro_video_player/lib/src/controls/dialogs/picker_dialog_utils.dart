import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Utility functions for picker dialogs

/// Determines if the current platform should use desktop-style UI (popup menus).
///
/// Returns `true` for:
/// - macOS, Windows, Linux (when not on web)
/// - Web platform
///
/// Returns `false` for:
/// - iOS, Android (mobile platforms)
bool isDesktopPlatform(BuildContext context) =>
    !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.macOS ||
            Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux) ||
    kIsWeb;
