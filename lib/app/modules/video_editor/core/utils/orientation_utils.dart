import 'package:flutter/services.dart';

/// Small helper around [SystemChrome.setPreferredOrientations] so screens
/// that need to unlock landscape (the editor, on tablets) don't repeat the
/// same platform-channel call inline.
class OrientationUtils {
  const OrientationUtils._();

  static Future<void> allowAll() => SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

  static Future<void> portraitOnly() => SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
}
