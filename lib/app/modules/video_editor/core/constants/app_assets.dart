/// Static references to bundled assets. Keeping paths here avoids typo'd
/// string literals scattered through the widget tree.
class AppAssets {
  const AppAssets._();

  static const String _images = 'assets/images';
  static const String _lottie = 'assets/lottie';
  static const String _icons = 'assets/icons';

  static const String logo = '$_images/logo.png';
  static const String onboardingBg = '$_images/onboarding_bg.png';
  static const String placeholderThumb = '$_images/placeholder_thumb.png';
  static const String emptyState = '$_images/empty_state.png';

  static const String splashLottie = '$_lottie/splash.json';
  static const String exportingLottie = '$_lottie/exporting.json';
  static const String successLottie = '$_lottie/success.json';
  static const String emptyLottie = '$_lottie/empty.json';

  static const String icCrop = '$_icons/ic_crop.svg';
  static const String icTrim = '$_icons/ic_trim.svg';
  static const String icRotate = '$_icons/ic_rotate.svg';
  static const String icFilters = '$_icons/ic_filters.svg';
  static const String icAudio = '$_icons/ic_audio.svg';
  static const String icText = '$_icons/ic_text.svg';
  static const String icSticker = '$_icons/ic_sticker.svg';
  static const String icSpeed = '$_icons/ic_speed.svg';
  static const String icTransition = '$_icons/ic_transition.svg';
  static const String icBackground = '$_icons/ic_background.svg';
}
