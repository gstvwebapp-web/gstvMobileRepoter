import 'package:get/get.dart';
/// All user-facing copy lives here so the app can later be localised by
/// swapping this file (or feeding these keys into `intl`) without touching
/// widget code.
class AppStrings {
  const AppStrings._();

  static String get appName => 'appName'.tr;

  // Splash
  static String get splashTagline => 'splashTagline'.tr;

  // Permissions
  static String get permissionsTitle => 'permissionsTitle'.tr;
  static String get permissionsSubtitle => 'permissionsSubtitle'.tr;
  // 'We need a few permissions to import, edit and save your videos.';
  static String get permissionCamera => 'permissionCamera'.tr;
  static String get permissionCameraDesc => 'permissionCameraDesc'.tr;
  static String get permissionGallery => 'permissionGallery'.tr;
  static String get permissionGalleryDesc => 'permissionGalleryDesc'.tr;
  static String get permissionMicrophone => 'permissionMicrophone'.tr;
  static String get permissionMicrophoneDesc => 'permissionMicrophoneDesc'.tr;
  static String get permissionStorage => 'permissionStorage'.tr;
  static String get permissionStorageDesc => 'permissionStorageDesc'.tr;
  static String get grantAccess => 'grantAccess'.tr;
  static String get permissionDeniedForever => 'permissionDeniedForever'.tr;
  // 'Permission permanently denied. Please enable it from system settings.';
  static String get openSettings => 'openSettings'.tr;
  static String get continueLabel => 'continueLabel'.tr;

  // Home
  static String get homeGreeting => 'homeGreeting'.tr;
  static String get importVideo => 'importVideo'.tr;
  static String get recentProjects => 'recentProjects'.tr;
  static String get templates => 'templates'.tr;
  static String get noRecentProjects => 'noRecentProjects'.tr;
  static String get settings => 'settings'.tr;

  // Import sheet
  static String get chooseSource => 'chooseSource'.tr;
  static String get fromGallery => 'fromGallery'.tr;
  static String get fromCamera => 'fromCamera'.tr;
  static String get recentFiles => 'recentFiles'.tr;
  static String get dragDropHint => 'dragDropHint'.tr;

  // Editor
  static String get editorTitle => 'editorTitle'.tr;
  static String get tabTrim => 'tabTrim'.tr;
  static String get tabCrop => 'tabCrop'.tr;
  static String get tabRotate => 'tabRotate'.tr;
  static String get tabFilters => 'tabFilters'.tr;
  static String get tabAudio => 'tabAudio'.tr;
  static String get tabText => 'tabText'.tr;
  static String get tabStickers => 'tabStickers'.tr;
  static String get tabSpeed => 'tabSpeed'.tr;
  static String get tabTransitions => 'tabTransitions'.tr;
  static String get tabBackground => 'tabBackground'.tr;
  static String get tabAdjust => 'tabAdjust'.tr;
  static String get undo => 'undo'.tr;
  static String get redo => 'redo'.tr;
  static String get export => 'export'.tr;

  // Export
  static String get exportingTitle => 'exportingTitle'.tr;
  static String get exportingSubtitle => 'exportingSubtitle'.tr;
  static String get exportCancel => 'exportCancel'.tr;
  static String get exportRetry => 'exportRetry'.tr;
  static String get exportDone => 'exportDone'.tr;
  static String get exportFailed => 'exportFailed'.tr;
  static String get saveToGallery => 'saveToGallery'.tr;
  static String get shareVideo => 'shareVideo'.tr;

  // Errors
  static String get errorNoPermission => 'errorNoPermission'.tr;
  static String get errorLowStorage => 'errorLowStorage'.tr;
  static String get errorUnsupportedVideo => 'errorUnsupportedVideo'.tr;
  static String get errorCorruptedVideo => 'errorCorruptedVideo'.tr;
  static String get errorGeneric => 'errorGeneric'.tr;
}