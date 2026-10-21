import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../core/config/app_config.dart';
import '../../core/services/gallery_service.dart';
import '../../core/services/logger_service.dart';
import '../../data/models/clip_model.dart';
import '../../data/models/export_settings_model.dart';
import '../../data/models/filter_model.dart';
import '../../data/models/video_project_model.dart';
import '../../data/repository/editor_repository_impl.dart';
import '../../data/repository/project_repository_impl.dart';
import '../../domain/repository/editor_repository.dart';
import '../../domain/repository/project_repository.dart';

/// Navigation arguments passed from Home -> Editor.
class EditorArgs {
  const EditorArgs({required this.projectId});
  final String projectId;
}

enum EditorTab {
  trim,
  crop,
  rotate,
  filters,
  audio,
  speed,
}

/// Snapshot of project state used for undo/redo. Cheap to keep many of
/// these in memory since a project's JSON footprint is small (no binary
/// media is embedded — only paths and edit parameters).
class _HistoryEntry {
  _HistoryEntry(Map<String, dynamic> json) : jsonString = jsonEncode(json);
  final String jsonString;
}

class EditorController extends GetxController {
  EditorController({
    required this.args,
    EditorRepository? editorRepository,
    ProjectRepository? projectRepository,
  })  : _editorRepository = editorRepository ?? EditorRepositoryImpl(),
        _projectRepository = projectRepository ?? ProjectRepositoryImpl();

  final EditorArgs args;
  final EditorRepository _editorRepository;
  final ProjectRepository _projectRepository;

  late final Rx<VideoProjectModel> project;
  VideoPlayerController? playerController;

  final selectedClipIndex = 0.obs;
  final selectedTab = Rx<EditorTab>(EditorTab.trim);
  final isPlaying = false.obs;
  final playheadPosition = Duration.zero.obs;
  final isPlayerReady = false.obs;

  final exportProgress = Rx<ExportProgress>(
    const ExportProgress(status: ExportStatus.idle),
  );

  final List<_HistoryEntry> _undoStack = [];
  final List<_HistoryEntry> _redoStack = [];
  final canUndo = false.obs;
  final canRedo = false.obs;

  Timer? _autosaveTimer;
  StreamSubscription<ExportProgress>? _exportSubscription;

  ClipModel get selectedClip => project.value.clips[selectedClipIndex.value];

  @override
  void onInit() {
    super.onInit();
    final loaded = _projectRepository.loadProject(args.projectId);
    project = Rx<VideoProjectModel>(
      loaded ?? VideoProjectModel(title: 'Untitled project'),
    );
    _pushHistory(recordRedo: false);
    _initPlayer();
    _autosaveTimer =
        Timer.periodic(AppConfig.autosaveInterval, (_) => _autosave());
  }

  @override
  void onClose() {
    _autosaveTimer?.cancel();
    _exportSubscription?.cancel();
    playerController?.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------
  // Player
  // ---------------------------------------------------------------------

  Future<void> _initPlayer() async {
    if (project.value.clips.isEmpty) return;
    final clip = project.value.clips[selectedClipIndex.value];
    isPlayerReady.value = false;
    await playerController?.dispose();

    final file = File(clip.sourcePath);
    if (!file.existsSync()) {
      LoggerService.instance.e('Video file not found at: ${clip.sourcePath}');
      Get.snackbar('File Missing',
          'The video file for this project could not be found.');
      return;
    }

    try {
      final controller = VideoPlayerController.file(file);
      playerController = controller;
      await controller.initialize();
      controller.addListener(_onPlayerTick);
      
      // Update clip duration now that we know the real length
      if (clip.originalDuration == const Duration(seconds: 30) && clip.trimEnd == const Duration(seconds: 30)) {
        clip.originalDuration = controller.value.duration;
        clip.trimEnd = controller.value.duration;
      }
      
      await controller.seekTo(clip.trimStart);
      try {
        await controller.setPlaybackSpeed(clip.playbackSpeed);
      } catch (e) {
        LoggerService.instance.w('Could not set playback speed: $e');
      }
      await controller.setVolume(clip.muted ? 0 : clip.volume);
      
      isPlayerReady.value = true;
    } catch (e, st) {
      LoggerService.instance.e('Failed to load video: $e\n$st');
      Get.snackbar('Playback Error', 'Could not load the video file.');
    }
  }

  void _onPlayerTick() {
    final controller = playerController;
    if (controller == null || !controller.value.isInitialized) return;
    playheadPosition.value = controller.value.position;
    isPlaying.value = controller.value.isPlaying;

    // Loop playback within the clip's trim range.
    final clip = selectedClip;
    if (clip.trimEnd > clip.trimStart && controller.value.position >= clip.trimEnd) {
      controller.seekTo(clip.trimStart);
    }
  }

  Future<void> togglePlayback() async {
    final controller = playerController;
    if (controller == null) {
      Get.snackbar('Error', 'Player is null');
      return;
    }
    if (!controller.value.isInitialized) {
      Get.snackbar('Loading', 'Video is still loading...');
      return;
    }
    
    if (controller.value.isPlaying) {
      await controller.pause();
      Get.snackbar('Playback', 'Paused');
    } else {
      // If we are already at the end of the clip, restart from the trim start
      final clip = selectedClip;
      if (clip.trimEnd > clip.trimStart && controller.value.position >= clip.trimEnd) {
        await controller.seekTo(clip.trimStart);
      }
      try {
        await controller.play();
        Get.snackbar('Playback', 'Playing! isPlaying: ${controller.value.isPlaying}');
      } catch (e) {
        Get.snackbar('Playback Error', 'Failed to play: $e');
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    await playerController?.seekTo(position);
  }

  // ---------------------------------------------------------------------
  // Tabs / selection
  // ---------------------------------------------------------------------

  void selectTab(EditorTab tab) => selectedTab.value = tab;

  Future<void> selectClip(int index) async {
    selectedClipIndex.value = index;
    await _initPlayer();
  }

  // ---------------------------------------------------------------------
  // Edits — every mutating method below follows the same pattern:
  // mutate the model, push undo history, bump `project` to notify
  // listeners (Rx doesn't deep-watch nested objects), and let autosave
  // pick up the change on its next tick.
  // ---------------------------------------------------------------------

  void _commit() {
    project.refresh();
    _pushHistory();
  }

  void updateTrim(Duration start, Duration end) {
    final clip = selectedClip;
    clip.trimStart = start;
    clip.trimEnd = end;
    _commit();
  }

  void rotateClip90() {
    final clip = selectedClip;
    clip.rotationDegrees = (clip.rotationDegrees + 90) % 360;
    _commit();
  }

  void setCustomRotation(double degrees) {
    selectedClip.customRotationDegrees = degrees;
    _commit();
  }

  void toggleFlipHorizontal() {
    selectedClip.flipHorizontal = !selectedClip.flipHorizontal;
    _commit();
  }

  void toggleFlipVertical() {
    selectedClip.flipVertical = !selectedClip.flipVertical;
    _commit();
  }

  void setCropPreset(CropPreset preset) {
    selectedClip.cropPreset = preset;
    
    if (preset == CropPreset.free || preset.ratio == null) {
      selectedClip.cropRect = null;
    } else {
      final videoAspect = playerController?.value.aspectRatio ?? (16 / 9);
      final targetAspect = preset.ratio!;
      
      double w = 1.0;
      double h = 1.0;
      
      if (videoAspect > targetAspect) {
        // Video is wider than target. Crop sides.
        w = targetAspect / videoAspect;
      } else {
        // Video is taller than target. Crop top/bottom.
        h = videoAspect / targetAspect;
      }
      
      double left = (1.0 - w) / 2.0;
      double right = 1.0 - left;
      double top = (1.0 - h) / 2.0;
      double bottom = 1.0 - top;
      
      selectedClip.cropRect = [left, top, right, bottom];
    }
    
    _commit();
  }

  void setCropRect(List<double> normalizedRect) {
    selectedClip.cropRect = normalizedRect;
    _commit();
  }

  void setPlaybackSpeed(double speed) {
    selectedClip.playbackSpeed = speed;
    playerController?.setPlaybackSpeed(speed);
    _commit();
  }

  void setVolume(double volume) {
    selectedClip.volume = volume;
    playerController?.setVolume(selectedClip.muted ? 0 : volume);
    _commit();
  }

  void toggleMute() {
    selectedClip.muted = !selectedClip.muted;
    playerController?.setVolume(selectedClip.muted ? 0 : selectedClip.volume);
    _commit();
  }

  void upsertFilter(FilterType type, double intensity) {
    final clip = selectedClip;
    final index = clip.filters.indexWhere((f) => f.type == type);
    if (index >= 0) {
      clip.filters[index] = clip.filters[index].copyWith(intensity: intensity);
    } else {
      clip.filters.add(FilterModel(type: type, intensity: intensity));
    }
    _commit();
  }

  void removeFilter(FilterType type) {
    selectedClip.filters.removeWhere((f) => f.type == type);
    _commit();
  }

  void addClip(ClipModel clip) {
    if (project.value.clips.length >= AppConfig.maxTimelineClips) {
      Get.snackbar('Timeline full',
          'Maximum ${AppConfig.maxTimelineClips} clips reached');
      return;
    }
    project.value.clips.add(clip);
    _commit();
  }

  void reorderClips(int oldIndex, int newIndex) {
    final clips = project.value.clips;
    if (newIndex > oldIndex) newIndex -= 1;
    final clip = clips.removeAt(oldIndex);
    clips.insert(newIndex, clip);
    _commit();
  }

  void deleteClip(int index) {
    if (project.value.clips.length <= 1) return;
    project.value.clips.removeAt(index);
    if (selectedClipIndex.value >= project.value.clips.length) {
      selectedClipIndex.value = project.value.clips.length - 1;
    }
    _commit();
    _initPlayer();
  }

  void duplicateClip(int index) {
    final original = project.value.clips[index];
    final copy = ClipModel.fromJson(original.toJson());
    project.value.clips.insert(index + 1, copy);
    _commit();
  }

  // ---------------------------------------------------------------------
  // Undo / redo
  // ---------------------------------------------------------------------

  void _pushHistory({bool recordRedo = true}) {
    if (recordRedo) _redoStack.clear();
    _undoStack.add(_HistoryEntry(project.value.toJson()));
    if (_undoStack.length > AppConfig.maxHistoryEntries) {
      _undoStack.removeAt(0);
    }
    canUndo.value = _undoStack.length > 1;
    canRedo.value = _redoStack.isNotEmpty;
  }

  void undo() {
    if (_undoStack.length <= 1) return;
    final current = _undoStack.removeLast();
    _redoStack.add(current);
    final previous = _undoStack.last;
    project.value = VideoProjectModel.fromJson(
      jsonDecode(previous.jsonString) as Map<String, dynamic>,
    );
    project.refresh();
    canUndo.value = _undoStack.length > 1;
    canRedo.value = _redoStack.isNotEmpty;
    _initPlayer();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final entry = _redoStack.removeLast();
    _undoStack.add(entry);
    project.value = VideoProjectModel.fromJson(
      jsonDecode(entry.jsonString) as Map<String, dynamic>,
    );
    project.refresh();
    canUndo.value = _undoStack.length > 1;
    canRedo.value = _redoStack.isNotEmpty;
    _initPlayer();
  }

  // ---------------------------------------------------------------------
  // Autosave / persistence
  // ---------------------------------------------------------------------

  Future<void> _autosave() async {
    try {
      await _projectRepository.saveProject(project.value);
    } catch (e, st) {
      LoggerService.instance.w('Autosave failed: $e\n$st');
    }
  }

  Future<void> saveNow() => _projectRepository.saveProject(project.value);

  // ---------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------

  Future<void> startExport(ExportSettingsModel settings) async {
    await saveNow();
    exportProgress.value = const ExportProgress(status: ExportStatus.rendering);
    _exportSubscription?.cancel();
    _exportSubscription = _editorRepository
        .exportProject(project.value, settings)
        .listen((progress) {
      exportProgress.value = progress;
      if (progress.status == ExportStatus.success &&
          progress.outputPath != null) {
        _onExportSuccess(progress.outputPath!);
      }
    });
  }

  Future<void> cancelExport() => _editorRepository.cancelExport();

  Future<void> retryExport(ExportSettingsModel settings) =>
      startExport(settings);

  Future<GallerySaveResult> _onExportSuccess(String outputPath) {
    return GalleryService.instance
        .saveVideo(outputPath, title: project.value.title);
  }
}
