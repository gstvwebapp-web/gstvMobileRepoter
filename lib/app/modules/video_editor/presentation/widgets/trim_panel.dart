import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/duration_extensions.dart';
import '../../data/models/clip_model.dart';

/// Frame-accurate trim control: two draggable handles over a thumbnail
/// track. Dragging clamps `trimStart < trimEnd` and reports live updates
/// via [onChanged] so the preview can scrub while dragging.
class TrimPanel extends StatefulWidget {
  const TrimPanel({
    super.key,
    required this.clip,
    required this.onChanged,
  });

  final ClipModel clip;
  final void Function(Duration start, Duration end) onChanged;

  @override
  State<TrimPanel> createState() => _TrimPanelState();
}

class _TrimPanelState extends State<TrimPanel> {
  late double _startFraction;
  late double _endFraction;

  @override
  void initState() {
    super.initState();
    _syncFromClip();
  }

  @override
  void didUpdateWidget(covariant TrimPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.id != widget.clip.id) _syncFromClip();
  }

  void _syncFromClip() {
    final totalMs = widget.clip.originalDuration.inMilliseconds;
    _startFraction = totalMs == 0 ? 0 : widget.clip.trimStart.inMilliseconds / totalMs;
    _endFraction = totalMs == 0 ? 1 : widget.clip.trimEnd.inMilliseconds / totalMs;
  }

  void _emit() {
    final totalMs = widget.clip.originalDuration.inMilliseconds;
    widget.onChanged(
      Duration(milliseconds: (_startFraction * totalMs).round()),
      Duration(milliseconds: (_endFraction * totalMs).round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.clip.trimStart.toTimecode(),
                style: context.textTheme.labelMedium,
              ),
              Text(
                widget.clip.trimmedDuration.toTimecode(),
                style: context.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                widget.clip.trimEnd.toTimecode(),
                style: context.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 56,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.timelineTrack,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                      ),
                    ),
                    Positioned(
                      left: _startFraction * width,
                      width: (_endFraction - _startFraction) * width,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          border: Border.all(color: AppColors.primary, width: 2),
                          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                        ),
                      ),
                    ),
                    _Handle(
                      left: _startFraction * width - 10,
                      onDrag: (dx) {
                        setState(() {
                          _startFraction = ((_startFraction * width + dx) / width)
                              .clamp(0.0, _endFraction - 0.02);
                        });
                        _emit();
                      },
                    ),
                    _Handle(
                      left: _endFraction * width - 10,
                      onDrag: (dx) {
                        setState(() {
                          _endFraction = ((_endFraction * width + dx) / width)
                              .clamp(_startFraction + 0.02, 1.0);
                        });
                        _emit();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.left, required this.onDrag});
  final double left;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Icon(Icons.drag_indicator, color: Colors.white, size: 14),
          ),
        ),
      ),
    );
  }
}
