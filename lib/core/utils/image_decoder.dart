import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageDecoderUtils {
  /// Decodes an encoded image byte array into a downsampled [ui.Image] directly at engine level.
  /// This bypasses allocating full-resolution RGBA bitmaps on the Dart heap.
  /// Caller MUST call `.dispose()` on the returned [ui.Image] when finished.
  static Future<ui.Image> decodePreview(
    Uint8List bytes, {
    int maxSide = 1440,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final desc = await ui.ImageDescriptor.encoded(buffer);

    final double scale = math.min(
      1.0,
      maxSide / math.max(desc.width, desc.height),
    );

    final targetWidth = (desc.width * scale).round();
    final targetHeight = (desc.height * scale).round();

    final codec = await desc.instantiateCodec(
      targetWidth: targetWidth > 0 ? targetWidth : desc.width,
      targetHeight: targetHeight > 0 ? targetHeight : desc.height,
    );

    final frameInfo = await codec.getNextFrame();

    codec.dispose();
    desc.dispose();
    buffer.dispose();

    return frameInfo.image;
  }

  /// Quickly reads image dimensions without decoding pixel data into memory.
  static Future<({int width, int height})> getImageDimensions(
    Uint8List bytes,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final desc = await ui.ImageDescriptor.encoded(buffer);
    final width = desc.width;
    final height = desc.height;

    desc.dispose();
    buffer.dispose();

    return (width: width, height: height);
  }
}
