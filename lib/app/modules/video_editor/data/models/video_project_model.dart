import 'package:uuid/uuid.dart';
import 'audio_track_model.dart';
import 'clip_model.dart';
import 'export_settings_model.dart';
import 'layer_model.dart';

const _uuid = Uuid();

enum BackgroundType { none, blur, solidColor, gradient, transparent }

class BackgroundModel {
  const BackgroundModel({
    this.type = BackgroundType.none,
    this.blurSigma = 12,
    this.colorValue = 0xFF000000,
    this.gradientColors = const [0xFF7B2FF7, 0xFFF107A3],
  });

  final BackgroundType type;
  final double blurSigma;
  final int colorValue;
  final List<int> gradientColors;
}

/// The full editable project: an ordered list of [ClipModel]s (the
/// timeline), overlay [LayerModel]s, extra [AudioTrackModel]s, transitions
/// between clips, background treatment and export settings.
///
/// This is what gets serialised to JSON for autosave (every
/// [core/config/app_config.dart AppConfig.autosaveInterval]) and what
/// `EditorRepositoryImpl.buildRenderData` converts into a `VideoRenderData`
/// for `pro_video_editor` at export time.
class VideoProjectModel {
  VideoProjectModel({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ClipModel>? clips,
    List<LayerModel>? layers,
    List<AudioTrackModel>? audioTracks,
    Map<String, TransitionType>? transitionsBetweenClips,
    this.background = const BackgroundModel(),
    this.exportSettings = const ExportSettingsModel(),
    this.thumbnailPath,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        clips = clips ?? [],
        layers = layers ?? [],
        audioTracks = audioTracks ?? [],
        transitionsBetweenClips = transitionsBetweenClips ?? {};

  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;

  List<ClipModel> clips;
  List<LayerModel> layers;
  List<AudioTrackModel> audioTracks;

  /// Keyed by `'${leftClipId}_${rightClipId}'` -> transition type applied
  /// between those two adjacent clips.
  Map<String, TransitionType> transitionsBetweenClips;

  BackgroundModel background;
  ExportSettingsModel exportSettings;
  String? thumbnailPath;

  Duration get totalDuration => clips.fold(
        Duration.zero,
        (sum, clip) => sum + clip.trimmedDuration,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'clips': clips.map((c) => c.toJson()).toList(),
        'layers': layers.map((l) => l.toJson()).toList(),
        'audioTracks': audioTracks.map((a) => a.toJson()).toList(),
        'transitions': transitionsBetweenClips.map(
          (key, value) => MapEntry(key, value.name),
        ),
        'backgroundType': background.type.name,
        'backgroundBlurSigma': background.blurSigma,
        'backgroundColorValue': background.colorValue,
        'backgroundGradientColors': background.gradientColors,
        'thumbnailPath': thumbnailPath,
      };

  factory VideoProjectModel.fromJson(Map<String, dynamic> json) {
    return VideoProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      clips: (json['clips'] as List)
          .map((c) => ClipModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      layers: (json['layers'] as List)
          .map((l) => LayerModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      audioTracks: (json['audioTracks'] as List)
          .map((a) => AudioTrackModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      transitionsBetweenClips:
          (json['transitions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          TransitionType.values.firstWhere((e) => e.name == value),
        ),
      ),
      background: BackgroundModel(
        type: BackgroundType.values.firstWhere(
          (e) => e.name == json['backgroundType'],
          orElse: () => BackgroundType.none,
        ),
        blurSigma: (json['backgroundBlurSigma'] as num?)?.toDouble() ?? 12,
        colorValue: json['backgroundColorValue'] as int? ?? 0xFF000000,
        gradientColors:
            (json['backgroundGradientColors'] as List?)?.cast<int>() ??
                const [0xFF7B2FF7, 0xFFF107A3],
      ),
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }
}
