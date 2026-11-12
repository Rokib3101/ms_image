import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../errors/app_exception.dart';
import '../errors/error_handler.dart';

class PipelineTaskToken {
  bool isCancelled = false;
  void cancel() {
    isCancelled = true;
  }
}

class ImagePipelineService {
  static final ImagePipelineService instance = ImagePipelineService._internal();
  ImagePipelineService._internal();

  // Active cancellation tokens indexed by task tag (e.g. "filters_preview")
  final Map<String, PipelineTaskToken> _activeTokens = {};

  /// Max recommended Megapixels for mobile Dart image manipulation (40 MP)
  static const int maxSupportedPixels = 40 * 1000 * 1000;

  /// Generates a new task token for [taskTag], automatically cancelling any active previous task for that tag.
  PipelineTaskToken createToken(String taskTag) {
    if (_activeTokens.containsKey(taskTag)) {
      _activeTokens[taskTag]?.cancel();
    }
    final token = PipelineTaskToken();
    _activeTokens[taskTag] = token;
    return token;
  }

  /// Checks if image dimensions exceed memory limits for safety.
  static bool isWithinSafeBounds(int width, int height) {
    return (width * height) <= maxSupportedPixels;
  }

  /// Runs an isolated task with TransferableTypedData zero-copy transfers when possible.
  Future<Uint8List?> runIsolatedTask({
    required String taskTag,
    required Uint8List inputBytes,
    required Uint8List Function(Uint8List bytes) operation,
  }) async {
    final token = createToken(taskTag);

    try {
      final inputTransfer = TransferableTypedData.fromList([inputBytes]);
      final resultBytes = await Isolate.run(() {
        final raw = inputTransfer.materialize().asUint8List();
        return operation(raw);
      });

      if (token.isCancelled) {
        debugPrint('⚠️ ImagePipelineService: Task [$taskTag] result discarded due to cancellation.');
        return null;
      }

      return resultBytes;
    } catch (e, stackTrace) {
      if (!token.isCancelled) {
        ErrorHandler.logError(e, stackTrace, 'ImagePipelineService.runIsolatedTask');
        throw ImageProcessingException(
          'ইমেজ প্রসেসিং করার সময় ত্রুটি ঘটেছে',
          e,
          stackTrace,
        );
      }
      return null;
    } finally {
      if (_activeTokens[taskTag] == token) {
        _activeTokens.remove(taskTag);
      }
    }
  }

  /// Runs a compute task on an Isolate with cancellation check upon completion.
  Future<R?> processWithCancellation<P, R>({
    required String taskTag,
    required ComputeCallback<P, R> callback,
    required P param,
  }) async {
    final token = createToken(taskTag);

    try {
      final result = await compute(callback, param);
      if (token.isCancelled) {
        debugPrint('⚠️ ImagePipelineService: Task [$taskTag] result discarded due to cancellation.');
        return null;
      }
      return result;
    } catch (e, stackTrace) {
      if (!token.isCancelled) {
        ErrorHandler.logError(e, stackTrace, 'ImagePipelineService.processWithCancellation');
        throw ImageProcessingException(
          'ইমেজ প্রসেসিং করার সময় ত্রুটি ঘটেছে',
          e,
          stackTrace,
        );
      }
      return null;
    } finally {
      if (_activeTokens[taskTag] == token) {
        _activeTokens.remove(taskTag);
      }
    }
  }

  /// Downscales an image for UI preview using a background isolate
  Future<Uint8List> downscaleForPreview({
    required Uint8List bytes,
    int maxSide = 1600,
    int quality = 85,
  }) async {
    try {
      final result = await Isolate.run(() {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          throw const ImageProcessingException('Cannot decode image format');
        }

        if (decoded.width <= maxSide && decoded.height <= maxSide) {
          return bytes;
        }

        final resized = img.copyResize(
          decoded,
          width: decoded.width > decoded.height ? maxSide : null,
          height: decoded.height > decoded.width ? maxSide : null,
          interpolation: img.Interpolation.linear,
        );

        return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      });

      return result;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ImagePipelineService.downscaleForPreview');
      throw ImageProcessingException(
        'ইমেজ প্রিভিউ ডাউনস্কেলিং করার সময় সমস্যা হয়েছে',
        e,
        stackTrace,
      );
    }
  }

  /// Explicitly cancels an active task by tag
  void cancelTask(String taskTag) {
    if (_activeTokens.containsKey(taskTag)) {
      _activeTokens[taskTag]?.cancel();
      _activeTokens.remove(taskTag);
      debugPrint('ℹ️ ImagePipelineService: Manually cancelled task [$taskTag]');
    }
  }

  /// Clean temp processing files from cache
  Future<void> cleanupTempFiles(List<String> tempPaths) async {
    for (final path in tempPaths) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
  }
}
