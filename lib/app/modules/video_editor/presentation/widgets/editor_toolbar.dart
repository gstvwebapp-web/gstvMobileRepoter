import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../controllers/editor_controller.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key, required this.selected, required this.onSelect});

  final EditorTab selected;
  final ValueChanged<EditorTab> onSelect;

  static List<(EditorTab, IconData, String)> get _items => [
    (EditorTab.trim, Icons.content_cut_rounded, AppStrings.tabTrim),
    (EditorTab.crop, Icons.crop_rounded, AppStrings.tabCrop),
    (EditorTab.rotate, Icons.rotate_right_rounded, AppStrings.tabRotate),
    (EditorTab.filters, Icons.tune_rounded, AppStrings.tabFilters),
    (EditorTab.audio, Icons.audiotrack_rounded, AppStrings.tabAudio),
    (EditorTab.speed, Icons.speed_rounded, AppStrings.tabSpeed),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final (tab, icon, label) = _items[index];
          final isSelected = tab == selected;
          return InkWell(
            onTap: () => onSelect(tab),
            child: Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: AppDimens.toolbarIconSize,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
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
