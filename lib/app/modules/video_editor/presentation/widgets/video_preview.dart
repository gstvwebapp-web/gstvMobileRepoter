import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/color_matrix_utils.dart';
import '../../data/models/clip_model.dart';

/// Renders the live video preview with the current clip's rotation, flip,
/// crop AND colour filters applied as widget-level transforms.
///
/// This is a *preview-only* approximation for real-time feedback — the
/// authoritative pixel-accurate transform/filter is applied server-/
/// native-side by `pro_video_editor` at export time via [ClipModel] ->
/// `VideoSegment` mapping (see `EditorRepositoryImpl`). Both paths share
/// the same matrix math via [ColorMatrixUtils] so what you see here should
/// match the exported result.
class VideoPreview extends StatelessWidget {
  const VideoPreview({
    super.key,
    required this.controller,
    required this.clip,
  });

  final VideoPlayerController controller;
  final ClipModel clip;

  @override
  Widget build(BuildContext context) {
    final totalRotation = clip.rotationDegrees + clip.customRotationDegrees;
    final radians = totalRotation * pi / 180;

    Widget video = AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );

    // --- Filters -----------------------------------------------------
    // If the clip has any colour-matrix-representable filters applied
    // (brightness/contrast/saturation/mono/invert/sepia/warm/cool/vintage),
    // wrap the video in a ColorFiltered using the composed matrix. This is
    // the piece that was previously missing — filter sliders updated the
    // data model but nothing rendered it, so no visual change ever showed.
    final matrix = ColorMatrixUtils.combinedMatrixFor(clip.filters);
    if (matrix != null) {
      video = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: video,
      );
    }

    // --- Rotate / flip -------------------------------------------------
    video = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateZ(radians)
        ..scale(clip.flipHorizontal ? -1.0 : 1.0, clip.flipVertical ? -1.0 : 1.0),
      child: video,
    );

    // --- Crop ------------------------------------------------------------
    if (clip.cropRect != null) {
      final rect = clip.cropRect!;
      final w = rect[2] - rect[0];
      final h = rect[3] - rect[1];
      
      // Calculate alignment. Range is -1.0 to 1.0.
      final alignX = w < 1.0 ? -1.0 + 2.0 * rect[0] / (1.0 - w) : 0.0;
      final alignY = h < 1.0 ? -1.0 + 2.0 * rect[1] / (1.0 - h) : 0.0;
      
      video = ClipRect(
        child: Align(
          alignment: Alignment(alignX, alignY),
          widthFactor: w,
          heightFactor: h,
          child: video,
        ),
      );
    }

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: video,
    );
  }
}
