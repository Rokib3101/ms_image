import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum MergeMode { horizontal, vertical, grid }

enum EnhancementPreset {
  auto,
  natural,
  document,
  cleanWhite,
  textClear,
  strongScan,
}

class EnhancementParams {
  final double strength;
  final double backgroundNormalization;
  final double shadowRemoval;
  final double contrast;
  final double brightness;
  final double sharpening;
  final double saturation;
  final bool isDocumentMode;

  EnhancementParams({
    this.strength = 0.5,
    this.backgroundNormalization = 0.5,
    this.shadowRemoval = 0.3,
    this.contrast = 0.0,
    this.brightness = 0.0,
    this.sharpening = 0.2,
    this.saturation = 0.0,
    this.isDocumentMode = false,
  });

  factory EnhancementParams.fromPreset(
      EnhancementPreset preset, double strength,
      {double documentConfidence = 0.5}) {
    switch (preset) {
      case EnhancementPreset.natural:
        return EnhancementParams(
          strength: strength,
          backgroundNormalization: strength * 0.3,
          shadowRemoval: strength * 0.2,
          contrast: strength * 0.1,
          brightness: strength * 0.05,
          sharpening: strength * 0.2,
          saturation: strength * 0.1,
          isDocumentMode: false,
        );
      case EnhancementPreset.document:
        return EnhancementParams(
          strength: strength,
          backgroundNormalization: 0.4 + (strength * 0.4),
          shadowRemoval: 0.3 + (strength * 0.4),
          contrast: 0.1 + (strength * 0.3),
          brightness: 0.1,
          sharpening: 0.2 + (strength * 0.3),
          saturation: -0.1,
          isDocumentMode: true,
        );
      case EnhancementPreset.cleanWhite:
        return EnhancementParams(
          strength: strength,
          backgroundNormalization: 0.7 + (strength * 0.3),
          shadowRemoval: 0.5 + (strength * 0.4),
          contrast: 0.2 + (strength * 0.4),
          brightness: 0.15,
          sharpening: 0.3,
          saturation: -0.3,
          isDocumentMode: true,
        );
      case EnhancementPreset.textClear:
        return EnhancementParams(
          strength: strength,
          backgroundNormalization: 0.5,
          shadowRemoval: 0.4,
          contrast: 0.6 + (strength * 0.4),
          brightness: -0.05,
          sharpening: 0.5 + (strength * 0.5),
          saturation: -1.0, // Black and white
          isDocumentMode: true,
        );
      case EnhancementPreset.strongScan:
        return EnhancementParams(
          strength: strength,
          backgroundNormalization: 0.9,
          shadowRemoval: 0.8,
          contrast: 0.5,
          brightness: 0.2,
          sharpening: 0.6,
          saturation: -0.2,
          isDocumentMode: true,
        );
      case EnhancementPreset.auto:
      default:
        bool isDoc = documentConfidence > 0.4;
        if (isDoc) {
          return EnhancementParams.fromPreset(
              EnhancementPreset.document, strength);
        } else {
          return EnhancementParams.fromPreset(
              EnhancementPreset.natural, strength);
        }
    }
  }
}

class ImageProcessingLogic {
  /// Merges multiple images based on the mode.
  static Future<String?> mergeImages({
    required List<String> imagePaths,
    required MergeMode mode,
    int spacing = 0,
    int? backgroundColor, // 0xAABBGGRR
  }) async {
    if (imagePaths.isEmpty) return null;

    final List<img.Image> images = [];
    for (var path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) images.add(decoded);
    }

    if (images.isEmpty) return null;

    img.Image? result;

    switch (mode) {
      case MergeMode.horizontal:
        result = _mergeHorizontal(images, spacing, backgroundColor);
        break;
      case MergeMode.vertical:
        result = _mergeVertical(images, spacing, backgroundColor);
        break;
      case MergeMode.grid:
        result = _mergeGrid(images, spacing, backgroundColor);
        break;
    }

    if (result == null) return null;

    final tempDir = await getTemporaryDirectory();
    final fileName = 'merged_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = p.join(tempDir.path, fileName);

    final encoded = img.encodePng(result);
    await File(filePath).writeAsBytes(encoded);

    return filePath;
  }

  static img.Image _mergeHorizontal(
      List<img.Image> images, int spacing, int? bg) {
    int totalWidth = (images.length - 1) * spacing;
    int maxHeight = 0;

    for (var image in images) {
      totalWidth += image.width;
      maxHeight = max(maxHeight, image.height);
    }

    final result = img.Image(width: totalWidth, height: maxHeight);
    if (bg != null)
      result.clear(img.ColorUint32.rgba(
          bg >> 24, (bg >> 16) & 0xFF, (bg >> 8) & 0xFF, bg & 0xFF));

    int xOffset = 0;
    for (var image in images) {
      img.compositeImage(result, image,
          dstX: xOffset, dstY: (maxHeight - image.height) ~/ 2);
      xOffset += image.width + spacing;
    }

    return result;
  }

  static img.Image _mergeVertical(
      List<img.Image> images, int spacing, int? bg) {
    int totalHeight = (images.length - 1) * spacing;
    int maxWidth = 0;

    for (var image in images) {
      totalHeight += image.height;
      maxWidth = max(maxWidth, image.width);
    }

    final result = img.Image(width: maxWidth, height: totalHeight);
    if (bg != null)
      result.clear(img.ColorUint32.rgba(
          bg >> 24, (bg >> 16) & 0xFF, (bg >> 8) & 0xFF, bg & 0xFF));

    int yOffset = 0;
    for (var image in images) {
      img.compositeImage(result, image,
          dstX: (maxWidth - image.width) ~/ 2, dstY: yOffset);
      yOffset += image.height + spacing;
    }

    return result;
  }

  static img.Image _mergeGrid(List<img.Image> images, int spacing, int? bg) {
    int columns = sqrt(images.length).ceil();
    int rows = (images.length / columns).ceil();

    int cellWidth = 0;
    int cellHeight = 0;

    for (var image in images) {
      cellWidth = max(cellWidth, image.width);
      cellHeight = max(cellHeight, image.height);
    }

    int totalWidth = (columns * cellWidth) + ((columns - 1) * spacing);
    int totalHeight = (rows * cellHeight) + ((rows - 1) * spacing);

    final result = img.Image(width: totalWidth, height: totalHeight);
    if (bg != null)
      result.clear(img.ColorUint32.rgba(
          bg >> 24, (bg >> 16) & 0xFF, (bg >> 8) & 0xFF, bg & 0xFF));

    for (int i = 0; i < images.length; i++) {
      int col = i % columns;
      int row = i ~/ columns;

      int x = col * (cellWidth + spacing) + (cellWidth - images[i].width) ~/ 2;
      int y =
          row * (cellHeight + spacing) + (cellHeight - images[i].height) ~/ 2;

      img.compositeImage(result, images[i], dstX: x, dstY: y);
    }

    return result;
  }

  /// Creates a resized preview image for faster processing without blocking UI thread
  static Future<String?> createPreviewImage({
    required String imagePath,
    int maxDimension = 1200,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      
      final tempDir = await getTemporaryDirectory();
      final fileName = 'preview_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = p.join(tempDir.path, fileName);

      final resultBytes = await Isolate.run(() {
        final img.Image? source = img.decodeImage(bytes);
        if (source == null) return null;

        if (source.width <= maxDimension && source.height <= maxDimension) {
          return bytes;
        }

        img.Image resized;
        if (source.width > source.height) {
          resized = img.copyResize(source,
              width: maxDimension, interpolation: img.Interpolation.linear);
        } else {
          resized = img.copyResize(source,
              height: maxDimension, interpolation: img.Interpolation.linear);
        }

        return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      });

      if (resultBytes == null) return null;

      await File(filePath).writeAsBytes(resultBytes);
      return filePath;
    } catch (e) {
      debugPrint('Preview Creation Error: $e');
      return null;
    }
  }

  /// Magic Colour 2.0 Enhancement (Modular pipeline)
  static Future<String?> enhanceImage({
    required String imagePath,
    double strength = 0.5,
    EnhancementPreset preset = EnhancementPreset.auto,
  }) async {
    return compute(_enhanceImageWorker, {
      'imagePath': imagePath,
      'strength': strength,
      'preset': preset,
    });
  }

  static Future<String?> _enhanceImageWorker(Map<String, dynamic> args) async {
    try {
      final String imagePath = args['imagePath'];
      final double strength = args['strength'];
      final EnhancementPreset preset = args['preset'];

      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Ensure RGBA
      if (image.numChannels != 4) {
        image = image.convert(numChannels: 4);
      }

      // 1. Analyze image for document characteristics
      double docConfidence = _calculateDocumentConfidence(image);
      final params = EnhancementParams.fromPreset(preset, strength,
          documentConfidence: docConfidence);

      // 2. Background/Illumination Estimation (Robust percentile-based)
      const int blockSize = 32;
      final illuminationMap =
          _estimateIllumination(image, blockSize: blockSize, percentile: 0.95);

      // 3. Background Normalization & Shadow Removal
      var result = _applyIlluminationCorrection(
        image,
        illuminationMap,
        blockSize,
        params.backgroundNormalization,
        params.shadowRemoval,
        params.isDocumentMode,
      );

      // 4. Contrast, Brightness & Saturation
      if (params.contrast != 0 ||
          params.brightness != 0 ||
          params.saturation != 0) {
        img.adjustColor(
          result,
          contrast: 1.0 + params.contrast,
          brightness: 1.0 + params.brightness,
          saturation: 1.0 + params.saturation,
        );
      }

      // 5. Edge-Aware Sharpening (approximate)
      if (params.sharpening > 0) {
        final double sharp = params.sharpening;
        img.convolution(result, filter: [
          0,
          -sharp,
          0,
          -sharp,
          1 + 4 * sharp,
          -sharp,
          0,
          -sharp,
          0
        ]);
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'enhanced_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = p.join(tempDir.path, fileName);

      await File(filePath).writeAsBytes(img.encodePng(result));
      return filePath;
    } catch (e) {
      return null;
    }
  }

  static double _calculateDocumentConfidence(img.Image image) {
    // Sample some pixels to check for high-key background
    int brightCount = 0;
    const int samples = 100;
    final random = Random(42);

    for (int i = 0; i < samples; i++) {
      int x = random.nextInt(image.width);
      int y = random.nextInt(image.height);
      final p = image.getPixel(x, y);
      double lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      if (lum > 180) brightCount++;
    }

    return (brightCount / samples).clamp(0.0, 1.0);
  }

  static List<List<List<double>>> _estimateIllumination(img.Image image,
      {required int blockSize, double percentile = 0.95}) {
    final int blocksX = (image.width / blockSize).ceil();
    final int blocksY = (image.height / blockSize).ceil();

    final List<List<List<double>>> map = List.generate(
        blocksY, (_) => List.generate(blocksX, (_) => [255.0, 255.0, 255.0]));

    for (int by = 0; by < blocksY; by++) {
      for (int bx = 0; bx < blocksX; bx++) {
        final List<int> rValues = [];
        final List<int> gValues = [];
        final List<int> bValues = [];

        final startX = bx * blockSize;
        final startY = by * blockSize;
        final endX = min(startX + blockSize, image.width);
        final endY = min(startY + blockSize, image.height);

        for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
            final pixel = image.getPixel(x, y);
            rValues.add(pixel.r.toInt());
            gValues.add(pixel.g.toInt());
            bValues.add(pixel.b.toInt());
          }
        }

        if (rValues.isEmpty) continue;

        rValues.sort();
        gValues.sort();
        bValues.sort();

        int idx = ((rValues.length - 1) * percentile).toInt();
        map[by][bx] = [
          max(1.0, rValues[idx].toDouble()),
          max(1.0, gValues[idx].toDouble()),
          max(1.0, bValues[idx].toDouble()),
        ];
      }
    }
    return map;
  }

  static img.Image _applyIlluminationCorrection(
    img.Image image,
    List<List<List<double>>> illuminationMap,
    int blockSize,
    double normalizationAmount,
    double shadowRemovalAmount,
    bool isDocumentMode,
  ) {
    final int blocksY = illuminationMap.length;
    final int blocksX = illuminationMap[0].length;
    final result =
        img.Image(width: image.width, height: image.height, numChannels: 4);

    for (int y = 0; y < image.height; y++) {
      final double fby = (y / blockSize).clamp(0.0, blocksY - 1.0);
      final int by0 = fby.floor();
      final int by1 = min(by0 + 1, blocksY - 1);
      final double dy = fby - by0;

      for (int x = 0; x < image.width; x++) {
        final double fbx = (x / blockSize).clamp(0.0, blocksX - 1.0);
        final int bx0 = fbx.floor();
        final int bx1 = min(bx0 + 1, blocksX - 1);
        final double dx = fbx - bx0;

        final double bgR = _bilinear(
            illuminationMap[by0][bx0][0],
            illuminationMap[by0][bx1][0],
            illuminationMap[by1][bx0][0],
            illuminationMap[by1][bx1][0],
            dx,
            dy);
        final double bgG = _bilinear(
            illuminationMap[by0][bx0][1],
            illuminationMap[by0][bx1][1],
            illuminationMap[by1][bx0][1],
            illuminationMap[by1][bx1][1],
            dx,
            dy);
        final double bgB = _bilinear(
            illuminationMap[by0][bx0][2],
            illuminationMap[by0][bx1][2],
            illuminationMap[by1][bx0][2],
            illuminationMap[by1][bx1][2],
            dx,
            dy);

        final pixel = image.getPixel(x, y);

        // Division: New = (Old / Background) * 255
        // Independent correction (for documents)
        double indR = (pixel.r / bgR) * 255;
        double indG = (pixel.g / bgG) * 255;
        double indB = (pixel.b / bgB) * 255;

        // Luminance-based correction (for photos)
        double bgL = 0.299 * bgR + 0.587 * bgG + 0.114 * bgB;
        double scale = 255 / max(1.0, bgL);
        double lumR = pixel.r * scale;
        double lumG = pixel.g * scale;
        double lumB = pixel.b * scale;

        // Choose base based on mode
        double targetR = isDocumentMode ? indR : lumR;
        double targetG = isDocumentMode ? indG : lumG;
        double targetB = isDocumentMode ? indB : lumB;

        // Apply normalization amount
        double finalR = _lerp(pixel.r.toDouble(), targetR, normalizationAmount);
        double finalG = _lerp(pixel.g.toDouble(), targetG, normalizationAmount);
        double finalB = _lerp(pixel.b.toDouble(), targetB, normalizationAmount);

        result.setPixel(
            x,
            y,
            img.ColorUint32.rgba(
                finalR.toInt().clamp(0, 255),
                finalG.toInt().clamp(0, 255),
                finalB.toInt().clamp(0, 255),
                pixel.a.toInt()));
      }
    }
    return result;
  }

  static double _lerp(double a, double b, double t) => a * (1 - t) + b * t;

  static double _bilinear(
      double v00, double v01, double v10, double v11, double dx, double dy) {
    return v00 * (1 - dx) * (1 - dy) +
        v01 * dx * (1 - dy) +
        v10 * (1 - dx) * dy +
        v11 * dx * dy;
  }

  /// Image Overlay
  static Future<String?> overlayImages({
    required String backgroundPath,
    required String foregroundPath,
    required Rect
        foregroundRect, // Normalized 0-1 or actual pixel? Let's use actual pixels relative to background size.
  }) async {
    final bgBytes = await File(backgroundPath).readAsBytes();
    final fgBytes = await File(foregroundPath).readAsBytes();

    final bg = img.decodeImage(bgBytes);
    final fg = img.decodeImage(fgBytes);

    if (bg == null || fg == null) return null;

    // Resize foreground to match target rect
    final resizedFg = img.copyResize(
      fg,
      width: foregroundRect.width.toInt(),
      height: foregroundRect.height.toInt(),
      interpolation: img.Interpolation.linear,
    );

    img.compositeImage(
      bg,
      resizedFg,
      dstX: foregroundRect.left.toInt(),
      dstY: foregroundRect.top.toInt(),
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'overlay_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = p.join(tempDir.path, fileName);

    await File(filePath).writeAsBytes(img.encodePng(bg));
    return filePath;
  }

  /// Independent Corner Crop (Perspective Warp)
  static Future<String?> perspectiveCrop({
    required String imagePath,
    required Point<int> topLeft,
    required Point<int> topRight,
    required Point<int> bottomLeft,
    required Point<int> bottomRight,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final rectified = img.copyRectify(
      image,
      topLeft: img.Point(topLeft.x, topLeft.y),
      topRight: img.Point(topRight.x, topRight.y),
      bottomLeft: img.Point(bottomLeft.x, bottomLeft.y),
      bottomRight: img.Point(bottomRight.x, bottomRight.y),
      interpolation: img.Interpolation.linear,
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'crop_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = p.join(tempDir.path, fileName);

    await File(filePath).writeAsBytes(img.encodePng(rectified));
    return filePath;
  }
}
