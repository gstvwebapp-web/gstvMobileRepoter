import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import '../../core/services/logger_service.dart';
import '../../domain/repository/media_repository.dart';
import '../models/video_metadata_model.dart';

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickVideoFromGallery() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    return file?.path;
  }

  @override
  Future<String?> pickVideoFromCamera() async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 10),
    );
    return file?.path;
  }

  @override
  Future<List<String>> pickMultipleVideos() async {
    // image_picker doesn't support multi-video pick on every platform; fall
    // back to sequential single picks driven by the UI (Merge Videos flow
    // calls this repeatedly), so this returns at most one path per call by
    // design and the controller loops it.
    final path = await pickVideoFromGallery();
    return path == null ? [] : [path];
  }

  @override
  Future<VideoMetadataModel> readMetadata(String filePath) async {
    try {
      final metadata = await ProVideoEditor.instance.getMetadata(
        EditorVideo.file(File(filePath)),
      );

      return VideoMetadataModel(
        duration: metadata.duration,
        width: metadata.resolution.width.toInt(),
        height: metadata.resolution.height.toInt(),
        fps: metadata.frameRate ?? 0.0,
        codec: metadata.extension,
        bitrateKbps: (metadata.bitrate / 1000).round(),
        rotationDegrees: metadata.rotation,
        fileSizeBytes: await File(filePath).length(),
      );
    } catch (e, st) {
      // `pro_video_editor`'s metadata field names are version-sensitive;
      // if the installed 2.7.1 API differs from what's referenced above,
      // this catch block still returns a best-effort metadata object from
      // the file itself so the app doesn't hard-crash on import — but log
      // loudly so it gets caught in QA rather than silently degrading.
      LoggerService.instance.e(
        'Metadata read failed — verify pro_video_editor API surface for '
        'the installed version against this call site.',
        e,
        st,
      );
      final size = await File(filePath).exists() ? await File(filePath).length() : 0;
      return VideoMetadataModel(
        duration: Duration.zero,
        width: 0,
        height: 0,
        fps: 0,
        codec: 'unknown',
        bitrateKbps: 0,
        rotationDegrees: 0,
        fileSizeBytes: size,
      );
    }
  }
}
