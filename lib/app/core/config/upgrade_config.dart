import 'package:upgrader/upgrader.dart';

class UpgradeConfig {
  // Basic upgrader configuration
  static Upgrader getUpgrader() {
    return Upgrader(
      debugDisplayAlways: false, // Set to true for testing
      debugDisplayOnce: false,
      debugLogging: true,
      durationUntilAlertAgain: const Duration(days: 3),
      countryCode: 'IN',
      languageCode: 'en',
      messages: CustomEnglishMessages(),
      clientHeaders: const {'User-Agent': 'GSTV Admin App'},
    );
  }

  // Test upgrader - always shows dialog
  static Upgrader getTestUpgrader() {
    return Upgrader(
      debugDisplayAlways: true, // Always show for testing
      debugDisplayOnce: false,
      debugLogging: true,
      durationUntilAlertAgain: const Duration(seconds: 1),
      countryCode: 'IN',
      languageCode: 'en',
      messages: TestUpgraderMessages(),
      clientHeaders: const {'User-Agent': 'GSTV Admin App'},
    );
  }

  // Get upgrader with specific language
  static Upgrader getUpgraderWithLanguage(String languageCode) {
    UpgraderMessages messages;
    switch (languageCode) {
      case 'gu':
        messages = CustomGujaratiMessages();
        break;
      case 'hi':
        messages = CustomHindiMessages();
        break;
      default:
        messages = CustomEnglishMessages();
    }

    return Upgrader(
      debugDisplayAlways: false,
      debugDisplayOnce: false,
      debugLogging: true,
      durationUntilAlertAgain: const Duration(days: 3),
      countryCode: 'IN',
      languageCode: languageCode,
      messages: messages,
      clientHeaders: const {'User-Agent': 'GSTV Admin App'},
    );
  }
}

// Custom message classes
class CustomEnglishMessages extends UpgraderMessages {
  @override
  String message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.body:
        return 'A new version of GSTV Admin is available! Please update to get the latest features and improvements.';
      case UpgraderMessage.buttonTitleIgnore:
        return 'Ignore';
      case UpgraderMessage.buttonTitleLater:
        return 'Later';
      case UpgraderMessage.buttonTitleUpdate:
        return 'Update Now';
      case UpgraderMessage.prompt:
        return 'Would you like to update GSTV Admin now?';
      case UpgraderMessage.releaseNotes:
        return 'Release Notes:';
      case UpgraderMessage.title:
        return 'Update GSTV Admin';
    }
  }
}

class CustomGujaratiMessages extends UpgraderMessages {
  @override
  String message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.body:
        return 'GSTV Admin નું નવું વર્ઝન ઉપલબ્ધ છે! કૃપા કરીને નવી સુવિધાઓ અને સુધારાઓ મેળવવા માટે અપડેટ કરો.';
      case UpgraderMessage.buttonTitleIgnore:
        return 'અવગણો';
      case UpgraderMessage.buttonTitleLater:
        return 'પછીથી';
      case UpgraderMessage.buttonTitleUpdate:
        return 'અપડેટ કરો';
      case UpgraderMessage.prompt:
        return 'શું તમે હવે GSTV Admin અપડેટ કરવા માંગો છો?';
      case UpgraderMessage.releaseNotes:
        return 'રિલીઝ નોટ્સ:';
      case UpgraderMessage.title:
        return 'GSTV Admin અપડેટ કરો';
    }
  }
}

class CustomHindiMessages extends UpgraderMessages {
  @override
  String message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.body:
        return 'GSTV Admin का नया वर्जन उपलब्ध है! कृपया नई सुविधाओं और सुधारों को प्राप्त करने के लिए अपडेट करें।';
      case UpgraderMessage.buttonTitleIgnore:
        return 'अनदेखा करें';
      case UpgraderMessage.buttonTitleLater:
        return 'बाद में';
      case UpgraderMessage.buttonTitleUpdate:
        return 'अपडेट करें';
      case UpgraderMessage.prompt:
        return 'क्या आप अब GSTV Admin को अपडेट करना चाहते हैं?';
      case UpgraderMessage.releaseNotes:
        return 'रिलीज़ नोट्स:';
      case UpgraderMessage.title:
        return 'GSTV Admin अपडेट करें';
    }
  }
}

class TestUpgraderMessages extends UpgraderMessages {
  @override
  String message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.body:
        return 'TEST MODE: A new version of GSTV Admin is available. This is a test dialog to verify the upgrade functionality works correctly.';
      case UpgraderMessage.buttonTitleIgnore:
        return 'Ignore (Test)';
      case UpgraderMessage.buttonTitleLater:
        return 'Later (Test)';
      case UpgraderMessage.buttonTitleUpdate:
        return 'Update Now (Test)';
      case UpgraderMessage.prompt:
        return 'This is a test prompt. Would you like to test the update?';
      case UpgraderMessage.releaseNotes:
        return 'Test Release Notes:';
      case UpgraderMessage.title:
        return 'Update GSTV Admin (TEST MODE)';
    }
  }
}
