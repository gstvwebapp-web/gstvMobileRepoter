import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';

class SpeedPanel extends StatelessWidget {
  const SpeedPanel({super.key, required this.selected, required this.onSelect});

  final double selected;
  final ValueChanged<double> onSelect;

  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Wrap(
        spacing: AppDimens.space8,
        runSpacing: AppDimens.space8,
        children: _speeds.map((speed) {
          final isSelected = (speed - selected).abs() < 0.001;
          return ChoiceChip(
            label: Text('${speed}x'),
            selected: isSelected,
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            onSelected: (_) => onSelect(speed),
          );
        }).toList(),
      ),
    );
  }
}
