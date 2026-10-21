import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile_news_model.dart';
import 'user_profile_news_controller.dart';

class UserProfileNewsScreen extends StatelessWidget {
  const UserProfileNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final userId = (args is Map ? args['userId'] : null) as int? ?? 0;
    final userName = (args is Map ? args['userName'] : null) as String? ?? 'User';

    final controller = Get.put(
      UserProfileNewsController(userId: userId, userName: userName),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Obx(() => IconButton(
          icon: Icon(
            controller.isSearching.value ? Icons.close : Icons.arrow_back_ios_new,
            color: const Color(0xFF1A202C),
            size: 18,
          ),
          onPressed: () {
            if (controller.isSearching.value) {
              controller.isSearching.value = false;
              controller.searchController.clear();
              controller.searchText.value = '';
              controller.loadNews(isRefresh: true);
            } else {
              Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
            }
          },
        )),
        title: Obx(() => controller.isSearching.value
            ? TextField(
                  controller: controller.searchController,
                  autofocus: true,
                  onChanged: controller.onSearchChanged,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A202C)),
                  decoration: InputDecoration(
                    hintText: 'Search news...'.tr,
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    // prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.primary),
                    // border: InputBorder.none,
                    // enabledBorder: InputBorder.none,
                    // focusedBorder: InputBorder.none,
                    // contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    isDense: true,
                  ),
                )
            : Text(
                userName,
                style: const TextStyle(
                  color: Color(0xFF1A202C),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              )),
        actions: [
          Obx(() => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: controller.searchText.value.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                controller.isSearching.value && controller.searchText.value.isEmpty
                    ? Icons.search
                    : controller.searchText.value.isNotEmpty
                        ? Icons.search_off
                        : Icons.search,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            onPressed: () {
              if (controller.isSearching.value && controller.searchText.value.isNotEmpty) {
                controller.searchController.clear();
                controller.searchText.value = '';
                controller.loadNews(isRefresh: true);
              } else {
                controller.isSearching.value = !controller.isSearching.value;
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildDateRow(controller),
            Expanded(child: _buildBody(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(UserProfileNewsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => GestureDetector(
              onTap: () => controller.selectDate(Get.context!, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: controller.startDateText.value.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : const Color(0xFFF7F8FA),
                  border: Border.all(
                    color: controller.startDateText.value.isNotEmpty
                        ? AppColors.primary
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14,
                        color: controller.startDateText.value.isNotEmpty
                            ? AppColors.primary
                            : Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        controller.startDateText.value.isNotEmpty
                            ? controller.startDateText.value
                            : 'Start Date',
                        style: TextStyle(
                          fontSize: 13,
                          color: controller.startDateText.value.isNotEmpty
                              ? AppColors.primary
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                    if (controller.startDateText.value.isNotEmpty)
                      GestureDetector(
                        onTap: () => controller.clearDate(true),
                        child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                      ),
                  ],
                ),
              ),
            )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() => GestureDetector(
              onTap: () => controller.selectDate(Get.context!, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: controller.endDateText.value.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : const Color(0xFFF7F8FA),
                  border: Border.all(
                    color: controller.endDateText.value.isNotEmpty
                        ? AppColors.primary
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14,
                        color: controller.endDateText.value.isNotEmpty
                            ? AppColors.primary
                            : Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        controller.endDateText.value.isNotEmpty
                            ? controller.endDateText.value
                            : 'End Date',
                        style: TextStyle(
                          fontSize: 13,
                          color: controller.endDateText.value.isNotEmpty
                              ? AppColors.primary
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                    if (controller.endDateText.value.isNotEmpty)
                      GestureDetector(
                        onTap: () => controller.clearDate(false),
                        child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                      ),
                  ],
                ),
              ),
            )),
          ),
          const SizedBox(width: 10),
          // Today toggle button
          Obx(() => GestureDetector(
            onTap: controller.toggleToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: controller.isTodayActive.value
                    ? AppColors.primary
                    : const Color(0xFFF7F8FA),
                border: Border.all(
                  color: controller.isTodayActive.value
                      ? AppColors.primary
                      : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Today'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: controller.isTodayActive.value
                      ? Colors.white
                      : Colors.grey[600],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBody(UserProfileNewsController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.newsList.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      if (controller.errorMessage.value.isNotEmpty && controller.newsList.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.loadNews(isRefresh: true),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text('Retry'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.newsList.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No news found'.tr,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => controller.loadNews(isRefresh: true),
              child: ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.zero,
                itemCount: controller.newsList.length +
                    (controller.isLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.newsList.length) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Text('loading_more'.tr,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.primary)),
                        ],
                      ),
                    );
                  }
                  return _ProfileNewsRow(
                    news: controller.newsList[index],
                    index: index,
                  );
                },
              ),
            ),
          ),
          _buildPaginationInfo(controller),
        ],
      );
    });
  }

  Widget _buildPaginationInfo(UserProfileNewsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Obx(() => Text(
            'Showing 1 to ${controller.newsList.length} of ${controller.totalNews.value}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          )),
          const Spacer(),
          Obx(() => TextButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : () => controller.loadNews(isRefresh: true),
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 16),
            label: Text('refresh'.tr),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          )),
        ],
      ),
    );
  }
}

class _ProfileNewsRow extends StatelessWidget {
  final UserProfileNewsModel news;
  final int index;

  const _ProfileNewsRow({required this.news, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (!await launchUrl(Uri.parse(news.url),
            mode: LaunchMode.externalApplication)) {
          Get.snackbar('Error'.tr, 'Could not open URL'.tr,
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number
            SizedBox(
              width: 30,
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            // Title + meta
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.categories,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatDateTime(news.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${news.viewer}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[900],
                        ),
                      ).paddingSymmetric(horizontal: 8),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day-$month-${dt.year} $hour:$min $period';
    } catch (_) {
      return raw;
    }
  }
}
