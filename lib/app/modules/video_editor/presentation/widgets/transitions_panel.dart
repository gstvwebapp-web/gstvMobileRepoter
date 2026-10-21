import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../data/models/export_settings_model.dart';

class TransitionsPanel extends StatelessWidget {
  const TransitionsPanel({super.key, required this.selected, required this.onSelect});

  final TransitionType selected;
  final ValueChanged<TransitionType> onSelect;

  static const _labels = {
    TransitionType.none: 'None',
    TransitionType.fade: 'Fade',
    TransitionType.crossFade: 'Cross fade',
    TransitionType.zoom: 'Zoom',
    TransitionType.slide: 'Slide',
    TransitionType.blur: 'Blur',
    TransitionType.push: 'Push',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Wrap(
        spacing: AppDimens.space8,
        runSpacing: AppDimens.space8,
        children: _labels.entries.map((entry) {
          return ChoiceChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (_) => onSelect(entry.key),
          );
        }).toList(),
      ),
    );
  }
}
