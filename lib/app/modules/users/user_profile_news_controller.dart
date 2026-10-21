import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/constants/api_constants.dart';
import '../../data/models/user_profile_news_model.dart';

class UserProfileNewsController extends GetxController {
  final int userId;
  final String userName;

  UserProfileNewsController({required this.userId, required this.userName});

  final RxList<UserProfileNewsModel> newsList = <UserProfileNewsModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalNews = 0.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool isTodayActive = false.obs;
  final ScrollController scrollController = ScrollController();

  // Date filters
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final RxString startDateText = ''.obs;
  final RxString endDateText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    loadNews();
  }

  @override
  void onClose() {
    searchController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 300) {
        if (!isLoadingMore.value && currentPage.value < totalPages.value) {
          _loadMore();
        }
      }
    });
  }

  Future<void> loadNews({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        currentPage.value = 1;
        newsList.clear();
      }
      isLoading.value = true;
      errorMessage.value = '';

      final dioClient = dio.Dio()..interceptors.add(dio.LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true));
      final fields = {
        'page': currentPage.value.toString(),
        'userid': userId.toString(),
        'search': searchController.text.trim(),
      };
      if (startDateController.text.isNotEmpty) {
        fields['startDate'] = startDateController.text;
      }
      if (endDateController.text.isNotEmpty) {
        fields['endDate'] = endDateController.text;
      }

      final formData = dio.FormData.fromMap(fields);
      final response = await dioClient.post(
        ApiConstants.userProfileNewsListUrl,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List list = data['news'] ?? [];
        final items =
            list.map((e) => UserProfileNewsModel.fromJson(e)).toList();

        if (isRefresh) {
          newsList.assignAll(items);
        } else {
          newsList.addAll(items);
        }

        totalPages.value = data['last_page'] ?? 1;
        totalNews.value = data['total'] ?? 0;
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> _loadMore() async {
    if (isLoadingMore.value || currentPage.value >= totalPages.value) return;
    isLoadingMore.value = true;
    currentPage.value++;
    await loadNews();
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    loadNews(isRefresh: true);
  }

  void toggleToday() {
    isTodayActive.value = !isTodayActive.value;
    if (isTodayActive.value) {
      final today = _formatDate(DateTime.now());
      startDateController.text = today;
      startDateText.value = today;
      endDateController.text = today;
      endDateText.value = today;
    } else {
      startDateController.clear();
      startDateText.value = '';
      endDateController.clear();
      endDateText.value = '';
    }
    loadNews(isRefresh: true);
  }

  void selectDate(BuildContext context, bool isStart) async {
    isTodayActive.value = false;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      if (isStart) {
        startDateController.text = formatted;
        startDateText.value = formatted;
      } else {
        endDateController.text = formatted;
        endDateText.value = formatted;
      }
      loadNews(isRefresh: true);
    }
  }

  void clearDate(bool isStart) {
    isTodayActive.value = false;
    if (isStart) {
      startDateController.clear();
      startDateText.value = '';
    } else {
      endDateController.clear();
      endDateText.value = '';
    }
    loadNews(isRefresh: true);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
