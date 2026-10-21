/// Global, compile-time-ish configuration and feature flags.
///
/// Keeping these as static fields (rather than scattering `bool` literals
/// through the codebase) means QA/build variants can flip behaviour by
/// editing exactly one file, and it documents *why* a feature is gated.
class AppConfig {
  const AppConfig._();

  /// Autosave interval for in-progress projects (project JSON + thumbnail).
  static const Duration autosaveInterval = Duration(seconds: 10);

  /// Maximum number of undo/redo history entries kept in memory per project.
  static const int maxHistoryEntries = 50;

  /// Maximum number of clips allowed in a single timeline. `pro_video_editor`
  /// has no hard limit, but unbounded clip counts degrade thumbnail/timeline
  /// scroll performance on low-end devices, so we cap it and surface a
  /// friendly message instead of letting the UI degrade silently.
  static const int maxTimelineClips = 50;

  /// Whether ffmpeg_kit is allowed to be used as a fallback renderer for
  /// export presets that `pro_video_editor`'s native pipeline cannot satisfy
  /// (e.g. certain legacy codecs). Disabled by default because of the GPL
  /// dependency's binary size (~ 60-100MB per ABI) and licensing footprint;
  /// flip to true only if your distribution channel allows GPL binaries.
  static const bool enableFfmpegFallback = false;

  /// Thumbnail cache budget, in megabytes, before the LRU cache in
  /// `core/services/thumbnail_cache_service.dart` starts evicting entries.
  static const int thumbnailCacheBudgetMb = 128;

  /// Default export preset shown pre-selected in the export sheet.
  static const String defaultExportResolution = '1080p';
  static const int defaultExportFps = 30;

  /// GetStorage box names.
  static const String storageBoxSettings = 'settings_box';
  static const String storageBoxProjects = 'projects_box';
  static const String storageBoxRecentFiles = 'recent_files_box';
}
