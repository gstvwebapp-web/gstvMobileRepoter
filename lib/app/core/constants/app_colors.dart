import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF8A0B00);
  static const Color secondary = Color(0xFFDABB63);
  
  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF8A0B00),
    Color(0xFFDABB63),
  ];
  
  // Common colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  
  // Text colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF8F8F8);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Shadow colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // UI Component colors
  static const Color cardBackground = Color(0xFFF7FAFC);
  static const Color selectedBorder = Color(0xFF8A0B00);
  static const Color unselectedBorder = Color(0xFFE2E8F0);
  static const Color tabUnselected = Color(0xFF718096);
  static const Color dashboardBackground = Color(0xFFF8FAFC);
  static const Color videoEditorBackground = Color(0xFF404040);
  static const Color videoEditorSurface = Color(0xFF2D2D2D);

  // Legacy colors (to be phased out)
  static const Color legacyBlue = Color(0xFF8A0B00);
  static const Color legacyPurple = Color(0xFF764ba2);
  static const Color legacyGrey = Color(0xFFA0AEC0);

  // Drawing/Editor colors
  static const Color red = Color(0xFFF44336);
  static const Color blue = Color(0xFF2196F3);
  static const Color green = Color(0xFF4CAF50);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color purple = Color(0xFF9C27B0);
  static const Color orange = Color(0xFFFF9800);
  static const Color pink = Color(0xFFE91E63);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color amber = Color(0xFFFFC107);
  static const Color indigo = Color(0xFF3F51B5);
  static const Color brown = Color(0xFF795548);
  static const Color grey = Color(0xFF9E9E9E);

  // Semantic colors with opacity
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color black54 = Color(0x8A000000);

  // Logo colors
  static const Color logoGS = Color(0xFF8D4E2A); // Brown for GS
  static const Color logoTV = Color(0xFFFF8C42); // Orange for TV
  
  // Gradient definitions
  static const LinearGradient primaryLinearGradient = LinearGradient(
    colors: primaryGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: primaryGradient,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient primaryHorizontalGradient = LinearGradient(
    colors: primaryGradient,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Legacy gradients (to be phased out)
  static const LinearGradient legacyButtonGradient = LinearGradient(
    colors: [legacyBlue, legacyPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Color lists for pickers and editors
  static const List<Color> textEditorColors = [
    black, red, green, blue,
    orange, purple, brown, pink,
    grey, cyan, amber, indigo,
  ];

  static const List<Color> drawingColors = [
    red, blue, green, yellow,
    purple, orange, pink, cyan,
    black, white,
  ];

  // Helper methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color primaryWithOpacity(double opacity) {
    return primary.withOpacity(opacity);
  }

  static Color secondaryWithOpacity(double opacity) {
    return secondary.withOpacity(opacity);
  }

  static Color errorWithOpacity(double opacity) {
    return error.withOpacity(opacity);
  }

  static Color blackWithOpacity(double opacity) {
    return black.withOpacity(opacity);
  }

  static Color greyWithOpacity(double opacity) {
    return grey.withOpacity(opacity);
  }
}
