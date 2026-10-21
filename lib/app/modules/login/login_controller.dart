import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/storage_service.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController emailController = TextEditingController(
    // text: 'krishna@gmail.com',
  );
  final TextEditingController passwordController = TextEditingController(
    // text: 'Krishna@345',
  );
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'email_required'.tr;
    }
    if (!GetUtils.isEmail(value)) {
      return 'email_invalid'.tr;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    if (value.length < 3) {
      return 'password_min_length'.tr;
    }
    return null;
  }

  Future<void> login() async {
    if (!_validateInputs()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authRepository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      currentUser.value = user;

      // Save user data persistently
      await StorageService.saveUser(user);

      print('Login successful for: ${user.name}');

      // Show success message
      Get.snackbar(
        'success'.tr,
        'Login successful'.tr,
        // 'welcome_back'.trParams({'name': user.name}),
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );

      // Navigate to home
      Get.offAllNamed('/home');
    } catch (e) {
      print('Login error: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');

      Get.snackbar(
        'login_failed'.tr,
        errorMessage.value,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await StorageService.logout();
      currentUser.value = null;

      // Clear form fields
      emailController.clear();
      passwordController.clear();
      errorMessage.value = '';

      print('User logged out successfully');

      Get.snackbar(
        'Logged Out'.tr,
        'You have been logged out successfully'.tr,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );

      // Navigate to login screen
      Get.offAllNamed('/login');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  bool _validateInputs() {
    if (emailController.text.trim().isEmpty) {
      errorMessage.value = 'please_enter_email'.tr;
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      errorMessage.value = 'please_enter_valid_email'.tr;
      return false;
    }

    if (passwordController.text.isEmpty) {
      errorMessage.value = 'please_enter_password'.tr;
      return false;
    }

    if (passwordController.text.length < 6) {
      errorMessage.value = 'password_min_length_6'.tr;
      return false;
    }

    return true;
  }
}
