import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../data/services/document_detection_service.dart';
import '../widgets/scanner_crop_overlay.dart';

class ScannerCropScreen extends StatefulWidget {
  final String imagePath;
  final List<Offset> initialCorners;

  const ScannerCropScreen({
    super.key,
    required this.imagePath,
    required this.initialCorners,
  });

  @override
  State<ScannerCropScreen> createState() => _ScannerCropScreenState();
}

class _ScannerCropScreenState extends State<ScannerCropScreen> {
  late List<Offset> _corners;
  final TransformationController _transformationController =
      TransformationController();

  img.Image? _loadedImage;
  bool _isLoading = true;
  int _activeHandleIndex = -1;
  bool _isIndependent = true;

  @override
  void initState() {
    super.initState();
    _corners = List.from(widget.initialCorners);
    _loadImage();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = await compute(_decodeAndBakeScanner, bytes);
      if (mounted) {
        setState(() {
          _loadedImage = decoded;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectAll() {
    setState(() {
      _corners = [
        const Offset(0.0, 0.0),
        const Offset(1.0, 0.0),
        const Offset(1.0, 1.0),
        const Offset(0.0, 1.0),
      ];
      _transformationController.value = Matrix4.identity();
    });
  }

  void _autoDetect() {
    if (_loadedImage != null) {
      final detection = DocumentDetectionService.detectDocument(_loadedImage!);
      setState(() {
        _corners = List.from(detection.corners);
        if (!_isIndependent) {
          _alignCornersSymmetrically();
        }
        _transformationController.value = Matrix4.identity();
      });
    }
  }

  void _alignCornersSymmetrically() {
    if (_corners.length != 4) return;
    final minX = min(min(_corners[0].dx, _corners[1].dx),
            min(_corners[2].dx, _corners[3].dx))
        .clamp(0.0, 1.0);
    final maxX = max(max(_corners[0].dx, _corners[1].dx),
            max(_corners[2].dx, _corners[3].dx))
        .clamp(0.0, 1.0);
    final minY = min(min(_corners[0].dy, _corners[1].dy),
            min(_corners[2].dy, _corners[3].dy))
        .clamp(0.0, 1.0);
    final maxY = max(max(_corners[0].dy, _corners[1].dy),
            max(_corners[2].dy, _corners[3].dy))
        .clamp(0.0, 1.0);

    _corners = [
      Offset(minX, minY),
      Offset(maxX, minY),
      Offset(maxX, maxY),
      Offset(minX, maxY),
    ];
  }

  void _resetCorners() {
    setState(() {
      _corners = List.from(widget.initialCorners);
      if (!_isIndependent) {
        _alignCornersSymmetrically();
      }
      _transformationController.value = Matrix4.identity();
    });
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 4.0) {
      final newScale = currentScale * 1.3;
      _transformationController.value = Matrix4.identity()..scale(newScale);
    }
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      final newScale = (currentScale / 1.3).clamp(1.0, 4.0);
      _transformationController.value = Matrix4.identity()..scale(newScale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Adjust Crop',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.cyanAccent,
            ),
            icon: Icon(
              _isIndependent ? Icons.crop_square : Icons.crop_free,
              color: Colors.cyanAccent,
              size: 18,
            ),
            label: Text(
              _isIndependent ? 'Symmetrical' : 'Independent',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              setState(() {
                _isIndependent = !_isIndependent;
                if (!_isIndependent) {
                  _alignCornersSymmetrically();
                }
              });
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset Crop',
            onPressed: _resetCorners,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.cyanAccent, size: 28),
            tooltip: 'Done',
            onPressed: () => Navigator.pop(context, _corners),
          ),
        ],
      ),
      body: _isLoading || _loadedImage == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : LayoutBuilder(
              builder: (context, constraints) {
                final imgW = _loadedImage!.width.toDouble();
                final imgH = _loadedImage!.height.toDouble();

                final bottomPadding = MediaQuery.of(context).padding.bottom;
                final availW = constraints.maxWidth;
                final availH = constraints.maxHeight -
                    64 -
                    bottomPadding; // Leave space for bottom toolbar & safe area

                final scaleX = availW / imgW;
                final scaleY = availH / imgH;
                final displayScale = min(scaleX, scaleY);

                final displayW = imgW * displayScale;
                final displayH = imgH * displayScale;
                final displaySize = Size(displayW, displayH);

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          width: displayW,
                          height: displayH,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 1.0,
                            maxScale: 5.0,
                            panEnabled: _activeHandleIndex == -1,
                            scaleEnabled: _activeHandleIndex == -1,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.file(
                                  File(widget.imagePath),
                                  width: displayW,
                                  height: displayH,
                                  fit: BoxFit.fill,
                                ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    size: displaySize,
                                    painter: ScannerCropOverlay(
                                      corners: _corners,
                                      displaySize: displaySize,
                                      activeHandleIndex: _activeHandleIndex,
                                    ),
                                  ),
                                ),
                                // 4 Interactive Corner Drag Handles
                                for (int i = 0; i < 4; i++)
                                  _buildHandleWidget(i, displaySize),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Toolbar with Zoom & Action Controls
                    Container(
                      color: const Color(0xFF1E1E1E),
                      child: SafeArea(
                        top: false,
                        child: Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.zoom_out,
                                    color: Colors.white),
                                onPressed: _zoomOut,
                                tooltip: 'Zoom Out',
                              ),
                              IconButton(
                                icon: const Icon(Icons.zoom_in,
                                    color: Colors.white),
                                onPressed: _zoomIn,
                                tooltip: 'Zoom In',
                              ),
                              IconButton(
                                icon: const Icon(Icons.crop_free,
                                    color: Colors.cyanAccent),
                                onPressed: _selectAll,
                                tooltip: 'Full',
                              ),
                              IconButton(
                                icon: const Icon(Icons.auto_awesome,
                                    color: Colors.amberAccent),
                                onPressed: _autoDetect,
                                tooltip: 'Magic',
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  foregroundColor: Colors.black,
                                ),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Apply'),
                                onPressed: () =>
                                    Navigator.pop(context, _corners),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildHandleWidget(int index, Size displaySize) {
    const double touchSize = 44.0;
    final corner = _corners[index];
    final posX = corner.dx * displaySize.width - (touchSize / 2);
    final posY = corner.dy * displaySize.height - (touchSize / 2);

    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          setState(() {
            _activeHandleIndex = index;
          });
        },
        onPanUpdate: (details) {
          final scale = _transformationController.value.getMaxScaleOnAxis();
          final deltaX = details.delta.dx / (displaySize.width * scale);
          final deltaY = details.delta.dy / (displaySize.height * scale);

          setState(() {
            final current = _corners[index];
            final newX = (current.dx + deltaX).clamp(0.0, 1.0);
            final newY = (current.dy + deltaY).clamp(0.0, 1.0);
            final newPos = Offset(newX, newY);

            _corners[index] = newPos;

            if (!_isIndependent) {
              switch (index) {
                case 0: // Top-Left
                  _corners[1] = Offset(_corners[1].dx, newY);
                  _corners[3] = Offset(newX, _corners[3].dy);
                  break;
                case 1: // Top-Right
                  _corners[0] = Offset(_corners[0].dx, newY);
                  _corners[2] = Offset(newX, _corners[2].dy);
                  break;
                case 2: // Bottom-Right
                  _corners[1] = Offset(newX, _corners[1].dy);
                  _corners[3] = Offset(_corners[3].dx, newY);
                  break;
                case 3: // Bottom-Left
                  _corners[0] = Offset(_corners[0].dx, newY);
                  _corners[2] = Offset(_corners[2].dx, newY);
                  break;
              }
            }
          });
        },
        onPanEnd: (_) {
          setState(() {
            _activeHandleIndex = -1;
          });
        },
        onPanCancel: () {
          setState(() {
            _activeHandleIndex = -1;
          });
        },
        child: Container(
          width: touchSize,
          height: touchSize,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

img.Image? _decodeAndBakeScanner(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  return decoded != null ? img.bakeOrientation(decoded) : null;
}
