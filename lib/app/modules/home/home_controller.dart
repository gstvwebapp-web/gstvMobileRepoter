import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../login/login_controller.dart';
import '../../core/constants/global_variables.dart';
import '../../data/services/storage_service.dart';

enum HomeMenuItem {
  dashboard,
  categories,
  news,
  users,
  editorListing,
  changePassword,
  poll,
  mediaGallery,
  webStories,
  frontendUsers,
  feedbackList,
  epaperCategories,
  epaper,
  newsFlash,
  imJournalist,
  campusCorner,
  magazineReview,
}

class HomeController extends GetxController {
  late final Rx<HomeMenuItem> selectedMenu = _getInitialMenu().obs;

  HomeMenuItem _getInitialMenu() {
    final roleID = GlobalVariables.roleID;
    if (roleID == '6' || roleID == '7') {
      return HomeMenuItem.news;
    }
    return HomeMenuItem.dashboard;
  }

  void selectMenu(HomeMenuItem item) {
    selectedMenu.value = item;
    // Close drawer if open
    final ctx = Get.context;
    if (ctx != null && Navigator.canPop(ctx)) {
      Navigator.pop(ctx);
    }
  }

  void logout() {
    Get.dialog(
      CupertinoAlertDialog(
        title: Text('logout'.tr),
        content: Text('logout_confirmation'.tr),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('cancel'.tr),
            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('logout'.tr),
            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
              _performLogout();
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _performLogout() async {
    try {
      await StorageService.logout();
      
      // Also try to use LoginController if it exists, to clear its state
      try {
        final loginController = Get.find<LoginController>();
        loginController.currentUser.value = null;
        loginController.emailController.clear();
        loginController.passwordController.clear();
      } catch (e) {
        // Ignore if LoginController is not found
      }

      Get.offAllNamed('/login');
    } catch (e) {
      Get.offAllNamed('/login');
    }
  }
}
