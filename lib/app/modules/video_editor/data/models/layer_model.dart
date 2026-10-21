import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum LayerType { text, image, sticker, svg, gif, logo, watermark }

enum LayerAnimationType {
  none,
  fade,
  slide,
  scale,
  rotate,
  bounce,
  elastic,
  zoom,
}

enum LayerAnimationPhase { inPhase, outPhase, inOutPhase }

class LayerAnimation {
  const LayerAnimation({
    this.type = LayerAnimationType.none,
    this.phase = LayerAnimationPhase.inPhase,
    this.duration = const Duration(milliseconds: 400),
    this.curve = 'easeInOut',
  });

  final LayerAnimationType type;
  final LayerAnimationPhase phase;
  final Duration duration;
  final String curve;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'phase': phase.name,
        'durationMs': duration.inMilliseconds,
        'curve': curve,
      };

  factory LayerAnimation.fromJson(Map<String, dynamic> json) => LayerAnimation(
        type: LayerAnimationType.values.firstWhere((e) => e.name == json['type']),
        phase: LayerAnimationPhase.values.firstWhere((e) => e.name == json['phase']),
        duration: Duration(milliseconds: json['durationMs'] as int),
        curve: json['curve'] as String,
      );
}

/// A timed overlay placed above the video — text, sticker, image, logo or
/// watermark — positioned in normalised (0..1) canvas coordinates so it
/// scales correctly across export resolutions.
class LayerModel {
  LayerModel({
    String? id,
    required this.type,
    required this.startTime,
    required this.duration,
    this.dx = 0.5,
    this.dy = 0.5,
    this.widthFraction = 0.3,
    this.heightFraction = 0.15,
    this.rotationDegrees = 0,
    this.text,
    this.assetPath,
    this.textColorValue,
    this.fontSizeSp = 24,
    this.animation = const LayerAnimation(),
  }) : id = id ?? _uuid.v4();

  final String id;
  final LayerType type;

  Duration startTime;
  Duration duration;

  double dx;
  double dy;
  double widthFraction;
  double heightFraction;
  double rotationDegrees;

  String? text;
  String? assetPath;
  int? textColorValue;
  double fontSizeSp;

  LayerAnimation animation;

  Duration get endTime => startTime + duration;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'startTimeMs': startTime.inMilliseconds,
        'durationMs': duration.inMilliseconds,
        'dx': dx,
        'dy': dy,
        'widthFraction': widthFraction,
        'heightFraction': heightFraction,
        'rotationDegrees': rotationDegrees,
        'text': text,
        'assetPath': assetPath,
        'textColorValue': textColorValue,
        'fontSizeSp': fontSizeSp,
        'animation': animation.toJson(),
      };

  factory LayerModel.fromJson(Map<String, dynamic> json) => LayerModel(
        id: json['id'] as String,
        type: LayerType.values.firstWhere((e) => e.name == json['type']),
        startTime: Duration(milliseconds: json['startTimeMs'] as int),
        duration: Duration(milliseconds: json['durationMs'] as int),
        dx: (json['dx'] as num).toDouble(),
        dy: (json['dy'] as num).toDouble(),
        widthFraction: (json['widthFraction'] as num).toDouble(),
        heightFraction: (json['heightFraction'] as num).toDouble(),
        rotationDegrees: (json['rotationDegrees'] as num).toDouble(),
        text: json['text'] as String?,
        assetPath: json['assetPath'] as String?,
        textColorValue: json['textColorValue'] as int?,
        fontSizeSp: (json['fontSizeSp'] as num?)?.toDouble() ?? 24,
        animation: LayerAnimation.fromJson(
          json['animation'] as Map<String, dynamic>,
        ),
      );
}
