import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../scanner/data/services/document_detection_service.dart';
import '../../scanner/data/services/perspective_transform_service.dart';
import '../../scanner/data/services/scanner_storage_service.dart';
import '../../../../core/services/image_cache_manager.dart';
import '../../../../core/services/image_pipeline_service.dart';

class CropRepository {
  Future<String?> getThumbnail(String imagePath, {int maxDimension = 1200}) async {
    return ImageCacheManager.instance.getThumbnailPath(imagePath, maxDimension: maxDimension);
  }

  Future<img.Image?> decodeImageBytes(Uint8List bytes) async {
    return compute(_decodeBytes, bytes);
  }

  Future<DocumentDetectionResult> detectDocumentCorners(img.Image decoded) async {
    return compute(DocumentDetectionService.detectDocument, decoded);
  }

  Future<String?> processPreview({
    required Uint8List bytes,
    required List<Offset> corners,
  }) async {
    return ImagePipelineService.instance.processWithCancellation<Map<String, Object>, String?>(
      taskTag: 'crop_preview',
      callback: _processCropInBackground,
      param: {
        'bytes': bytes,
        'corners': corners,
      },
    );
  }

  Future<List<String>> saveCroppedDocument({
    required String originalImagePath,
    required List<Offset> corners,
    required String baseName,
    required OutputFormat format,
    required int quality,
  }) async {
    final bytes = await File(originalImagePath).readAsBytes();
    final croppedPath = await ImagePipelineService.instance.processWithCancellation<Map<String, Object>, String?>(
      taskTag: 'crop_save',
      callback: _processCropInBackground,
      param: {
        'bytes': bytes,
        'corners': corners,
      },
    );

    if (croppedPath == null) return [];

    final decoded = img.decodeImage(await File(croppedPath).readAsBytes());
    if (decoded == null) return [];

    final savedPath = await ScannerStorageService.saveImage(
      image: decoded,
      baseName: baseName,
      format: format,
      quality: quality,
      pageIndex: 0,
      totalPages: 1,
    );

    return savedPath != null ? [savedPath] : [];
  }
}

img.Image? _decodeBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  return decoded != null ? img.bakeOrientation(decoded) : null;
}

String? _processCropInBackground(Map<String, Object> params) {
  try {
    final bytes = params['bytes'] as Uint8List;
    final corners = params['corners'] as List<Offset>;

    final original = img.decodeImage(bytes);
    if (original == null) return null;

    final oriented = img.bakeOrientation(original);

    final warped = PerspectiveTransformService.transform(
      sourceImage: oriented,
      normalizedCorners: corners,
    );

    final encoded = img.encodeJpg(warped, quality: 90);
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/crop_${DateTime.now().microsecondsSinceEpoch}.jpg');
    tempFile.writeAsBytesSync(encoded);

    return tempFile.path;
  } catch (e) {
    return null;
  }
}
