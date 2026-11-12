import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class TextOverlayData {
  final String id;
  final String text;
  final Offset
      positionRatio; // Offset in 0.0 to 1.0 relative to image width/height
  final Color textColor;
  final Color? backgroundColor;
  final double fontSize;
  final bool hasShadow;
  final double rotation; // In radians (0.0 to 2*pi)
  final double opacity; // 0.0 to 1.0

  TextOverlayData({
    required this.id,
    required this.text,
    required this.positionRatio,
    required this.textColor,
    this.backgroundColor,
    this.fontSize = 28.0,
    this.hasShadow = true,
    this.rotation = 0.0,
    this.opacity = 1.0,
  });

  TextOverlayData copyWith({
    String? id,
    String? text,
    Offset? positionRatio,
    Color? textColor,
    Color? backgroundColor,
    double? fontSize,
    bool? hasShadow,
    double? rotation,
    double? opacity,
  }) {
    return TextOverlayData(
      id: id ?? this.id,
      text: text ?? this.text,
      positionRatio: positionRatio ?? this.positionRatio,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontSize: fontSize ?? this.fontSize,
      hasShadow: hasShadow ?? this.hasShadow,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
    );
  }
}

class TextOverlayService {
  /// Bakes text overlays onto an image file and returns path to new temporary image file.
  static Future<String?> renderTextOverlay({
    required String imagePath,
    required List<TextOverlayData> overlays,
  }) async {
    if (overlays.isEmpty) return imagePath;

    try {
      final file = File(imagePath);
      if (!file.existsSync()) return imagePath;

      final bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      );

      // Draw original image
      canvas.drawImage(image, Offset.zero, Paint());

      for (final overlay in overlays) {
        if (overlay.text.trim().isEmpty) continue;

        // Scale font size based on image height relative to a standard 800px height
        final scaledFontSize =
            overlay.fontSize * (image.height / 800.0).clamp(0.5, 4.0);

        final textStyle = TextStyle(
          color: overlay.textColor,
          fontSize: scaledFontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
          shadows: overlay.hasShadow
              ? [
                  Shadow(
                    offset:
                        Offset(scaledFontSize * 0.05, scaledFontSize * 0.05),
                    blurRadius: scaledFontSize * 0.15,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ]
              : null,
        );

        final textPainter = TextPainter(
          text: TextSpan(text: overlay.text, style: textStyle),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: image.width.toDouble() * 0.95);

        final x = (overlay.positionRatio.dx * image.width)
            .clamp(0.0, image.width.toDouble() - textPainter.width);
        final y = (overlay.positionRatio.dy * image.height)
            .clamp(0.0, image.height.toDouble() - textPainter.height);

        canvas.save();

        if (overlay.opacity < 1.0) {
          canvas.saveLayer(
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            Paint()
              ..color = Colors.white
                  .withValues(alpha: overlay.opacity.clamp(0.0, 1.0)),
          );
        }

        if (overlay.rotation != 0.0) {
          final centerX = x + textPainter.width / 2.0;
          final centerY = y + textPainter.height / 2.0;
          canvas.translate(centerX, centerY);
          canvas.rotate(overlay.rotation);
          canvas.translate(-centerX, -centerY);
        }

        // Draw background box if present and not transparent
        if (overlay.backgroundColor != null &&
            overlay.backgroundColor != Colors.transparent) {
          final bgPaint = Paint()..color = overlay.backgroundColor!;
          final paddingH = scaledFontSize * 0.35;
          final paddingV = scaledFontSize * 0.2;
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - paddingH,
              y - paddingV,
              textPainter.width + (paddingH * 2),
              textPainter.height + (paddingV * 2),
            ),
            Radius.circular(scaledFontSize * 0.25),
          );
          canvas.drawRRect(rect, bgPaint);
        }

        // Draw text
        textPainter.paint(canvas, Offset(x, y));

        if (overlay.opacity < 1.0) {
          canvas.restore();
        }

        canvas.restore();
      }

      final picture = recorder.endRecording();
      final imgWithText = await picture.toImage(image.width, image.height);
      final byteData =
          await imgWithText.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return imagePath;

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'text_baked_${DateTime.now().millisecondsSinceEpoch}.png';
      final outFile = File('${tempDir.path}/$fileName');
      await outFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      return outFile.path;
    } catch (e) {
      debugPrint('Error rendering text overlay: $e');
      return imagePath;
    }
  }
}
