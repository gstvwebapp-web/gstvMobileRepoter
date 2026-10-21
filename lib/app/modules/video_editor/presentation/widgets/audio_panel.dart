import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/clip_model.dart';

/// Audio tab: mute/volume for the selected clip's original audio, plus an
/// entry point for adding background music tracks (wired to
/// `EditorController` via [onAddBackgroundMusic] — the actual audio track
/// list rendering lives in the timeline once a track is added, similar to
/// how additional video clips render as blocks).
class AudioPanel extends StatelessWidget {
  const AudioPanel({
    super.key,
    required this.clip,
    required this.onVolumeChanged,
    required this.onToggleMute,
  });

  final ClipModel clip;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Original audio', style: context.textTheme.labelLarge),
              ),
              IconButton(
                onPressed: onToggleMute,
                icon: Icon(clip.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
              ),
            ],
          ),
          Slider(
            value: clip.volume,
            min: 0,
            max: 1,
            onChanged: clip.muted ? null : onVolumeChanged,
          ),
        ],
      ),
    );
  }
}
