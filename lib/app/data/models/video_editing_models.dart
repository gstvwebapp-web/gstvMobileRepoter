import 'dart:io';

class VideoProject {
  final String id;
  final String name;
  final List<VideoClip> clips;
  final VideoOrientation orientation;
  final File? referenceImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoProject({
    required this.id,
    required this.name,
    required this.clips,
    required this.orientation,
    this.referenceImage,
    required this.createdAt,
    required this.updatedAt,
  });

  VideoProject copyWith({
    String? id,
    String? name,
    List<VideoClip>? clips,
    VideoOrientation? orientation,
    File? referenceImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoProject(
      id: id ?? this.id,
      name: name ?? this.name,
      clips: clips ?? this.clips,
      orientation: orientation ?? this.orientation,
      referenceImage: referenceImage ?? this.referenceImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VideoClip {
  final String id;
  final File file;
  final String name;
  final Duration duration;
  final double startTime;
  final double endTime;
  final String? thumbnailPath;
  final VideoTransform transform;

  VideoClip({
    required this.id,
    required this.file,
    required this.name,
    required this.duration,
    this.startTime = 0.0,
    double? endTime,
    this.thumbnailPath,
    VideoTransform? transform,
  }) : endTime = endTime ?? duration.inMilliseconds.toDouble(),
        transform = transform ?? VideoTransform();

  VideoClip copyWith({
    String? id,
    File? file,
    String? name,
    Duration? duration,
    double? startTime,
    double? endTime,
    String? thumbnailPath,
    VideoTransform? transform,
  }) {
    return VideoClip(
      id: id ?? this.id,
      file: file ?? this.file,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      transform: transform ?? this.transform,
    );
  }

  Duration get trimmedDuration {
    final start = Duration(milliseconds: startTime.round());
    final end = Duration(milliseconds: endTime.round());
    return end - start;
  }
}

class VideoTransform {
  final double scale;
  final double rotation;
  final double offsetX;
  final double offsetY;
  final bool flipHorizontal;
  final bool flipVertical;

  VideoTransform({
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  VideoTransform copyWith({
    double? scale,
    double? rotation,
    double? offsetX,
    double? offsetY,
    bool? flipHorizontal,
    bool? flipVertical,
  }) {
    return VideoTransform(
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
    );
  }
}

enum VideoOrientation {
  portrait,
  landscape,
}

enum VideoQuality {
  low,
  medium,
  high,
  ultra,
}

class VideoExportSettings {
  final VideoQuality quality;
  final int? customWidth;
  final int? customHeight;
  final int? bitrate;
  final int frameRate;
  final String format;

  VideoExportSettings({
    this.quality = VideoQuality.high,
    this.customWidth,
    this.customHeight,
    this.bitrate,
    this.frameRate = 30,
    this.format = 'mp4',
  });

  VideoExportSettings copyWith({
    VideoQuality? quality,
    int? customWidth,
    int? customHeight,
    int? bitrate,
    int? frameRate,
    String? format,
  }) {
    return VideoExportSettings(
      quality: quality ?? this.quality,
      customWidth: customWidth ?? this.customWidth,
      customHeight: customHeight ?? this.customHeight,
      bitrate: bitrate ?? this.bitrate,
      frameRate: frameRate ?? this.frameRate,
      format: format ?? this.format,
    );
  }

  Map<String, int> get dimensions {
    if (customWidth != null && customHeight != null) {
      return {'width': customWidth!, 'height': customHeight!};
    }

    switch (quality) {
      case VideoQuality.low:
        return {'width': 480, 'height': 360};
      case VideoQuality.medium:
        return {'width': 720, 'height': 480};
      case VideoQuality.high:
        return {'width': 1280, 'height': 720};
      case VideoQuality.ultra:
        return {'width': 1920, 'height': 1080};
    }
  }
}

class VideoEditingProgress {
  final double progress;
  final String currentOperation;
  final bool isCompleted;
  final String? errorMessage;

  VideoEditingProgress({
    required this.progress,
    required this.currentOperation,
    this.isCompleted = false,
    this.errorMessage,
  });

  VideoEditingProgress copyWith({
    double? progress,
    String? currentOperation,
    bool? isCompleted,
    String? errorMessage,
  }) {
    return VideoEditingProgress(
      progress: progress ?? this.progress,
      currentOperation: currentOperation ?? this.currentOperation,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
