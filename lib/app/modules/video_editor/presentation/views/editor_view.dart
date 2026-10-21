import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/export_settings_model.dart';
import '../controllers/editor_controller.dart';
import '../widgets/audio_panel.dart';
import '../widgets/crop_panel.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/export_progress_dialog.dart';
import '../widgets/export_settings_sheet.dart';
import '../widgets/filters_panel.dart';
import '../widgets/rotate_panel.dart';
import '../widgets/speed_panel.dart';
import '../widgets/timeline_strip.dart';
import '../widgets/trim_panel.dart';
import '../widgets/video_preview.dart';

class EditorView extends GetView<EditorController> {
  const EditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Obx(() {
          final project = controller.project.value;
          if (project.clips.isEmpty) {
            return const Center(
              child: Text(
                'No clips in this project',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (controller.isPlayerReady.value &&
                        controller.playerController != null)
                      VideoPreview(
                        controller: controller.playerController!,
                        clip: controller.selectedClip,
                      )
                    else
                      const CircularProgressIndicator(color: Colors.white),
                    Positioned(
                      bottom: AppDimens.space12,
                      child: Obx(
                        () => IconButton(
                          iconSize: 44,
                          color: Colors.white,
                          onPressed: controller.togglePlayback,
                          icon: Icon(
                            controller.isPlaying.value
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TimelineStrip(
                clips: project.clips,
                selectedClipIndex: controller.selectedClipIndex.value,
                playheadPosition: controller.playheadPosition,
                onSelectClip: controller.selectClip,
                onScrub: controller.seekTo,
                onReorder: controller.reorderClips,
              ),
              Container(
                color: const Color(0xFF15151C),
                child: Column(
                  children: [
                    SizedBox(
                      height: AppDimens.bottomPanelHeight - 76,
                      child: const _PanelSwitcher(),
                    ),
                    EditorToolbar(
                      selected: controller.selectedTab.value,
                      onSelect: controller.selectTab,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(AppStrings.editorTitle),
      actions: [
        Obx(
          () => IconButton(
            onPressed: controller.canUndo.value ? controller.undo : null,
            icon: const Icon(Icons.undo_rounded),
            tooltip: AppStrings.undo,
          ),
        ),
        Obx(
          () => IconButton(
            onPressed: controller.canRedo.value ? controller.redo : null,
            icon: const Icon(Icons.redo_rounded),
            tooltip: AppStrings.redo,
          ),
        ),
        TextButton(
          onPressed: () => _startExportFlow(context),
          child: Text(AppStrings.export, style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: AppDimens.space8),
      ],
    );
  }

  Future<void> _startExportFlow(BuildContext context) async {
    final settings = await ExportSettingsSheet.show(
      context,
      initial: controller.project.value.exportSettings,
    );
    if (settings == null) return;

    controller.startExport(settings);

    if (!context.mounted) return;

    final path = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Obx(() {
        final progress = controller.exportProgress.value;
        return ExportProgressDialog(
          progress: progress,
          onCancel: () async {
            await controller.cancelExport();
            Navigator.of(dialogContext).pop();
          },
          onRetry: () => controller.retryExport(settings),
          onDone: () {
            final outPath = controller.exportProgress.value.outputPath;
            print('====== ONDONE CLICKED, outPath: $outPath ======');
            Navigator.of(dialogContext).pop(outPath);
          },
        );
      }),
    );

    print('====== DIALOG RETURNED PATH: $path ======');
    if (path != null && path.isNotEmpty) {
      print('====== CALLING GET.BACK WITH FILE ======');
      Get.back(result: File(path));
    }
  }
}

class _PanelSwitcher extends GetView<EditorController> {
  const _PanelSwitcher();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.selectedTab.value;
      // Read project.value so this Obx rebuilds on project.refresh()
      // (triggered by _commit after any edit). selectedClip is a plain
      // getter over project.value.clips, so without this read the Obx
      // would not know to rebuild when clip properties change.
      final _ = controller.project.value;
      final clip = controller.selectedClip;

      switch (tab) {
        case EditorTab.trim:
          return TrimPanel(clip: clip, onChanged: controller.updateTrim);
        case EditorTab.crop:
          return CropPanel(
            selected: clip.cropPreset,
            onSelect: controller.setCropPreset,
          );
        case EditorTab.rotate:
          return RotatePanel(
            clip: clip,
            onRotate90: controller.rotateClip90,
            onCustomRotation: controller.setCustomRotation,
            onFlipHorizontal: controller.toggleFlipHorizontal,
            onFlipVertical: controller.toggleFlipVertical,
          );
        case EditorTab.filters:
          return FiltersPanel(clip: clip, onChanged: controller.upsertFilter);
        case EditorTab.audio:
          return AudioPanel(
            clip: clip,
            onVolumeChanged: controller.setVolume,
            onToggleMute: controller.toggleMute,
          );
        case EditorTab.speed:
          return SpeedPanel(
            selected: clip.playbackSpeed,
            onSelect: controller.setPlaybackSpeed,
          );
      }
    });
  }
}
