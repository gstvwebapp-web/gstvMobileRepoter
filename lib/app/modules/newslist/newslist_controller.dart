import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/constants/constants.dart';
import '../../data/models/news_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/news_repository.dart';
import '../../data/services/filter_service.dart';
import '../../data/models/news_source_model.dart';
import '../login/login_controller.dart';
import '../home/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/network_status_widget.dart';
import '../../data/services/storage_service.dart';

class NewslistController extends GetxController with NetworkAwareMixin {
  final NewsRepository _newsRepository = NewsRepository();
  final FilterService _filterService = FilterService();

  final RxList<NewsModel> newsList = <NewsModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalNews = 0.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isFilterVisible = true.obs;

  // Filter Data
  final RxList<CategoryModel> availableCategories = <CategoryModel>[].obs;
  final RxList<UserModel> availableUsers = <UserModel>[].obs;
  final RxList<NewsSourceModel> availableNewsSources = <NewsSourceModel>[].obs;
  final RxBool isLoadingFilterData = false.obs;

  // Store user ID to avoid repeated controller lookups (reserved for future use)

  // Filter controls
  final TextEditingController searchController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final RxString selectedStatus = 'Active'.obs;
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);
  final Rx<CategoryModel?> selectedCategoryModel = Rx<CategoryModel?>(null);
  final Rx<NewsSourceModel?> selectedNewsSource = Rx<NewsSourceModel?>(null);

  // Dialog filter controls (temporary values before apply)
  final TextEditingController dialogSearchController = TextEditingController();
  final TextEditingController dialogStartDateController =
      TextEditingController();
  final TextEditingController dialogEndDateController = TextEditingController();
  final Rx<UserModel?> dialogSelectedUser = Rx<UserModel?>(null);
  final Rx<CategoryModel?> dialogSelectedCategory = Rx<CategoryModel?>(null);
  final Rx<NewsSourceModel?> dialogSelectedNewsSource = Rx<NewsSourceModel?>(null);

  // Reactive strings for dialog date fields
  final RxString dialogStartDateText = ''.obs;
  final RxString dialogEndDateText = ''.obs;

  // Scroll controller for pagination
  final ScrollController scrollController = ScrollController();

  // Filter options

  final RxList<String> statusOptions = <String>[
    'Active',
    'Inactive',
    'Schedule',
    'Videos',
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserID();
    _setupScrollListener();
    // Data loads lazily when the screen becomes visible (see NewslistScreen)
    listenToNetworkChanges(
      () { if (newsList.isNotEmpty) refreshData(); },
      () {},
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    dialogSearchController.dispose();
    dialogStartDateController.dispose();
    dialogEndDateController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // Network-aware refresh method
  Future<void> refreshData() async {
    if (!isConnected) {
      print('🌐 Dashboard: Cannot refresh - no internet connection');
      return;
    }

    print('🌐 Dashboard: Refreshing all data');
    try {
      // Refresh news list and filter data in parallel
      await Future.wait([
        loadNewsList(),
        loadFilterData(),
      ]);
      print('🌐 Dashboard: Data refresh completed');
    } catch (e) {
      print('🌐 Dashboard: Error refreshing data: $e');
    }
  }

  void _initializeUserID() {
    try {
      Get.find<LoginController>();
    } catch (_) {}
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 300) {
        // Load more when user is 200 pixels from bottom
        if (!isLoadingMore.value && currentPage.value < totalPages.value) {
          loadMoreNews();
        }
      }
    });
  }

  Future<void> loadNewsList({bool isRefresh = false}) async {
    return await executeWithNetworkCheck<void>(
      () async {
        try {
      if (isRefresh) {
        currentPage.value = 1;
        newsList.clear();
      }

      isLoading.value = true;
      errorMessage.value = '';

      // Get filter values
      final startDate = startDateController.text.isNotEmpty
          ? startDateController.text
          : '';
      var endDate = endDateController.text.isNotEmpty
          ? endDateController.text
          : '';
      if (endDate.isEmpty) {
        endDate = startDate;
      }
      // Use category ID instead of title
      final categoryId = selectedCategoryModel.value?.id.toString() ?? '';

      // Use selected user ID for author filtering
      String authorId = selectedUser.value?.userID.toString() ?? '';
      
      final String roleID = GlobalVariables.roleID;
      if (roleID == '6' || roleID == '7') {
        authorId = GlobalVariables.userID.toString();
      }

      final title = searchController.text.trim();
      final newssourceId = selectedNewsSource.value?.id.toString() ?? '';

      print(
        'Filters - Start: $startDate, End: $endDate, CategoryID: $categoryId, AuthorID: $authorId, Title: $title, NewsSource: $newssourceId',
      );

      final response = await _newsRepository.getNewsList(
        status: selectedStatus.value,
        userID: authorId,
        startDate: startDate,
        endDate: endDate,
        catID: categoryId,
        title: title,
        newssource: newssourceId,
        page: currentPage.value,
      );

      print(
        'API Response - Total: ${response.total}, Current Page: ${response.currentPage}',
      );

      if (isRefresh) {
        newsList.assignAll(response.newslist);
      } else {
        newsList.addAll(response.newslist);
      }

      totalPages.value = response.lastPage;
      totalNews.value = response.total;

      print(
        'Updated UI - News count: ${newsList.length}, Total: ${totalNews.value}',
      );
    } catch (e) {
      print('Error loading news: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'error'.tr,
        errorMessage.value,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
        } finally {
          isLoading.value = false;
          isLoadingMore.value = false;
        }
      },
      onNoConnection: () {
        addPendingOperation(() => loadNewsList(isRefresh: isRefresh));
      },
    );
  }

  Future<void> loadMoreNews() async {
    if (isLoadingMore.value || currentPage.value >= totalPages.value) {
      return;
    }

    isLoadingMore.value = true;
    currentPage.value++;
    await loadNewsList();
  }

  Future<void> refreshNews() async {
    print('Refresh button pressed - starting refresh');
    await loadNewsList(isRefresh: true);

    // // Show success message only if no error
    // if (errorMessage.value.isEmpty) {
    //   Get.snackbar(
    //     'Success',
    //     'News list refreshed',
    //     backgroundColor: Get.theme.colorScheme.primary,
    //     colorText: Get.theme.colorScheme.onPrimary,
    //     duration: const Duration(seconds: 2),
    //   );
    // }
  }

  Future<void> retryLoadNews() async {
    print('Retry button pressed - attempting to reload news');
    errorMessage.value = ''; // Clear previous error
    await loadNewsList(isRefresh: true);
  }

  Future<void> applyFilters() async {
    print('Applying filters');
    await loadNewsList(isRefresh: true);
  }

  // void clearFilters() {
  //   searchController.clear();
  //   selectedCategoryModel.value = null;
  //   selectedStatus.value = 'Active';
  //   selectedUser.value = null;
  //   applyFilters();
  // }

  void toggleFilterVisibility() {
    isFilterVisible.value = !isFilterVisible.value;
  }

  Future<void> loadFilterData() async {
    try {
      isLoadingFilterData.value = true;
      final filterData = await _filterService.getFilterData();

      // Only load main categories (parentID: 0) for filtering in dashboard
      // Subcategories are typically not used for filtering news lists
      final mainCategories = filterData.categories
          .where((category) => category.parentID == 0)
          .toList();

      availableCategories.assignAll(mainCategories);
      availableUsers.assignAll(filterData.users);
      availableNewsSources.assignAll(filterData.newsSources);

      print(
        'Loaded ${mainCategories.length} main categories, ${filterData.users.length} users and ${filterData.newsSources.length} news sources for filtering',
      );
    } catch (e) {
      print('Error loading filter data: $e');
      Get.snackbar('Error'.tr, 'Failed to load filter options'.tr,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingFilterData.value = false;
    }
  }

  void showFilterDialog() {
    // Safety check to prevent accessing disposed controllers
    if (!Get.isRegistered<NewslistController>()) return;

    // Copy current filter values to dialog controllers
    dialogSearchController.text = searchController.text;
    // Only copy dates if they were explicitly set by user (not default dates)
    final startDateValue =
        searchController.text.isNotEmpty ||
            selectedUser.value != null ||
            selectedCategoryModel.value != null
        ? startDateController.text
        : '';
    final endDateValue =
        searchController.text.isNotEmpty ||
            selectedUser.value != null ||
            selectedCategoryModel.value != null
        ? endDateController.text
        : '';

    dialogStartDateController.text = startDateValue;
    dialogEndDateController.text = endDateValue;
    dialogStartDateText.value = startDateValue;
    dialogEndDateText.value = endDateValue;

    dialogSelectedUser.value = selectedUser.value;
    dialogSelectedCategory.value = selectedCategoryModel.value;
    dialogSelectedNewsSource.value = selectedNewsSource.value;

    // Load filter data if not already loaded
    if (availableCategories.isEmpty || availableUsers.isEmpty || availableNewsSources.isEmpty) {
      loadFilterData();
    }

    // This will be called from the screen widget
    print('Filter dialog requested');
  }

  void applyDialogFilters() {
    // Validate dates before applying
    if (!_validateDialogDates()) {
      return;
    }

    // Copy dialog values to actual filter controllers
    searchController.text = dialogSearchController.text;
    startDateController.text = dialogStartDateController.text;
    endDateController.text = dialogEndDateController.text;
    selectedUser.value = dialogSelectedUser.value;
    selectedCategoryModel.value = dialogSelectedCategory.value;
    selectedNewsSource.value = dialogSelectedNewsSource.value;

    // Close dialog and apply filters
    Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
    applyFilters();
  }

  void cancelDialogFilters() {
    // Reset dialog values to current filter values
    dialogSearchController.text = searchController.text;
    dialogStartDateController.text = startDateController.text;
    dialogEndDateController.text = endDateController.text;
    dialogStartDateText.value = startDateController.text;
    dialogEndDateText.value = endDateController.text;
    dialogSelectedUser.value = selectedUser.value;
    dialogSelectedCategory.value = selectedCategoryModel.value;
    dialogSelectedNewsSource.value = selectedNewsSource.value;

    Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
  }

  void clearDialogFilters() {
    // Clear all dialog filter values
    dialogSearchController.clear();
    dialogStartDateController.clear();
    dialogEndDateController.clear();
    dialogStartDateText.value = '';
    dialogEndDateText.value = '';
    dialogSelectedUser.value = null;
    dialogSelectedCategory.value = null;
    dialogSelectedNewsSource.value = null;

    // Apply the cleared filters immediately
    searchController.clear();
    startDateController.clear();
    endDateController.clear();
    selectedUser.value = null;
    selectedCategoryModel.value = null;
    selectedNewsSource.value = null;
    selectedStatus.value = 'Active';
    // Close dialog and refresh news list
    Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
    applyFilters();
  }

  bool _validateDialogDates() {
    final startDateText = dialogStartDateController.text.trim();
    final endDateText = dialogEndDateController.text.trim();

    // If both dates are empty, validation passes
    if (startDateText.isEmpty && endDateText.isEmpty) {
      return true;
    }

    // If only one date is provided, validation passes
    if (startDateText.isEmpty || endDateText.isEmpty) {
      return true;
    }

    try {
      final startDate = DateTime.parse(startDateText);
      final endDate = DateTime.parse(endDateText);

      if (startDate.isAfter(endDate)) {
        Get.snackbar('Invalid Date Range'.tr, 'Start date must be before end date'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
      return true;
    } catch (e) {
      Get.snackbar('Invalid Date Format'.tr, 'Please select valid dates'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  void clearDialogStartDate() {
    dialogStartDateController.clear();
    dialogStartDateText.value = '';
  }

  void clearDialogEndDate() {
    dialogEndDateController.clear();
    dialogEndDateText.value = '';
  }

  Future<void> selectDialogDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = _formatDate(picked);
      if (isStartDate) {
        dialogStartDateController.text = formattedDate;
        dialogStartDateText.value = formattedDate;
      } else {
        dialogEndDateController.text = formattedDate;
        dialogEndDateText.value = formattedDate;
      }
    }
  }

  void createNews() {
    Get.toNamed('/create-news');
  }

  Future<void> updateNewsOrder(List<NewsModel> orderedList) async {
    Get.dialog(
      CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 16),
            Text('Updating order...'.tr),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    try {
      final newOrder = orderedList.map((n) => n.id).toList();
      final newLiveOrder = orderedList.map((n) => n.isLiveNews).toList();

      final dioClient = dio.Dio()..interceptors.add(dio.LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true));
      final response = await dioClient.post(
        ApiConstants.newsorderUrl,
        data: jsonEncode({'newOrder': newOrder, 'newliveOrder': newLiveOrder}),
        options: dio.Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back(); // close loader

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          response.data['message'] ?? 'News order updated',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        await loadNewsList(isRefresh: true);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update order');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void editNews(NewsModel news) {
    Get.toNamed('/create-news', arguments: {'news': news})?.then((_) {
      try {
        Get.find<HomeController>().selectedMenu.value = HomeMenuItem.news;
      } catch (_) {}
    });
  }

  void viewNews(NewsModel news) {
    // Determine new status (toggle between Active and Inactive)
    final newStatus = news.status == 'Active' ? 'Inactive' : 'Active';

    Get.dialog(
      CupertinoAlertDialog(
        title: Text('Update Status'.tr),
        content: Text('Change status to $newStatus?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Cancel'.tr),
            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
            },
          ),
          CupertinoDialogAction(
            child: Text('Update'.tr),
            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
              _updateNewsStatus(news, newStatus);
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void deleteNews(NewsModel news) {
    Get.dialog(
      CupertinoAlertDialog(
        title: Text('Delete News'.tr),
        content: Text('Are you sure you want to delete this news article?'.tr,
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Cancel'.tr),
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
            child: Text('Delete'.tr),
            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
              _performDeleteNews(news);
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _performDeleteNews(NewsModel news) async {
    try {
      // Show loading indicator
      Get.dialog(
        CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('Deleting news...'.tr),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final dioClient = dio.Dio()..interceptors.add(dio.LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true));
      final formData = dio.FormData.fromMap({'id': news.id.toString()});

      final response = await dioClient.post(
        ApiConstants.deleteNewsUrl,
        data: formData,
      );

      // Close loading dialog
      Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if the API response indicates success
        if (responseData['success'] == true) {
          // Remove the news from the list
          newsList.removeWhere((item) => item.id == news.id);
          totalNews.value = totalNews.value - 1;

          // Show the API response message
          final message =
              responseData['message'] ?? 'News deleted successfully';
          Get.snackbar(
            'Success',
            message,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: AppConstants.shortSnackbarDuration,
          );
        } else {
          // API returned success: false
          final errorMessage =
              responseData['message'] ?? 'Failed to delete news';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('Failed to delete news');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
      }

      print('Error deleting news: $e');
      Get.snackbar(
        'error'.tr,
        'failed_to_delete_news'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
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

  Future<void> _updateNewsStatus(NewsModel news, String newStatus) async {
    try {
      // Show loading indicator
      Get.dialog(
        CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('Updating status...'.tr),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final dioClient = dio.Dio()..interceptors.add(dio.LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true));
      final formData = dio.FormData.fromMap({
        'id': news.id.toString(),
        'status': newStatus,
      });

      final response = await dioClient.post(
        ApiConstants.updateStatusUrl,
        data: formData,
      );

      // Close loading dialog
      Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if the API response indicates success
        if (responseData['success'] == true) {
          // Remove the news from the current list since status changed
          newsList.removeWhere((item) => item.id == news.id);
          totalNews.value = totalNews.value - 1;

          // Show the API response message
          final message =
              responseData['message'] ?? 'Status updated successfully';
          Get.snackbar(
            'Success',
            message,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: AppConstants.shortSnackbarDuration,
          );
        } else {
          // API returned success: false
          final errorMessage =
              responseData['message'] ?? 'Failed to update status';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
      }

      print('Error updating news status: $e');
      Get.snackbar(
        'error'.tr,
        'failed_to_update_status'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: AppConstants.mediumSnackbarDuration,
      );
    }
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
      print('Error during logout: $e');
      Get.offAllNamed('/login');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
