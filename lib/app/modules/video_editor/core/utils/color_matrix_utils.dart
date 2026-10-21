import '../../data/models/filter_model.dart';

/// Builds and composes 4x5 colour matrices for [FilterModel]s.
///
/// This is the single source of truth for filter math — both the live
/// preview (`VideoPreview`, via Flutter's `ColorFiltered`/`ColorFilter.matrix`,
/// which expects exactly this 4x5-with-0..255-offset format) and the
/// export pipeline (`EditorRepositoryImpl`, via `pro_video_editor`'s
/// `colorMatrixList`) call into this class. Keeping the math in one place
/// means what you see in the editor preview is guaranteed to match what
/// gets baked into the exported file — if you ever suspect "preview looks
/// different from export", this is the first file to check, and there
/// should only ever be one implementation to fix.
class ColorMatrixUtils {
  const ColorMatrixUtils._();

  static const List<double> identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  /// Matrix for a single filter. Returns [identity] for filter types that
  /// aren't representable as a linear colour matrix (blur, sharpen — these
  /// are convolution effects, not per-pixel colour transforms) so callers
  /// can safely fold them into [compose] without special-casing.
  static List<double> matrixFor(FilterModel filter) {
    final i = filter.intensity;
    switch (filter.type) {
      case FilterType.brightness:
        final b = i * 255;
        return [
          1, 0, 0, 0, b, //
          0, 1, 0, 0, b, //
          0, 0, 1, 0, b, //
          0, 0, 0, 1, 0,
        ];
      case FilterType.contrast:
        final c = 1 + i;
        final t = (1 - c) * 127.5;
        return [
          c, 0, 0, 0, t, //
          0, c, 0, 0, t, //
          0, 0, c, 0, t, //
          0, 0, 0, 1, 0,
        ];
      case FilterType.saturation:
        final s = 1 + i;
        const rw = 0.213, gw = 0.715, bw = 0.072;
        return [
          rw * (1 - s) + s, gw * (1 - s), bw * (1 - s), 0, 0, //
          rw * (1 - s), gw * (1 - s) + s, bw * (1 - s), 0, 0, //
          rw * (1 - s), gw * (1 - s), bw * (1 - s) + s, 0, 0, //
          0, 0, 0, 1, 0,
        ];
      case FilterType.mono:
        return [
          0.33 * i + (1 - i), 0.59 * i, 0.11 * i, 0, 0,
          0.33 * i, 0.59 * i + (1 - i), 0.11 * i, 0, 0,
          0.33 * i, 0.59 * i, 0.11 * i + (1 - i), 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.invert:
        return [
          1 - 2 * i, 0, 0, 0, 255 * i, //
          0, 1 - 2 * i, 0, 0, 255 * i, //
          0, 0, 1 - 2 * i, 0, 255 * i, //
          0, 0, 0, 1, 0,
        ];
      case FilterType.sepia:
        return [
          0.393 * i + (1 - i), 0.769 * i, 0.189 * i, 0, 0,
          0.349 * i, 0.686 * i + (1 - i), 0.168 * i, 0, 0,
          0.272 * i, 0.534 * i, 0.131 * i + (1 - i), 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.warm:
        return [
          1, 0, 0, 0, 25 * i, //
          0, 1, 0, 0, 12 * i, //
          0, 0, 1, 0, -25 * i, //
          0, 0, 0, 1, 0,
        ];
      case FilterType.cool:
        return [
          1, 0, 0, 0, -25 * i, //
          0, 1, 0, 0, 0, //
          0, 0, 1, 0, 25 * i, //
          0, 0, 0, 1, 0,
        ];
      case FilterType.vintage:
        // Cheap "vintage" approximation: desaturate slightly + warm tint +
        // lift blacks. Blended by intensity against identity.
        const List<double> vintage = [
          0.9, 0.1, 0.0, 0, 20.0,
          0.05, 0.85, 0.05, 0, 10.0,
          0.05, 0.1, 0.75, 0, -10.0,
          0, 0, 0, 1, 0,
        ];
        return _blend(identity, vintage, i);
      case FilterType.exposure:
      case FilterType.gamma:
      case FilterType.hue:
      case FilterType.sharpen:
      case FilterType.blur:
        // Not representable as a single linear colour matrix — see the
        // class doc comment. Rendered as identity in this matrix path;
        // wire these through dedicated renderer parameters at export time.
        return identity;
    }
  }

  static List<double> _blend(List<double> a, List<double> b, double t) {
    return List.generate(20, (idx) => a[idx] * (1 - t) + b[idx] * t);
  }

  /// Composes (multiplies) two 4x5 matrices in the order [second] ∘ [first]
  /// — i.e. [first] is applied to the pixel, then [second].
  static List<double> compose(List<double> first, List<double> second) {
    // Treat both as 5x5 with an implicit [0,0,0,0,1] last row so the
    // offset column composes correctly under matrix multiplication.
    List<double> to5x5(List<double> m) => [...m, 0, 0, 0, 0, 1];
    final a = to5x5(second);
    final b = to5x5(first);
    final result = List<double>.filled(25, 0);
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        var sum = 0.0;
        for (var k = 0; k < 5; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        result[row * 5 + col] = sum;
      }
    }
    return result.sublist(0, 20);
  }

  /// Folds every filter in [filters] into a single composed 4x5 matrix, or
  /// null if there are no colour-matrix-representable filters (so callers
  /// can skip wrapping in a `ColorFiltered`/matrix param entirely).
  static List<double>? combinedMatrixFor(List<FilterModel> filters) {
    if (filters.isEmpty) return null;
    var result = identity;
    var any = false;
    for (final filter in filters) {
      final m = matrixFor(filter);
      if (identical(m, identity) || m == identity) continue;
      result = compose(result, m);
      any = true;
    }
    return any ? result : null;
  }
}
