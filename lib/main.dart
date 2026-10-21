import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gstv_admin/app/data/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/api_service.dart';
import 'app/data/services/network_service.dart';
import 'app/core/constants/app_colors.dart';
import 'app/core/config/upgrade_config.dart';
import 'app/modules/video_editor/core/services/storage_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize WebView platform for macOS
    if (GetPlatform.isMacOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }

    await initServices();
    runApp(const MyApp());
  } catch (e) {
    print('Error during app initialization: $e');
    // Still try to run the app even if some services fail
    runApp(const MyApp());
  }
}

Future<void> initServices() async {
  try {
    // Initialize Network service first (highest priority)
    final networkService = NetworkService();
    Get.put(networkService, permanent: true);
    await networkService.onInit();

    // Initialize API service
    ApiService().initialize();

    // Initialize SharedPreferences
    await Get.putAsync(() => SharedPreferences.getInstance());

    // Initialize canva_style_video_editor storage boxes for the editor
    await StorageService.initBoxes();

    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
    // Continue even if some services fail to initialize
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus!.unfocus();
        }
      },
      child: UpgradeAlert(
        upgrader: UpgradeConfig.getUpgrader(),
        // For testing, uncomment the line below and comment the line above
        // upgrader: UpgradeConfig.getTestUpgrader(),

        // UpgradeAlert specific parameters
        showIgnore: false, // Set to false to force update
        showLater: false, // Set to false to force update
        showReleaseNotes: true, // Show release notes
        barrierDismissible: false, // Don't allow dismissing by tapping outside
        dialogStyle: UpgradeDialogStyle.material, // Use material design
        child: GetMaterialApp(
          title: 'GSTV Admin'.tr,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            useMaterial3: true,
            fontFamily: 'Poppins',
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          locale: LocalizationService.getInitialLocale(),
          fallbackLocale: LocalizationService.fallbackLocale,
          translations: LocalizationService(),
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
