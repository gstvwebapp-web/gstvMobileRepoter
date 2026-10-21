enum ExportResolution { r720p, r1080p, r2k, r4k, original }

extension ExportResolutionMeta on ExportResolution {
  String get label {
    switch (this) {
      case ExportResolution.r720p:
        return '720p';
      case ExportResolution.r1080p:
        return '1080p';
      case ExportResolution.r2k:
        return '2K';
      case ExportResolution.r4k:
        return '4K';
      case ExportResolution.original:
        return 'Original';
    }
  }

  /// Target height in pixels, null for [ExportResolution.original] (keep
  /// source resolution).
  int? get heightPx {
    switch (this) {
      case ExportResolution.r720p:
        return 720;
      case ExportResolution.r1080p:
        return 1080;
      case ExportResolution.r2k:
        return 1440;
      case ExportResolution.r4k:
        return 2160;
      case ExportResolution.original:
        return null;
    }
  }
}

enum ExportCodec { h264, hevc }

enum ExportContainer { mp4, mov }

class ExportSettingsModel {
  const ExportSettingsModel({
    this.resolution = ExportResolution.r1080p,
    this.fps = 30,
    this.codec = ExportCodec.h264,
    this.container = ExportContainer.mp4,
    this.bitrateKbps,
    this.optimizeForStreaming = true,
  });

  final ExportResolution resolution;
  final int fps;
  final ExportCodec codec;
  final ExportContainer container;

  /// Explicit bitrate override; null lets the encoder pick a sensible
  /// default for the chosen resolution/fps.
  final int? bitrateKbps;
  final bool optimizeForStreaming;

  ExportSettingsModel copyWith({
    ExportResolution? resolution,
    int? fps,
    ExportCodec? codec,
    ExportContainer? container,
    int? bitrateKbps,
    bool? optimizeForStreaming,
  }) {
    return ExportSettingsModel(
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      codec: codec ?? this.codec,
      container: container ?? this.container,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      optimizeForStreaming: optimizeForStreaming ?? this.optimizeForStreaming,
    );
  }
}

enum TransitionType { none, fade, crossFade, zoom, slide, blur, push }

class TransitionModel {
  const TransitionModel({
    this.type = TransitionType.fade,
    this.duration = const Duration(milliseconds: 500),
  });

  final TransitionType type;
  final Duration duration;
}
