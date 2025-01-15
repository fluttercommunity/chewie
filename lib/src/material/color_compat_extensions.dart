import 'package:flutter/material.dart';

//ignore_for_file: deprecated_member_use
extension ColorCompatExtensions on Color {
  /// Returns a new color that matches this color with the given opacity.
  ///
  /// This is a compatibility layer that ensures compatibility with Flutter
  /// versions below 3.27. In Flutter 3.27 and later, `Color.withOpacity`
  /// has been deprecated in favor of `Color.withValues`.
  ///
  /// This method bridges the gap by providing a consistent way to adjust
  /// the opacity of a color across different Flutter versions.
  ///
  /// **Important:** Once the minimum supported Flutter version is bumped
  /// to 3.27 or higher, this method should be removed and replaced with
  /// `withValues(alpha: opacity)`.
  ///
  /// See also:
  ///  * [Color.withOpacity], which is deprecated in Flutter 3.27 and later.
  ///  * [Color.withValues], the recommended replacement for `withOpacity`.
  Color withOpacityCompat(double opacity) {
    // Compatibility layer that uses the legacy withOpacity method, while
    // ignoring the deprecation for now (in order to guarantee N-1 minimum
    // version compatibility).
    // Once it's removed from a future update, we'll have to replace uses of
    // this method with withValues(alpha: opacity).
    // TODO: Replace this bridge method once the above holds true.
    return withOpacity(opacity);
  }
}
