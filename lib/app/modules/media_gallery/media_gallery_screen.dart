import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/media_model.dart';
import 'media_gallery_controller.dart';
import '../../core/constants/app_colors.dart';

class MediaGalleryScreen extends StatelessWidget {
  const MediaGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MediaGalleryController>(
      init: MediaGalleryController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.dashboardBackground,
          appBar: _buildAppBar(controller),
          body: Column(
            children: [
              _buildSearchHeader(controller),
              Expanded(child: _buildMediaGrid(controller)),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigation(controller),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(MediaGalleryController controller) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2D3748),
      title: Obx(
        () => Text(
          controller.initialMediaType.value == '1' ? 'images'.tr : 'videos'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
      actions: [],
    );
  }

  Widget _buildSearchHeader(MediaGalleryController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackWithOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildSearchBar(controller),
    );
  }

  Widget _buildSearchBar(MediaGalleryController controller) {
    return TextField(
      controller: controller.searchController,
      decoration: InputDecoration(
        hintText: 'search_media'.tr,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: Obx(
          () => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  onPressed: controller.clearSearch,
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                )
              : const SizedBox.shrink(),
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  Widget _buildMediaGrid(MediaGalleryController controller) {
    return Obx(() {
      if (controller.isLoading.value &&
          controller.displayedMediaItems.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.displayedMediaItems.isEmpty) {
        return _buildEmptyState(controller);
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = controller.getCrossAxisCount(
            constraints.maxWidth,
          );
          final childAspectRatio = controller.getChildAspectRatio(
            constraints.maxWidth,
          );

          return RefreshIndicator(
            onRefresh: controller.loadMediaList,
            child: GridView.builder(
              controller: controller.scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemCount:
                  controller.displayedMediaItems.length +
                  (controller.isLoadingMore.value ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.displayedMediaItems.length) {
                  return _buildLoadingCard();
                }

                final media = controller.displayedMediaItems[index];
                return _buildMediaCard(media, controller);
              },
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState(MediaGalleryController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.searchQuery.value.isNotEmpty
                ? Icons.search_off
                : Icons.photo_library_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'no_media_found'.trParams({
                    'query': controller.searchQuery.value,
                  })
                : 'no_media_available'.tr,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'upload_some_media'.tr,
            style: const TextStyle(fontSize: 14, color: Color(0xFFA0AEC0)),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(MediaModel media, MediaGalleryController controller) {
    return Obx(() {
      final isSelected = controller.selectedMedia.value?.id == media.id;

      return GestureDetector(
        onTap: () => controller.selectMedia(media),
        child: Container(
          decoration: BoxDecoration(
            // borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.selectedBorder
                  : AppColors.unselectedBorder,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackWithOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: AppColors.cardBackground,
                  child: _buildMediaPreview(media),
                ),
                // Selection check indicator
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                // Delete action button (top-right, below check indicator)
                Positioned(
                  top: 5,
                  right: 5,
                  child: InkWell(
                    onTap: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: Get.context!,
                        builder: (ctx) => AlertDialog(
                          title: Text('delete_media'.tr),
                          content: Text('delete_media_confirmation'.tr),
                          actions: [
                            TextButton(
                              onPressed: () {
                                if (Get.overlayContext != null) {
                                  Navigator.pop(Get.overlayContext!, false);
                                } else {
                                  Get.overlayContext != null ? Navigator.pop(Get.overlayContext!, false) : Get.back(result: false);
                                }
                              },
                              child: Text('cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () {
                                if (Get.overlayContext != null) {
                                  Navigator.pop(Get.overlayContext!, true);
                                } else {
                                  Get.overlayContext != null ? Navigator.pop(Get.overlayContext!, true) : Get.back(result: true);
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: Text('delete'.tr),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await controller.deleteMediaById(media.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Badge for video/GIF
                if (media.isVideo || media.isGif)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            media.isGif ? Icons.gif : Icons.play_arrow,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            media.isGif ? 'GIF' : 'VIDEO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMediaPreview(MediaModel media) {
    final String imageUrl = media.thumbnailUrl;
    final String? fallbackUrl = media.fallbackThumbnailUrl;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return Center(
          child: CircularProgressIndicator(
            value: downloadProgress.progress,
            strokeWidth: 2,
          ),
        );
      },
      errorWidget: (context, url, error) {
        final secondaryUrl = fallbackUrl ??
            (url.contains('_video.gif')
                ? url.replaceFirst('_video.gif', '_video_small.jpg')
                : null);

        if (secondaryUrl != null && secondaryUrl != url) {
          return CachedNetworkImage(
            imageUrl: secondaryUrl,
            fit: BoxFit.contain,
            progressIndicatorBuilder: (context, url, downloadProgress) {
              return Center(
                child: CircularProgressIndicator(
                  value: downloadProgress.progress,
                  strokeWidth: 2,
                ),
              );
            },
            errorWidget: (context, url, error) => _buildErrorWidget(),
          );
        }

        return _buildErrorWidget();
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF718096),
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Failed to load'.tr,
            style: const TextStyle(color: Color(0xFF718096), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildBottomNavigation(MediaGalleryController controller) {
    return Obx(
      () => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (Get.overlayContext != null) {
                      Navigator.pop(Get.overlayContext!);
                    } else {
                      Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'.tr,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.selectedMedia.value != null
                      ? controller.confirmSelection
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Select Media'.tr,
                    style: TextStyle(
                      color: controller.selectedMedia.value != null
                          ? Colors.white
                          : const Color(0xFF718096),
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
}
