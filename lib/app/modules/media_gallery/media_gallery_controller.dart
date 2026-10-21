import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/media_model.dart';
import '../../data/services/media_service.dart';

class MediaGalleryController extends GetxController {
  final MediaService _mediaService = MediaService();

  // Observable variables
  final RxList<MediaModel> allMediaItems = <MediaModel>[].obs;
  final RxList<MediaModel> videoMediaItems = <MediaModel>[].obs;
  final RxList<MediaModel> displayedMediaItems = <MediaModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString selectedMediaType = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasMorePages = true.obs;
  final Rx<MediaModel?> selectedMedia = Rx<MediaModel?>(null);

  // Controllers
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Media type options (simplified)
  final RxString initialMediaType = '1'.obs; // Store the initial media type from arguments

  @override
  void onInit() {
    super.onInit();
    _handleInitialMediaType();
    loadMediaList();
    setupScrollController();
    setupSearchListener();
  }

  void _handleInitialMediaType() {
    final arguments = Get.arguments;
    if (arguments != null && arguments['mediaType'] != null) {
      initialMediaType.value = arguments['mediaType'];
      selectedMediaType.value = arguments['mediaType'] == '1' ? 'images' : 'videos';
    } else {
      initialMediaType.value = '1';
      selectedMediaType.value = 'images';
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void setupScrollController() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore.value && hasMorePages.value) {
          loadMoreMedia();
        }
      }
    });
  }

  void setupSearchListener() {
    searchController.addListener(() {
      if (searchQuery.value != searchController.text) {
        searchQuery.value = searchController.text;
        _debounceSearch();
      }
    });
  }

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery.value == searchController.text) {
        resetAndSearch();
      }
    });
  }

  Future<void> loadMediaList() async {
    try {
      isLoading.value = true;
      currentPage.value = 1;

      final response = await _mediaService.getMediaList(
        page: currentPage.value,
        mediaType: initialMediaType.value,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      allMediaItems.clear();
      videoMediaItems.clear();

      allMediaItems.addAll(response.media.data);
      videoMediaItems.addAll(response.videoMedia.data);

      // Set total pages based on the requested media type
      if (initialMediaType.value == '1') {
        totalPages.value = response.media.lastPage;
      } else {
        totalPages.value = response.videoMedia.lastPage;
      }
      hasMorePages.value = currentPage.value < totalPages.value;

      updateDisplayedMedia();
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to load media: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreMedia() async {
    if (!hasMorePages.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      final response = await _mediaService.getMediaList(
        page: currentPage.value,
        mediaType: initialMediaType.value,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      allMediaItems.addAll(response.media.data);
      videoMediaItems.addAll(response.videoMedia.data);

      // Update hasMorePages based on the requested media type
      if (initialMediaType.value == '1') {
        hasMorePages.value = currentPage.value < response.media.lastPage;
      } else {
        hasMorePages.value = currentPage.value < response.videoMedia.lastPage;
      }

      updateDisplayedMedia();
    } catch (e) {
      currentPage.value--; // Revert page increment on error
      Get.snackbar('Error'.tr, 'Failed to load more media: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> resetAndSearch() async {
    currentPage.value = 1;
    hasMorePages.value = true;
    await searchMedia();
  }

  Future<void> searchMedia() async {
    try {
      isLoading.value = true;

      final response = await _mediaService.searchMedia(
        page: currentPage.value,
        mediaType: initialMediaType.value,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      if (currentPage.value == 1) {
        allMediaItems.clear();
        videoMediaItems.clear();
      }

      allMediaItems.addAll(response.media.data);
      videoMediaItems.addAll(response.videoMedia.data);

      // Set pagination based on the requested media type
      if (initialMediaType.value == '1') {
        totalPages.value = response.media.lastPage;
      } else {
        totalPages.value = response.videoMedia.lastPage;
      }
      hasMorePages.value = currentPage.value < totalPages.value;

      updateDisplayedMedia();
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to search media: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void updateDisplayedMedia() {
    // Show only the media type that was requested
    if (initialMediaType.value == '1') {
      // Show only images from media key
      displayedMediaItems.value = allMediaItems;
    } else {
      // Show only videos from videomedia key
      displayedMediaItems.value = videoMediaItems;
    }
  }
  Future<void> deleteMediaById(int id) async {
    try {
      isLoading.value = true;
      final bool success = await _mediaService.deleteMedia(id: id);
      if (success) {
        // Remove from all lists
        allMediaItems.removeWhere((m) => m.id == id);
        videoMediaItems.removeWhere((m) => m.id == id);
        displayedMediaItems.removeWhere((m) => m.id == id);
        if (selectedMedia.value?.id == id) {
          selectedMedia.value = null;
        }
        Get.snackbar('Success'.tr, 'Media deleted successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Error'.tr, 'Failed to delete media'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to delete media: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectMedia(MediaModel media) {
    if (selectedMedia.value?.id == media.id) {
      selectedMedia.value = null; // Deselect if already selected
    } else {
      selectedMedia.value = media;
    }
  }

  void confirmSelection() {
    if (selectedMedia.value != null) {
      if (Get.overlayContext != null) {
        Navigator.pop(Get.overlayContext!, selectedMedia.value);
      } else {
        Get.overlayContext != null ? Navigator.pop(Get.overlayContext!, selectedMedia.value) : Get.back(result: selectedMedia.value);
      }
    }
  }

  void clearSelection() {
    selectedMedia.value = null;
  }



  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadMediaList();
  }

  int getCrossAxisCount(double width) {
    if (width > 1200) return 6; // Desktop
    if (width > 800) return 4; // Tablet
    if (width > 600) return 3; // Large mobile
    return 2; // Mobile
  }

  double getChildAspectRatio(double width) {
    if (width > 800) return 1.0; // Desktop/Tablet
    return 0.8; // Mobile
  }
}