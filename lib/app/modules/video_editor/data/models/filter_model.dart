/// The distinct filter/adjustment kinds exposed in the Filters tab.
///
/// Every value here is ultimately expressed as one or more 4x5 colour
/// matrices when handed to `pro_video_editor` (`ColorMatrix` /
/// `ColorFilterGenerator`-style construction) — see
/// `EditorRepositoryImpl._colorMatrixFor`.
enum FilterType {
  brightness,
  contrast,
  exposure,
  gamma,
  hue,
  saturation,
  sharpen,
  sepia,
  vintage,
  warm,
  cool,
  mono,
  invert,
  blur,
}

/// A single applied filter/adjustment with its intensity.
///
/// [intensity] range is filter-dependent: adjustments like brightness /
/// contrast / saturation use a signed `-1.0..1.0` range centred on 0 (no
/// change), while stylised filters like sepia/vintage/mono use `0.0..1.0`
/// as an opacity-style blend strength. Blur uses a positive sigma in
/// logical pixels, `0..25`.
class FilterModel {
  const FilterModel({required this.type, required this.intensity});

  final FilterType type;
  final double intensity;

  FilterModel copyWith({double? intensity}) =>
      FilterModel(type: type, intensity: intensity ?? this.intensity);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'intensity': intensity,
      };

  factory FilterModel.fromJson(Map<String, dynamic> json) => FilterModel(
        type: FilterType.values.firstWhere((e) => e.name == json['type']),
        intensity: (json['intensity'] as num).toDouble(),
      );
}

extension FilterTypeMeta on FilterType {
  String get label {
    switch (this) {
      case FilterType.brightness:
        return 'Brightness';
      case FilterType.contrast:
        return 'Contrast';
      case FilterType.exposure:
        return 'Exposure';
      case FilterType.gamma:
        return 'Gamma';
      case FilterType.hue:
        return 'Hue';
      case FilterType.saturation:
        return 'Saturation';
      case FilterType.sharpen:
        return 'Sharpen';
      case FilterType.sepia:
        return 'Sepia';
      case FilterType.vintage:
        return 'Vintage';
      case FilterType.warm:
        return 'Warm';
      case FilterType.cool:
        return 'Cool';
      case FilterType.mono:
        return 'Mono';
      case FilterType.invert:
        return 'Invert';
      case FilterType.blur:
        return 'Blur';
    }
  }

  /// Whether this filter uses a signed -1..1 "adjustment" range vs an
  /// unsigned 0..1 "stylised blend" range.
  bool get isSignedAdjustment => const {
        FilterType.brightness,
        FilterType.contrast,
        FilterType.exposure,
        FilterType.gamma,
        FilterType.hue,
        FilterType.saturation,
        FilterType.sharpen,
      }.contains(this);
}
