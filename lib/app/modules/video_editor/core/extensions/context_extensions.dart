import 'package:flutter/material.dart';

/// Shorthand accessors for theme/media-query values, used throughout the
/// presentation layer to avoid repeating `Theme.of(context)` boilerplate.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get viewPadding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isTablet => screenWidth >= 600;
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;
}
