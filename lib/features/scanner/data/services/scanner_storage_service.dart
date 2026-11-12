import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/storage_utils.dart';

enum OutputFormat { jpg, png }

class ScannerStorageService {
  /// Generates timestamp string in YYMMDDHHMMSS format (e.g. 260922164012)
  static String generateTimestamp() {
    final now = DateTime.now();
    return DateFormat('yyMMddHHmmss').format(now);
  }

  /// Saves an encoded image to MS Smart Tools directory and device Gallery.
  static Future<String?> saveImage({
    required img.Image image,
    required String baseName,
    required OutputFormat format,
    int quality = 85,
    int? pageIndex,
    int? totalPages,
  }) async {
    try {
      final timestamp = generateTimestamp();
      final extension = format == OutputFormat.jpg ? 'jpg' : 'png';

      String fileName;
      final cleanBaseName = _sanitizeFileName(baseName);

      if (totalPages != null && totalPages > 1 && pageIndex != null) {
        fileName =
            '${cleanBaseName}_page${pageIndex + 1}_$timestamp.$extension';
      } else {
        fileName = '${cleanBaseName}_$timestamp.$extension';
      }

      // Encode image
      List<int> bytes;
      if (format == OutputFormat.jpg) {
        bytes = img.encodeJpg(image, quality: quality.clamp(10, 100));
      } else {
        bytes = img.encodePng(image);
      }

      final outputDir = await StorageUtils.getAppOutputDir();
      final targetPath = '$outputDir/$fileName';

      final file = File(targetPath);
      await file.writeAsBytes(bytes, flush: true);

      // Save to Gallery under "MS Smart Tools" album
      await StorageUtils.saveFileToCustomFolder(targetPath, fileName);

      return targetPath;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ScannerStorageService.saveImage');
      return null;
    }
  }

  static String _sanitizeFileName(String name) {
    var s = name.trim();
    if (s.isEmpty) s = 'document';
    if (s.toLowerCase().endsWith('.jpg') ||
        s.toLowerCase().endsWith('.png') ||
        s.toLowerCase().endsWith('.jpeg')) {
      s = s.substring(0, s.lastIndexOf('.'));
    }
    return s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// Deletes a saved image or document file from disk to avoid orphan files
  static Future<bool> deleteImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ScannerStorageService.deleteImageFile');
      return false;
    }
  }

  /// Deletes multiple files from disk
  static Future<void> deleteDocumentFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      await deleteImageFile(path);
    }
  }
}
