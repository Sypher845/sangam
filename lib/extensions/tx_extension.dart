import 'package:flutter/material.dart';

import '../widgets/translated_text.dart';

/// Extension providing a convenient `tr()` getter on String to
/// create a [TranslatedText] widget in-place.
extension Tx on String {
  /// Example:  'Hello'.tr(style: TextStyle(fontSize: 18))
  Widget tr({
    TextStyle? style,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return TranslatedText(
      this,
      style: style,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
