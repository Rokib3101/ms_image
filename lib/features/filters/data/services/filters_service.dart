import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/filters_type.dart';

class FiltersService {
  /// Applies [filterType] and optional [fineTune] settings to [inputImage].
  static img.Image applyFilter(
    img.Image inputImage,
    FiltersType filterType, {
    FiltersFineTuneSettings fineTune = const FiltersFineTuneSettings(),
  }) {
    img.Image workingImage = inputImage;
    if (workingImage.numChannels < 3) {
      workingImage = workingImage.convert(numChannels: 3);
    }

    img.Image filtered;
    switch (filterType) {
      case FiltersType.original:
        filtered = img.Image.from(workingImage);
        break;
      case FiltersType.magicColor:
        filtered = img.Image.from(workingImage);
        img.adjustColor(filtered, saturation: 1.35, contrast: 1.15, brightness: 1.05);
        _applySharpen(filtered, 0.3);
        break;
      case FiltersType.magicSharp:
        filtered = img.Image.from(workingImage);
        img.adjustColor(filtered, saturation: 1.25, contrast: 1.25, brightness: 1.02);
        _applySharpen(filtered, 0.6);
        break;
      case FiltersType.auto:
        filtered = img.Image.from(workingImage);
        img.adjustColor(filtered, saturation: 1.15, contrast: 1.1, brightness: 1.08);
        _applySharpen(filtered, 0.25);
        break;
      case FiltersType.shadow:
        filtered = img.Image.from(workingImage);
        _applyShadowLift(filtered, 1.2);
        break;
      case FiltersType.bw:
        filtered = img.grayscale(workingImage);
        break;
      case FiltersType.bwCrisp:
        filtered = img.grayscale(workingImage);
        img.adjustColor(filtered, contrast: 1.35);
        _applySharpen(filtered, 0.4);
        break;
      case FiltersType.grayscale:
        filtered = img.grayscale(workingImage);
        img.adjustColor(filtered, brightness: 1.05, contrast: 1.05);
        break;
      case FiltersType.lighten:
        filtered = img.Image.from(workingImage);
        img.adjustColor(filtered, brightness: 1.2, contrast: 1.05);
        break;
    }

    if (!fineTune.isDefault) {
      filtered = _applyFineTuning(filtered, fineTune);
    }

    return filtered;
  }

  static void _applySharpen(img.Image src, double amount) {
    if (amount <= 0) return;
    final w = src.width;
    final h = src.height;
    final clone = img.Image.from(src);

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final pC = clone.getPixel(x, y);
        final pT = clone.getPixel(x, y - 1);
        final pB = clone.getPixel(x, y + 1);
        final pL = clone.getPixel(x - 1, y);
        final pR = clone.getPixel(x + 1, y);

        final r = (pC.r * (1.0 + 4.0 * amount) - (pT.r + pB.r + pL.r + pR.r) * amount)
            .round()
            .clamp(0, 255);
        final g = (pC.g * (1.0 + 4.0 * amount) - (pT.g + pB.g + pL.g + pR.g) * amount)
            .round()
            .clamp(0, 255);
        final b = (pC.b * (1.0 + 4.0 * amount) - (pT.b + pB.b + pL.b + pR.b) * amount)
            .round()
            .clamp(0, 255);

        src.setPixelRgb(x, y, r, g, b);
      }
    }
  }

  static void _applyShadowLift(img.Image src, double factor) {
    final w = src.width;
    final h = src.height;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        double r = p.r.toDouble();
        double g = p.g.toDouble();
        double b = p.b.toDouble();

        double lum = 0.299 * r + 0.587 * g + 0.114 * b;
        if (lum < 128) {
          double lift = (1.0 - (lum / 128.0)) * 25.0 * factor;
          r = (r + lift).clamp(0, 255);
          g = (g + lift).clamp(0, 255);
          b = (b + lift).clamp(0, 255);
        }

        src.setPixelRgb(x, y, r.round(), g.round(), b.round());
      }
    }
  }

  static img.Image _applyFineTuning(
      img.Image src, FiltersFineTuneSettings tune) {
    final out = img.Image.from(src);

    double brightnessVal = 1.0 + (tune.brightness / 100.0);
    double contrastVal = 1.0 + (tune.contrast / 100.0);
    double saturationVal = 1.0 + (tune.saturation / 100.0);

    img.adjustColor(
      out,
      brightness: brightnessVal,
      contrast: contrastVal,
      saturation: saturationVal,
    );

    if (tune.sharpness > 0.0) {
      _applySharpen(out, (tune.sharpness / 100.0) * 0.5);
    }

    return out;
  }
}
