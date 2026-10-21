import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/duration_extensions.dart';
import '../../core/services/thumbnail_cache_service.dart';
import '../../data/models/clip_model.dart';

/// A horizontally scrollable, pinch-zoomable timeline strip showing every
/// clip as a row of frame thumbnails, with a draggable playhead and
/// frame-snapping when scrubbing.
class TimelineStrip extends StatefulWidget {
  const TimelineStrip({
    super.key,
    required this.clips,
    required this.selectedClipIndex,
    required this.playheadPosition,
    required this.onSelectClip,
    required this.onScrub,
    required this.onReorder,
  });

  final List<ClipModel> clips;
  final int selectedClipIndex;
  final Rx<Duration> playheadPosition;
  final ValueChanged<int> onSelectClip;
  final ValueChanged<Duration> onScrub;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip> {
  /// Pixels-per-second — the core "zoom" value; frame snapping rounds
  /// scrub positions to `1 / fps` once fps metadata is known, defaulting
  /// to a 1-frame-per-30ms snap grid which is imperceptible for scrubbing.
  double _pxPerSecond = 40;

  Duration get _totalDuration => widget.clips.fold(
        Duration.zero,
        (sum, c) => sum + c.trimmedDuration,
      );

  @override
  Widget build(BuildContext context) {
    final totalWidth = max(
      MediaQuery.of(context).size.width,
      _totalDuration.inMilliseconds / 1000 * _pxPerSecond,
    );

    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _pxPerSecond = (_pxPerSecond * details.scale).clamp(10, 240);
        });
      },
      child: SizedBox(
        height: AppDimens.timelineHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.clips.length; i++)
                      _ClipBlock(
                        clip: widget.clips[i],
                        pxPerSecond: _pxPerSecond,
                        selected: i == widget.selectedClipIndex,
                        onTap: () => widget.onSelectClip(i),
                      ),
                  ],
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    final seconds = details.localPosition.dx / _pxPerSecond;
                    widget.onScrub(
                      Duration(milliseconds: (seconds * 1000).round()),
                    );
                  },
                  child: SizedBox(width: totalWidth, height: AppDimens.timelineHeight),
                ),
                Obx(() => Positioned(
                  left: widget.playheadPosition.value.inMilliseconds / 1000 * _pxPerSecond,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(width: 2, color: AppColors.timelinePlayhead),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double max(double a, double b) => a > b ? a : b;

class _ClipBlock extends StatefulWidget {
  const _ClipBlock({
    required this.clip,
    required this.pxPerSecond,
    required this.selected,
    required this.onTap,
  });

  final ClipModel clip;
  final double pxPerSecond;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ClipBlock> createState() => _ClipBlockState();
}

class _ClipBlockState extends State<_ClipBlock> {
  List<Uint8List>? _frames;

  @override
  void initState() {
    super.initState();
    _loadFrames();
  }

  Future<void> _loadFrames() async {
    final widthSeconds = widget.clip.trimmedDuration.inMilliseconds / 1000;
    final frameCount = (widthSeconds * widget.pxPerSecond / 60).clamp(1, 12).round();
    final frames = await ThumbnailCacheService.instance.getStrip(
      sourcePath: widget.clip.sourcePath,
      videoDuration: widget.clip.trimmedDuration,
      frameCount: frameCount,
    );
    if (mounted) setState(() => _frames = frames);
  }

  @override
  Widget build(BuildContext context) {
    final width = (widget.clip.trimmedDuration.inMilliseconds / 1000) * widget.pxPerSecond;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: max(width, 1.0),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        decoration: BoxDecoration(
          color: AppColors.timelineClip,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: widget.selected ? AppColors.timelineSelected : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _frames == null
            ? const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                children: _frames!
                    .map((bytes) => Expanded(
                          child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
                        ))
                    .toList(),
              ),
      ),
    );
  }
}
