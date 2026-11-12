import 'package:image/image.dart' as img;
import '../../errors/app_exception.dart';
import '../../utils/storage_utils.dart';
import '../../../features/scanner/data/services/scanner_storage_service.dart';

abstract class ImageStorageRepository {
  Future<String> getAppOutputDir();
  Future<String?> saveImage({
    required img.Image image,
    required String baseName,
    required OutputFormat format,
    int quality = 85,
    int? pageIndex,
    int? totalPages,
  });
  Future<String?> saveFileToCustomFolder(String sourcePath, String fileName);
  Future<String?> saveDocumentToStorage({
    required String sourcePath,
    required String fileName,
  });
  Future<bool> deleteImageFile(String filePath);
  Future<void> deleteDocumentFiles(List<String> filePaths);
}

class AppImageStorageRepository implements ImageStorageRepository {
  @override
  Future<String> getAppOutputDir() async {
    try {
      return await StorageUtils.getAppOutputDir();
    } catch (e, stackTrace) {
      throw FileException(
        'Failed to obtain application output directory',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<String?> saveImage({
    required img.Image image,
    required String baseName,
    required OutputFormat format,
    int quality = 85,
    int? pageIndex,
    int? totalPages,
  }) async {
    try {
      return await ScannerStorageService.saveImage(
        image: image,
        baseName: baseName,
        format: format,
        quality: quality,
        pageIndex: pageIndex,
        totalPages: totalPages,
      );
    } catch (e, stackTrace) {
      throw FileException(
        'Failed to save encoded image',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<String?> saveFileToCustomFolder(String sourcePath, String fileName) async {
    try {
      return await StorageUtils.saveFileToCustomFolder(sourcePath, fileName);
    } catch (e, stackTrace) {
      throw FileException(
        'Failed to save file to custom folder',
        filePath: sourcePath,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<String?> saveDocumentToStorage({
    required String sourcePath,
    required String fileName,
  }) async {
    try {
      return await StorageUtils.saveDocumentToStorage(
        sourcePath: sourcePath,
        fileName: fileName,
      );
    } catch (e, stackTrace) {
      throw FileException(
        'Failed to save document to storage',
        filePath: sourcePath,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> deleteImageFile(String filePath) async {
    try {
      return await ScannerStorageService.deleteImageFile(filePath);
    } catch (e, stackTrace) {
      throw FileException(
        'Failed to delete file from storage',
        filePath: filePath,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteDocumentFiles(List<String> filePaths) async {
    try {
      await ScannerStorageService.deleteDocumentFiles(filePaths);
    } catch (e, stackTrace) {
      throw FileException(
        'Failed to delete document files from storage',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
