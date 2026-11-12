import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../../../core/errors/error_handler.dart';
import '../../data/crop_repository.dart';
import '../../../scanner/data/services/scanner_storage_service.dart';

class CropProvider extends ChangeNotifier {
  final CropRepository _cropRepository = CropRepository();

  String? _originalImagePath;
  String? _thumbnailPath;
  List<Offset> _corners = const [
    Offset(0.0, 0.0),
    Offset(1.0, 0.0),
    Offset(1.0, 1.0),
    Offset(0.0, 1.0),
  ];
  String? _previewPath;
  bool _isLoading = false;
  String? _loadingMessage;

  String? get originalImagePath => _originalImagePath;
  List<Offset> get corners => _corners;
  String? get currentPreviewPath => _previewPath;
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  Future<void> initSession(String imagePath) async {
    _isLoading = true;
    _loadingMessage = 'Detecting document corners...';
    notifyListeners();

    _originalImagePath = imagePath;
    _previewPath = null;

    try {
      _thumbnailPath = await _cropRepository.getThumbnail(imagePath, maxDimension: 1200);

      final bytes = await File(_thumbnailPath ?? imagePath).readAsBytes();
      final decoded = await _cropRepository.decodeImageBytes(bytes);

      if (decoded != null) {
        final detection = await _cropRepository.detectDocumentCorners(decoded);
        _corners = detection.corners;
        await _renderPreview();
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'CropProvider.initSession');
    } finally {
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
    }
  }

  Future<void> updateCorners(List<Offset> newCorners) async {
    _corners = newCorners;
    notifyListeners();
    await _renderPreview();
  }

  Future<void> _renderPreview() async {
    if (_originalImagePath == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final inputPath = _thumbnailPath ?? _originalImagePath!;
      final bytes = await File(inputPath).readAsBytes();

      final processedPath = await _cropRepository.processPreview(
        bytes: bytes,
        corners: _corners,
      );

      if (processedPath != null) {
        _previewPath = processedPath;
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'CropProvider._renderPreview');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> saveSession({
    required String baseName,
    required OutputFormat format,
    required int quality,
  }) async {
    if (_originalImagePath == null) return [];

    _isLoading = true;
    _loadingMessage = 'Processing full resolution cropped document...';
    notifyListeners();

    try {
      final savedPaths = await _cropRepository.saveCroppedDocument(
        originalImagePath: _originalImagePath!,
        corners: _corners,
        baseName: baseName,
        format: format,
        quality: quality,
      );

      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
      return savedPaths;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'CropProvider.saveSession');
    }

    _isLoading = false;
    _loadingMessage = null;
    notifyListeners();
    return [];
  }
}
