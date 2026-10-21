/// Formatting helpers for [Duration], used by the timeline, trim handles
/// and playback clock in the editor.
extension DurationExtensions on Duration {
  /// `mm:ss` for durations under an hour, `h:mm:ss` otherwise.
  String toTimecode() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Frame-accurate timecode, e.g. `00:12:03.24` for 24 fps.
  String toFrameTimecode(double fps) {
    final base = toTimecode();
    final frameCount = ((inMilliseconds % 1000) / (1000 / fps)).floor();
    return '$base.${frameCount.toString().padLeft(2, '0')}';
  }
}
