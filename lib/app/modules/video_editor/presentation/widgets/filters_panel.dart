import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/clip_model.dart';
import '../../data/models/filter_model.dart';

/// Filter/adjustment panel: one row of preset "style" filters (sepia,
/// vintage, warm, cool, mono, invert) plus fine-grained sliders for the
/// signed adjustments (brightness, contrast, exposure, gamma, hue,
/// saturation, sharpen). Blur is included as its own slider since it uses
/// a positive-only sigma range.
class FiltersPanel extends StatelessWidget {
  const FiltersPanel({
    super.key,
    required this.clip,
    required this.onChanged,
  });

  final ClipModel clip;
  final void Function(FilterType type, double intensity) onChanged;

  double _intensityOf(FilterType type) {
    final match = clip.filters.where((f) => f.type == type);
    return match.isEmpty ? 0 : match.first.intensity;
  }

  @override
  Widget build(BuildContext context) {
    const styleFilters = [
      FilterType.sepia,
      FilterType.vintage,
      FilterType.warm,
      FilterType.cool,
      FilterType.mono,
      FilterType.invert,
    ];
    const adjustmentFilters = [
      FilterType.brightness,
      FilterType.contrast,
      FilterType.exposure,
      FilterType.gamma,
      FilterType.hue,
      FilterType.saturation,
      FilterType.sharpen,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Styles', style: context.textTheme.labelLarge),
          const SizedBox(height: AppDimens.space8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: styleFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppDimens.space8),
              itemBuilder: (context, index) {
                final type = styleFilters[index];
                final active = _intensityOf(type) > 0;
                return ChoiceChip(
                  label: Text(type.label),
                  selected: active,
                  onSelected: (selected) => onChanged(type, selected ? 1.0 : 0.0),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimens.space20),
          Text('Adjust', style: context.textTheme.labelLarge),
          for (final type in adjustmentFilters)
            _AdjustmentSlider(
              type: type,
              value: _intensityOf(type),
              onChanged: (value) => onChanged(type, value),
            ),
          _AdjustmentSlider(
            type: FilterType.blur,
            value: _intensityOf(FilterType.blur),
            min: 0,
            max: 1,
            onChanged: (value) => onChanged(FilterType.blur, value),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentSlider extends StatelessWidget {
  const _AdjustmentSlider({
    required this.type,
    required this.value,
    required this.onChanged,
    this.min = -1,
    this.max = 1,
  });

  final FilterType type;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 84, child: Text(type.label, style: context.textTheme.bodySmall)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
