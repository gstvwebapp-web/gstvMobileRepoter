import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/clip_model.dart';

/// Crop-preset picker. Selecting a preset stores the ratio on the
/// [ClipModel]; the actual crop rectangle is computed centred by default
/// and can be fine-tuned by dragging the preview (drag handling on the
/// canvas itself is wired in `EditorView` via `onPanUpdate` on the preview
/// stack, calling back into `EditorController.setCropRect`).
class CropPanel extends StatelessWidget {
  const CropPanel({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final CropPreset selected;
  final ValueChanged<CropPreset> onSelect;

  static const _presets = [
    CropPreset.free,
    CropPreset.square1x1,
    CropPreset.portrait4x5,
    CropPreset.portrait9x16,
    CropPreset.landscape16x9,
    CropPreset.portrait3x4,
    CropPreset.landscape4x3,
    CropPreset.instagramPost,
    CropPreset.youtubeShorts,
    CropPreset.tiktok,
    CropPreset.facebook,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.space8),
        itemBuilder: (context, index) {
          final preset = _presets[index];
          final isSelected = preset == selected;
          final ratio = preset.ratio ?? 0.6;

          return InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            onTap: () => onSelect(preset),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.colors.outline,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: ratio.clamp(0.4, 2.2),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppColors.primary : context.colors.onSurface,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.label,
                    style: context.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
