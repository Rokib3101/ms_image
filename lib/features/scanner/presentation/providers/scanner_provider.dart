import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/scanner_page_model.dart';
import '../../data/services/scanner_storage_service.dart';
import '../../../image_tools/data/services/text_overlay_service.dart';

class ScannerProvider extends ChangeNotifier {
  final List<ScannerPageModel> _pages = [];
  int _currentIndex = 0;

  bool _isLoading = false;
  String? _loadingMessage;

  // Cached rendered preview path for each page ID
  final Map<String, String> _previewCache = {};

  List<ScannerPageModel> get pages => List.unmodifiable(_pages);
  int get currentIndex => _currentIndex;
  int get totalPages => _pages.length;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  ScannerPageModel? get currentPage =>
      (_pages.isNotEmpty && _currentIndex >= 0 && _currentIndex < _pages.length)
          ? _pages[_currentIndex]
          : null;

  String? get currentPreviewPath =>
      currentPage != null ? _previewCache[currentPage!.id] : null;

  /// Initializes a new session from selected gallery image paths without cropping.
  Future<void> initSession(List<String> imagePaths) async {
    _isLoading = true;
    _loadingMessage = 'Loading image(s)...';
    notifyListeners();

    _pages.clear();
    _previewCache.clear();
    _currentIndex = 0;

    const uuid = Uuid();

    for (int i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      _loadingMessage = 'Loading image ${i + 1} of ${imagePaths.length}...';
      notifyListeners();

      try {
        final bytes = await File(path).readAsBytes();
        final decoded = await compute(_decodeAndBake, bytes);

        if (decoded != null) {
          final page = ScannerPageModel(
            id: uuid.v4(),
            originalImagePath: path,
            rotationAngle: 0,
            isFlippedHorizontal: false,
            isFlippedVertical: false,
            textOverlays: const [],
          );

          _pages.add(page);

          // Render initial preview
          final previewPath = await _renderPreviewForPage(page, decoded);
          if (previewPath != null) {
            _previewCache[page.id] = previewPath;
          }
        }
      } catch (e) {
        debugPrint('Error initializing page $i: $e');
      }
    }

    _isLoading = false;
    _loadingMessage = null;
    notifyListeners();
  }

  /// Updates text overlays for a page and re-renders preview
  Future<void> updateTextOverlays(
      int pageIndex, List<TextOverlayData> overlays) async {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;

    _pages[pageIndex] = _pages[pageIndex].copyWith(textOverlays: overlays);
    notifyListeners();

    await _refreshCurrentPreview();
  }

  /// Rotates current page 90 degrees right
  Future<void> rotateCurrentPageRight() async {
    if (currentPage == null) return;
    final newAngle = (currentPage!.rotationAngle + 90) % 360;
    _pages[_currentIndex] = currentPage!.copyWith(rotationAngle: newAngle);
    notifyListeners();

    await _refreshCurrentPreview();
  }

  /// Rotates current page 90 degrees left
  Future<void> rotateCurrentPageLeft() async {
    if (currentPage == null) return;
    final newAngle = (currentPage!.rotationAngle - 90 + 360) % 360;
    _pages[_currentIndex] = currentPage!.copyWith(rotationAngle: newAngle);
    notifyListeners();

    await _refreshCurrentPreview();
  }

  /// Flips current page horizontally (Mirror left-right)
  Future<void> flipHorizontalCurrentPage() async {
    if (currentPage == null) return;
    _pages[_currentIndex] = currentPage!.copyWith(
      isFlippedHorizontal: !currentPage!.isFlippedHorizontal,
    );
    notifyListeners();

    await _refreshCurrentPreview();
  }

  /// Flips current page vertically (Mirror top-bottom)
  Future<void> flipVerticalCurrentPage() async {
    if (currentPage == null) return;
    _pages[_currentIndex] = currentPage!.copyWith(
      isFlippedVertical: !currentPage!.isFlippedVertical,
    );
    notifyListeners();

    await _refreshCurrentPreview();
  }

  /// Navigates to page by index
  void goToPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _currentIndex = index;
      notifyListeners();
      if (!_previewCache.containsKey(currentPage?.id)) {
        _refreshCurrentPreview();
      }
    }
  }

  void nextPage() {
    if (_currentIndex < _pages.length - 1) {
      goToPage(_currentIndex + 1);
    }
  }

  void previousPage() {
    if (_currentIndex > 0) {
      goToPage(_currentIndex - 1);
    }
  }

  /// Re-renders preview for current active page
  Future<void> _refreshCurrentPreview() async {
    final page = currentPage;
    if (page == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final bytes = await File(page.originalImagePath).readAsBytes();
      final decoded = await compute(_decodeAndBake, bytes);

      if (decoded != null) {
        final oldPath = _previewCache[page.id];

        final previewPath = await _renderPreviewForPage(page, decoded);
        if (previewPath != null) {
          _previewCache[page.id] = previewPath;

          if (oldPath != null && oldPath != previewPath) {
            try {
              final oldFile = File(oldPath);
              if (await oldFile.exists()) {
                await oldFile.delete();
              }
              await FileImage(oldFile).evict();
            } catch (e) {
              debugPrint('Error cleaning old preview: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error refreshing preview: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Saves all pages in session to device storage
  Future<List<String>> saveSession({
    required String baseName,
    required OutputFormat format,
    int quality = 85,
    required void Function(int current, int total) onProgress,
  }) async {
    final savedPaths = <String>[];

    for (int i = 0; i < _pages.length; i++) {
      onProgress(i + 1, _pages.length);

      final page = _pages[i];
      try {
        final bytes = await File(page.originalImagePath).readAsBytes();
        final decoded = await compute(_decodeAndBake, bytes);

        if (decoded != null) {
          // Render full resolution (rotation & mirror only)
          final processed =
              await compute(_processPageFull, _ProcessParams(page, decoded));

          var savedPath = await ScannerStorageService.saveImage(
            image: processed,
            baseName: baseName,
            format: format,
            quality: quality,
            pageIndex: i,
            totalPages: _pages.length,
          );

          if (savedPath != null) {
            // Apply text overlays to final saved image if any
            if (page.textOverlays.isNotEmpty) {
              final textBakedPath = await TextOverlayService.renderTextOverlay(
                imagePath: savedPath,
                overlays: page.textOverlays,
              );
              if (textBakedPath != null && textBakedPath != savedPath) {
                final bakedBytes = await File(textBakedPath).readAsBytes();
                await File(savedPath).writeAsBytes(bakedBytes, flush: true);
              }
            }
            savedPaths.add(savedPath);
          }
        }
      } catch (e) {
        debugPrint('Error saving page $i: $e');
      }
    }

    return savedPaths;
  }

  static Future<String?> _renderPreviewForPage(
      ScannerPageModel page, img.Image fullImage) async {
    try {
      // Downscale image for quick preview rendering
      final previewImage =
          await compute(_processPagePreview, _ProcessParams(page, fullImage));

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile =
          File('${tempDir.path}/preview_${page.id}_$timestamp.jpg');
      final jpgBytes = img.encodeJpg(previewImage, quality: 80);
      await tempFile.writeAsBytes(jpgBytes, flush: true);

      var previewPath = tempFile.path;

      // Bake text overlays onto preview image if present
      if (page.textOverlays.isNotEmpty) {
        final bakedPath = await TextOverlayService.renderTextOverlay(
          imagePath: previewPath,
          overlays: page.textOverlays,
        );
        if (bakedPath != null) {
          previewPath = bakedPath;
        }
      }

      return previewPath;
    } catch (e) {
      debugPrint('Error rendering preview: $e');
      return null;
    }
  }
}

class _ProcessParams {
  final ScannerPageModel page;
  final img.Image image;
  _ProcessParams(this.page, this.image);
}

img.Image? _decodeAndBake(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return img.bakeOrientation(decoded);
}

img.Image _processPagePreview(_ProcessParams params) {
  final page = params.page;
  var image = params.image;

  // Downscale to max 1000px for preview rendering (maintaining original aspect ratio / dimensions without cropping)
  if (image.width > 1000 || image.height > 1000) {
    image = img.copyResize(
      image,
      width: image.width > image.height ? 1000 : null,
      height: image.height >= image.width ? 1000 : null,
    );
  }

  // 1. Rotation
  if (page.rotationAngle != 0) {
    image = img.copyRotate(image, angle: page.rotationAngle);
  }

  // 2. Mirror / Flip
  if (page.isFlippedHorizontal) {
    image = img.copyFlip(image, direction: img.FlipDirection.horizontal);
  }
  if (page.isFlippedVertical) {
    image = img.copyFlip(image, direction: img.FlipDirection.vertical);
  }

  return image;
}

img.Image _processPageFull(_ProcessParams params) {
  final page = params.page;
  var image = params.image;

  // 1. Rotation
  if (page.rotationAngle != 0) {
    image = img.copyRotate(image, angle: page.rotationAngle);
  }

  // 2. Mirror / Flip
  if (page.isFlippedHorizontal) {
    image = img.copyFlip(image, direction: img.FlipDirection.horizontal);
  }
  if (page.isFlippedVertical) {
    image = img.copyFlip(image, direction: img.FlipDirection.vertical);
  }

  return image;
}
