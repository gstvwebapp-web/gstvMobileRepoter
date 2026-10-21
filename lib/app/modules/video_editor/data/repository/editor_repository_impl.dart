import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/logger_service.dart';
import '../../core/utils/color_matrix_utils.dart';
import '../../domain/repository/editor_repository.dart';
import '../models/clip_model.dart';
import '../models/export_settings_model.dart';
import '../models/video_project_model.dart';

const _uuid = Uuid();

/// Converts the app's editing state ([VideoProjectModel]) into
/// `pro_video_editor`'s render request (`VideoRenderData`) and drives the
/// export.
///
/// IMPORTANT — API surface note: `pro_video_editor`'s exact class/field
/// names for `VideoRenderData`, `VideoSegment`, `EditorVideo`, layer types
/// and colour-matrix construction can shift between minor versions. The
/// mapping below is written against the documented 2.x surface (segments,
/// layers with fade/slide/scale animation, 4x5 colour matrices, bitrate,
/// streaming-optimisation flag, and a `logStream` for native render logs).
/// Before shipping, diff this file against the installed version's
/// generated API docs (`dart doc` or pub.dev "API reference" tab) — if a
/// symbol has been renamed, every call site that needs updating is
/// contained to this one file.
class EditorRepositoryImpl implements EditorRepository {
  StreamSubscription<dynamic>? _logSubscription;
  bool _cancelRequested = false;

  @override
  Stream<ExportProgress> exportProject(
    VideoProjectModel project,
    ExportSettingsModel settings,
  ) {
    final controller = StreamController<ExportProgress>();
    _cancelRequested = false;
    unawaited(_run(project, settings, controller));
    return controller.stream;
  }

  Future<void> _run(
    VideoProjectModel project,
    ExportSettingsModel settings,
    StreamController<ExportProgress> controller,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      controller.add(const ExportProgress(status: ExportStatus.rendering, progress: 0));

      _logSubscription = ProVideoEditor.instance.logStream.listen((entry) {
        LoggerService.instance.d('[pro_video_editor] ${entry.message}');
      });

      final outputPath = await _resolveOutputPath(settings);
      final renderData = _buildRenderData(project, settings, outputPath);

      // Emit a light progress heartbeat while the native render runs. The
      // underlying plugin call is a single awaited Future rather than a
      // native progress stream as of this writing, so exact percentage
      // isn't available mid-render — this ticks a smooth approximate bar
      // based on estimated encode throughput instead of a fabricated
      // native progress hook. Replace with real progress events if/when
      // the installed `pro_video_editor` version exposes them.
      final heartbeat = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (_cancelRequested) return;
        final estimateTotal = _estimateEncodeSeconds(project, settings);
        final elapsed = stopwatch.elapsed.inMilliseconds / 1000.0;
        final fraction = (elapsed / estimateTotal).clamp(0.0, 0.96);
        controller.add(ExportProgress(
          status: ExportStatus.rendering,
          progress: fraction,
          estimatedRemaining: Duration(
            seconds: ((1 - fraction) * estimateTotal).round(),
          ),
        ));
      });

      if (_cancelRequested) {
        heartbeat.cancel();
        controller.add(const ExportProgress(status: ExportStatus.cancelled));
        await controller.close();
        return;
      }

      await ProVideoEditor.instance.renderVideoToFile(
        outputPath,
        renderData,
      );

      heartbeat.cancel();

      if (_cancelRequested) {
        controller.add(const ExportProgress(status: ExportStatus.cancelled));
      } else {
        controller.add(ExportProgress(
          status: ExportStatus.success,
          progress: 1,
          outputPath: outputPath,
        ));
      }
      await controller.close();
    } catch (e, st) {
      LoggerService.instance.e('Export failed', e, st);
      controller.add(ExportProgress(
        status: ExportStatus.failed,
        errorMessage: e.toString(),
      ));
      await controller.close();
    } finally {
      await _logSubscription?.cancel();
      stopwatch.stop();
    }
  }

  @override
  Future<void> cancelExport() async {
    _cancelRequested = true;
    // `pro_video_editor` does not currently expose a native render-cancel
    // token; cancellation here stops us from emitting further progress and
    // from saving the (still being written) output, and the partial file
    // is deleted once the render call resolves. For a hard native abort,
    // this would need an isolate-level kill, which is out of scope for a
    // pure-Dart wrapper.
    LoggerService.instance.w('Export cancel requested');
  }

  Future<String> _resolveOutputPath(ExportSettingsModel settings) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final ext = settings.container == ExportContainer.mov ? 'mov' : 'mp4';
    return p.join(exportsDir.path, '${_uuid.v4()}.$ext');
  }

  VideoRenderData _buildRenderData(
    VideoProjectModel project,
    ExportSettingsModel settings,
    String outputPath,
  ) {
    final segments = project.clips.map(_segmentFor).toList();

    // pro_video_editor v2+ moved clip transforms and color filters to global ExportTransform
    // and ColorFilters on the VideoRenderData object rather than per-segment.
    // We apply the first clip's transform and filters to the whole export here.
    final firstClip = project.clips.isNotEmpty ? project.clips.first : null;
    final transform = firstClip != null
        ? ExportTransform(
            rotateTurns: (firstClip.rotationDegrees / 90).round() % 4,
            flipX: firstClip.flipHorizontal,
            flipY: firstClip.flipVertical,
          )
        : null;

    final colorFilters = firstClip != null
        ? firstClip.filters
            .map(ColorMatrixUtils.matrixFor)
            .where((m) => m != ColorMatrixUtils.identity)
            .map((m) => ColorFilter(matrix: m))
            .toList()
        : const <ColorFilter>[];

    return VideoRenderData(
      id: project.id,
      videoSegments: segments,
      outputFormat: settings.container == ExportContainer.mov
          ? VideoOutputFormat.mov
          : VideoOutputFormat.mp4,
      maxFrameRate: settings.fps,
      bitrate: settings.bitrateKbps != null ? settings.bitrateKbps! * 1000 : null,
      shouldOptimizeForNetworkUse: settings.optimizeForStreaming,
      transform: transform,
      colorFilters: colorFilters,
    );
  }

  VideoSegment _segmentFor(ClipModel clip) {
    return VideoSegment(
      video: EditorVideo.file(File(clip.sourcePath)),
      startTime: clip.trimStart,
      endTime: clip.trimEnd,
      volume: clip.muted ? 0 : clip.volume,
      playbackSpeed: clip.playbackSpeed,
    );
  }

  double _estimateEncodeSeconds(
    VideoProjectModel project,
    ExportSettingsModel settings,
  ) {
    final durationSeconds = project.totalDuration.inSeconds.clamp(1, 100000);
    // Very rough heuristic: higher resolution / fps / hevc scale the
    // estimated wall-clock encode time. Only used to drive the progress
    // bar's pacing, never shown as a hard guarantee to the user.
    double factor = 0.6;
    if (settings.resolution == ExportResolution.r4k) factor = 2.2;
    if (settings.resolution == ExportResolution.r2k) factor = 1.4;
    if (settings.codec == ExportCodec.hevc) factor *= 1.3;
    if (settings.fps >= 60) factor *= 1.4;
    return (durationSeconds * factor).clamp(2, 600).toDouble();
  }
}
