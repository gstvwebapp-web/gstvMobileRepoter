import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'logger_service.dart';

/// Result of a gallery save attempt.
class GallerySaveResult {
  const GallerySaveResult({required this.success, this.assetId, this.error});
  final bool success;
  final String? assetId;
  final String? error;
}

/// Saves exported video files into the platform photo library via
/// `photo_manager`, which internally targets:
/// - Android: `MediaStore.Video` (works unchanged across Android 13/14/15
///   granular-permission models, since MediaStore inserts don't require
///   `WRITE_EXTERNAL_STORAGE` on modern Android).
/// - iOS: `PHPhotoLibrary`.
class GalleryService {
  GalleryService._internal();
  static final GalleryService instance = GalleryService._internal();

  Future<GallerySaveResult> saveVideo(String filePath, {String? title}) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth && !permission.hasAccess) {
      return const GallerySaveResult(
        success: false,
        error: 'Gallery permission not granted',
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return const GallerySaveResult(
        success: false,
        error: 'Exported file not found on disk',
      );
    }

    try {
      final asset = await PhotoManager.editor.saveVideo(
        file,
        title: title ?? file.uri.pathSegments.last,
      );
      return GallerySaveResult(success: true, assetId: asset.id);
    } catch (e, st) {
      LoggerService.instance.e('Gallery save failed', e, st);
      return GallerySaveResult(success: false, error: e.toString());
    }
  }
}
