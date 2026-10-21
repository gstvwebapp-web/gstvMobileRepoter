import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/core/constants/api_constants.dart';
import '../../../app/core/constants/app_colors.dart';

class ForceUpdateService {
  static const String _iosUrl =
      'https://apps.apple.com/in/app/gstv-reporter/id6753674993';
  static const String _androidUrl =
      'https://play.google.com/store/apps/details?id=com.gstv.repoter';

  /// Call this during splash. Returns true if app can proceed.
  static Future<bool> checkForUpdate() async {
    // Skip force update check on web
    if (kIsWeb) {
      print('🔄 Running on web - skipping force update check');
      return true;
    }
    
    try {
      final dio = Dio()..interceptors.add(LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true));
      final response = await dio.get(ApiConstants.forceUpdateUrl);

      if (response.statusCode != 200) return true;

      final data = response.data;
      final bool isForce = Platform.isIOS
          ? (data['is_ios_update'] == 1)
          : (data['is_android_update'] == 1);

      if (!isForce) return true;

      final packageInfo = await PackageInfo.fromPlatform();
      // Strip any debug suffix like "-debug"
      final currentVersion = packageInfo.version.split('-').first;
      final requiredVersion = Platform.isIOS
          ? (data['ios_version'] as String)
          : (data['android_version'] as String);

      if (_isUpdateRequired(currentVersion, requiredVersion)) {
        _showForceUpdateDialog(requiredVersion);
        return false;
      }

      return true;
    } catch (e) {
      print('🔄 Force update check error: $e');
      return true; // On error, allow app to proceed
    }
  }

  static bool _isUpdateRequired(String current, String required) {
    final c = current.split('.').map(int.parse).toList();
    final r = required.split('.').map(int.parse).toList();
    for (int i = 0; i < r.length; i++) {
      final cv = i < c.length ? c[i] : 0;
      if (cv < r[i]) return true;
      if (cv > r[i]) return false;
    }
    return false;
  }

  static void _showForceUpdateDialog(String newVersion) {
    final storeUrl = Platform.isIOS ? _iosUrl : _androidUrl;

    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.system_update, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Update Required'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version ($newVersion) of GSTV Reporter is available.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
              ),
              const SizedBox(height: 8),
              Text('Please update the app to continue using it.'.tr,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openStore(storeUrl),
                icon: Icon(
                  Platform.isIOS ? Icons.apple : Icons.shop,
                  size: 18,
                ),
                label: Text('Update Now'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> _openStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
