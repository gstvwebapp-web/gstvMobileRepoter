import 'package:flutter/material.dart';

/// Centralised colour palette for the app.
///
/// Keeping every raw colour value in one place means the light/dark
/// [ThemeData] built in `core/theme/app_theme.dart` never hard-codes a
/// colour itself — it only references these constants. This is what makes
/// swapping the whole palette (e.g. a rebrand) a one-file change.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF7B2FF7);
  static const Color primaryVariant = Color(0xFF9F44FF);
  static const Color secondary = Color(0xFF00C2CB);
  static const Color accent = Color(0xFFFF5C8D);

  // Gradients
  static const List<Color> brandGradient = [
    Color(0xFF7B2FF7),
    Color(0xFFF107A3),
  ];

  static const List<Color> exportGradient = [
    Color(0xFF00C2CB),
    Color(0xFF7B2FF7),
  ];

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1B1B23);
  static const Color lightBorder = Color(0xFFE7E7EF);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0E0E13);
  static const Color darkSurface = Color(0xFF17171F);
  static const Color darkCard = Color(0xFF1E1E28);
  static const Color darkOnSurface = Color(0xFFF3F3F7);
  static const Color darkBorder = Color(0xFF2A2A36);

  // Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE94057);
  static const Color info = Color(0xFF2F80ED);

  // Timeline / editor
  static const Color timelineTrack = Color(0xFF26262F);
  static const Color timelineClip = Color(0xFF3A3A47);
  static const Color timelinePlayhead = Color(0xFFFF5C8D);
  static const Color timelineSelected = Color(0xFF7B2FF7);

  static const Color overlayScrim = Color(0x99000000);
}
