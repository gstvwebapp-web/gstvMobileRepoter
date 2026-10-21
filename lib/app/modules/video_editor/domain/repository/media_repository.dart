import '../../data/models/video_metadata_model.dart';

/// Abstraction over picking source media and reading its metadata.
/// Implemented by [MediaRepositoryImpl] using `image_picker` +
/// `pro_video_editor`. Kept as an interface so the presentation layer
/// (controllers) depend on this contract, not the concrete picker/plugin
/// APIs — makes controllers unit-testable with a fake implementation.
abstract class MediaRepository {
  Future<String?> pickVideoFromGallery();
  Future<String?> pickVideoFromCamera();
  Future<List<String>> pickMultipleVideos();
  Future<VideoMetadataModel> readMetadata(String filePath);
}
