import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gstv_admin/app/data/services/localization_controller.dart';
import 'package:gstv_admin/app/data/services/localization_service.dart';
import '../core/constants/app_colors.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabel;
  final bool isCompact;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;

  const LanguageSwitcher({
    super.key,
    this.showLabel = true,
    this.isCompact = false,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final LocalizationController localizationController = Get.put(LocalizationController());

    if (isCompact) {
      return _buildCompactSwitcher(localizationController);
    }

    return _buildFullSwitcher(context, localizationController);
  }

  Widget _buildCompactSwitcher(LocalizationController controller) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary.withValues(alpha: 0.1);

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.language,
          color: effectiveIconColor,
          size: 18,
        ),
      ),
      tooltip: 'change_language'.tr,
      onSelected: (String language) {
        controller.changeLocale(language);
      },
      itemBuilder: (BuildContext context) {
        return LocalizationService.langs.map((String language) {
          return PopupMenuItem<String>(
            value: language,
            child: Row(
              children: [
                Icon(
                  _getLanguageIcon(language),
                  size: 20,
                  color: _isCurrentLanguage(language)
                      ? Theme.of(context).primaryColor
                      : AppColors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _getLanguageDisplayName(language),
                  style: TextStyle(
                    fontWeight: _isCurrentLanguage(language)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _isCurrentLanguage(language)
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                ),
                if (_isCurrentLanguage(language)) ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildFullSwitcher(BuildContext context, LocalizationController controller) {
    final effectiveIconColor = iconColor ?? AppColors.textSecondary;
    final effectiveTextColor = textColor ?? AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Icon(Icons.language, size: 20, color: effectiveIconColor),
            const SizedBox(width: 8),
            Text(
              'language'.tr,
              style: TextStyle(
                fontSize: 14,
                color: effectiveTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
          ],
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _getCurrentLanguage(),
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              onChanged: (String? newLanguage) {
                if (newLanguage != null) {
                  controller.changeLocale(newLanguage);
                }
              },
              items: LocalizationService.langs.map<DropdownMenuItem<String>>((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getLanguageIcon(language),
                        size: 16,
                        color: _isCurrentLanguage(language) 
                            ? Theme.of(context).primaryColor 
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getLanguageDisplayName(language),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _isCurrentLanguage(language) 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentLanguage() {
    final currentLocale = Get.locale;
    if (currentLocale?.languageCode == 'gu') {
      return 'Gujarati';
    }
    return 'English';
  }

  bool _isCurrentLanguage(String language) {
    return _getCurrentLanguage() == language;
  }

  IconData _getLanguageIcon(String language) {
    switch (language) {
      case 'English':
        return Icons.language;
      case 'Gujarati':
        return Icons.translate;
      default:
        return Icons.language;
    }
  }

  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'English':
        return 'english'.tr;
      case 'Gujarati':
        return 'gujarati'.tr;
      default:
        return language;
    }
  }
}

// Alternative simple toggle button version
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalizationController localizationController = Get.put(LocalizationController());
    
    return Obx(() {
      final isGujarati = Get.locale?.languageCode == 'gu';
      
      return IconButton(
        onPressed: () {
          final newLanguage = isGujarati ? 'English' : 'Gujarati';
          localizationController.changeLocale(newLanguage);
        },
        icon: Icon(
          isGujarati ? Icons.language : Icons.translate,
          color: Theme.of(context).primaryColor,
        ),
        tooltip: isGujarati ? 'Switch to English' : 'Switch to Gujarati',
      );
    });
  }
}
