import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';
import 'package:flutter/material.dart' show Size;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import '../config/app_config.dart';
import 'logger_service.dart';

/// Generates and disk-caches video frame thumbnails used by the timeline
/// strip, project cards and the trim-handle preview.
///
/// Thumbnails are generated through `pro_video_editor`'s native thumbnail
/// pipeline (`ProVideoEditor.instance.getThumbnail`), which runs off the UI
/// isolate on the platform side, then persisted under the app's cache
/// directory keyed by a hash of `(sourcePath, timestampMs, size)` so repeat
/// requests for the same frame are disk-cache hits instead of re-decodes.
///
/// API-surface note: the `ThumbnailConfigs`/`ThumbnailFormat`/`Size`
/// signature below is written against the documented thumbnail-generation
/// surface, but — like the render pipeline in
/// `data/repository/editor_repository_impl.dart` — should be diffed
/// against your installed `pro_video_editor` version's API docs before
/// shipping. `Size` here needs to resolve to whichever the plugin expects
/// (Flutter's `dart:ui`/`package:flutter` `Size`, or a package-specific
/// type) — add the matching import if analysis flags it as undefined.
class ThumbnailCacheService {
  ThumbnailCacheService._internal();
  static final ThumbnailCacheService instance =
      ThumbnailCacheService._internal();

  Directory? _cacheDir;

  Future<Directory> _resolveCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'thumb_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _keyFor(String sourcePath, Duration timestamp, int width) {
    final raw = '$sourcePath|${timestamp.inMilliseconds}|$width';
    return crypto.sha1.convert(utf8.encode(raw)).toString();
  }

  /// Returns a single JPEG-encoded thumbnail frame, using the on-disk cache
  /// when available.
  Future<Uint8List> getFrame({
    required String sourcePath,
    required Duration timestamp,
    int width = 240,
  }) async {
    final dir = await _resolveCacheDir();
    final key = _keyFor(sourcePath, timestamp, width);
    final file = File(p.join(dir.path, '$key.jpg'));

    if (await file.exists()) {
      return file.readAsBytes();
    }

    final frames = await ProVideoEditor.instance.getThumbnails(
      ThumbnailConfigs(
        video: EditorVideo.file(File(sourcePath)),
        timestamps: [timestamp],
        outputFormat: ThumbnailFormat.jpeg,
        outputSize: Size(width.toDouble(), width.toDouble()),
      ),
    );
    final bytes = frames.first;

    await file.writeAsBytes(bytes, flush: false);
    await _evictIfOverBudget(dir);
    return bytes;
  }

  /// Generates an evenly spaced strip of thumbnails for the timeline, e.g.
  /// one frame every second of the clip.
  Future<List<Uint8List>> getStrip({
    required String sourcePath,
    required Duration videoDuration,
    required int frameCount,
    int width = 160,
  }) async {
    if (frameCount <= 0) return [];
    final step = videoDuration.inMilliseconds / frameCount;
    final frames = <Uint8List>[];
    for (var i = 0; i < frameCount; i++) {
      final ts = Duration(milliseconds: (step * i).round());
      frames.add(
          await getFrame(sourcePath: sourcePath, timestamp: ts, width: width));
    }
    return frames;
  }

  Future<void> _evictIfOverBudget(Directory dir) async {
    try {
      final files = await dir.list().toList();
      var totalBytes = 0;
      final entries = <MapEntry<File, FileStat>>[];
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          totalBytes += stat.size;
          entries.add(MapEntry(entity, stat));
        }
      }

      const budgetBytes = AppConfig.thumbnailCacheBudgetMb * 1024 * 1024;
      if (totalBytes <= budgetBytes) return;

      // LRU eviction: oldest-accessed first until back under budget.
      entries.sort((a, b) => a.value.accessed.compareTo(b.value.accessed));
      for (final entry in entries) {
        if (totalBytes <= budgetBytes) break;
        totalBytes -= entry.value.size;
        await entry.key.delete();
      }
    } catch (e, st) {
      LoggerService.instance.w('Thumbnail cache eviction failed: $e\n$st');
    }
  }

  Future<void> clearAll() async {
    final dir = await _resolveCacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }
}
