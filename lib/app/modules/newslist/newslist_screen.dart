import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gstv_admin/app/core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'newslist_controller.dart';
import '../../data/models/news_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/news_source_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/global_variables.dart';

class NewslistScreen extends StatefulWidget {
  const NewslistScreen({super.key});

  @override
  State<NewslistScreen> createState() => _NewslistScreenState();
}

class _NewslistScreenState extends State<NewslistScreen>
    with AutomaticKeepAliveClientMixin {
  late final NewslistController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NewslistController(), permanent: true);
    // Load only on first visit – deferred to after the build phase to avoid
    // "setState() or markNeedsBuild() called during build" when reactive
    // variables (isLoading) change while the widget tree is still building.
    if (controller.newsList.isEmpty && !controller.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            controller.newsList.isEmpty &&
            !controller.isLoading.value) {
          controller.loadNewsList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return SafeArea(
      top: false,
      child: Column(
        children: [
          _buildContentHeader(controller),
          Expanded(child: _buildNewsList(controller)),
        ],
      ),
    );
  }

  Widget _buildContentHeader(NewslistController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'news'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showFilterDialog(controller),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.filter_alt_outlined,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 5),
          if (GlobalVariables.roleID != '7') ...[
            GestureDetector(
              onTap: () => _showReorderDialog(controller),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_vert,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          ElevatedButton.icon(
            onPressed: controller.createNews,
            icon: const Icon(Icons.add, size: 14),
            label: Text('create_news'.tr, style: const TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(0, 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList(NewslistController controller) {
    return Obx(() {
      // Show error state if there's an error and no data
      if (controller.errorMessage.value.isNotEmpty &&
          controller.newsList.isEmpty &&
          !controller.isLoading.value) {
        return _buildErrorState(controller);
      }

      if (controller.isLoading.value && controller.newsList.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.newsList.isEmpty && !controller.isLoading.value) {
        return _buildEmptyState(controller);
      }

      return Column(
        children: [
          // Show error banner if there's an error but we have cached data
          if (controller.errorMessage.value.isNotEmpty &&
              controller.newsList.isNotEmpty)
            _buildErrorBanner(controller),

          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshNews,
              color: AppColors.primary,
              child: ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.zero,
                itemCount:
                    controller.newsList.length +
                    (controller.isLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the bottom when loading more
                  if (index == controller.newsList.length) {
                    return _buildLoadingMoreIndicator();
                  }
                  final news = controller.newsList[index];
                  return NewsTableRow(
                    news: news,
                    index: index,
                    controller: controller,
                    onLongPress: GlobalVariables.roleID != '7'
                        ? () => _showReorderDialog(controller)
                        : () {},
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

  Widget _buildPaginationInfo(NewslistController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Obx(
            () => Text(
              'Showing 1 to ${controller.newsList.length} of ${controller.totalNews.value}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const Spacer(),
          Obx(
            () => TextButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.refreshNews,
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text('refresh'.tr),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildEmptyState(NewslistController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'no_news_articles_found'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'try_adjusting_filters'.tr,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.createNews,
              icon: const Icon(Icons.add),
              label: Text('create_news_button'.tr),
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

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'loading_more'.tr,
            style: TextStyle(fontSize: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(NewslistController controller) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Error Title
            Text(
              'failed_to_load_news'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),

            // Error Message
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : 'something_went_wrong'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Retry Button
            Obx(
              () => ElevatedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.retryLoadNews,
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  controller.isLoading.value ? 'retrying'.tr : 'try_again'.tr,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA0AEC0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Secondary Action - Go to Create News
            TextButton.icon(
              onPressed: () => Get.toNamed('/create-news'),
              icon: const Icon(Icons.add, size: 18),
              label: Text('create_new_news'.tr),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.legacyGrey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(NewslistController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorWithOpacity(0.1),
        border: Border.all(color: AppColors.errorWithOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'connection_issue'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${'showing_cached_data'.tr} ${controller.errorMessage.value}',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => TextButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.retryLoadNews,
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                controller.isLoading.value ? 'retrying'.tr : 'retry'.tr,
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReorderDialog(NewslistController controller) {
    final reorderList = ValueNotifier<List<NewsModel>>(
      controller.newsList.toList(),
    );
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.78,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_vert,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Reorder News'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Get.overlayContext != null
                          ? Navigator.pop(Get.overlayContext!)
                          : Get.back(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Reorderable list
              Expanded(
                child: ValueListenableBuilder<List<NewsModel>>(
                  valueListenable: reorderList,
                  builder: (context, list, _) {
                    return ReorderableListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: list.length,
                      onReorder: (oldIndex, newIndex) {
                        final updated = List<NewsModel>.from(list);
                        if (newIndex > oldIndex) newIndex--;
                        final item = updated.removeAt(oldIndex);
                        updated.insert(newIndex, item);
                        reorderList.value = updated;
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: child,
                        );
                      },
                      itemBuilder: (context, i) {
                        final news = list[i];
                        return Container(
                          key: ValueKey('${news.id}_$i'),
                          decoration: BoxDecoration(
                            color: (news.isHome == 1 && news.isLiveNews == 0)
                                ? const Color(0xFFF0F0F0)
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            leading: SizedBox(
                              width: 24,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: news.isLiveNews == 1
                                ? RichText(
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Live: ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
                                        ),
                                        TextSpan(
                                          text: news.title,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2D3748),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    news.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                            trailing: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              // Save button
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final ordered = reorderList.value.take(20).toList();
                      Get.overlayContext != null
                          ? Navigator.pop(Get.overlayContext!)
                          : Get.back();
                      controller.updateNewsOrder(ordered);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Save Order'.tr,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showFilterDialog(NewslistController controller) {
    controller.showFilterDialog();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.8,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: Get.height * 0.8,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'filter_news'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: controller.cancelDialogFilters,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildDialogTextField(
                        controller: controller.dialogSearchController,
                        label: 'search_title'.tr,
                        hint: 'enter_news_title_hint'.tr,
                      ),

                      const SizedBox(height: 20),
                      // Status Dropdown
                      _buildDialogStatusDropdown(controller),
                      const SizedBox(height: 20),
                      // Filter Form
                      if (GlobalVariables.roleID != '6' &&
                          GlobalVariables.roleID != '7')
                        _buildDialogUserDropdown(controller),
                      if (GlobalVariables.roleID != '6' &&
                          GlobalVariables.roleID != '7')
                        const SizedBox(height: 20),
                      // User and Category Dropdowns
                      if (GlobalVariables.roleID != '6' &&
                          GlobalVariables.roleID != '7')
                        _buildDialogCategoryDropdown(controller),
                      if (GlobalVariables.roleID != '6' &&
                          GlobalVariables.roleID != '7')
                        const SizedBox(height: 20),
                      if (GlobalVariables.roleID != '6' &&
                          GlobalVariables.roleID != '7')
                        _buildDialogNewsSourceDropdown(controller),
                      if (GlobalVariables.roleID != '6' &&
                          GlobalVariables.roleID != '7')
                        const SizedBox(height: 20),

                      _buildDialogDateField(
                        dashboardController: controller,
                        controller: controller.dialogStartDateController,
                        label: 'start_date'.tr,
                        isStartDate: true,
                        onTap: () =>
                            controller.selectDialogDate(Get.context!, true),
                        onClear: controller.clearDialogStartDate,
                      ),
                      const SizedBox(height: 20),
                      _buildDialogDateField(
                        dashboardController: controller,
                        controller: controller.dialogEndDateController,
                        label: 'end_date'.tr,
                        isStartDate: false,
                        onTap: () =>
                            controller.selectDialogDate(Get.context!, false),
                        onClear: controller.clearDialogEndDate,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons (outside scrollable area)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.clearDialogFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('clear_filters'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.applyDialogFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('apply_filters'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildDialogUserDropdown(NewslistController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => controller.isLoadingFilterData.value
              ? Container(
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<UserModel?>(
                  value: controller.dialogSelectedUser.value,
                  decoration: InputDecoration(
                    labelText: 'user'.tr,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'select_user'.tr,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<UserModel?>(
                      value: null,
                      child: Text(
                        'all_users'.tr,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    ...controller.availableUsers.map((UserModel user) {
                      return DropdownMenuItem<UserModel?>(
                        value: user,
                        child: Text(
                          user.name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (UserModel? value) {
                    controller.dialogSelectedUser.value = value;
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDialogCategoryDropdown(NewslistController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => controller.isLoadingFilterData.value
              ? Container(
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<CategoryModel?>(
                  value: controller.dialogSelectedCategory.value,
                  decoration: InputDecoration(
                    labelText: 'category'.tr,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'select_category_filter'.tr,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<CategoryModel?>(
                      value: null,
                      child: Text(
                        'all_categories'.tr,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    ...controller.availableCategories.map((
                      CategoryModel category,
                    ) {
                      return DropdownMenuItem<CategoryModel?>(
                        value: category,
                        child: Text(
                          category.title,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (CategoryModel? value) {
                    controller.dialogSelectedCategory.value = value;
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDialogNewsSourceDropdown(NewslistController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => controller.isLoadingFilterData.value
              ? Container(
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<NewsSourceModel?>(
                  value: controller.dialogSelectedNewsSource.value,
                  decoration: InputDecoration(
                    labelText: 'News Source'.tr,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Select News Source'.tr,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<NewsSourceModel?>(
                      value: null,
                      child: Text('All News Sources'.tr,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    ...controller.availableNewsSources.map((
                      NewsSourceModel source,
                    ) {
                      return DropdownMenuItem<NewsSourceModel?>(
                        value: source,
                        child: Text(
                          source.title,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (NewsSourceModel? value) {
                    controller.dialogSelectedNewsSource.value = value;
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDialogStatusDropdown(NewslistController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.selectedStatus.value,
            decoration: InputDecoration(
              labelText: 'status'.tr,
              labelStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            isExpanded: true,
            items: controller.statusOptions.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                controller.selectedStatus.value = value;
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDialogDateField({
    required NewslistController dashboardController,
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    required bool isStartDate,
    VoidCallback? onClear,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: 'yyyy-mm-dd'.tr,
        label: Text(label),
        suffixIcon: Obx(() {
          final dateText = isStartDate
              ? dashboardController.dialogStartDateText.value
              : dashboardController.dialogEndDateText.value;
          return dateText.isEmpty
              ? const Icon(Icons.calendar_today, size: 18)
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                  color: Colors.grey[600],
                  tooltip: 'clear_date'.tr,
                );
        }),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
    );
  }
}

class NewsTableRow extends StatelessWidget {
  final NewsModel news;
  final int index;
  final NewslistController controller;
  final VoidCallback? onLongPress;

  const NewsTableRow({
    super.key,
    required this.news,
    required this.index,
    required this.controller,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      onTap: () async {
        if (news.status == 'Active') {
          final String type = news.categories == 'Videos' ? '' : 'news';
          final String categoryPath = news.categorySlugs
              .replaceAll(',', '/')
              .replaceAll(' ', '');
          final String pathPrefix = type.isEmpty ? '' : '/$type';
          final String url =
              '${ApiConstants.baseUrl}$pathPrefix/$categoryPath/${news.slug}';
          debugPrint('Sharing URL: $url');
          if (!await launchUrl(Uri.parse(url))) {
            throw Exception('Could not launch $url');
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
          color: (news.isHome == 1 && news.isLiveNews == 0)
              ? const Color(0xFFF0F0F0)
              : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                // Title + category + action buttons
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (news.isLiveNews == 1)
                        RichText(
                          // maxLines: 2,
                          // overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Live: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                              TextSpan(
                                text: news.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3748),
                          ),
                          // maxLines: 2,
                          // overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 6),
                      // Action icons
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  news.categories,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  news.authorName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 61, 150, 209),
                                  ),
                                ).paddingOnly(right: 10),
                              ],
                            ),
                          ),
                          Text(
                            '${news.viewer ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[900],
                            ),
                          ).paddingSymmetric(horizontal: 8),
                          _IconBtn(
                            icon: Icons.edit_outlined,
                            color: AppColors.info,
                            tooltip: 'Edit'.tr,
                            onTap: () => controller.editNews(news),
                          ),
                          const SizedBox(width: 4),
                          _IconBtn(
                            icon: Icons.delete_outline,
                            color: AppColors.error,
                            tooltip: 'Delete'.tr,
                            onTap: () => controller.deleteNews(news),
                          ),
                          const SizedBox(width: 4),
                          _IconBtn(
                            icon: news.status == 'Inactive'
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.success,
                            tooltip: news.status == 'Inactive'
                                ? 'activate'.tr
                                : 'deactivate'.tr,
                            onTap: () => controller.viewNews(news),
                          ),
                          const SizedBox(width: 4),
                          _IconBtn(
                            icon: Icons.reorder,
                            color: const Color.fromARGB(255, 191, 35, 173),
                            tooltip: 'Reoder'.tr,
                            onTap: () => onLongPress?.call(),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (news.newssource != null && news.newssource!.isNotEmpty)
                  Text(
                    news.newssource!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ).paddingOnly(left: 30)
                else
                  const SizedBox.shrink(),
                Text(
                  _formatDate(news.createdAt),
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ).paddingOnly(right: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'pm'.tr : 'am'.tr}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const monthKeys = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return monthKeys[month - 1].tr;
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
