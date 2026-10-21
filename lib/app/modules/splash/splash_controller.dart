import 'package:get/get.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/force_update_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    // Check for force update before proceeding
    final canProceed = await ForceUpdateService.checkForUpdate();
    if (!canProceed) return; // Dialog is shown, stop navigation

    try {
      final isLoggedIn = await StorageService.isLoggedIn();

      if (isLoggedIn) {
        final user = await StorageService.getUser();
        if (user != null) {
          print('User is logged in: ${user.name}');
          Get.offAllNamed('/home');
        } else {
          print('No user data found, redirecting to login');
          Get.offAllNamed('/login');
        }
      } else {
        print('User is not logged in, redirecting to login');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      print('Error checking login status: $e');
      Get.offAllNamed('/login');
    }
  }
}
