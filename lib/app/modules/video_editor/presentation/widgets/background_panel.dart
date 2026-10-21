import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/video_project_model.dart';

class BackgroundPanel extends StatelessWidget {
  const BackgroundPanel({
    super.key,
    required this.background,
    required this.onTypeSelected,
    required this.onBlurChanged,
  });

  final BackgroundModel background;
  final ValueChanged<BackgroundType> onTypeSelected;
  final ValueChanged<double> onBlurChanged;

  static const _labels = {
    BackgroundType.none: 'None',
    BackgroundType.blur: 'Blur',
    BackgroundType.solidColor: 'Solid',
    BackgroundType.gradient: 'Gradient',
    BackgroundType.transparent: 'Transparent',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimens.space8,
            children: _labels.entries.map((entry) {
              return ChoiceChip(
                label: Text(entry.value),
                selected: background.type == entry.key,
                onSelected: (_) => onTypeSelected(entry.key),
              );
            }).toList(),
          ),
          if (background.type == BackgroundType.blur) ...[
            const SizedBox(height: AppDimens.space16),
            Text('Blur strength', style: context.textTheme.labelLarge),
            Slider(
              value: background.blurSigma,
              min: 0,
              max: 40,
              onChanged: onBlurChanged,
            ),
          ],
        ],
      ),
    );
  }
}
