import 'dart:ui' show Color;

/// Style attributes for a styled text span in subtitles.
///
/// Represents formatting that can be applied to subtitle text,
/// extracted from subtitle format-specific styling tags:
/// - **WebVTT**: `<b>`, `<i>`, `<u>`, `<c.classname>`
/// - **SSA/ASS**: `{\b1}`, `{\i1}`, `{\u1}`, `{\c&HBBGGRR&}`, `{\fs##}`
/// - **TTML**: `tts:fontWeight`, `tts:fontStyle`, `tts:textDecoration`, `tts:color`
class SubtitleTextStyle {
  /// Creates a subtitle text style.
  const SubtitleTextStyle({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.fontFamily,
  });

  /// Whether the text is bold.
  final bool isBold;

  /// Whether the text is italic.
  final bool isItalic;

  /// Whether the text is underlined.
  final bool isUnderline;

  /// Whether the text has strikethrough.
  final bool isStrikethrough;

  /// Text color (foreground).
  ///
  /// SSA/ASS uses BGR format (&HBBGGRR&), which is converted to standard ARGB.
  /// WebVTT/TTML use CSS-style colors.
  final Color? color;

  /// Background color behind the text.
  final Color? backgroundColor;

  /// Font size in pixels.
  ///
  /// SSA/ASS uses `{\fs##}` tags.
  final double? fontSize;

  /// Font family name.
  ///
  /// SSA/ASS uses `{\fn<name>}` tags.
  final String? fontFamily;

  /// Whether this style has any formatting.
  bool get hasFormatting =>
      isBold ||
      isItalic ||
      isUnderline ||
      isStrikethrough ||
      color != null ||
      backgroundColor != null ||
      fontSize != null ||
      fontFamily != null;

  /// Creates a copy with merged values from [other].
  ///
  /// Values from [other] take precedence when not null/false.
  SubtitleTextStyle merge(SubtitleTextStyle other) => SubtitleTextStyle(
    isBold: other.isBold || isBold,
    isItalic: other.isItalic || isItalic,
    isUnderline: other.isUnderline || isUnderline,
    isStrikethrough: other.isStrikethrough || isStrikethrough,
    color: other.color ?? color,
    backgroundColor: other.backgroundColor ?? backgroundColor,
    fontSize: other.fontSize ?? fontSize,
    fontFamily: other.fontFamily ?? fontFamily,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubtitleTextStyle) return false;
    return isBold == other.isBold &&
        isItalic == other.isItalic &&
        isUnderline == other.isUnderline &&
        isStrikethrough == other.isStrikethrough &&
        color == other.color &&
        backgroundColor == other.backgroundColor &&
        fontSize == other.fontSize &&
        fontFamily == other.fontFamily;
  }

  @override
  int get hashCode =>
      Object.hash(isBold, isItalic, isUnderline, isStrikethrough, color, backgroundColor, fontSize, fontFamily);

  @override
  String toString() =>
      'SubtitleTextStyle(bold: $isBold, italic: $isItalic, underline: $isUnderline, '
      'strikethrough: $isStrikethrough, color: $color, backgroundColor: $backgroundColor, '
      'fontSize: $fontSize, fontFamily: $fontFamily)';
}

/// A span of text with optional styling.
///
/// Used to represent rich text in subtitles where different parts
/// of the text may have different formatting.
class StyledTextSpan {
  /// Creates a styled text span.
  const StyledTextSpan({required this.text, this.style});

  /// Creates a plain text span with no styling.
  const StyledTextSpan.plain(this.text) : style = null;

  /// The text content.
  final String text;

  /// Optional style for this span.
  ///
  /// If null, the span uses the default subtitle style.
  final SubtitleTextStyle? style;

  /// Whether this span has any custom styling.
  bool get hasStyle => style != null && style!.hasFormatting;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StyledTextSpan) return false;
    return text == other.text && style == other.style;
  }

  @override
  int get hashCode => Object.hash(text, style);

  @override
  String toString() => 'StyledTextSpan(text: "$text", style: $style)';
}
