import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:gstv_admin/app/data/services/localization_service.dart';

class LocalizationController extends GetxController {
  final localizationService = LocalizationService();

  final Rx<Locale> _locale = Rx<Locale>(LocalizationService.getInitialLocale());
  Locale get locale => _locale.value;

  void changeLocale(String lang) {
    localizationService.changeLocale(lang);
    _locale.value = localizationService.getLocaleFromLanguage(lang);
  }
}
