import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../data/models/category_model.dart';
import '../../data/models/news_source_model.dart';
import '../../data/models/voice_model.dart';
import '../../data/models/media_model.dart';
import '../../routes/app_routes.dart';
import 'create_news_controller.dart';
import 'widgets/google_tags_widget.dart';
import 'widgets/html_editor_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/global_variables.dart';

class CreateNewsScreen extends StatelessWidget {
  const CreateNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateNewsController>(
      init: CreateNewsController(),
      builder: (controller) {
        return PopScope(
          canPop: false, // Always intercept back navigation
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return; // Already popped

            print('🔙 PopScope onPopInvokedWithResult called');
            final shouldPop = await controller.handleBackNavigation();
            if (shouldPop) {
              Get.offAllNamed('/home', arguments: {'menu': 'news'});
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: _buildAppBar(controller),
            body: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                    ],
                  ),
                );
              }
              return _buildUnifiedContent(controller);
            }),
            bottomNavigationBar: _buildSubmitBar(controller),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(CreateNewsController controller) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2D3748),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          final shouldNavigate = await controller.handleBackNavigation();
          if (shouldNavigate) {
            Get.offAllNamed('/home', arguments: {'menu': 'news'});
          }
        },
      ),
      title: Obx(
        () => Text(
          controller.isEditing.value ? 'edit_news'.tr : 'create_news'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
      // actions: [
      //   // Test button to manually trigger dialog
      //   IconButton(
      //     icon: const Icon(Icons.bug_report),
      //     onPressed: () => controller.testBackNavigationDialog(),
      //     tooltip: 'Test Dialog'.tr,
      //   ),
      // ],
    );
  }

  Widget _buildUnifiedContent(CreateNewsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info
            _buildTextField(
              controller: controller.titleController,
              label: 'title'.tr,
              hint: 'enter_news_title'.tr,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildEnglishTitleField(controller),
            const SizedBox(height: 20),
            _buildContentTypeSelector(controller),
            Obx(() {
              if (controller.selectedMedia.value != null) {
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildMediaSelector(controller),
                    _buildImageCreditField(controller),
                    _buildVideoSettings(controller),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 20),
            // Content Editor
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'content'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    const Text(' *', style: TextStyle(color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(
                  () => HtmlEditorWidget(
                    key: ValueKey(controller.contentUpdateKey.value),
                    controller: controller.htmlEditorController,
                    initialContent: controller.editingNewsContent.value,
                    hint: 'Enter news content here...',
                    onContentChanged: (String content) {
                      // Update the editing content for display
                      controller.editingNewsContent.value = content;
                      // Trigger validation when content changes
                      controller.validateStep(1);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Live News Toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: controller.isLiveNews.value
                          ? AppColors.primary
                          : Colors.white,
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: InkWell(
                      onTap: () => controller.isLiveNews.value =
                          !controller.isLiveNews.value,
                      borderRadius: BorderRadius.circular(6),
                      child: controller.isLiveNews.value
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'live_news'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const Spacer(),
                  if (controller.isLiveNews.value)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: controller.addLiveNewsItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'add_more'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (controller.isLiveNews.value) ...[
              const SizedBox(height: 20),
              _buildSimpleLiveNewsSection(controller),
            ],
            const SizedBox(height: 20),
            // Categories & Settings
            if (controller.isLoadingCategories.value)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (GlobalVariables.roleID != '7') ...[
                _buildNewsSourceDropdown(
                  label: 'News Source'.tr,
                  value: controller.selectedNewsSource.value,
                  items: controller.availableNewsSources.toList(),
                  onChanged: controller.updateNewsSource,
                ),
                const SizedBox(height: 20),
                _buildCategoryDropdown(
                  label: 'category_label'.tr,
                  value: controller.selectedCategory.value,
                  items: controller.availableCategories
                      .where(
                        (c) =>
                            c.id != controller.selectedEventCategory.value?.id,
                      )
                      .toList(),
                  onChanged: controller.updateCategory,
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                if (controller.selectedCategory.value != null &&
                    controller.hasSubCategories) ...[
                  _buildCategoryDropdown(
                    label: 'sub_category'.tr,
                    value: controller.selectedSubCategory.value,
                    items: controller
                        .getFilteredSubCategories()
                        .where(
                          (sc) =>
                              sc.id !=
                              controller.selectedEventCategory.value?.id,
                        )
                        .toList(),
                    onChanged: controller.updateSubCategory,
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),
                ],
                _buildCategoryDropdown(
                  label: 'event_festival_category'.tr,
                  value: controller.selectedEventCategory.value,
                  items: controller.availableEventCategories
                      .where(
                        (e) =>
                            e.id != controller.selectedCategory.value?.id &&
                            e.id != controller.selectedSubCategory.value?.id,
                      )
                      .toList(),
                  onChanged: controller.updateEventCategory,
                ),
                const SizedBox(height: 20),
              ],
              GoogleTagsWidget(
                onTagsChanged: controller.onTagsChanged,
                initialTags: controller.getInitialTags(),
              ),
              const SizedBox(height: 20),
              _buildRelatedNewsSection(controller),
              const SizedBox(height: 40),
              Text(
                'settings'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingsTile(
                title: 'breaking_news'.tr,
                subtitle: 'mark_as_breaking_news'.tr,
                value: controller.isBreakingNews.value,
                onChanged: (value) => controller.isBreakingNews.value = value,
                icon: Icons.announcement_outlined,
                color: Colors.red,
              ),
              _buildSettingsTile(
                title: 'send_notification'.tr,
                subtitle: 'push_notification_to_users'.tr,
                value: controller.sendNotification.value,
                onChanged: (value) => controller.sendNotification.value = value,
                icon: Icons.notifications_outlined,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              _buildStatusSelector(controller),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar(CreateNewsController controller) {
    return Obx(
      () => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.submitNews,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          controller.submitButtonText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int? minLines,
    int? maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType:
              keyboardType ??
              (maxLines != null && maxLines > 1
                  ? TextInputType.multiline
                  : TextInputType.text),
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          inputFormatters: [
            ...?inputFormatters,
            if (maxLength != null)
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.characters.length > maxLength) {
                  return oldValue;
                }
                return newValue;
              }),
          ],
          buildCounter:
              (
                BuildContext context, {
                required int currentLength,
                required int? maxLength,
                required bool isFocused,
              }) {
                if (maxLength == null) return null;
                final charLength = controller.text.characters.length;
                return Text(
                  '$charLength/$maxLength',
                  style: TextStyle(
                    fontSize: 12,
                    color: charLength > maxLength
                        ? Colors.red
                        : const Color(0xFFA0AEC0),
                  ),
                );
              },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildEnglishTitleField(CreateNewsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'english_title'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),
            const Text(' *', style: TextStyle(color: Colors.red)),
            const Spacer(),
            TextButton(
              onPressed: () => controller.translateTitle(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Obx(
                () => controller.isTranslating.value
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Translate'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.englishTitleController,
          decoration: InputDecoration(
            hintText: 'enter_english_title'.tr,
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeSelector(CreateNewsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'upload_from_device'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),

            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Image Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.pickAndUploadImage(),
                icon: const Icon(Icons.image, size: 16),
                label: Text('image'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Video Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.pickAndUploadVideo(),
                icon: const Icon(Icons.videocam, size: 16),
                label: Text('video'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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
        const SizedBox(height: 16),
        // Upload Progress Indicator
        Obx(() {
          if (controller.isUploading.value) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'uploading_media'.tr,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.cancelUpload,
                        child: Text('cancel'.tr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: controller.uploadProgress.value,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(controller.uploadProgress.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 8),
        // Content Type Selector (for gallery selection)
        Row(
          children: [
            Text(
              'select_from_mobile_gallery'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),

            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),

        const SizedBox(height: 8),
        Row(
          children: [
            // Image Gallery Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.selectedContentType.value = 'Image';
                  _openMediaGalleryByType(controller, 'Image');
                },
                icon: const Icon(Icons.image_outlined, size: 16),
                label: Text('Image'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Video Gallery Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.selectedContentType.value = 'Video';
                  _openMediaGalleryByType(controller, 'Video');
                },
                icon: const Icon(Icons.videocam_outlined, size: 16),
                label: Text('Video'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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
      ],
    );
  }

  Future<void> _openMediaGalleryByType(
    CreateNewsController controller,
    String contentType,
  ) async {
    print('Opening Media Gallery with contentType: $contentType');
    final String mediaType = contentType == 'Image' ? '1' : '2';
    final dynamic result = await Get.toNamed(
      AppRoutes.mediaGallery,
      arguments: {'mediaType': mediaType},
    );
    print('Media Gallery returned: $result');

    if (result != null && result is MediaModel) {
      print('Calling setSelectedMedia with ID: ${result.id}');
      controller.setSelectedMedia(result);
    } else {
      print('Result was null or not a MediaModel');
    }
  }

  Widget _buildMediaSelector(CreateNewsController controller) {
    return Obx(() {
      final selectedMedia = controller.selectedMedia.value;

      if (selectedMedia == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF7FAFC),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: selectedMedia.thumbnailUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      errorWidget: (context, url, error) {
                        final secondaryUrl =
                            selectedMedia.fallbackThumbnailUrl ??
                            (url.contains('_video.gif')
                                ? url.replaceFirst(
                                    '_video.gif',
                                    '_video_small.jpg',
                                  )
                                : null);
                        if (secondaryUrl != null && secondaryUrl != url) {
                          return CachedNetworkImage(
                            imageUrl: secondaryUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                    const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image_outlined,
                              size: 30,
                              color: Color(0xFF718096),
                            ),
                          );
                        }
                        return const Icon(
                          Icons.broken_image_outlined,
                          size: 30,
                          color: Color(0xFF718096),
                        );
                      },
                    ),
                    if (selectedMedia.isVideo || selectedMedia.isGif)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            selectedMedia.isGif ? Icons.gif : Icons.play_arrow,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedMedia.photos,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedMedia.isVideo
                        ? 'video'.tr
                        : selectedMedia.isGif
                        ? 'gif'.tr
                        : 'image'.tr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _openMediaGalleryByType(
                    controller,
                    controller.selectedContentType.value,
                  ),
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  tooltip: 'change_media'.tr,
                ),
                IconButton(
                  onPressed: controller.clearSelectedMedia,
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  tooltip: 'remove_media'.tr,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildImageCreditField(CreateNewsController controller) {
    return Obx(() {
      final selectedMedia = controller.selectedMedia.value;

      if (selectedMedia == null) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildTextField(
            controller: controller.imageCreditController,
            label: 'Image/Video Credit'.tr,
            hint: 'Enter image/video credit text',
            isRequired: true,
          ),
        ],
      );
    });
  }

  Widget _buildVideoSettings(CreateNewsController controller) {
    return Obx(() {
      final selectedMedia = controller.selectedMedia.value;

      if (selectedMedia == null || !selectedMedia.isVideo) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.videocam_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'video_settings'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: controller.videoStartController,
              label: 'Video GIF Start With'.tr,
              hint: 'Enter video GIF start time (seconds)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: _buildVideoCheckbox(
                    title: 'Jacket'.tr,
                    value: controller.isJacket.value,
                    onChanged: (value) => controller.isJacket.value = value,
                  ),
                ),
                Expanded(
                  child: _buildVideoCheckbox(
                    title: 'Horizontal Video'.tr,
                    value: controller.isVideoHorizontal.value,
                    onChanged: (value) =>
                        controller.isVideoHorizontal.value = value,
                  ),
                ),
              ],
            ),
            if (controller.isJacket.value) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: controller.jacketTitleController,
                label: 'Jacket Title'.tr,
                hint: 'Enter jacket title',
                isRequired: true,
                maxLength: 32,
              ),
              const SizedBox(height: 16),
              _buildVoiceDropdown(
                label: 'Select Voice for Video'.tr,
                value: controller.selectedVoice.value,
                items: controller.availableVoices,
                onChanged: (value) => controller.selectedVoice.value = value,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: controller.voiceOverTextController,
                label: 'Voice Over Text'.tr,
                hint: 'Enter voice over text',
                isRequired: false,
                minLines: 4,
                maxLines: 8,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildVideoCheckbox({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSourceDropdown({
    required String label,
    required NewsSourceModel? value,
    required List<NewsSourceModel> items,
    required void Function(NewsSourceModel?) onChanged,
  }) {
    NewsSourceModel? safeValue;
    if (value != null) {
      try {
        safeValue = items.firstWhere((e) => e.id == value.id);
      } catch (_) {
        safeValue = null;
      }
    }
    final Set<int> seenIds = <int>{};
    final List<NewsSourceModel> uniqueItems = items
        .where((c) => seenIds.add(c.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<NewsSourceModel>(
          value: safeValue,
          decoration: InputDecoration(
            hintText: 'Select $label',
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: uniqueItems.map((NewsSourceModel source) {
            return DropdownMenuItem<NewsSourceModel>(
              value: source,
              child: Text(source.title),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildVoiceDropdown({
    required String label,
    required VoiceModel? value,
    required List<VoiceModel> items,
    required void Function(VoiceModel?) onChanged,
  }) {
    VoiceModel? safeValue;
    if (value != null) {
      try {
        safeValue = items.firstWhere((e) => e.voiceId == value.voiceId);
      } catch (_) {
        safeValue = null;
      }
    }
    final Set<String> seenIds = <String>{};
    final List<VoiceModel> uniqueItems = items
        .where((v) => seenIds.add(v.voiceId))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<VoiceModel>(
          key: ValueKey(safeValue?.voiceId ?? 'none'),
          // ignore: deprecated_member_use
          value: safeValue,
          decoration: InputDecoration(
            hintText: 'Select Voice for Video'.tr,
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: safeValue != null
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 18,
                      color: Color(0xFFA0AEC0),
                    ),
                    onPressed: () => onChanged(null),
                  )
                : null,
          ),
          items: uniqueItems.map((VoiceModel voice) {
            return DropdownMenuItem<VoiceModel>(
              value: voice,
              child: Text(voice.name),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown({
    required String label,
    required CategoryModel? value,
    required List<CategoryModel> items,
    required void Function(CategoryModel?) onChanged,
    bool isRequired = false,
  }) {
    // Ensure the selected value object exists in the items list; otherwise pass null to avoid assertion
    CategoryModel? safeValue;
    if (value != null) {
      try {
        safeValue = items.firstWhere((e) => e.id == value.id);
      } catch (_) {
        safeValue = null;
      }
    }
    // Ensure unique items by ID to avoid duplicate values in Dropdown
    final Set<int> seenIds = <int>{};
    final List<CategoryModel> uniqueItems = items
        .where((c) => seenIds.add(c.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryModel>(
                    value: safeValue,
                    hint: Text(
                      'Select $label',
                      style: const TextStyle(color: Color(0xFFA0AEC0)),
                    ),
                    isExpanded: true,
                    items: uniqueItems.map((category) {
                      return DropdownMenuItem<CategoryModel>(
                        value: category,
                        child: Text(
                          category.title,
                          style: const TextStyle(color: Color(0xFF2D3748)),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
              if (safeValue != null)
                IconButton(
                  tooltip: 'Clear $label',
                  icon: const Icon(
                    Icons.clear,
                    size: 18,
                    color: Color(0xFF718096),
                  ),
                  onPressed: () => onChanged(null),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(CreateNewsController controller) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'publication_status'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: controller.statusOptions.map((status) {
              final isSelected = controller.selectedStatus.value == status;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectedStatus.value = status,
                  child: Container(
                    margin: EdgeInsets.only(
                      right: status == controller.statusOptions.last ? 0 : 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryWithOpacity(0.1)
                          : AppColors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.unselectedBorder,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.tabUnselected,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (controller.selectedStatus.value == 'Schedule') ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: Get.context!,
                  initialDate:
                      controller.scheduledDateTime.value ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  final TimeOfDay? time = await showTimePicker(
                    context: Get.context!,
                    initialTime: TimeOfDay.fromDateTime(
                      controller.scheduledDateTime.value ?? DateTime.now(),
                    ),
                  );
                  if (time != null) {
                    controller.scheduledDateTime.value = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      time.hour,
                      time.minute,
                    );
                    controller.scheduleDateError.value = false;
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: controller.scheduleDateError.value
                        ? Colors.red
                        : const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: controller.scheduleDateError.value
                          ? Colors.red
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.scheduledDateTime.value != null
                            ? DateFormat(
                                'MMM dd, yyyy hh:mm a',
                              ).format(controller.scheduledDateTime.value!)
                            : 'select_date_and_time'.tr,
                        style: TextStyle(
                          color: controller.scheduledDateTime.value != null
                              ? const Color(0xFF4A5568)
                              : controller.scheduleDateError.value
                              ? Colors.red
                              : Color(0xFFA0AEC0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // if (controller.scheduledDateTime.value != null)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: controller.scheduledDateTime.value == null
                            ? Colors.transparent
                            : Color(0xFF4A5568),
                      ),
                      onPressed: () =>
                          controller.scheduledDateTime.value = null,
                      tooltip: 'clear'.tr,
                    ),
                  ],
                ),
              ),
            ),
            if (controller.scheduleDateError.value)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 4),
                child: Text(
                  'please_select_date_time'.tr,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // All unused toolbar methods removed - HTML editor has built-in toolbar

  // Old Quill formatting methods removed - HTML editor has built-in toolbar

  Widget _buildRelatedNewsSection(CreateNewsController controller) {
    return Builder(
      builder: (context) {
        return Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'related_news'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 8),

              // Debug info

              // Search Field with Autocomplete-style dropdown
              Column(
                children: [
                  // Search Input Field
                  TextField(
                    controller: controller.relatedNewsSearchController,
                    onChanged: (value) {
                      controller.searchRelatedNews(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'search_related_news'.tr,
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFA0AEC0),
                      ),
                      prefixIcon: controller.isSearchingRelatedNews.value
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.search,
                              color: Color(0xFFA0AEC0),
                              size: 20,
                            ),
                      suffixIcon:
                          controller.relatedNewsSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF718096),
                              ),
                              onPressed: controller.clearRelatedNewsSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  // Search Results Dropdown
                  if (controller.searchedRelatedNews.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(
                        maxHeight: 250,
                        minHeight: 50,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryWithOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Found ${controller.searchedRelatedNews.length} results',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                if (controller.selectedRelatedNews.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${controller.selectedRelatedNews.length} selected',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Search Results List
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: controller.searchedRelatedNews.length,
                              itemBuilder: (context, index) {
                                final news =
                                    controller.searchedRelatedNews[index];
                                final isSelected = controller
                                    .selectedRelatedNews
                                    .any((selected) => selected.id == news.id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryWithOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.primaryWithOpacity(
                                              0.3,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        if (isSelected) {
                                          controller.removeRelatedNews(news);
                                        } else {
                                          controller.addRelatedNews(news);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            // Selection indicator
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Colors.grey[400]!,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 12,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 10),
                                            // News title
                                            Expanded(
                                              child: Text(
                                                news.title,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : const Color(0xFF2D3748),
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Action icon
                                            Icon(
                                              isSelected
                                                  ? Icons.remove_circle_outline
                                                  : Icons.add_circle_outline,
                                              color: isSelected
                                                  ? Colors.red[400]
                                                  : AppColors.primary,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Selected Related News - only show when keyboard is closed or no search
              if (controller.selectedRelatedNews.isNotEmpty &&
                  (MediaQuery.of(context).viewInsets.bottom == 0 ||
                      controller.relatedNewsSearchController.text.isEmpty)) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryWithOpacity(0.1),
                        const Color(0xFF764ba2).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryWithOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Selected Related News (${controller.selectedRelatedNews.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...controller.selectedRelatedNews.map((news) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryWithOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  news.title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2D3748),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () =>
                                      controller.removeRelatedNews(news),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleLiveNewsSection(CreateNewsController controller) {
    return Obx(
      () => Column(
        children: controller.liveNewsItems.map((item) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title and Delete Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: item.titleController,
                      decoration: InputDecoration(
                        labelText: 'title'.tr,
                        hintText: 'enter_live_news_title'.tr,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),

                  if (controller.liveNewsItems.length > 1)
                    Container(
                      height: 48, // Match text field height
                      width: 48,
                      margin: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: IconButton(
                        onPressed: () => controller.removeLiveNewsItem(item.id),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        tooltip: 'remove_this_live_news_item'.tr,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Content HTML Editor
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live News Content'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 8),
                  HtmlEditorWidget(
                    controller: item.contentController,
                    initialContent: item.initialContent,
                    hint: 'Enter live news content...',
                    onContentChanged: (String content) {
                      // Keep the item's initial content in sync so we can submit without opening editor
                      item.initialContent = content;
                    },
                  ),
                ],
              ),
            ],
          ).paddingOnly(bottom: 16);
        }).toList(),
      ),
    );
  }

  // Removed unused Quill toolbar - HTML editor has built-in toolbar

  // All unused Quill methods removed - HTML editor handles all formatting internally
}
