import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/scanner_filter_type.dart';

class ScannerFilterService {
  /// Applies the selected filter to [inputImage] and returns a new transformed image.
  static img.Image applyFilter(
      img.Image inputImage, ScannerFilterType filterType) {
    switch (filterType) {
      case ScannerFilterType.original:
        return img.Image.from(inputImage);
      case ScannerFilterType.auto:
        return _applyAuto(inputImage);
      case ScannerFilterType.shadow:
        return _applyShadowReduction(inputImage);
      case ScannerFilterType.enhanced:
        return _applyEnhanced(inputImage);
      case ScannerFilterType.grayscale:
        return _applyGrayscale(inputImage);
    }
  }

  /// Computes a smooth, continuous bilinear background illumination map.
  static List<Float64List> _computeBilinearIlluminationMap(
    img.Image src, {
    int step = 20,
    double percentile = 0.92,
  }) {
    final w = src.width;
    final h = src.height;
    final gridW = (w / step).ceil();
    final gridH = (h / step).ceil();

    final bgR = Float64List(gridW * gridH);
    final bgG = Float64List(gridW * gridH);
    final bgB = Float64List(gridW * gridH);

    for (int gy = 0; gy < gridH; gy++) {
      for (int gx = 0; gx < gridW; gx++) {
        final startX = gx * step;
        final startY = gy * step;
        final endX = min(startX + step, w);
        final endY = min(startY + step, h);

        final rVals = <int>[];
        final gVals = <int>[];
        final bVals = <int>[];

        for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
            final p = src.getPixel(x, y);
            rVals.add(p.r.toInt());
            gVals.add(p.g.toInt());
            bVals.add(p.b.toInt());
          }
        }

        final idxPos = gy * gridW + gx;
        if (rVals.isNotEmpty) {
          rVals.sort();
          gVals.sort();
          bVals.sort();
          final idx = ((rVals.length - 1) * percentile)
              .toInt()
              .clamp(0, rVals.length - 1);
          bgR[idxPos] = max(40.0, rVals[idx].toDouble());
          bgG[idxPos] = max(40.0, gVals[idx].toDouble());
          bgB[idxPos] = max(40.0, bVals[idx].toDouble());
        } else {
          bgR[idxPos] = 220.0;
          bgG[idxPos] = 220.0;
          bgB[idxPos] = 220.0;
        }
      }
    }

    return [
      bgR,
      bgG,
      bgB,
      Float64List.fromList(
          [gridW.toDouble(), gridH.toDouble(), step.toDouble()])
    ];
  }

  /// Looks up continuous background color at pixel (x, y) using bilinear interpolation.
  static void _getBilinearBg(
    List<Float64List> bgMap,
    double x,
    double y,
    double w,
    double h,
    List<double> outRgb,
  ) {
    final bgR = bgMap[0];
    final bgG = bgMap[1];
    final bgB = bgMap[2];
    final gridW = bgMap[3][0].toInt();
    final gridH = bgMap[3][1].toInt();
    final step = bgMap[3][2];

    final gxF = (x / step) - 0.5;
    final gyF = (y / step) - 0.5;

    final gx0 = gxF.floor().clamp(0, gridW - 1);
    final gx1 = (gx0 + 1).clamp(0, gridW - 1);
    final gy0 = gyF.floor().clamp(0, gridH - 1);
    final gy1 = (gy0 + 1).clamp(0, gridH - 1);

    final tx = (gxF - gx0).clamp(0.0, 1.0);
    final ty = (gyF - gy0).clamp(0.0, 1.0);

    final i00 = gy0 * gridW + gx0;
    final i10 = gy0 * gridW + gx1;
    final i01 = gy1 * gridW + gx0;
    final i11 = gy1 * gridW + gx1;

    final w00 = (1 - tx) * (1 - ty);
    final w10 = tx * (1 - ty);
    final w01 = (1 - tx) * ty;
    final w11 = tx * ty;

    outRgb[0] =
        w00 * bgR[i00] + w10 * bgR[i10] + w01 * bgR[i01] + w11 * bgR[i11];
    outRgb[1] =
        w00 * bgG[i00] + w10 * bgG[i10] + w01 * bgG[i01] + w11 * bgG[i11];
    outRgb[2] =
        w00 * bgB[i00] + w10 * bgB[i10] + w01 * bgB[i01] + w11 * bgB[i11];
  }

  /// Auto filter: Mild bilinear illumination flattening, subtle document contrast, and sharpening.
  static img.Image _applyAuto(img.Image src) {
    final w = src.width;
    final h = src.height;
    final out = img.Image(width: w, height: h);

    final bgMap =
        _computeBilinearIlluminationMap(src, step: 24, percentile: 0.92);
    final bgRgb = [220.0, 220.0, 220.0];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        _getBilinearBg(bgMap, x.toDouble(), y.toDouble(), w.toDouble(),
            h.toDouble(), bgRgb);

        final p = src.getPixel(x, y);

        double rNorm = (p.r / (bgRgb[0] + 1.0)) * 235.0;
        double gNorm = (p.g / (bgRgb[1] + 1.0)) * 235.0;
        double bNorm = (p.b / (bgRgb[2] + 1.0)) * 235.0;

        const contrast = 1.15;
        const brightness = 8.0;

        int r = (((rNorm - 128.0) * contrast) + 128.0 + brightness)
            .round()
            .clamp(0, 255);
        int g = (((gNorm - 128.0) * contrast) + 128.0 + brightness)
            .round()
            .clamp(0, 255);
        int b = (((bNorm - 128.0) * contrast) + 128.0 + brightness)
            .round()
            .clamp(0, 255);

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return _applyEdgeAwareSharpen(out, 0.25);
  }

  /// Shadow Reduction filter using bilinear background illumination division.
  static img.Image _applyShadowReduction(img.Image src) {
    final w = src.width;
    final h = src.height;
    final out = img.Image(width: w, height: h);

    final bgMap =
        _computeBilinearIlluminationMap(src, step: 20, percentile: 0.90);
    final bgRgb = [200.0, 200.0, 200.0];

    double avgBg = 0.0;
    for (int i = 0; i < bgMap[0].length; i++) {
      avgBg +=
          (0.299 * bgMap[0][i] + 0.587 * bgMap[1][i] + 0.114 * bgMap[2][i]);
    }
    avgBg = (avgBg / max(1, bgMap[0].length)).clamp(180.0, 240.0);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        _getBilinearBg(bgMap, x.toDouble(), y.toDouble(), w.toDouble(),
            h.toDouble(), bgRgb);

        final p = src.getPixel(x, y);

        final r = ((p.r / (bgRgb[0] + 1.0)) * avgBg).round().clamp(0, 255);
        final g = ((p.g / (bgRgb[1] + 1.0)) * avgBg).round().clamp(0, 255);
        final b = ((p.b / (bgRgb[2] + 1.0)) * avgBg).round().clamp(0, 255);

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return _applyEdgeAwareSharpen(out, 0.30);
  }

  /// Enhanced filter: Strong Magic Color processing with clean white paper background.
  static img.Image _applyEnhanced(img.Image src) {
    final w = src.width;
    final h = src.height;
    final out = img.Image(width: w, height: h);

    final bgMap =
        _computeBilinearIlluminationMap(src, step: 20, percentile: 0.92);
    final bgRgb = [220.0, 220.0, 220.0];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        _getBilinearBg(bgMap, x.toDouble(), y.toDouble(), w.toDouble(),
            h.toDouble(), bgRgb);

        final p = src.getPixel(x, y);

        double rNorm = (p.r / (bgRgb[0] + 1.0)) * 245.0;
        double gNorm = (p.g / (bgRgb[1] + 1.0)) * 245.0;
        double bNorm = (p.b / (bgRgb[2] + 1.0)) * 245.0;

        rNorm = rNorm.clamp(0.0, 255.0);
        gNorm = gNorm.clamp(0.0, 255.0);
        bNorm = bNorm.clamp(0.0, 255.0);

        final lum = 0.299 * rNorm + 0.587 * gNorm + 0.114 * bNorm;

        double rOut = rNorm;
        double gOut = gNorm;
        double bOut = bNorm;

        if (lum > 170.0) {
          final factor = ((lum - 170.0) / 85.0).clamp(0.0, 1.0);
          final knee = factor * factor;
          rOut = rOut + (255.0 - rOut) * knee;
          gOut = gOut + (255.0 - gOut) * knee;
          bOut = bOut + (255.0 - bOut) * knee;
        } else if (lum < 130.0) {
          final factor = ((130.0 - lum) / 130.0).clamp(0.0, 1.0);
          final darken = 1.0 - (0.35 * factor);
          rOut = (rOut * darken).clamp(0.0, 255.0);
          gOut = (gOut * darken).clamp(0.0, 255.0);
          bOut = (bOut * darken).clamp(0.0, 255.0);
        }

        out.setPixelRgb(
          x,
          y,
          rOut.round().clamp(0, 255),
          gOut.round().clamp(0, 255),
          bOut.round().clamp(0, 255),
        );
      }
    }

    return _applyEdgeAwareSharpen(out, 0.50);
  }

  /// Grayscale filter with paper whitening.
  static img.Image _applyGrayscale(img.Image src) {
    final w = src.width;
    final h = src.height;
    final out = img.Image(width: w, height: h);

    final bgMap =
        _computeBilinearIlluminationMap(src, step: 20, percentile: 0.92);
    final bgRgb = [220.0, 220.0, 220.0];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        _getBilinearBg(bgMap, x.toDouble(), y.toDouble(), w.toDouble(),
            h.toDouble(), bgRgb);

        final p = src.getPixel(x, y);
        final bgLum = 0.299 * bgRgb[0] + 0.587 * bgRgb[1] + 0.114 * bgRgb[2];

        final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        double normLum = (lum / (bgLum + 1.0)) * 245.0;

        if (normLum > 175.0) {
          final factor = ((normLum - 175.0) / 80.0).clamp(0.0, 1.0);
          normLum = normLum + (255.0 - normLum) * factor * factor;
        }

        final g = normLum.round().clamp(0, 255);
        out.setPixelRgb(x, y, g, g, g);
      }
    }

    return _applyEdgeAwareSharpen(out, 0.20);
  }

  /// Edge-Aware Smart Sharpening
  static img.Image _applyEdgeAwareSharpen(img.Image src, double amount) {
    if (amount <= 0) return src;

    final w = src.width;
    final h = src.height;
    final out = img.Image.from(src);

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final pC = src.getPixel(x, y);
        final pT = src.getPixel(x, y - 1);
        final pB = src.getPixel(x, y + 1);
        final pL = src.getPixel(x - 1, y);
        final pR = src.getPixel(x + 1, y);

        final lumC = 0.299 * pC.r + 0.587 * pC.g + 0.114 * pC.b;
        final lumT = 0.299 * pT.r + 0.587 * pT.g + 0.114 * pT.b;
        final lumB = 0.299 * pB.r + 0.587 * pB.g + 0.114 * pB.b;
        final lumL = 0.299 * pL.r + 0.587 * pL.g + 0.114 * pL.b;
        final lumR = 0.299 * pR.r + 0.587 * pR.g + 0.114 * pR.b;

        final gx = (lumR - lumL).abs();
        final gy = (lumB - lumT).abs();
        final grad = (gx + gy).clamp(0.0, 255.0);

        final edgeWeight = (grad / 50.0).clamp(0.0, 1.0);
        final effectiveAmount = amount * edgeWeight;

        final centerWeight = 1.0 + (4.0 * effectiveAmount);
        final neighborWeight = -effectiveAmount;

        final r =
            (pC.r * centerWeight + (pT.r + pB.r + pL.r + pR.r) * neighborWeight)
                .round()
                .clamp(0, 255);
        final g =
            (pC.g * centerWeight + (pT.g + pB.g + pL.g + pR.g) * neighborWeight)
                .round()
                .clamp(0, 255);
        final b =
            (pC.b * centerWeight + (pT.b + pB.b + pL.b + pR.b) * neighborWeight)
                .round()
                .clamp(0, 255);

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }
}
