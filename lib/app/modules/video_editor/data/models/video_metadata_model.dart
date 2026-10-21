/// Technical metadata read off a source video via
/// `ProVideoEditor.instance.getMetadata`.
class VideoMetadataModel {
  const VideoMetadataModel({
    required this.duration,
    required this.width,
    required this.height,
    required this.fps,
    required this.codec,
    required this.bitrateKbps,
    required this.rotationDegrees,
    required this.fileSizeBytes,
  });

  final Duration duration;
  final int width;
  final int height;
  final double fps;
  final String codec;
  final int bitrateKbps;
  final int rotationDegrees;
  final int fileSizeBytes;

  bool get isPortrait => height > width;

  String get resolutionLabel => '${width}x$height';
}
