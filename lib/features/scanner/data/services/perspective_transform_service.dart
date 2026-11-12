import 'dart:math';
import 'dart:ui';
import 'package:image/image.dart' as img;

class PerspectiveTransformService {
  /// Applies a 4-point perspective warp on [sourceImage] given 4 corners in normalized coordinates (0.0 to 1.0).
  /// Order of corners: Top-Left, Top-Right, Bottom-Right, Bottom-Left.
  static img.Image transform({
    required img.Image sourceImage,
    required List<Offset> normalizedCorners,
  }) {
    if (normalizedCorners.length != 4) {
      return sourceImage;
    }

    final srcW = sourceImage.width;
    final srcH = sourceImage.height;

    // Convert normalized corners to pixel coordinates in source image
    final x0 =
        (normalizedCorners[0].dx * srcW).clamp(0.0, srcW.toDouble() - 1.0);
    final y0 =
        (normalizedCorners[0].dy * srcH).clamp(0.0, srcH.toDouble() - 1.0);

    final x1 =
        (normalizedCorners[1].dx * srcW).clamp(0.0, srcW.toDouble() - 1.0);
    final y1 =
        (normalizedCorners[1].dy * srcH).clamp(0.0, srcH.toDouble() - 1.0);

    final x2 =
        (normalizedCorners[2].dx * srcW).clamp(0.0, srcW.toDouble() - 1.0);
    final y2 =
        (normalizedCorners[2].dy * srcH).clamp(0.0, srcH.toDouble() - 1.0);

    final x3 =
        (normalizedCorners[3].dx * srcW).clamp(0.0, srcW.toDouble() - 1.0);
    final y3 =
        (normalizedCorners[3].dy * srcH).clamp(0.0, srcH.toDouble() - 1.0);

    // Calculate destination width and height based on max edge lengths
    final topW = sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
    final bottomW = sqrt((x2 - x3) * (x2 - x3) + (y2 - y3) * (y2 - y3));
    final destW = max(topW, bottomW).round().clamp(50, 4000);

    final leftH = sqrt((x3 - x0) * (x3 - x0) + (y3 - y0) * (y3 - y0));
    final rightH = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    final destH = max(leftH, rightH).round().clamp(50, 4000);

    // Solve perspective mapping parameters from unit square [0,1]^2 to quadrilateral (P0, P1, P2, P3)
    final dx1 = x1 - x2;
    final dx2 = x3 - x2;
    final sumX = x0 - x1 + x2 - x3;

    final dy1 = y1 - y2;
    final dy2 = y3 - y2;
    final sumY = y0 - y1 + y2 - y3;

    final det = dx1 * dy2 - dx2 * dy1;
    double g = 0.0;
    double h = 0.0;

    if (det.abs() > 1e-7) {
      g = (sumX * dy2 - sumY * dx2) / det;
      h = (dx1 * sumY - dy1 * sumX) / det;
    }

    final a = x1 - x0 + g * x1;
    final b = x3 - x0 + h * x3;
    final c = x0;
    final d = y1 - y0 + g * y1;
    final e = y3 - y0 + h * y3;
    final f = y0;

    final output = img.Image(width: destW, height: destH);

    final double wMinus1 = (destW > 1) ? (destW - 1).toDouble() : 1.0;
    final double hMinus1 = (destH > 1) ? (destH - 1).toDouble() : 1.0;

    for (int y = 0; y < destH; y++) {
      final v = y / hMinus1;
      final bvPlusC = b * v + c;
      final evPlusF = e * v + f;
      final hvPlus1 = h * v + 1.0;

      for (int x = 0; x < destW; x++) {
        final u = x / wMinus1;
        double denom = g * u + hvPlus1;
        if (denom.abs() < 1e-7) denom = 1e-7;

        final srcX = (a * u + bvPlusC) / denom;
        final srcY = (d * u + evPlusF) / denom;

        // Bilinear interpolation
        final pixel = _sampleBilinear(sourceImage, srcX, srcY, srcW, srcH);
        output.setPixel(x, y, pixel);
      }
    }

    return output;
  }

  static img.Color _sampleBilinear(
      img.Image image, double x, double y, int w, int h) {
    final xClamped = x.clamp(0.0, w - 1.0);
    final yClamped = y.clamp(0.0, h - 1.0);

    final x0 = xClamped.floor();
    final y0 = yClamped.floor();
    final x1 = min(x0 + 1, w - 1);
    final y1 = min(y0 + 1, h - 1);

    final fx = xClamped - x0;
    final fy = yClamped - y0;

    final p00 = image.getPixel(x0, y0);
    final p10 = image.getPixel(x1, y0);
    final p01 = image.getPixel(x0, y1);
    final p11 = image.getPixel(x1, y1);

    final r = _bilerp(p00.r, p10.r, p01.r, p11.r, fx, fy);
    final g = _bilerp(p00.g, p10.g, p01.g, p11.g, fx, fy);
    final b = _bilerp(p00.b, p10.b, p01.b, p11.b, fx, fy);
    final a = _bilerp(p00.a, p10.a, p01.a, p11.a, fx, fy);

    final result = image.getColor(r.round(), g.round(), b.round(), a.round());
    return result;
  }

  static double _bilerp(
      num v00, num v10, num v01, num v11, double fx, double fy) {
    final top = v00 + (v10 - v00) * fx;
    final bottom = v01 + (v11 - v01) * fx;
    return top + (bottom - top) * fy;
  }
}
