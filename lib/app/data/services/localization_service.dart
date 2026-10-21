import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gstv_admin/app/core/lang/en.dart';
import 'package:gstv_admin/app/core/lang/gu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends Translations {
  // Default locale (first install): Gujarati
  static const Locale locale = Locale('gu', 'IN');

  // Fallback locale when the selected locale has issues
  static const Locale fallbackLocale = Locale('en', 'US');

  // Supported languages
  // Needs to be same order with locales
  static final langs = [
    'English',
    'Gujarati',
  ];

  // Supported locales
  // Needs to be same order with langs
  static final locales = [
    const Locale('en', 'US'),
    const Locale('gu', 'IN'),
  ];

  // Keys and their translations
  // Translations are separated maps in `lang` file
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en,
        'gu_IN': gu,
      };

  // Gets locale from language, and updates the locale
  void changeLocale(String lang) {
    final locale = getLocaleFromLanguage(lang);
    final prefs = Get.find<SharedPreferences>();
    prefs.setString('language', lang);
    Get.updateLocale(locale);
  }

  // Finds language in `langs` list and returns it as Locale
  Locale getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale!;
  }

  // Determine initial locale
  // 1) If user has previously chosen a language (stored as the language name), use it
  // 2) Else if system locale matches a supported locale, use it (optional)
  // 3) Else fall back to our default (Gujarati)
  static Locale getInitialLocale() {
    final SharedPreferences prefs = Get.find<SharedPreferences>();
    final String? savedLanguage = prefs.getString('language');
    if (savedLanguage != null) {
      for (int i = 0; i < langs.length; i++) {
        if (savedLanguage == langs[i]) return locales[i];
      }
    }
    // Default to Gujarati on first install
    return locale;
  }
}
