import 'package:uuid/uuid.dart';
import 'filter_model.dart';

const _uuid = Uuid();

/// Supported crop aspect presets. `custom` stores an explicit ratio in
/// [ClipModel.customAspectRatio].
enum CropPreset {
  free,
  square1x1,
  portrait4x5,
  portrait9x16,
  landscape16x9,
  portrait3x4,
  landscape4x3,
  instagramPost,
  youtubeShorts,
  tiktok,
  facebook,
  custom,
}

extension CropPresetRatio on CropPreset {
  /// Returns width/height ratio, or null for [CropPreset.free] /
  /// [CropPreset.custom] (custom ratio is read from [ClipModel.customAspectRatio]).
  double? get ratio {
    switch (this) {
      case CropPreset.free:
      case CropPreset.custom:
        return null;
      case CropPreset.square1x1:
      case CropPreset.instagramPost:
        return 1;
      case CropPreset.portrait4x5:
        return 4 / 5;
      case CropPreset.portrait9x16:
      case CropPreset.tiktok:
      case CropPreset.youtubeShorts:
        return 9 / 16;
      case CropPreset.landscape16x9:
      case CropPreset.facebook:
        return 16 / 9;
      case CropPreset.portrait3x4:
        return 3 / 4;
      case CropPreset.landscape4x3:
        return 4 / 3;
    }
  }

  String get label {
    switch (this) {
      case CropPreset.free:
        return 'Free';
      case CropPreset.square1x1:
        return '1:1';
      case CropPreset.portrait4x5:
        return '4:5';
      case CropPreset.portrait9x16:
        return '9:16';
      case CropPreset.landscape16x9:
        return '16:9';
      case CropPreset.portrait3x4:
        return '3:4';
      case CropPreset.landscape4x3:
        return '4:3';
      case CropPreset.instagramPost:
        return 'Instagram';
      case CropPreset.youtubeShorts:
        return 'YouTube';
      case CropPreset.tiktok:
        return 'TikTok';
      case CropPreset.facebook:
        return 'Facebook';
      case CropPreset.custom:
        return 'Custom';
    }
  }
}

/// A single video clip placed on the timeline.
///
/// Multiple [ClipModel]s concatenated in order form the full timeline; this
/// mirrors how `pro_video_editor`'s `VideoRenderData.videoSegments` expects
/// its list of `VideoSegment`s, so [ClipModel] maps close to 1:1 onto that
/// type at render time (see `EditorRepositoryImpl.buildRenderData`).
class ClipModel {
  ClipModel({
    String? id,
    required this.sourcePath,
    required this.originalDuration,
    Duration? trimStart,
    Duration? trimEnd,
    this.rotationDegrees = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.cropPreset = CropPreset.free,
    this.customAspectRatio,
    this.cropRect,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
    this.muted = false,
    List<FilterModel>? filters,
  })  : id = id ?? _uuid.v4(),
        trimStart = trimStart ?? Duration.zero,
        trimEnd = trimEnd ?? originalDuration,
        filters = filters ?? [];

  final String id;
  final String sourcePath;
  Duration originalDuration;

  Duration trimStart;
  Duration trimEnd;

  /// 0, 90, 180 or 270 — plus free-form custom rotation is layered on top
  /// via [customRotationDegrees] for the "custom rotation" requirement.
  int rotationDegrees;
  double customRotationDegrees = 0;

  bool flipHorizontal;
  bool flipVertical;

  CropPreset cropPreset;
  double? customAspectRatio;

  /// Normalised crop rect (0..1 in both axes), null = full frame.
  List<double>? cropRect;

  double playbackSpeed;
  double volume;
  bool muted;

  List<FilterModel> filters;

  Duration get trimmedDuration => trimEnd - trimStart;

  ClipModel copyWith({
    Duration? trimStart,
    Duration? trimEnd,
    int? rotationDegrees,
    bool? flipHorizontal,
    bool? flipVertical,
    CropPreset? cropPreset,
    double? customAspectRatio,
    List<double>? cropRect,
    double? playbackSpeed,
    double? volume,
    bool? muted,
    List<FilterModel>? filters,
  }) {
    return ClipModel(
      id: id,
      sourcePath: sourcePath,
      originalDuration: originalDuration,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      cropPreset: cropPreset ?? this.cropPreset,
      customAspectRatio: customAspectRatio ?? this.customAspectRatio,
      cropRect: cropRect ?? this.cropRect,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
      filters: filters ?? List.of(this.filters),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourcePath': sourcePath,
        'originalDurationMs': originalDuration.inMilliseconds,
        'trimStartMs': trimStart.inMilliseconds,
        'trimEndMs': trimEnd.inMilliseconds,
        'rotationDegrees': rotationDegrees,
        'customRotationDegrees': customRotationDegrees,
        'flipHorizontal': flipHorizontal,
        'flipVertical': flipVertical,
        'cropPreset': cropPreset.name,
        'customAspectRatio': customAspectRatio,
        'cropRect': cropRect,
        'playbackSpeed': playbackSpeed,
        'volume': volume,
        'muted': muted,
        'filters': filters.map((f) => f.toJson()).toList(),
      };

  factory ClipModel.fromJson(Map<String, dynamic> json) {
    final clip = ClipModel(
      id: json['id'] as String,
      sourcePath: json['sourcePath'] as String,
      originalDuration: Duration(milliseconds: json['originalDurationMs'] as int),
      trimStart: Duration(milliseconds: json['trimStartMs'] as int),
      trimEnd: Duration(milliseconds: json['trimEndMs'] as int),
      rotationDegrees: json['rotationDegrees'] as int? ?? 0,
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
      cropPreset: CropPreset.values.firstWhere(
        (e) => e.name == json['cropPreset'],
        orElse: () => CropPreset.free,
      ),
      customAspectRatio: (json['customAspectRatio'] as num?)?.toDouble(),
      cropRect: (json['cropRect'] as List?)?.cast<double>(),
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      muted: json['muted'] as bool? ?? false,
      filters: (json['filters'] as List? ?? [])
          .map((f) => FilterModel.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
    clip.customRotationDegrees =
        (json['customRotationDegrees'] as num?)?.toDouble() ?? 0;
    return clip;
  }
}
