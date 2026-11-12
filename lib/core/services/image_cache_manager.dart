import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../errors/error_handler.dart';

class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._internal();
  ImageCacheManager._internal();

  // In-Memory LRU Cache for decoded image thumbnails (max 20 items)
  final Map<String, img.Image> _memoryThumbnailCache = {};
  final List<String> _lruOrder = [];
  static const int _maxMemoryCacheCount = 20;

  // Disk cache path map
  final Map<String, String> _diskCache = {};

  /// Obtains a downscaled thumbnail path for fast preview rendering.
  Future<String?> getThumbnailPath(String originalPath, {int maxDimension = 1080}) async {
    final cacheKey = '${originalPath}_$maxDimension';

    if (_diskCache.containsKey(cacheKey)) {
      final diskFile = File(_diskCache[cacheKey]!);
      if (await diskFile.exists() && await diskFile.length() > 0) {
        return diskFile.path;
      }
    }

    try {
      final file = File(originalPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final thumbnailPath = await compute(_generateThumbnailTask, {
        'bytes': bytes,
        'maxDimension': maxDimension,
        'cacheKey': cacheKey,
      });

      if (thumbnailPath != null) {
        _diskCache[cacheKey] = thumbnailPath;
      }
      return thumbnailPath;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ImageCacheManager.getThumbnailPath');
      return originalPath; // Fallback to original path on error
    }
  }

  /// Task executed in background isolate to generate thumbnail JPEG file
  static Future<String?> _generateThumbnailTask(Map<String, dynamic> params) async {
    try {
      final bytes = params['bytes'] as Uint8List;
      final maxDimension = params['maxDimension'] as int;

      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      img.Image thumbnail = decoded;
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        thumbnail = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDimension : null,
          height: decoded.height > decoded.width ? maxDimension : null,
          interpolation: img.Interpolation.linear,
        );
      }

      final encoded = img.encodeJpg(thumbnail, quality: 85);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/thumb_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(encoded, flush: true);
      return tempFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Store img.Image thumbnail in RAM LRU cache
  void putMemoryThumbnail(String key, img.Image thumbnail) {
    if (_memoryThumbnailCache.containsKey(key)) {
      _lruOrder.remove(key);
    } else if (_memoryThumbnailCache.length >= _maxMemoryCacheCount) {
      final oldest = _lruOrder.removeAt(0);
      _memoryThumbnailCache.remove(oldest);
    }
    _memoryThumbnailCache[key] = thumbnail;
    _lruOrder.add(key);
  }

  /// Get img.Image thumbnail from RAM cache
  img.Image? getMemoryThumbnail(String key) {
    if (_memoryThumbnailCache.containsKey(key)) {
      _lruOrder.remove(key);
      _lruOrder.add(key);
      return _memoryThumbnailCache[key];
    }
    return null;
  }

  /// Clears Flutter framework image rendering cache (RAM)
  void clearFlutterImageCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint('PaintingBinding imageCache cleared.');
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, 'ImageCacheManager.clearFlutterImageCache');
    }
  }

  /// Calculates total size of disk cache files in bytes
  Future<int> getDiskCacheSize() async {
    int totalSize = 0;
    for (final path in _diskCache.values) {
      try {
        final f = File(path);
        if (await f.exists()) {
          totalSize += await f.length();
        }
      } catch (_) {}
    }
    return totalSize;
  }

  /// Clears RAM, temp disk cache, and Flutter framework image cache
  Future<void> clearCache() async {
    _memoryThumbnailCache.clear();
    _lruOrder.clear();

    for (final path in _diskCache.values) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
    _diskCache.clear();
    clearFlutterImageCache();
  }
}
