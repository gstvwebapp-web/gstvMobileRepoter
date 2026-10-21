import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TinymceEditorController {
  final WebViewController webViewController = WebViewController();
  final RxBool isEditorReady = false.obs;
  
  // Future that completes when the editor is ready
  Completer<void> _readyCompleter = Completer<void>();
  Future<void> get editorReady => _readyCompleter.future;

  TinymceEditorController() {
    _initWebView();
  }

  void _initWebView() {
    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'ready') {
            if (!_readyCompleter.isCompleted) {
              isEditorReady.value = true;
              _readyCompleter.complete();
            }
          }
        },
      );
  }

  /// Sets the initial HTML configuration for TinyMCE
  Future<void> initializeWithHtml(String html) async {
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
      isEditorReady.value = false;
    }
    await webViewController.loadHtmlString(html);
  }

  /// Get content from the editor
  Future<String> getText() async {
    if (!isEditorReady.value) {
      return '';
    }
    try {
      final result = await webViewController.runJavaScriptReturningResult('getContent();');
      // result comes back as a JSON string literal (e.g. "\"<p>test</p>\"")
      if (result is String) {
        try {
          return jsonDecode(result) as String;
        } catch (e) {
          // Fallback if not valid JSON
          return result;
        }
      }
      return result.toString();
    } catch (e) {
      print('Error getting text from TinyMCE: $e');
      return '';
    }
  }

  /// Set content to the editor
  Future<void> setText(String content) async {
    await editorReady; // Wait until ready
    try {
      // Escape the content for JS injection
      final escapedContent = content
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r');
      await webViewController.runJavaScript('setContent("$escapedContent");');
    } catch (e) {
      print('Error setting text in TinyMCE: $e');
    }
  }

  /// Clear content in the editor
  Future<void> clear() async {
    await setText('');
  }

  /// Insert HTML into the editor
  Future<void> insertHtml(String html) async {
    await editorReady;
    try {
      final escapedContent = html
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r');
      await webViewController.runJavaScript('insertHtml("$escapedContent");');
    } catch (e) {
      print('Error inserting html in TinyMCE: $e');
    }
  }

  /// Insert a network image
  Future<void> insertNetworkImage(String url) async {
    final html = '<img src="\$url" alt="" style="max-width:100%;height:auto;" />';
    await insertHtml(html);
  }
}
