class AppConstants {
  // App Information
  static const String appName = 'GSTV Admin';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userKey = 'user_data';
  static const String authTokenKey = 'auth_token';
  static const String isLoggedInKey = 'is_logged_in';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Snackbar Durations
  static const Duration shortSnackbarDuration = Duration(seconds: 2);
  static const Duration mediumSnackbarDuration = Duration(seconds: 3);
  static const Duration longSnackbarDuration = Duration(seconds: 5);
}
