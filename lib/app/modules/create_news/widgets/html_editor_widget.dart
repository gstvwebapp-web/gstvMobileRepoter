import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../create_news_controller.dart';
import 'tinymce_editor_controller.dart';

class HtmlEditorWidget extends StatefulWidget {
  final TinymceEditorController controller;
  final String? initialContent;
  final Function(String)? onContentChanged;
  final String hint;

  const HtmlEditorWidget({
    super.key,
    required this.controller,
    this.initialContent,
    this.onContentChanged,
    this.hint = 'Enter content here...',
  });

  @override
  State<HtmlEditorWidget> createState() => _HtmlEditorWidgetState();
}

class _HtmlEditorWidgetState extends State<HtmlEditorWidget> {
  String _cachedContent = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  Future<void> _initializeContent() async {
    if (!_isInitialized) {
      if (mounted) {
        setState(() {
          _cachedContent = widget.initialContent ?? '';
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openFullScreenEditor(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _isInitialized
                ? Builder(
                    builder: (context) {
                      if (_cachedContent.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            top: 10,
                            bottom: 100,
                            left: 16,
                          ),
                          child: Text(
                            widget.hint,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        );
                      }

                      return HtmlWidget(
                        _cachedContent,
                      ).paddingAll(16);
                    },
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Loading content...'.tr,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenEditor(BuildContext context) async {
    final result = await Get.to<String>(
      () => FullScreenHtmlEditor(
        controller: widget.controller,
        initialContent: _cachedContent.isNotEmpty
            ? _cachedContent
            : widget.initialContent,
        hint: widget.hint,
        onContentChanged: (content) {
          setState(() {
            _cachedContent = content;
          });
          widget.onContentChanged?.call(content);
        },
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );

    if (result != null) {
      _cachedContent = result;
      widget.onContentChanged?.call(result);
    }
  }
}

class FullScreenHtmlEditorController extends GetxController {
  final TinymceEditorController htmlController;
  final String? initialContent;
  final Function(String)? onContentChanged;

  FullScreenHtmlEditorController({
    required this.htmlController,
    this.initialContent,
    this.onContentChanged,
  });

  final RxBool isLoading = true.obs;
  final RxString currentContent = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeContent();
  }

  Future<void> _initializeContent() async {
    try {
      currentContent.value = (initialContent ?? '');
      await _loadTinyMceHtml();
      await htmlController.editorReady;
      if (currentContent.value.isNotEmpty) {
         await htmlController.setText(currentContent.value);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTinyMceHtml() async {
    final String htmlString = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/tinymce/6.8.3/tinymce.min.js" referrerpolicy="origin"></script>
  <script>
    tinymce.init({
      selector: '#editor',
      height: '100%',
      menubar: false,
      plugins: 'lists link image media table code wordcount',
      toolbar: 'undo redo | blocks | bold italic | alignleft aligncenter alignright | indent outdent | bullist numlist | link image media | code',
      setup: function(editor) {
        editor.on('init', function() {
          if (window.FlutterChannel) {
             window.FlutterChannel.postMessage('ready');
          }
        });
        editor.on('Change KeyUp', function() {
          if (window.FlutterChannel) {
             window.FlutterChannel.postMessage('content_changed'); // Not sending full content to avoid lag
          }
        });
      }
    });

    function setContent(html) {
      if (tinymce.activeEditor) {
        tinymce.activeEditor.setContent(html);
      }
    }
    
    function getContent() {
      if (tinymce.activeEditor) {
        return tinymce.activeEditor.getContent();
      }
      return '';
    }

    function insertHtml(html) {
      if (tinymce.activeEditor) {
        tinymce.activeEditor.insertContent(html);
      }
    }
  </script>
  <style>
    body, html { margin: 0; padding: 0; height: 100%; overflow: hidden; }
    #editor-container { height: 100%; display: flex; flex-direction: column; }
    .tox-tinymce { border: none !important; }
  </style>
</head>
<body>
  <div id="editor-container">
    <textarea id="editor"></textarea>
  </div>
</body>
</html>
''';
    await htmlController.initializeWithHtml(htmlString);
  }

  Future<void> saveAndClose() async {
    try {
      String content = currentContent.value;
      try {
        content = await htmlController.getText();
      } catch (_) {}

      onContentChanged?.call(content);
      Get.overlayContext != null ? Navigator.pop(Get.overlayContext!, content) : Get.back(result: content);
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to save content'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red[800],
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

class FullScreenHtmlEditor extends StatelessWidget {
  final TinymceEditorController controller;
  final String? initialContent;
  final Function(String)? onContentChanged;
  final String hint;

  const FullScreenHtmlEditor({
    super.key,
    required this.controller,
    this.initialContent,
    this.onContentChanged,
    this.hint = 'Enter content here...',
  });

  Future<void> _insertImageFromServer() async {
    try {
      final c = Get.find<CreateNewsController>();
      final url = await c.pickAndUploadImageForEditor();
      if (url != null && url.isNotEmpty) {
        controller.insertNetworkImage(url);
      }
    } catch (_) {}
  }

  Future<void> _insertVideoFromServer() async {
    try {
      final c = Get.find<CreateNewsController>();
      final url = await c.pickAndUploadVideoForEditor();
      if (url != null && url.isNotEmpty) {
        final html = "<p><video controls src='${url.replaceAll("'", "%27")}' style='max-width:100%;height:auto;'></video></p>";
        controller.insertHtml(html);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final editorController = Get.put(
      FullScreenHtmlEditorController(
        htmlController: controller,
        initialContent: initialContent,
        onContentChanged: onContentChanged,
      ),
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        title: Text('Content Editor'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Insert image from server'.tr,
            icon: const Icon(Icons.image_outlined),
            color: AppColors.primary,
            onPressed: () => _insertImageFromServer(),
          ),
          IconButton(
            tooltip: 'Insert video from server'.tr,
            icon: const Icon(Icons.videocam_outlined),
            color: AppColors.primary,
            onPressed: () => _insertVideoFromServer(),
          ),
          TextButton.icon(
            onPressed: editorController.saveAndClose,
            icon: const Icon(Icons.check, size: 18),
            label: Text('Save'.tr),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
      body: Obx(
        () => editorController.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: WebViewWidget(controller: controller.webViewController),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
