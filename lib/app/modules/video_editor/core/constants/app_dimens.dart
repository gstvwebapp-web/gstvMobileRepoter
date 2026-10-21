/// Spacing, radius and sizing constants used across the design system.
/// Widgets should reference these instead of raw numeric literals so the
/// whole app's density can be tuned from one place.
class AppDimens {
  const AppDimens._();

  // Spacing scale (4pt grid)
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;

  // Radii
  static const double radiusSmall = 8;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double radiusPill = 100;

  // Elevation
  static const double elevationLow = 2;
  static const double elevationMedium = 6;
  static const double elevationHigh = 12;

  // Editor / timeline
  static const double timelineHeight = 88;
  static const double timelineClipMinWidth = 48;
  static const double bottomPanelHeight = 260;
  static const double toolbarIconSize = 26;
  static const double thumbnailStripHeight = 64;

  // Buttons
  static const double buttonHeight = 52;
  static const double fabSize = 64;
}
