import 'dart:async';
import '../../data/models/export_settings_model.dart';
import '../../data/models/video_project_model.dart';

enum ExportStatus { idle, rendering, success, failed, cancelled }

class ExportProgress {
  const ExportProgress({
    required this.status,
    this.progress = 0,
    this.estimatedRemaining,
    this.outputPath,
    this.errorMessage,
  });

  final ExportStatus status;

  /// 0.0 - 1.0
  final double progress;
  final Duration? estimatedRemaining;
  final String? outputPath;
  final String? errorMessage;
}

/// Wraps `pro_video_editor`'s render pipeline behind a stable contract so
/// the editor controller never talks to `ProVideoEditor.instance` directly.
abstract class EditorRepository {
  /// Renders [project] to a file on disk using [settings], emitting
  /// progress updates on the returned stream. The stream closes after a
  /// terminal [ExportStatus] (success/failed/cancelled) is emitted.
  Stream<ExportProgress> exportProject(
    VideoProjectModel project,
    ExportSettingsModel settings,
  );

  /// Cancels an in-flight export started by [exportProject], if any.
  Future<void> cancelExport();
}
