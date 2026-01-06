/// ClosedCaption widget for video_player API compatibility.
///
/// This widget provides the exact video_player API signature for compatibility.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'package:flutter/material.dart';

import '../compat_annotation.dart';

/// A widget for displaying closed captions.
///
/// [video_player compatibility] This widget matches the video_player API exactly.
@videoPlayerCompat
class ClosedCaption extends StatelessWidget {
  /// Creates a closed caption widget.
  ///
  /// [video_player compatibility] This constructor matches video_player exactly.
  const ClosedCaption({super.key, this.text, this.textStyle});

  /// The text to display.
  final String? text;

  /// The style to use for the text.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveTextStyle =
        textStyle ?? DefaultTextStyle.of(context).style.copyWith(fontSize: 36, color: Colors.white);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(color: const Color(0xB8000000), borderRadius: BorderRadius.circular(4)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(text, style: effectiveTextStyle),
          ),
        ),
      ),
    );
  }
}
