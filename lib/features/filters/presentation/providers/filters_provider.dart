import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../../../core/services/image_cache_manager.dart';
import '../../../../core/services/image_pipeline_service.dart';
import '../../../../core/errors/error_handler.dart';
import '../../data/models/filters_type.dart';
import '../../data/services/filters_service.dart';
import '../../../scanner/data/services/scanner_storage_service.dart';

class FiltersProvider extends ChangeNotifier {
  String? _originalImagePath;
  String? _thumbnailPreviewPath;
  String? _previewPath;
  FiltersType _selectedFilter = FiltersType.original;
  bool _isLoading = false;
  String? _loadingMessage;

  String? get originalImagePath => _originalImagePath;
  String? get previewPath => _previewPath;
  FiltersType get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  Future<void> initImage(String imagePath) async {
    _originalImagePath = imagePath;
    _selectedFilter = FiltersType.original;
    _previewPath = imagePath;
    _isLoading = true;
    _loadingMessage = 'Preparing image preview...';
    notifyListeners();

    try {
      // Obtain downscaled thumbnail for ultra-fast filter previews
      _thumbnailPreviewPath = await ImageCacheManager.instance
          .getThumbnailPath(imagePath, maxDimension: 1200);
      _previewPath = _thumbnailPreviewPath ?? imagePath;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'FiltersProvider.initImage');
    } finally {
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
    }
  }

  Future<void> setFilter(FiltersType filter) async {
    if (_originalImagePath == null) return;
    _selectedFilter = filter;

    if (filter == FiltersType.original) {
      _previewPath = _thumbnailPreviewPath ?? _originalImagePath;
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _loadingMessage = 'Applying filter (${filter.labelEn})...';
    notifyListeners();

    try {
      final inputPath = _thumbnailPreviewPath ?? _originalImagePath!;
      final resultPath = await ImagePipelineService.instance.processWithCancellation(
        taskTag: 'filters_preview',
        callback: _applyFilterTask,
        param: {'path': inputPath, 'filter': filter.index},
      );

      if (resultPath != null) {
        _previewPath = resultPath;
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'FiltersProvider.setFilter');
    } finally {
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
    }
  }

  static String? _applyFilterTask(Map<String, dynamic> params) {
    try {
      final path = params['path'] as String;
      final filterIndex = params['filter'] as int;
      final filter = FiltersType.values[filterIndex];

      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final filtered = FiltersService.applyFilter(decoded, filter);
      final encoded = img.encodeJpg(filtered, quality: 88);

      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/filter_${DateTime.now().microsecondsSinceEpoch}.jpg');
      tempFile.writeAsBytesSync(encoded);
      return tempFile.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> saveFilteredImage(
      String baseName, OutputFormat format, int quality) async {
    if (_originalImagePath == null) return null;
    _isLoading = true;
    _loadingMessage = 'Saving full resolution filtered image...';
    notifyListeners();

    try {
      // Process FULL-RESOLUTION image in background isolate on save
      final savedPath = await compute(_fullResolutionSaveTask, {
        'originalPath': _originalImagePath!,
        'filterIndex': _selectedFilter.index,
        'baseName': baseName.isNotEmpty ? baseName : 'filtered_image',
        'formatIndex': format.index,
        'quality': quality,
      });

      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
      return savedPath;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'FiltersProvider.saveFilteredImage');
    }

    _isLoading = false;
    _loadingMessage = null;
    notifyListeners();
    return null;
  }

  static Future<String?> _fullResolutionSaveTask(Map<String, dynamic> params) async {
    try {
      final originalPath = params['originalPath'] as String;
      final filterIndex = params['filterIndex'] as int;
      final baseName = params['baseName'] as String;
      final formatIndex = params['formatIndex'] as int;
      final quality = params['quality'] as int;

      final filter = FiltersType.values[filterIndex];
      final format = OutputFormat.values[formatIndex];

      final bytes = await File(originalPath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final filtered = FiltersService.applyFilter(decoded, filter);
      return await ScannerStorageService.saveImage(
        image: filtered,
        baseName: baseName,
        format: format,
        quality: quality,
      );
    } catch (e) {
      return null;
    }
  }
}
