import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A background/replacement audio track mixed into the export alongside
/// (or instead of) each clip's original audio.
class AudioTrackModel {
  AudioTrackModel({
    String? id,
    required this.sourcePath,
    required this.startTime,
    required this.duration,
    this.volume = 1.0,
    this.fadeIn = Duration.zero,
    this.fadeOut = Duration.zero,
    this.muteOriginal = false,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String sourcePath;
  Duration startTime;
  Duration duration;
  double volume;
  Duration fadeIn;
  Duration fadeOut;
  bool muteOriginal;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourcePath': sourcePath,
        'startTimeMs': startTime.inMilliseconds,
        'durationMs': duration.inMilliseconds,
        'volume': volume,
        'fadeInMs': fadeIn.inMilliseconds,
        'fadeOutMs': fadeOut.inMilliseconds,
        'muteOriginal': muteOriginal,
      };

  factory AudioTrackModel.fromJson(Map<String, dynamic> json) => AudioTrackModel(
        id: json['id'] as String,
        sourcePath: json['sourcePath'] as String,
        startTime: Duration(milliseconds: json['startTimeMs'] as int),
        duration: Duration(milliseconds: json['durationMs'] as int),
        volume: (json['volume'] as num).toDouble(),
        fadeIn: Duration(milliseconds: json['fadeInMs'] as int),
        fadeOut: Duration(milliseconds: json['fadeOutMs'] as int),
        muteOriginal: json['muteOriginal'] as bool,
      );
}
