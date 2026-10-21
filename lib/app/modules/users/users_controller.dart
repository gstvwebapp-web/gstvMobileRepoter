import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/constants/api_constants.dart';
import '../../data/models/user_list_model.dart';

class UsersController extends GetxController {
  final RxList<UserListModel> usersList = <UserListModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalUsers = 0.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    loadUsers();
  }

  @override
  void onClose() {
    searchController.dispose();
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

  Future<void> loadUsers({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        currentPage.value = 1;
        usersList.clear();
      }
      isLoading.value = true;
      errorMessage.value = '';

      final dioClient = dio.Dio()..interceptors.add(dio.LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true));
      final formData = dio.FormData.fromMap({
        'page': currentPage.value.toString(),
        'search': searchController.text.trim(),
      });

      final response = await dioClient.post(
        ApiConstants.usersListUrl,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List list = data['users'] ?? [];
        final users = list.map((e) => UserListModel.fromJson(e)).toList();

        if (isRefresh) {
          usersList.assignAll(users);
        } else {
          usersList.addAll(users);
        }

        totalPages.value = data['last_page'] ?? 1;
        totalUsers.value = data['total'] ?? 0;
      } else {
        throw Exception('Failed to load users');
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
    await loadUsers();
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    loadUsers(isRefresh: true);
  }
}
