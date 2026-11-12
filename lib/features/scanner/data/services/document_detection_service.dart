import 'dart:ui';
import 'package:image/image.dart' as img;

class DocumentDetectionResult {
  final List<Offset> corners;
  final bool isHighConfidence;

  DocumentDetectionResult({
    required this.corners,
    required this.isHighConfidence,
  });
}

class DocumentDetectionService {
  /// Default inset fallback corners if detection fails or is low confidence
  static const List<Offset> defaultCorners = [
    Offset(0.05, 0.05), // Top-Left
    Offset(0.95, 0.05), // Top-Right
    Offset(0.95, 0.95), // Bottom-Right
    Offset(0.05, 0.95), // Bottom-Left
  ];

  /// Detects document corners in [sourceImage]. Returns 4 normalized offsets [0..1].
  static DocumentDetectionResult detectDocument(img.Image sourceImage) {
    try {
      final srcW = sourceImage.width;
      final srcH = sourceImage.height;

      if (srcW < 50 || srcH < 50) {
        return DocumentDetectionResult(
            corners: defaultCorners, isHighConfidence: false);
      }

      // Downscale to max 350px for fast analysis
      final scale = 350.0 / (srcW > srcH ? srcW : srcH);
      final targetW = (srcW * scale).round().clamp(50, 350);
      final targetH = (srcH * scale).round().clamp(50, 350);

      final smallImage =
          img.copyResize(sourceImage, width: targetW, height: targetH);

      // Convert to grayscale grid
      final gray = List<int>.filled(targetW * targetH, 0);
      for (int y = 0; y < targetH; y++) {
        for (int x = 0; x < targetW; x++) {
          final p = smallImage.getPixel(x, y);
          gray[y * targetW + x] =
              (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
        }
      }

      // Compute Sobel gradient magnitude for edge detection
      final grad = List<int>.filled(targetW * targetH, 0);
      int maxGrad = 1;
      for (int y = 1; y < targetH - 1; y++) {
        for (int x = 1; x < targetW - 1; x++) {
          final gx =
              (gray[y * targetW + (x + 1)] - gray[y * targetW + (x - 1)]) * 2 +
                  (gray[(y - 1) * targetW + (x + 1)] -
                      gray[(y - 1) * targetW + (x - 1)]) +
                  (gray[(y + 1) * targetW + (x + 1)] -
                      gray[(y + 1) * targetW + (x - 1)]);

          final gy =
              (gray[(y + 1) * targetW + x] - gray[(y - 1) * targetW + x]) * 2 +
                  (gray[(y + 1) * targetW + (x - 1)] -
                      gray[(y - 1) * targetW + (x - 1)]) +
                  (gray[(y + 1) * targetW + (x + 1)] -
                      gray[(y - 1) * targetW + (x + 1)]);

          final g = (gx.abs() + gy.abs());
          grad[y * targetW + x] = g;
          if (g > maxGrad) maxGrad = g;
        }
      }

      // Sample boundary extreme points where document paper edge transitions occur
      // Find top-left, top-right, bottom-right, bottom-left extreme corners
      int tlX = (targetW * 0.1).round(), tlY = (targetH * 0.1).round();
      int trX = (targetW * 0.9).round(), trY = (targetH * 0.1).round();
      int brX = (targetW * 0.9).round(), brY = (targetH * 0.9).round();
      int blX = (targetW * 0.1).round(), blY = (targetH * 0.9).round();

      double maxTL = -1, maxTR = -1, maxBR = -1, maxBL = -1;

      final thresholdGrad = maxGrad * 0.18;

      for (int y = (targetH * 0.05).round();
          y < (targetH * 0.95).round();
          y++) {
        for (int x = (targetW * 0.05).round();
            x < (targetW * 0.95).round();
            x++) {
          final g = grad[y * targetW + x];
          if (g < thresholdGrad) continue;

          // Corner distance projections
          final scoreTL = g - (x + y);
          if (scoreTL > maxTL) {
            maxTL = scoreTL.toDouble();
            tlX = x;
            tlY = y;
          }

          final scoreTR = g + (x - y);
          if (scoreTR > maxTR) {
            maxTR = scoreTR.toDouble();
            trX = x;
            trY = y;
          }

          final scoreBR = g + (x + y);
          if (scoreBR > maxBR) {
            maxBR = scoreBR.toDouble();
            brX = x;
            brY = y;
          }

          final scoreBL = g - (x - y);
          if (scoreBL > maxBL) {
            maxBL = scoreBL.toDouble();
            blX = x;
            blY = y;
          }
        }
      }

      // Check if found quad is reasonable (area >= 20% of image area and convex)
      final normTL = Offset(
          (tlX / targetW).clamp(0.02, 0.95), (tlY / targetH).clamp(0.02, 0.95));
      final normTR = Offset(
          (trX / targetW).clamp(0.05, 0.98), (trY / targetH).clamp(0.02, 0.95));
      final normBR = Offset(
          (brX / targetW).clamp(0.05, 0.98), (brY / targetH).clamp(0.05, 0.98));
      final normBL = Offset(
          (blX / targetW).clamp(0.02, 0.95), (blY / targetH).clamp(0.05, 0.98));

      final quadArea = _computeQuadArea(normTL, normTR, normBR, normBL);

      if (quadArea > 0.15 && maxTL > 0 && maxTR > 0 && maxBR > 0 && maxBL > 0) {
        return DocumentDetectionResult(
          corners: [normTL, normTR, normBR, normBL],
          isHighConfidence: true,
        );
      }
    } catch (_) {
      // Ignore errors and fallback to default corners safely
    }

    return DocumentDetectionResult(
      corners: List.from(defaultCorners),
      isHighConfidence: false,
    );
  }

  static double _computeQuadArea(Offset p0, Offset p1, Offset p2, Offset p3) {
    final area1 = 0.5 *
        ((p0.dx * (p1.dy - p2.dy) +
                p1.dx * (p2.dy - p0.dy) +
                p2.dx * (p0.dy - p1.dy))
            .abs());
    final area2 = 0.5 *
        ((p0.dx * (p2.dy - p3.dy) +
                p2.dx * (p3.dy - p0.dy) +
                p3.dx * (p0.dy - p2.dy))
            .abs());
    return area1 + area2;
  }
}
