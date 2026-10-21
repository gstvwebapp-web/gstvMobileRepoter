import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'widgets/tinymce_editor_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import '../../core/constants/constants.dart';
import '../../data/models/news_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/news_source_model.dart';
import '../../data/repositories/news_repository.dart';
import '../../data/models/media_model.dart';
import '../../data/models/related_news_model.dart';
import '../../data/services/filter_service.dart';
import '../../data/models/voice_model.dart';
import '../../data/services/storage_service.dart';
import '../newslist/newslist_controller.dart';

// Live News Item Model
class LiveNewsItem {
  final TextEditingController titleController;
  final TinymceEditorController contentController;
  final String id;
  String initialContent;

  LiveNewsItem({String? title, String? content})
    : titleController = TextEditingController(text: title ?? ''),
      contentController = TinymceEditorController(),
      id = DateTime.now().millisecondsSinceEpoch.toString(),
      initialContent = content ?? '';

  void dispose() {
    titleController.dispose();
    // Note: TinymceEditorController doesn't need explicit disposal
  }

  Future<String> getContentAsHtml() async {
    try {
      // Try to read from the editor if it has been opened/initialized
      final htmlContent = await contentController.getText();
      if (htmlContent.isNotEmpty) {
        return htmlContent;
      }
    } catch (e) {
      // Editor might not be initialized yet; fall back to initial content
    }
    return initialContent;
  }
}

class CreateNewsController extends GetxController {
  final FilterService _filterService = FilterService();
  final NewsRepository _newsRepository = NewsRepository();

  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController englishTitleController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController relatedNewsSearchController =
      TextEditingController();
  final TextEditingController imageCreditController = TextEditingController();
  final TinymceEditorController htmlEditorController =
      TinymceEditorController();

  // Content update key to force widget rebuild when content is set programmatically
  final RxInt contentUpdateKey = 0.obs;

  // Store the content for editing mode to pass to widget as initial content
  final RxString editingNewsContent = ''.obs;

  // Google Tags
  final RxList<String> selectedTags = <String>[].obs;

  // Pending category IDs for edit mode
  int? _pendingCategoryId;
  int? _pendingSubCategoryId;
  int? _pendingEventCategoryId;
  int? _pendingNewsSourceId;

  // Store is_home value from edit data
  String _isHomeValue = '0'; // Default to 0

  // Step Management
  final RxInt currentStep = 0.obs;
  final RxBool isEditing = false.obs;
  final RxString newsId = ''.obs;

  // Form Data
  final RxString selectedContentType = ''.obs;
  final RxString selectedImageType = 'Image'.obs;
  final Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);
  final Rx<CategoryModel?> selectedSubCategory = Rx<CategoryModel?>(null);
  final Rx<CategoryModel?> selectedEventCategory = Rx<CategoryModel?>(null);
  final RxBool isBreakingNews = false.obs;
  final RxBool enableInshorts = false.obs;
  final RxBool sendNotification = false.obs;
  final RxBool isLiveNews = false.obs; // Added for live news selection
  final RxString selectedStatus = 'Publish'.obs;

  // Video Settings
  final RxBool hideVideoTitle = false.obs;
  final RxBool isVerticalVideo = false.obs;
  final RxString oldVideoUrl = ''.obs;

  // Loading States
  final RxBool isLoading = false.obs;
  final RxBool isLoadingCategories = false.obs;
  final RxBool isSubmitting = false.obs;

  // Filter Data
  final RxList<CategoryModel> availableCategories = <CategoryModel>[].obs;
  final RxList<CategoryModel> availableSubCategories = <CategoryModel>[].obs;
  final RxList<CategoryModel> availableEventCategories = <CategoryModel>[].obs;
  final RxList<NewsSourceModel> availableNewsSources = <NewsSourceModel>[].obs;
  final Rx<NewsSourceModel?> selectedNewsSource = Rx<NewsSourceModel?>(null);
  final RxList<CategoryModel> allCategories =
      <CategoryModel>[].obs; // Store all categories from API
  final RxList<VoiceModel> availableVoices = <VoiceModel>[].obs;

  // Image/File Upload
  final RxList<PlatformFile> selectedFiles = <PlatformFile>[].obs;
  final RxString uploadedImageUrl = ''.obs;

  final RxBool isTranslating = false.obs;

  // Upload Media Properties
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  dio.CancelToken? _uploadCancelToken;
  final Rx<MediaModel?> selectedMedia = Rx<MediaModel?>(null);

  // Scheduled Date
  final Rx<DateTime?> scheduledDateTime = Rx<DateTime?>(null);

  // Jacket / Video configuration
  final videoStartController = TextEditingController(text: '1');
  final isJacket = false.obs;
  final jacketTitleController = TextEditingController();
  final Rx<VoiceModel?> selectedVoice = Rx<VoiceModel?>(null);
  final voiceOverTextController = TextEditingController();
  String? _pendingVoiceId;
  final isVideoHorizontal = true.obs;

  // Form Field
  final RxBool scheduleDateError = false.obs;

  // Step Configuration
  final List<String> stepTitles = [
    'Basic Info',
    'Content',
    'Categories & Settings',
  ];

  // Form Validation
  final RxBool isStep1Valid = false.obs;
  final RxBool isStep2Valid = false.obs;
  final RxBool isStep3Valid = false.obs;

  // Content Type Options
  final List<String> contentTypes = ['Image', 'Video'];
  final List<String> imageTypes = ['Image', 'Video'];
  final List<String> statusOptions = ['Publish', 'Draft', 'Schedule'];

  // Related News
  final RxList<RelatedNewsItem> searchedRelatedNews = <RelatedNewsItem>[].obs;
  final RxList<RelatedNewsItem> selectedRelatedNews = <RelatedNewsItem>[].obs;
  final RxBool isSearchingRelatedNews = false.obs;
  final RxString relatedNewsSearchQuery = ''.obs;

  // Live News
  final RxList<LiveNewsItem> liveNewsItems = <LiveNewsItem>[].obs;

  // Change Tracking for Back Navigation Confirmation
  final RxBool hasUnsavedChanges = false.obs;
  Map<String, dynamic> _initialFormState = {};

  @override
  void onInit() {
    super.onInit();
    _setupValidationListeners();
    loadFilterData();

    // Clear editing content when initializing
    editingNewsContent.value = '';

    // Setup related news search listener
    relatedNewsSearchController.addListener(_onRelatedNewsSearchChanged);

    // Clear any existing live news items and initialize with one new item
    clearAllLiveNewsItems();

    // Setup change tracking listeners
    _setupChangeTrackingListeners();

    // Check if editing mode
    final arguments = Get.arguments;
    if (arguments != null && arguments['news'] != null) {
      _setupEditMode(arguments['news'] as NewsModel);
    } else {
      // Capture initial state for new news creation
      _captureInitialFormState();
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    englishTitleController.dispose();
    videoStartController.dispose();
    jacketTitleController.dispose();
    voiceOverTextController.dispose();
    tagsController.dispose();
    relatedNewsSearchController.dispose();
    imageCreditController.dispose();
    // Note: TinymceEditorController doesn't need explicit disposal

    // Dispose live news controllers
    for (var item in liveNewsItems) {
      item.dispose();
    }

    super.onClose();
  }

  void _setupValidationListeners() {
    titleController.addListener(() => validateStep(0));
    englishTitleController.addListener(() => validateStep(0));
    imageCreditController.addListener(() => validateStep(0));
    jacketTitleController.addListener(() => validateStep(0));
    // Note: HTML editor validation will be handled differently
  }

  /// Validates a specific step or all steps
  Future<void> validateStep([int? stepIndex]) async {
    // If no step specified, validate all steps
    if (stepIndex == null) {
      await validateStep(0);
      await validateStep(1);
      await validateStep(2);
      return;
    }

    switch (stepIndex) {
      case 0: // Step 1 validation
        final hasTitle = titleController.text.trim().isNotEmpty;
        final hasEnglishTitle = englishTitleController.text.trim().isNotEmpty;
        final hasMedia = selectedMedia.value != null;
        final hasImageCredit =
            selectedMedia.value == null ||
            imageCreditController.text.trim().isNotEmpty;
        final hasJacketTitle =
            !isJacket.value || jacketTitleController.text.trim().isNotEmpty;
        isStep1Valid.value =
            hasTitle &&
            hasEnglishTitle &&
            hasMedia &&
            hasImageCredit &&
            hasJacketTitle;
        break;

      case 1: // Step 2 validation
        try {
          String content = '';

          // In edit mode, check editingNewsContent first, then HTML editor
          if (isEditing.value && editingNewsContent.value.isNotEmpty) {
            content = editingNewsContent.value;
          } else {
            // Try to get content from HTML editor
            try {
              content = await htmlEditorController.getText().timeout(
                const Duration(milliseconds: 500),
              );
            } catch (e) {
              // If HTML editor fails, fallback to editingNewsContent
              content = editingNewsContent.value;
            }
          }

          final plainText = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          isStep2Valid.value = plainText.isNotEmpty;
        } catch (e) {
          // Final fallback - check if we have any content in editingNewsContent
          final fallbackContent = editingNewsContent.value
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          isStep2Valid.value = fallbackContent.isNotEmpty;
        }
        break;

      case 2: // Step 3 validation
        if (GlobalVariables.roleID == '7') {
          isStep3Valid.value = true;
          break;
        }
        final bool hasMainCategory = selectedCategory.value != null;
        final bool requiresSubCategory = hasMainCategory && hasSubCategories;
        final bool hasSubCategory = selectedSubCategory.value != null;
        isStep3Valid.value =
            hasMainCategory && (!requiresSubCategory || hasSubCategory);
        break;
    }
  }

  // Change Tracking Methods
  void _setupChangeTrackingListeners() {
    // Text controllers
    titleController.addListener(_checkForChanges);
    englishTitleController.addListener(_checkForChanges);
    imageCreditController.addListener(_checkForChanges);
    tagsController.addListener(_checkForChanges);
    videoStartController.addListener(_checkForChanges);
    jacketTitleController.addListener(_checkForChanges);
    voiceOverTextController.addListener(_checkForChanges);

    // HTML editor changes will be handled via callbacks

    // Observable values - use ever() to listen to changes
    ever(selectedCategory, (_) => _checkForChanges());
    ever(selectedSubCategory, (_) => _checkForChanges());
    ever(selectedEventCategory, (_) => _checkForChanges());
    ever(selectedNewsSource, (_) => _checkForChanges());
    ever(selectedMedia, (_) => _checkForChanges());
    ever(isBreakingNews, (_) => _checkForChanges());
    ever(sendNotification, (_) => _checkForChanges());
    ever(isLiveNews, (_) => _checkForChanges());
    ever(selectedStatus, (_) => _checkForChanges());
    ever(hideVideoTitle, (_) => _checkForChanges());
    ever(isVerticalVideo, (_) => _checkForChanges());
    ever(isJacket, (val) {
      if (!val) {
        selectedVoice.value = null;
        voiceOverTextController.clear();
      }
      validateStep(0);
      _checkForChanges();
    });
    ever(selectedVoice, (_) => _checkForChanges());
    ever(isVideoHorizontal, (_) => _checkForChanges());
    ever(scheduledDateTime, (_) => _checkForChanges());
    ever(selectedTags, (_) => _checkForChanges());
    ever(selectedRelatedNews, (_) => _checkForChanges());
    ever(liveNewsItems, (_) => _checkForChanges());
  }

  void _captureInitialFormState() {
    _initialFormState = _getCurrentFormState();
    hasUnsavedChanges.value = false;
    print('🔄 Initial form state captured');
    print('🔄 Title: "${_initialFormState['title']}"');
    print('🔄 English Title: "${_initialFormState['englishTitle']}"');
  }

  Map<String, dynamic> _getCurrentFormState() {
    return {
      'title': titleController.text,
      'englishTitle': englishTitleController.text,
      'imageCredit': imageCreditController.text,
      'tags': tagsController.text,
      'content': 'HTML content', // Will be handled differently
      'selectedCategory': selectedCategory.value?.id,
      'selectedSubCategory': selectedSubCategory.value?.id,
      'selectedEventCategory': selectedEventCategory.value?.id,
      'selectedNewsSource': selectedNewsSource.value?.id,
      'selectedMedia': selectedMedia.value?.id,
      'isBreakingNews': isBreakingNews.value,
      'sendNotification': sendNotification.value,
      'isLiveNews': isLiveNews.value,
      'selectedStatus': selectedStatus.value,
      'hideVideoTitle': hideVideoTitle.value,
      'isVerticalVideo': isVerticalVideo.value,
      'videoStart': videoStartController.text,
      'isJacket': isJacket.value,
      'jacketTitle': jacketTitleController.text,
      'selectedVoice': selectedVoice.value?.voiceId,
      'voiceOverText': voiceOverTextController.text,
      'scheduledDateTime': scheduledDateTime.value?.millisecondsSinceEpoch,
      'selectedTags': selectedTags.toList(),
      'selectedRelatedNews': selectedRelatedNews.map((e) => e.id).toList(),
      'liveNewsItems': liveNewsItems
          .map(
            (e) => {'title': e.titleController.text, 'content': 'HTML content'},
          )
          .toList(),
    };
  }

  void _checkForChanges() {
    if (_initialFormState.isEmpty) {
      print('🔄 Change check skipped - initial state not captured yet');
      return; // Not initialized yet
    }

    final currentState = _getCurrentFormState();
    final hasChanges = !_areStatesEqual(_initialFormState, currentState);

    if (hasChanges != hasUnsavedChanges.value) {
      print(
        '🔄 Change detected! hasUnsavedChanges: ${hasUnsavedChanges.value} -> $hasChanges',
      );
      hasUnsavedChanges.value = hasChanges;
    }
  }

  bool _areStatesEqual(
    Map<String, dynamic> state1,
    Map<String, dynamic> state2,
  ) {
    // Compare all fields
    for (final key in state1.keys) {
      final value1 = state1[key];
      final value2 = state2[key];

      if (value1 is List && value2 is List) {
        if (value1.length != value2.length) return false;
        for (int i = 0; i < value1.length; i++) {
          if (value1[i] != value2[i]) return false;
        }
      } else if (value1 != value2) {
        return false;
      }
    }
    return true;
  }

  void _setupEditMode(NewsModel news) {
    isEditing.value = true;
    newsId.value = news.id.toString();

    // Show loader and fetch complete news details from API
    isLoading.value = true;
    _fetchCompleteNewsDetails(news.id);
  }

  // Back Navigation Confirmation
  Future<bool> handleBackNavigation() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Discard Changes?'.tr),
        content: Text(
          hasUnsavedChanges.value
              ? 'You have unsaved changes. Are you sure you want to leave this screen? Your changes will be lost.'
                    .tr
              : 'Are you sure you want to leave this screen?'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('🔙 User chose Stay');
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!, false);
              } else {
                Get.overlayContext != null
                    ? Navigator.pop(Get.overlayContext!, false)
                    : Get.back(result: false);
              }
            },
            child: Text('Stay'.tr),
          ),
          TextButton(
            onPressed: () {
              print('🔙 User chose Leave');
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!, true);
              } else {
                Get.overlayContext != null
                    ? Navigator.pop(Get.overlayContext!, true)
                    : Get.back(result: true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Leave'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    print('🔙 Dialog result: $result');
    return result ?? false; // Default to false if dialog is dismissed
  }

  // Test method to manually trigger dialog
  // Future<void> testBackNavigationDialog() async {
  //   print('🔙 Testing back navigation dialog manually');
  //   final shouldNavigate = await handleBackNavigation();
  //   if (shouldNavigate) {
  //     print('🔙 Test: User chose to leave');
  //     Get.offAllNamed('/dashboard');
  //   } else {
  //     print('🔙 Test: User chose to stay');
  //   }
  // }

  Future<void> _fetchCompleteNewsDetails(int newsId) async {
    try {
      isLoading.value = true;

      // Make API call to get complete news details
      final response = await _fetchNewsDetailsFromAPI(newsId);

      if (response != null) {
        await _populateFormWithCompleteData(response);
      }
    } catch (e) {
      print('Error fetching complete news details: $e');
      Get.snackbar(
        'Warning'.tr,
        'Could not load all news details. Some fields may be empty.'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> _fetchNewsDetailsFromAPI(int newsId) async {
    try {
      print('Calling edit news API for news ID: $newsId');
      final requestBody = jsonEncode({'news_id': newsId.toString()});
      print('HTTP POST request: ${ApiConstants.editNewsUrl}');
      print('Request Body: $requestBody');

      // Call the edit news API
      final response = await http.post(
        Uri.parse(ApiConstants.editNewsUrl),
        headers: ApiConstants.defaultHeaders,
        body: requestBody,
      );

      print('Edit news API response status: ${response.statusCode}');
      print('Edit news API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Edit news API response: $responseData');

        if (responseData['success'] == true) {
          return responseData['data'];
        }
      }
    } catch (e) {
      print('Error fetching news details from API: $e');
    }
    return null;
  }

  Future<void> _populateFormWithCompleteData(
    Map<String, dynamic> apiData,
  ) async {
    try {
      // Extract news data from the API response
      final newsData = apiData['news'] as Map<String, dynamic>?;
      if (newsData == null) {
        print('❌ No news data found in API response');
        return;
      }

      // Populate basic fields
      if (newsData['title'] != null) {
        titleController.text = newsData['title'];
      }

      if (newsData['englishTitle'] != null) {
        englishTitleController.text = newsData['englishTitle'];
      }

      if (newsData['img_credit_txt'] != null) {
        imageCreditController.text = newsData['img_credit_txt'];
      }

      // Handle tags - API returns as comma-separated string
      if (newsData['tags'] != null && newsData['tags'].toString().isNotEmpty) {
        final tagsString = newsData['tags'].toString();
        selectedTags.value = tagsString
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        tagsController.text = tagsString;
      }

      // Populate content
      if (newsData['description'] != null) {
        print('📝 Setting content from API: ${newsData['description']}');

        // Set content in HTML editor
        String originalContent = newsData['description'];
        await _setHtmlEditorContent(originalContent);
      }

      // Populate settings
      if (newsData['is_breaking'] != null) {
        final isBreakingValue = newsData['is_breaking'].toString() == '1';
        isBreakingNews.value = isBreakingValue;
        print(
          'Setting is_breaking: ${newsData['is_breaking']} -> $isBreakingValue',
        );
      }

      if (newsData['is_live_news'] != null) {
        final isLiveValue = newsData['is_live_news'].toString() == '1';
        isLiveNews.value = isLiveValue;
        print(
          'Setting is_live_news: ${newsData['is_live_news']} -> $isLiveValue',
        );
      }

      if (newsData['notification'] != null) {
        final notificationValue = newsData['notification'].toString() == '1';
        sendNotification.value = notificationValue;
        print(
          'Setting notification: ${newsData['notification']} -> $notificationValue',
        );
      }

      if (newsData['hide_title'] != null) {
        hideVideoTitle.value = newsData['hide_title'].toString() == '1';
      }

      if (newsData['is_vertical_video'] != null) {
        isVerticalVideo.value = newsData['is_vertical_video'].toString() == '9';
      }

      if (newsData['is_jacket'] != null) {
        isJacket.value = newsData['is_jacket'].toString() == '1';
      }

      if (newsData['video_start'] != null) {
        videoStartController.text = newsData['video_start'].toString();
      }

      if (newsData['jacket_title'] != null) {
        jacketTitleController.text = newsData['jacket_title'].toString();
      }

      if (newsData['voice_id'] != null || newsData['voiceId'] != null) {
        final vId = (newsData['voice_id'] ?? newsData['voiceId']).toString();
        _pendingVoiceId = vId;
        try {
          selectedVoice.value = availableVoices.firstWhere(
            (v) => v.voiceId == vId,
          );
        } catch (_) {
          if (vId.isNotEmpty) {
            selectedVoice.value = VoiceModel(voiceId: vId, name: vId);
          }
        }
      }

      if (newsData['voiceovertext'] != null) {
        voiceOverTextController.text = newsData['voiceovertext'].toString();
      }

      // Handle status - reverse map from API to UI
      if (newsData['status'] != null) {
        selectedStatus.value = _reverseMapStatusValue(newsData['status']);
      }

      // Handle is_home value from edit data
      if (newsData['is_home'] != null) {
        _isHomeValue = newsData['is_home'].toString();
      }

      // Handle schedule date
      if (newsData['scheduleDate'] != null &&
          newsData['scheduleDate'].toString().isNotEmpty) {
        try {
          scheduledDateTime.value = DateTime.parse(newsData['scheduleDate']);
        } catch (e) {
          print('Error parsing schedule date: $e');
        }
      }

      // Handle media (featureImage, videoURL)
      _populateMediaData(newsData);

      // Handle categories
      if (apiData['categoryIds'] != null && apiData['categoryIds'] is List) {
        print('Found categoryIds in API response: ${apiData['categoryIds']}');
        final categoryIds = apiData['categoryIds'] as List;

        // Populate main category (first ID)
        if (categoryIds.isNotEmpty) {
          _populateCategoryData([categoryIds.first]);
        }

        // Populate subcategory (second ID if exists)
        if (categoryIds.length > 1) {
          final subcategoryId = categoryIds[1];
          print('Found subcategory ID in categoryIds: $subcategoryId');
          _populateSubCategoryData([subcategoryId]);
        }
      } else {
        print('No categoryIds found in API response');
        print('Available keys in API response: ${apiData.keys.toList()}');
      }

      // Handle event categories - check if event category info is in news data
      if (newsData['eventCat'] != null &&
          newsData['eventCat'].toString().isNotEmpty) {
        final eventCatId = int.tryParse(newsData['eventCat'].toString());
        if (eventCatId != null && eventCatId > 0) {
          print('Found event category ID in news data: $eventCatId');
          _populateEventCategoryData([eventCatId]);
        }
      }

      if (newsData['newssource'] != null &&
          newsData['newssource'].toString().isNotEmpty) {
        final newsSourceId = int.tryParse(newsData['newssource'].toString());
        if (newsSourceId != null && newsSourceId > 0) {
          print('Found newssource ID in news data: $newsSourceId');
          _populateNewsSourceData([newsSourceId]);
        }
      }

      // Populate live news data if available (support multiple possible keys)
      final dynamic liveNewsRaw =
          apiData['livenews'] ?? apiData['live_news'] ?? apiData['liveNews'];
      if (liveNewsRaw is List) {
        _populateLiveNewsData(liveNewsRaw);
      }

      // Populate related news if available (support multiple possible keys)
      final dynamic relatedNewsRaw =
          apiData['relatedNews'] ??
          apiData['relatednews'] ??
          apiData['related_news'];
      if (relatedNewsRaw is List) {
        _populateRelatedNewsData(relatedNewsRaw);
      }

      // Handle related news IDs
      if (newsData['relatednewsid'] != null &&
          newsData['relatednewsid'].toString().isNotEmpty) {
        // This will be used to set the selected related news
        _setRelatedNewsFromIds(newsData['relatednewsid'].toString());
      }

      // Trigger all validations after populating data
      _triggerAllValidations();

      print('Successfully populated form with complete news data');
    } catch (e) {
      print('Error populating form with complete data: $e');
    }
  }

  void _triggerAllValidations() {
    // Use a small delay to ensure all UI updates are complete
    Future.delayed(const Duration(milliseconds: 100), () async {
      // Trigger all step validations to update validation states
      await validateStep();

      // Capture initial state after edit mode is populated
      if (isEditing.value) {
        _captureInitialFormState();
      }

      print(
        'All validations triggered - Step1: ${isStep1Valid.value}, Step2: ${isStep2Valid.value}, Step3: ${isStep3Valid.value}',
      );
    });
  }

  void _populateMediaData(Map<String, dynamic> newsData) {
    try {
      // Check for video URL first (priority over image)
      if (newsData['videoURL'] != null &&
          newsData['videoURL'].toString().isNotEmpty) {
        final videoUrl = newsData['videoURL'].toString();
        oldVideoUrl.value = videoUrl; // Save old video URL
        final fileName = videoUrl.split('/').last;

        // Ensure the filename has a video extension for proper detection
        String videoFileName = fileName;
        if (!fileName.toLowerCase().contains('.mp4') &&
            !fileName.toLowerCase().contains('.mov') &&
            !fileName.toLowerCase().contains('.avi') &&
            !fileName.toLowerCase().contains('video')) {
          // Add .mp4 extension if no video extension is found
          videoFileName = fileName.contains('.') ? fileName : '$fileName.mp4';
        }

        // Create a mock MediaModel for the selected video
        selectedMedia.value = MediaModel(
          id: 0,
          userID: 0,
          photos: videoFileName, // Use the corrected filename
          fullpath: videoUrl,
          createdAt: '',
          updatedAt: '',
        );
        // Set content type to Video
        selectedContentType.value = 'Video';
        print(
          'Populated video media: $videoUrl - Content type set to Video - fileName: $videoFileName',
        );
      }
      // Handle feature image if no video URL
      else if (newsData['featureImage'] != null &&
          newsData['featureImage'].toString().isNotEmpty) {
        final imageUrl = newsData['featureImage'].toString();
        final fileName = imageUrl.split('/').last;

        // Ensure the filename has an image extension for proper detection
        String imageFileName = fileName;
        if (!fileName.toLowerCase().contains('.jpg') &&
            !fileName.toLowerCase().contains('.jpeg') &&
            !fileName.toLowerCase().contains('.png') &&
            !fileName.toLowerCase().contains('.webp') &&
            !fileName.toLowerCase().contains('.gif')) {
          // Add .jpg extension if no image extension is found
          imageFileName = fileName.contains('.') ? fileName : '$fileName.jpg';
        }

        // Create a mock MediaModel for the selected image
        selectedMedia.value = MediaModel(
          id: 0,
          userID: 0,
          photos: imageFileName, // Use the corrected filename
          fullpath: imageUrl,
          createdAt: '',
          updatedAt: '',
        );
        // Set content type to Image
        selectedContentType.value = 'Image';
        print(
          'Populated image media: $imageUrl - Content type set to Image - fileName: $imageFileName',
        );
      }
    } catch (e) {
      print('Error populating media data: $e');
    }
  }

  void _populateCategoryData(List<dynamic> categoryIds) {
    try {
      if (categoryIds.isNotEmpty) {
        final categoryId = categoryIds.first;
        print('Trying to populate category with ID: $categoryId');
        print('Available categories count: ${allCategories.length}');

        // If categories are not loaded yet, wait for them
        if (allCategories.isEmpty) {
          print(
            'Categories not loaded yet, will retry after categories are loaded',
          );
          // Store the category ID to set later when categories are loaded
          _pendingCategoryId = categoryId;
          return;
        }

        // Find the category by ID
        CategoryModel? category;
        try {
          category = allCategories.firstWhere((cat) => cat.id == categoryId);
          selectedCategory.value = category;
          print('Successfully set category: ${category.title}');
          validateStep(2);
          _pendingCategoryId = null; // Clear pending ID
        } catch (e) {
          print(
            'Category with ID $categoryId not found in available categories',
          );
          // Print available category IDs for debugging
          print(
            'Available category IDs: ${allCategories.map((c) => c.id).toList()}',
          );
        }
      }
    } catch (e) {
      print('Error populating category data: $e');
    }
  }

  void _populateSubCategoryData(List<dynamic> subcategoryIds) {
    try {
      if (subcategoryIds.isNotEmpty) {
        final subcategoryId = subcategoryIds.first;
        print('Trying to populate subcategory with ID: $subcategoryId');
        print(
          'Available subcategories count: ${availableSubCategories.length}',
        );

        // If subcategories are not loaded yet, wait for them
        if (availableSubCategories.isEmpty) {
          print(
            'Subcategories not loaded yet, will retry after categories are loaded',
          );
          // Store the subcategory ID to set later when categories are loaded
          _pendingSubCategoryId = subcategoryId;
          return;
        }

        // Find the subcategory by ID
        CategoryModel? subcategory;
        try {
          subcategory = availableSubCategories.firstWhere(
            (subcat) => subcat.id == subcategoryId,
          );
          selectedSubCategory.value = subcategory;
          print('Successfully set subcategory: ${subcategory.title}');
          _pendingSubCategoryId = null; // Clear pending ID
        } catch (e) {
          print(
            'Subcategory with ID $subcategoryId not found in available subcategories',
          );
          // Print available subcategory IDs for debugging
          print(
            'Available subcategory IDs: ${availableSubCategories.map((c) => c.id).toList()}',
          );
        }
      }
    } catch (e) {
      print('Error populating subcategory data: $e');
    }
  }

  void _populateEventCategoryData(List<dynamic> eventCategoryIds) {
    try {
      if (eventCategoryIds.isNotEmpty) {
        final eventCategoryId = eventCategoryIds.first;
        print('Trying to populate event category with ID: $eventCategoryId');
        print(
          'Available event categories count: ${availableEventCategories.length}',
        );

        // If event categories are not loaded yet, wait for them
        if (availableEventCategories.isEmpty) {
          print(
            'Event categories not loaded yet, will retry after categories are loaded',
          );
          // Store the event category ID to set later when categories are loaded
          _pendingEventCategoryId = eventCategoryId;
          return;
        }

        // Find the event category by ID
        CategoryModel? eventCategory;
        try {
          eventCategory = availableEventCategories.firstWhere(
            (eventCat) => eventCat.id == eventCategoryId,
          );
          selectedEventCategory.value = eventCategory;
          print('Successfully set event category: ${eventCategory.title}');
          _pendingEventCategoryId = null; // Clear pending ID
        } catch (e) {
          print(
            'Event category with ID $eventCategoryId not found in available event categories',
          );
          // Print available event category IDs for debugging
          print(
            'Available event category IDs: ${availableEventCategories.map((c) => c.id).toList()}',
          );
        }
      }
    } catch (e) {
      print('Error populating event category data: $e');
    }
  }

  void _setRelatedNewsFromIds(String relatedNewsIds) {
    try {
      if (relatedNewsIds.isNotEmpty) {
        // Store the related news IDs for later use when related news data is populated
        // This will be handled in _populateRelatedNewsData
      }
    } catch (e) {
      print('Error setting related news from IDs: $e');
    }
  }

  String _getIsHomeValue() {
    return _isHomeValue;
  }

  String _mapStatusValue() {
    // Map UI status to API status
    switch (selectedStatus.value) {
      case 'Publish':
        return 'Active';
      case 'Draft':
        return 'Inactive';
      case 'Schedule':
        return 'Schedule';
      default:
        return selectedStatus.value; // Return as-is if no mapping needed
    }
  }

  String _reverseMapStatusValue(String apiStatus) {
    // Map API status back to UI status
    switch (apiStatus) {
      case 'Active':
        return 'Publish';
      case 'Inactive':
        return 'Draft';
      case 'Schedule':
        return 'Schedule';
      default:
        return apiStatus; // Return as-is if no mapping needed
    }
  }

  // All old Quill methods removed - using HTML editor now

  void _populateLiveNewsData(List<dynamic> liveNewsData) {
    try {
      // Clear existing live news items without auto-adding a blank one
      for (var item in liveNewsItems) {
        item.dispose();
      }
      liveNewsItems.clear();

      // Add live news items from data - API structure may vary: livetitle/livedesc or title/description
      for (final item in liveNewsData) {
        if (item is Map<String, dynamic>) {
          final title = (item['livetitle'] ?? item['title'] ?? '').toString();
          final content = (item['livedesc'] ?? item['description'] ?? '')
              .toString();
          final liveNewsItem = LiveNewsItem(title: title, content: content);
          liveNewsItems.add(liveNewsItem);
        }
      }

      // Ensure at least one item exists; do not override isLiveNews flag from API
      if (liveNewsItems.isEmpty) {
        addLiveNewsItem();
      }
    } catch (e) {
      print('Error populating live news data: $e');
    }
  }

  void _populateRelatedNewsData(List<dynamic> relatedNewsData) {
    try {
      selectedRelatedNews.clear();

      for (final item in relatedNewsData) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] ?? item['news_id'] ?? item['newsid'] ?? 0;
          final title =
              item['title'] ??
              item['news_title'] ??
              item['englishTitle'] ??
              item['name'] ??
              '';
          final relatedNews = RelatedNewsItem(
            id: (id is String) ? int.tryParse(id) ?? 0 : (id as int),
            title: title.toString(),
          );
          // Avoid duplicates
          if (!selectedRelatedNews.any((e) => e.id == relatedNews.id)) {
            selectedRelatedNews.add(relatedNews);
          }
        }
      }
    } catch (e) {
      print('Error populating related news data: $e');
    }
  }

  // Google Tags Methods
  void onTagsChanged(List<String> tags) {
    selectedTags.value = tags;
    tagsController.text = tags.join(', ');
  }

  List<String> getInitialTags() {
    if (selectedTags.isNotEmpty) {
      return selectedTags.toList();
    }

    // Parse from existing tags controller if available
    final tagsText = tagsController.text.trim();
    if (tagsText.isNotEmpty) {
      return tagsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  Future<void> loadFilterData() async {
    try {
      isLoadingCategories.value = true;
      final filterData = await _filterService.getFilterData();

      // Store all categories for reference
      allCategories.assignAll(filterData.categories);

      // Separate main categories (parentID: 0) and subcategories (parentID != 0)
      final mainCategories = filterData.categories
          .where((category) => category.parentID == 0)
          .toList();
      final subCategories = filterData.categories
          .where((category) => category.parentID != 0)
          .toList();

      availableCategories.assignAll(mainCategories);
      availableSubCategories.assignAll(subCategories);
      availableEventCategories.assignAll(filterData.eventCategories);
      availableNewsSources.assignAll(filterData.newsSources);
      availableVoices.assignAll(filterData.voiceIdarr);

      if (_pendingVoiceId != null && _pendingVoiceId!.isNotEmpty) {
        try {
          selectedVoice.value = availableVoices.firstWhere(
            (v) => v.voiceId == _pendingVoiceId,
          );
        } catch (_) {}
      }

      if (!isEditing.value &&
          selectedNewsSource.value == null &&
          availableNewsSources.isNotEmpty) {
        String roleID = GlobalVariables.roleID.toString();
        try {
          if (roleID == '3') {
            selectedNewsSource.value = availableNewsSources.firstWhere(
              (s) => s.title.toLowerCase() == 'direct' || s.id == 2,
            );
          } else if (roleID == '4') {
            selectedNewsSource.value = availableNewsSources.firstWhere(
              (s) => s.title.toLowerCase() == 'tv' || s.id == 3,
            );
          } else if (roleID == '6' || roleID == '7') {
            selectedNewsSource.value = availableNewsSources.firstWhere(
              (s) => s.title.toLowerCase() == 'reporter' || s.id == 4,
            );
          } else {
            selectedNewsSource.value = availableNewsSources.firstWhere(
              (s) => s.id == 1,
            );
          }
        } catch (e) {
          selectedNewsSource.value = availableNewsSources.first;
        }
      }

      print(
        'Loaded ${mainCategories.length} main categories and ${subCategories.length} subcategories',
      );

      // Check if there are pending category IDs to set
      if (_pendingCategoryId != null) {
        print('Setting pending category ID: $_pendingCategoryId');
        _populateCategoryData([_pendingCategoryId!]);
      }

      if (_pendingSubCategoryId != null) {
        print('Setting pending subcategory ID: $_pendingSubCategoryId');
        _populateSubCategoryData([_pendingSubCategoryId!]);
      }

      if (_pendingEventCategoryId != null) {
        print('Setting pending event category ID: $_pendingEventCategoryId');
        _populateEventCategoryData([_pendingEventCategoryId!]);
      }

      if (_pendingNewsSourceId != null) {
        print('Setting pending news source ID: $_pendingNewsSourceId');
        _populateNewsSourceData([_pendingNewsSourceId!]);
      }
    } catch (e) {
      print('Error loading filter data: $e');
      Get.snackbar(
        'Error'.tr,
        'Failed to load categories'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: AppConstants.mediumSnackbarDuration,
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void nextStep() {
    if (currentStep.value < stepTitles.length - 1) {
      if (_canProceedToNextStep()) {
        currentStep.value++;
        if (currentStep.value == 2) {
          validateStep(2);
        }
      } else {
        _showStepValidationError();
      }
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < stepTitles.length) {
      currentStep.value = step;
    }
  }

  bool _canProceedToNextStep() {
    switch (currentStep.value) {
      case 0:
        return isStep1Valid.value;
      case 1:
        return isStep2Valid.value;
      case 2:
        return isStep3Valid.value;
      default:
        return true;
    }
  }

  void _showStepValidationError() {
    final Map<int, String> stepMessages = {
      0: _getStep1ValidationMessage(),
      1: 'add_content'.tr,
      2: _getStep3ValidationMessage(),
    };

    final message =
        stepMessages[currentStep.value] ?? 'fill_required_fields'.tr;
    print('Validation Error: $message');

    // Dismiss keyboard before showing snackbar to prevent it from being hidden
    if (Get.context != null) {
      FocusScope.of(Get.context!).unfocus();
    }

    // Show using GetX
    Get.snackbar(
      'validation_error'.tr,
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: AppConstants.mediumSnackbarDuration,
      snackPosition: SnackPosition.BOTTOM,
    );

    // Fallback using ScaffoldMessenger just in case Get.snackbar fails or is hidden
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getStep1ValidationMessage() {
    if (titleController.text.trim().isEmpty) {
      return 'Please enter news title'.tr;
    } else if (englishTitleController.text.trim().isEmpty) {
      return 'Please enter English title'.tr;
    } else if (selectedMedia.value == null) {
      return 'Please select media (image or video)'.tr;
    } else if (selectedMedia.value != null &&
        imageCreditController.text.trim().isEmpty) {
      return 'Please enter image credit text'.tr;
    } else if (isJacket.value && jacketTitleController.text.trim().isEmpty) {
      return 'Please enter jacket title'.tr;
    }
    return 'fill_required_fields'.tr;
  }

  String _getStep3ValidationMessage() {
    if (GlobalVariables.roleID == '7') return '';
    if (selectedCategory.value == null) {
      return 'select_category'.tr;
    } else if (hasSubCategories && selectedSubCategory.value == null) {
      return 'Please select sub category'.tr;
    }
    return 'fill_required_fields'.tr;
  }

  Future<void> removeSelectedFile(int index) async {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
      selectedMedia.value = null; // Clear selected media when file is removed
      validateStep(0); // Trigger validation update
    }
  }

  void setSelectedMedia(MediaModel media) {
    selectedMedia.value = media;
    selectedMedia.refresh(); // Force UI update
    selectedFiles.clear();

    // Set content type based on media type
    if (media.isVideo) {
      selectedContentType.value = 'Video';
      print('Selected media is video - Content type set to Video');
    } else {
      selectedContentType.value = 'Image';
      print('Selected media is image - Content type set to Image');
    }

    // Create a mock PlatformFile for compatibility with existing code
    final mockFile = PlatformFile(
      name: media.photos,
      size: 0, // We don't have size from MediaModel
      path: media.fullpath,
    );
    selectedFiles.add(mockFile);

    // Trigger validation update
    validateStep(0);

    // Reset jacket settings when new media is selected
    isJacket.value = false;
    jacketTitleController.clear();
    selectedVoice.value = null;
    voiceOverTextController.clear();

    Get.snackbar(
      'Success'.tr,
      'Media selected successfully'.tr,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: AppConstants.shortSnackbarDuration,
    );
  }

  void clearSelectedMedia() {
    selectedMedia.value = null;
    selectedFiles.clear();
    imageCreditController.clear(); // Clear image credit text
    hideVideoTitle.value = false; // Reset video settings
    isVerticalVideo.value = false; // Reset video settings
    videoStartController.text = '1'; // Reset video start
    isJacket.value = false; // Reset jacket settings
    jacketTitleController.clear(); // Clear jacket title
    selectedVoice.value = null;
    voiceOverTextController.clear();
    validateStep(0); // Trigger validation update
  }

  void _populateNewsSourceData(List<dynamic> sourceIds) {
    try {
      if (sourceIds.isNotEmpty) {
        final sourceId = sourceIds.first;
        if (availableNewsSources.isEmpty) {
          _pendingNewsSourceId = sourceId;
          return;
        }
        NewsSourceModel? source;
        try {
          source = availableNewsSources.firstWhere((s) => s.id == sourceId);
          selectedNewsSource.value = source;
          _pendingNewsSourceId = null;
        } catch (e) {
          print('NewsSource with ID $sourceId not found');
        }
      }
    } catch (e) {
      print('Error populating news source data: $e');
    }
  }

  void updateNewsSource(NewsSourceModel? source) {
    selectedNewsSource.value = source;
    _checkForChanges();
  }

  void updateCategory(CategoryModel? category) {
    selectedCategory.value = category;
    // Reset sub-category when main category changes
    selectedSubCategory.value = null;
    // Ensure mutual exclusivity with event category
    if (category != null && selectedEventCategory.value?.id == category.id) {
      selectedEventCategory.value = null;
    }
    validateStep(2);
  }

  /// Get subcategories filtered by the selected main category
  List<CategoryModel> getFilteredSubCategories() {
    if (selectedCategory.value == null) {
      return [];
    }

    return availableSubCategories.where((subCategory) {
      return subCategory.parentID == selectedCategory.value!.id;
    }).toList();
  }

  /// Get all subcategories for a specific main category ID
  List<CategoryModel> getSubCategoriesForMainCategory(int mainCategoryId) {
    return availableSubCategories.where((subCategory) {
      return subCategory.parentID == mainCategoryId;
    }).toList();
  }

  /// Check if selected main category has subcategories
  bool get hasSubCategories {
    if (selectedCategory.value == null) return false;
    return getFilteredSubCategories().isNotEmpty;
  }

  /// Get main category by ID
  CategoryModel? getMainCategoryById(int categoryId) {
    try {
      return availableCategories.firstWhere(
        (category) => category.id == categoryId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get subcategory by ID
  CategoryModel? getSubCategoryById(int subCategoryId) {
    try {
      return availableSubCategories.firstWhere(
        (subCategory) => subCategory.id == subCategoryId,
      );
    } catch (e) {
      return null;
    }
  }

  void updateSubCategory(CategoryModel? subCategory) {
    selectedSubCategory.value = subCategory;
    // Ensure mutual exclusivity with event category
    if (subCategory != null &&
        selectedEventCategory.value?.id == subCategory.id) {
      selectedEventCategory.value = null;
    }
  }

  // Live News Management
  void addLiveNewsItem() {
    liveNewsItems.add(LiveNewsItem());
  }

  void removeLiveNewsItem(String id) {
    final index = liveNewsItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      liveNewsItems[index].dispose();
      liveNewsItems.removeAt(index);
    }
  }

  void clearAllLiveNewsItems() {
    for (var item in liveNewsItems) {
      item.dispose();
    }
    liveNewsItems.clear();
    // Add one empty item
    addLiveNewsItem();
  }

  void updateEventCategory(CategoryModel? eventCategory) {
    selectedEventCategory.value = eventCategory;
    // Ensure mutual exclusivity with main and sub categories
    if (eventCategory != null) {
      if (selectedCategory.value?.id == eventCategory.id) {
        selectedCategory.value = null;
        selectedSubCategory.value = null;
      }
      if (selectedSubCategory.value?.id == eventCategory.id) {
        selectedSubCategory.value = null;
      }
    }
  }

  Future<String> getContentAsHtml() async {
    try {
      String htmlContent = '';

      // In edit mode, prioritize editingNewsContent, then try HTML editor
      if (isEditing.value && editingNewsContent.value.isNotEmpty) {
        htmlContent = editingNewsContent.value;
        print(
          'getContentAsHtml (edit mode): Using editingNewsContent - ${htmlContent.length} chars',
        );
      } else {
        // Try to get content from HTML editor
        try {
          htmlContent = await htmlEditorController.getText().timeout(
            const Duration(milliseconds: 500),
          );
          print(
            'getContentAsHtml (create mode): Using htmlEditor - ${htmlContent.length} chars',
          );
        } catch (e) {
          // If HTML editor fails, fallback to editingNewsContent
          htmlContent = editingNewsContent.value;
          print(
            'getContentAsHtml (fallback): Using editingNewsContent - ${htmlContent.length} chars',
          );
        }
      }

      print('getContentAsHtml final: ${htmlContent.length} chars');
      return htmlContent;
    } catch (e) {
      print('Error getting HTML content: $e');
      // Final fallback - return editingNewsContent as-is
      return editingNewsContent.value;
    }
  }

  // Removed unused P to BR conversion method - HTML editor handles content directly

  // Old Quill P tag content setting method removed - using HTML editor now

  // Old paragraph extraction method removed - HTML editor handles content directly

  /// Set content in HTML editor with proper loading handling
  Future<void> _setHtmlEditorContent(String htmlContent) async {
    try {
      print(
        '📝 Setting HTML editor content: ${htmlContent.substring(0, htmlContent.length > 100 ? 100 : htmlContent.length)}...',
      );

      // Store content for widget to use as initial content
      editingNewsContent.value = htmlContent;

      if (htmlContent.isEmpty) {
        htmlEditorController.clear();
      } else {
        // Try to set content in controller, but don't fail if it's not ready
        // The widget will use editingNewsContent as fallback
        // Run in background without blocking the UI
        _setHtmlContentWithRetry(htmlContent).catchError((e) {
          print('🔄 Background HTML content setting failed: $e');
          // This is expected and handled gracefully
        });
      }

      // Trigger validation
      validateStep(1);

      // Update the key to force widget rebuild
      contentUpdateKey.value++;
    } catch (e) {
      print('❌ Error setting HTML editor content: $e');
      // Don't clear the controller, just store the content for the widget
      editingNewsContent.value = htmlContent;
      contentUpdateKey.value++;
    }
  }

  /// Set HTML content with retry logic to handle loading delays
  Future<void> _setHtmlContentWithRetry(
    String content, {
    int maxRetries = 8,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        // Wait progressively longer before each attempt (start with longer initial delay)
        await Future.delayed(Duration(milliseconds: 1000 + (i * 750)));

        // Check if the editor is ready by trying to get text first
        try {
          final testContent = await htmlEditorController.getText().timeout(
            const Duration(milliseconds: 500),
          );
          // If we can get text, the editor is ready
          print(
            '🔄 HTML editor ready on attempt ${i + 1}, current content length: ${testContent.length}',
          );
        } catch (e) {
          // Editor not ready yet, continue to next iteration
          if (i < maxRetries - 1) {
            print(
              '🔄 HTML editor not ready on attempt ${i + 1}, waiting longer... Error: ${e.toString().substring(0, 100)}',
            );
            continue;
          } else {
            print(
              '❌ HTML editor still not ready after $maxRetries attempts, giving up gracefully',
            );
            return; // Exit gracefully instead of throwing
          }
        }

        // Editor is ready, now set the content
        htmlEditorController.setText(content);
        print('✅ Successfully set HTML content on attempt ${i + 1}');
        return; // Success, exit the method
      } catch (e) {
        print(
          '⚠️ Attempt ${i + 1} failed to set HTML content: ${e.toString().substring(0, 100)}',
        );
        if (i < maxRetries - 1) {
          print('🔄 Retrying in ${1000 + (i * 750)}ms...');
        } else {
          print('❌ Failed to set HTML content after $maxRetries attempts');
          print(
            '❌ Content will be available when user opens the editor manually',
          );
          // Exit gracefully - content is already stored in editingNewsContent
        }
      }
    }
  }

  /// Get current logged-in user ID
  Future<String> _getCurrentUserId() async {
    try {
      final user = await StorageService.getUser();
      return user?.userID.toString() ?? '1'; // Fallback to '1' if no user found
    } catch (e) {
      print('Error getting current user ID: $e');
      return '1'; // Fallback to '1'
    }
  }

  Future<void> submitNews() async {
    if (!await _validateAllSteps()) {
      return;
    }

    // Validate scheduled date if status is 'Schedule'
    if (selectedStatus.value == 'Schedule' && scheduledDateTime.value == null) {
      Get.snackbar(
        'Validation Error'.tr,
        'Please select a schedule date and time'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: AppConstants.mediumSnackbarDuration,
      );
      return;
    }

    try {
      isSubmitting.value = true;

      // Get current user ID
      final currentUserId = await _getCurrentUserId();

      // Prepare form data
      final formData = dio.FormData();

      // Basic fields matching Postman request exactly
      formData.fields.addAll([
        MapEntry('title', titleController.text.trim()),
        MapEntry('englishTitle', englishTitleController.text.trim()),
        MapEntry('description', await getContentAsHtml()),
        MapEntry(
          'status',
          _mapStatusValue(),
        ), // Map status: Publish->Active, Draft->Inactive, Schedule->Schedule
        MapEntry('img_credit_txt', imageCreditController.text.trim()),

        MapEntry('userID', currentUserId), // Pass login user ID
        // MapEntry('usernews_userID', isEditing.value ? newsId.value : ''), // Pass news ID if editing

        // Category fields
        MapEntry(
          'catID',
          GlobalVariables.roleID == '7'
              ? '1'
              : (selectedCategory.value?.id.toString() ?? ''),
        ),
        MapEntry(
          'subcatID',
          GlobalVariables.roleID == '7'
              ? '15'
              : (selectedSubCategory.value?.id.toString() ?? ''),
        ),
        MapEntry('eventCat', selectedEventCategory.value?.id.toString() ?? ''),

        // Boolean flags
        MapEntry('is_breaking', isBreakingNews.value ? '1' : '0'),
        MapEntry('notification', sendNotification.value ? '1' : '0'),
        MapEntry('hide_title', '0'),
        MapEntry('is_live_news', isLiveNews.value ? '1' : '0'),
        MapEntry(
          'is_home',
          _getIsHomeValue(),
        ), // Get from edit data or default to 0
        MapEntry(
          'video_start',
          videoStartController.text.trim().isEmpty
              ? '1'
              : videoStartController.text.trim(),
        ),
        MapEntry('newssource', selectedNewsSource.value?.id.toString() ?? '1'),
        MapEntry('is_jacket', isJacket.value ? '1' : '0'),
        MapEntry(
          'jacket_title',
          isJacket.value ? jacketTitleController.text.trim() : '',
        ),
        MapEntry(
          'voice_id',
          isJacket.value ? (selectedVoice.value?.voiceId ?? '') : '',
        ),
        MapEntry(
          'voiceovertext',
          isJacket.value ? voiceOverTextController.text.trim() : '',
        ),
        MapEntry('is_video_horizontal', isVideoHorizontal.value ? '1' : '0'),

        // Tags and related news
        MapEntry('selectedTags[]', selectedTags.join(',')),
        MapEntry(
          'relatednewsid',
          selectedRelatedNews.isNotEmpty
              ? selectedRelatedNews.map((news) => news.id.toString()).join(',')
              : '',
        ), // Pass related news IDs if any
      ]);

      // Handle media type - if video pass videoURL, otherwise pass featureImage
      if (selectedMedia.value != null) {
        if (selectedMedia.value!.isVideo) {
          formData.fields.addAll([
            MapEntry('videoURL', selectedMedia.value!.fullpath),
            MapEntry('featureImage', ''),
          ]);
        } else {
          formData.fields.addAll([
            MapEntry('videoURL', ''),
            MapEntry('featureImage', selectedMedia.value!.fullpath),
          ]);
        }
      } else {
        formData.fields.addAll([
          MapEntry('videoURL', ''),
          MapEntry('featureImage', ''),
        ]);
      }

      // Add live news data if live news is enabled
      if (isLiveNews.value && liveNewsItems.isNotEmpty) {
        for (var item in liveNewsItems) {
          final title = item.titleController.text.trim();
          final content = (await item.getContentAsHtml()).trim();

          // Only add if both title and content are not empty
          if (title.isNotEmpty && content.isNotEmpty) {
            formData.fields.addAll([
              MapEntry('live_titles[]', title),
              MapEntry('live_contents[]', content),
            ]);
          }
        }
      }

      // Category fields are already handled above in the main fields section

      // Additional related news field (if API expects both relatednewsid and related_news)
      if (selectedRelatedNews.isNotEmpty) {
        final relatedNewsIds = selectedRelatedNews
            .map((news) => news.id.toString())
            .join(',');
        formData.fields.add(MapEntry('related_news', relatedNewsIds));
      }

      // Add scheduleDate if status is 'Schedule'
      if (selectedStatus.value == 'Schedule' &&
          scheduledDateTime.value != null) {
        formData.fields.add(
          MapEntry(
            'scheduleDate',
            scheduledDateTime.value != null
                ? DateFormat(
                    'yyyy-MM-ddTHH:mm',
                  ).format(scheduledDateTime.value!)
                : '',
          ),
        );
      }

      // Add files if any
      if (selectedFiles.isNotEmpty) {
        for (int i = 0; i < selectedFiles.length; i++) {
          final file = selectedFiles[i];
          if (file.bytes != null) {
            formData.files.add(
              MapEntry(
                'image',
                dio.MultipartFile.fromBytes(file.bytes!, filename: file.name),
              ),
            );
          }
        }
      }

      // API endpoint
      final endpoint = isEditing.value
          ? ApiConstants.updateNewsUrl
          : ApiConstants.storeNewsUrl;

      if (isEditing.value) {
        formData.fields.add(MapEntry('nid', newsId.value));

        if (oldVideoUrl.value.isNotEmpty) {
          if (selectedMedia.value != null &&
              selectedMedia.value!.fullpath == oldVideoUrl.value) {
            formData.fields.add(MapEntry('oldvideoURL', oldVideoUrl.value));
          } else {
            formData.fields.add(MapEntry('oldvideoURL', ''));
          }
        }
      }
      print(formData.fields);
      final dioClient = dio.Dio()
        ..interceptors.add(
          dio.LogInterceptor(
            request: true,
            requestHeader: true,
            requestBody: true,
            responseHeader: true,
            responseBody: true,
            error: true,
          ),
        );
      final response = await dioClient.post(endpoint, data: formData);

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          final message =
              responseData['message'] ??
              (isEditing.value
                  ? 'News updated successfully'
                  : 'News created successfully');

          Get.snackbar(
            'Success',
            message,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: AppConstants.shortSnackbarDuration,
          );

          // Reset change tracking since form was successfully submitted
          hasUnsavedChanges.value = false;

          // Refresh the news list in dashboard
          await _refreshDashboardNewsList();

          // Navigate back to home with news tab selected
          Get.offAllNamed('/home', arguments: {'menu': 'news'});
        } else {
          throw Exception(responseData['message'] ?? 'Failed to save news');
        }
      } else {
        throw Exception('Failed to save news');
      }
    } catch (e) {
      print('Error submitting news: $e');
      Get.snackbar(
        'error'.tr,
        'failed_to_save_news'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: AppConstants.mediumSnackbarDuration,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> _validateAllSteps() async {
    await validateStep();

    // Debug information for edit mode
    if (isEditing.value) {
      print(
        '🔍 Edit mode validation - Step1: ${isStep1Valid.value}, Step2: ${isStep2Valid.value}, Step3: ${isStep3Valid.value}',
      );
      print('🔍 Content length: ${editingNewsContent.value.length}');
    }

    if (!isStep1Valid.value) {
      goToStep(0);
      _showStepValidationError();
      return false;
    }

    if (!isStep2Valid.value) {
      goToStep(1);
      _showStepValidationError();
      return false;
    }

    if (!isStep3Valid.value) {
      goToStep(2);
      _showStepValidationError();
      return false;
    }

    return true;
  }

  Future<void> _refreshDashboardNewsList() async {
    try {
      // Try to get the dashboard controller if it exists
      if (Get.isRegistered<NewslistController>()) {
        final dashboardController = Get.find<NewslistController>();
        print('Refreshing dashboard news list after successful news operation');
        await dashboardController.refreshNews();
      } else {
        print('Dashboard controller not found, skipping news list refresh');
      }
    } catch (e) {
      print('Error refreshing dashboard news list: $e');
      // Don't throw error as this is not critical for the main operation
    }
  }

  void saveAsDraft() {
    submitNews();
  }

  void publishNews() {
    submitNews();
  }

  bool get canProceed => _canProceedToNextStep();
  bool get isLastStep => currentStep.value == stepTitles.length - 1;
  bool get isFirstStep => currentStep.value == 0;

  String get currentStepTitle => stepTitles[currentStep.value];
  String get submitButtonText =>
      isEditing.value ? 'Update News' : 'Submit News';

  void _onRelatedNewsSearchChanged() {
    final query = relatedNewsSearchController.text.trim();
    relatedNewsSearchQuery.value = query;

    if (query.length >= 2) {
      _debounceRelatedNewsSearch(query);
    } else {
      searchedRelatedNews.clear();
    }
  }

  Timer? _relatedNewsSearchTimer;

  void _debounceRelatedNewsSearch(String query) {
    _relatedNewsSearchTimer?.cancel();
    _relatedNewsSearchTimer = Timer(const Duration(milliseconds: 500), () {
      searchRelatedNews(query);
    });
  }

  Future<void> searchRelatedNews(String query) async {
    print('🔍 Starting search for: "$query"');

    if (query.trim().isEmpty) {
      print('🔍 Query is empty, clearing results');
      searchedRelatedNews.clear();
      return;
    }

    try {
      isSearchingRelatedNews.value = true;
      print('🔍 Search loading started');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.searchRelatedNewsUrl),
      );

      request.fields.addAll({'searchnews': query});
      print('🔍 Making API request with query: $query');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔍 API Response Status: ${response.statusCode}');
      print('🔍 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> newsData = responseData['data'] ?? [];
          print('🔍 Found ${newsData.length} news items');

          final relatedNewsList = newsData
              .map((item) => RelatedNewsItem.fromJson(item))
              .toList();

          // Filter out already selected news
          final filteredNews = relatedNewsList.where((news) {
            return !selectedRelatedNews.any(
              (selected) => selected.id == news.id,
            );
          }).toList();

          print('🔍 After filtering: ${filteredNews.length} items');
          searchedRelatedNews.assignAll(filteredNews);
          print(
            '🔍 Updated searchedRelatedNews list with ${searchedRelatedNews.length} items',
          );
        } else {
          print('🔍 API response success=false');
          searchedRelatedNews.clear();
        }
      } else {
        print('🔍 API request failed with status: ${response.statusCode}');
        throw Exception('Failed to search related news');
      }
    } catch (e) {
      print('🔍 Error searching related news: $e');
      Get.snackbar(
        'Error'.tr,
        'Failed to search related news'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: AppConstants.shortSnackbarDuration,
      );
      searchedRelatedNews.clear();
    } finally {
      isSearchingRelatedNews.value = false;
      print('🔍 Search loading finished');
    }
  }

  /// Add related news to selected list
  void addRelatedNews(RelatedNewsItem newsItem) {
    if (!selectedRelatedNews.any((item) => item.id == newsItem.id)) {
      selectedRelatedNews.add(newsItem);
      Get.snackbar(
        'Added'.tr,
        'Related news added successfully'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Remove related news from selected list
  void removeRelatedNews(RelatedNewsItem newsItem) {
    selectedRelatedNews.removeWhere((item) => item.id == newsItem.id);
    Get.snackbar(
      'Removed'.tr,
      'Related news removed successfully'.tr,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Clear related news search
  void clearRelatedNewsSearch() {
    relatedNewsSearchController.clear();
    searchedRelatedNews.clear();
    _relatedNewsSearchTimer?.cancel();
  }

  // Upload Media Methods

  Future<void> pickAndUploadImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return;
      final File original = File(result.files.single.path!);

      // Show crop selection UI with crop_your_image
      final File? croppedFile = await _showCropSelectionDialog(original);
      if (croppedFile == null) return; // user cancelled

      // Resize the cropped image to exactly 1200x680
      final File resizedFile = await _resizeImageTo1200x680(croppedFile);
      await uploadMedia(resizedFile);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_image'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pickAndUploadVideo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      // On web, use bytes; on mobile, use path
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('No file data available');
        }
        await uploadMediaFromBytes(file.bytes!, file.name);
      } else {
        if (file.path == null) {
          throw Exception('No file path available');
        }
        final File videoFile = File(file.path!);

        final String? option = await showModalBottomSheet<String>(
          context: Get.context!,
          backgroundColor: Get.theme.scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (BuildContext context) {
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: Text('Direct Upload'.tr),
                    onTap: () => Navigator.of(context).pop('direct'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text('Edit Video'.tr),
                    onTap: () => Navigator.of(context).pop('edit'),
                  ),
                ],
              ),
            );
          },
        );

        if (option == 'direct') {
          await uploadMedia(videoFile);
        } else if (option == 'edit') {
          final editedFile = await Get.toNamed(
            '/video-editor',
            arguments: videoFile,
          );

          print('====== RETURNED FROM EDITOR: $editedFile ======');
          print('====== TYPE: ${editedFile.runtimeType} ======');

          if (editedFile != null && editedFile is File) {
            await uploadMedia(editedFile);
          } else if (editedFile != null) {
            print('====== WARNING: RETURNED VALUE IS NOT A FILE ======');
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_video'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void cancelUpload() {
    _uploadCancelToken?.cancel('User cancelled upload');
  }

  Future<void> uploadMedia(File file) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;
      _uploadCancelToken = dio.CancelToken();

      final dio.Dio dioClient = dio.Dio()
        ..interceptors.add(
          dio.LogInterceptor(
            request: true,
            requestHeader: true,
            requestBody: true,
            responseHeader: true,
            responseBody: true,
            error: true,
          ),
        );
      String currentUserId = await _getCurrentUserId();
      final dio.FormData formData = dio.FormData.fromMap({
        'userID': currentUserId,
        'images': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      });

      final dio.Response response = await dioClient.post(
        ApiConstants.addmediaUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0) uploadProgress.value = sent / total;
        },
        cancelToken: _uploadCancelToken,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (jsonData['success'] == true) {
          final int imageId = jsonData['imageId'];
          final String imageUrl = jsonData['imageUrl'];

          // Create MediaModel from uploaded media
          final MediaModel uploadedMedia = MediaModel(
            id: imageId,
            userID: int.parse(currentUserId),
            photos: file.uri.pathSegments.last,
            fullpath: imageUrl,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );

          // Set the uploaded media as selected
          setSelectedMedia(uploadedMedia);

          Get.snackbar(
            'success'.tr,
            'Media uploaded successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception(
            'Upload failed: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to upload media: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        Get.snackbar(
          'info'.tr,
          'Upload cancelled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'Failed to upload media: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
      _uploadCancelToken = null;
    }
  }

  // Upload media from bytes (for web platform)
  Future<void> uploadMediaFromBytes(List<int> bytes, String filename) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;
      _uploadCancelToken = dio.CancelToken();

      final dio.Dio dioClient = dio.Dio(
        dio.BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      String currentUserId = await _getCurrentUserId();
      final dio.FormData formData = dio.FormData.fromMap({
        'userID': currentUserId,
        'images': dio.MultipartFile.fromBytes(bytes, filename: filename),
      });

      final dio.Response response = await dioClient.post(
        ApiConstants.addmediaUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0) uploadProgress.value = sent / total;
        },
        cancelToken: _uploadCancelToken,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (jsonData['success'] == true) {
          final int imageId = jsonData['imageId'];
          final String imageUrl = jsonData['imageUrl'];

          // Create MediaModel from uploaded media
          final MediaModel uploadedMedia = MediaModel(
            id: imageId,
            userID: int.parse(currentUserId),
            photos: filename,
            fullpath: imageUrl,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );

          // Set the uploaded media as selected
          setSelectedMedia(uploadedMedia);

          Get.snackbar(
            'success'.tr,
            'Media uploaded successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception(
            'Upload failed: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to upload media: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error details: $e');
      String errorMessage = 'Failed to upload media';

      if (e.toString().contains('cancelled')) {
        Get.snackbar(
          'info'.tr,
          'Upload cancelled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
        return;
      }

      // Check for CORS/network errors on web
      if (kIsWeb &&
          (e.toString().contains('XMLHttpRequest') ||
              e.toString().contains('connection error') ||
              e.toString().contains('Network Error'))) {
        errorMessage =
            'Upload failed: CORS error. The server needs to enable CORS for web uploads. Please contact your backend team.';
      } else {
        errorMessage = 'Failed to upload media: ${e.toString()}';
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
      _uploadCancelToken = null;
    }
  }

  // Inline upload helpers for HtmlEditor (do not affect selectedMedia)
  Future<String?> uploadInlineMedia(File file) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;
      _uploadCancelToken = dio.CancelToken();

      final dio.Dio dioClient = dio.Dio()
        ..interceptors.add(
          dio.LogInterceptor(
            request: true,
            requestHeader: true,
            requestBody: true,
            responseHeader: true,
            responseBody: true,
            error: true,
          ),
        );
      String currentUserId = await _getCurrentUserId();
      final dio.FormData formData = dio.FormData.fromMap({
        'userID': currentUserId,
        'images': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      });

      final dio.Response response = await dioClient.post(
        ApiConstants.addmediaUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0) uploadProgress.value = sent / total;
        },
        cancelToken: _uploadCancelToken,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (jsonData['success'] == true) {
          final String imageUrl = jsonData['imageUrl'];
          Get.snackbar(
            'success'.tr,
            'Media uploaded successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          return imageUrl;
        } else {
          throw Exception(
            'Upload failed: \'${jsonData['message'] ?? 'Unknown error'}\'',
          );
        }
      } else {
        throw Exception('Failed to upload media: ${response.statusCode}');
      }
    } catch (e) {
      if (!e.toString().contains('cancelled')) {
        Get.snackbar(
          'error'.tr,
          'Failed to upload media: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return null;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
      _uploadCancelToken = null;
    }
  }

  // Inline upload from bytes (for web platform)
  Future<String?> uploadInlineMediaFromBytes(
    List<int> bytes,
    String filename,
  ) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;
      _uploadCancelToken = dio.CancelToken();

      final dio.Dio dioClient = dio.Dio(
        dio.BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      String currentUserId = await _getCurrentUserId();
      final dio.FormData formData = dio.FormData.fromMap({
        'userID': currentUserId,
        'images': dio.MultipartFile.fromBytes(bytes, filename: filename),
      });

      final dio.Response response = await dioClient.post(
        ApiConstants.addmediaUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0) uploadProgress.value = sent / total;
        },
        cancelToken: _uploadCancelToken,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (jsonData['success'] == true) {
          final String imageUrl = jsonData['imageUrl'];
          Get.snackbar(
            'success'.tr,
            'Media uploaded successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          return imageUrl;
        } else {
          throw Exception(
            'Upload failed: \'${jsonData['message'] ?? 'Unknown error'}\'',
          );
        }
      } else {
        throw Exception('Failed to upload media: ${response.statusCode}');
      }
    } catch (e) {
      print('Inline upload error details: $e');

      if (e.toString().contains('cancelled')) {
        return null;
      }

      String errorMessage = 'Failed to upload media';

      // Check for CORS/network errors on web
      if (kIsWeb &&
          (e.toString().contains('XMLHttpRequest') ||
              e.toString().contains('connection error') ||
              e.toString().contains('Network Error'))) {
        errorMessage =
            'Upload failed: CORS error. The server needs to enable CORS for web uploads. Please contact your backend team.';
      } else {
        errorMessage = 'Failed to upload media: ${e.toString()}';
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      return null;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
      _uploadCancelToken = null;
    }
  }

  Future<String?> pickAndUploadImageForEditor() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return null;
      final File original = File(result.files.single.path!);

      // Crop and resize to 1200x680, same as feature image
      final File? croppedFile = await _showCropSelectionDialog(original);
      if (croppedFile == null) return null; // user cancelled
      final File resizedFile = await _resizeImageTo1200x680(croppedFile);

      return await uploadInlineMedia(resizedFile);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_image'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<String?> pickAndUploadVideoForEditor() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.single;

      // On web, use bytes; on mobile, use path
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('No file data available');
        }
        return await uploadInlineMediaFromBytes(file.bytes!, file.name);
      } else {
        if (file.path == null) {
          throw Exception('No file path available');
        }
        final File videoFile = File(file.path!);
        return await uploadInlineMedia(videoFile);
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_video'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Removed unused crop image method

  Future<File?> _showCropSelectionDialog(File imageFile) async {
    File? croppedFile;
    final CropController cropController = CropController();

    // Read image bytes
    final Uint8List imageBytes = await imageFile.readAsBytes();

    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: const Color(0xFF2196F3),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  if (Get.overlayContext != null) {
                    Navigator.pop(Get.overlayContext!);
                  } else {
                    Get.overlayContext != null
                        ? Navigator.pop(Get.overlayContext!)
                        : Get.back();
                  }
                },
              ),
              title: Text(
                'Crop Image (1200x680)'.tr,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.crop, color: Colors.white),
                  onPressed: () => cropController.crop(),
                ),
              ],
            ),
            body: Container(
              color: Colors.black,
              child: Crop(
                image: imageBytes,
                controller: cropController,
                onCropped: (cropResult) async {
                  try {
                    // Save cropped image to temporary file
                    final Directory tempDir = await getTemporaryDirectory();
                    final String tempPath =
                        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final File tempFile = File(tempPath);

                    // In crop_your_image v2.0.0, we need to access the cropped data differently
                    // Let's try different property names
                    Uint8List? imageData;

                    // Try common property names for CropResult
                    try {
                      imageData = (cropResult as dynamic).croppedImage;
                    } catch (e1) {
                      try {
                        imageData = (cropResult as dynamic).image;
                      } catch (e2) {
                        try {
                          imageData = (cropResult as dynamic).data;
                        } catch (e3) {
                          try {
                            imageData = (cropResult as dynamic).bytes;
                          } catch (e4) {
                            print(
                              'Could not access cropped image data. Available properties: ${cropResult.runtimeType}',
                            );
                            // Fallback: use original image for now
                            final originalBytes = await imageFile.readAsBytes();
                            imageData = originalBytes;
                          }
                        }
                      }
                    }

                    if (imageData != null) {
                      await tempFile.writeAsBytes(imageData);
                      print('Cropped image saved to: $tempPath');
                      print('File size: ${await tempFile.length()} bytes');
                    }

                    croppedFile = tempFile;
                    if (Get.overlayContext != null) {
                      Navigator.pop(Get.overlayContext!);
                    } else {
                      Get.overlayContext != null
                          ? Navigator.pop(Get.overlayContext!)
                          : Get.back();
                    }
                  } catch (e) {
                    print('Error saving cropped image: $e');
                    if (Get.overlayContext != null) {
                      Navigator.pop(Get.overlayContext!);
                    } else {
                      Get.overlayContext != null
                          ? Navigator.pop(Get.overlayContext!)
                          : Get.back();
                    }
                  }
                },
                aspectRatio: 1200.0 / 680.0, // 1.76:1 (landscape)
                maskColor: Colors.black.withOpacity(0.8),
                baseColor: Colors.black,
                cornerDotBuilder: (size, edgeAlignment) =>
                    const DotControl(color: Color(0xFF2196F3)),
                interactive: true,
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    return croppedFile;
  }

  // Removed unused crop image with selection method

  Future<File> _resizeImageTo1200x680(File imageFile) async {
    try {
      // Read image bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to exactly 1200x680
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 1200,
        height: 680,
      );

      print(
        'Resized image dimensions: ${resizedImage.width}x${resizedImage.height}',
      );

      // Encode as JPEG
      final Uint8List resizedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 90),
      );

      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File resizedFile = File(tempPath);
      await resizedFile.writeAsBytes(resizedBytes);

      return resizedFile;
    } catch (e) {
      print('Error resizing image: $e');
      // Return original file if resizing fails
      return imageFile;
    }
  }

  Future<void> translateTitle() async {
    final gujaratiTitle = titleController.text.trim();
    if (gujaratiTitle.isEmpty) {
      Get.snackbar(
        'Warning'.tr,
        'Please enter a Gujarati title first'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isTranslating.value = true;

      final translated = await _newsRepository.translateTitle(gujaratiTitle);

      if (translated != null && translated.isNotEmpty) {
        englishTitleController.text = translated;
        validateStep(0);
        Get.snackbar(
          'Success'.tr,
          'Title translated successfully'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error'.tr,
          'Translation failed'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error translating title: $e');
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isTranslating.value = false;
    }
  }
}
