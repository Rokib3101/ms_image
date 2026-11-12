import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/image_processing_logic.dart';
import '../../../../core/utils/storage_utils.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  String? _bgPath;
  String? _fgPath;
  bool _isEditing = false;

  // Foreground position and size
  Offset _fgPos = const Offset(50, 50);
  double _fgScale = 1.0;
  Size? _bgActualSize;
  Size? _fgActualSize;

  // Gesture helpers
  Offset _basePos = Offset.zero;
  double _baseScale = 1.0;
  Offset _startFocalPoint = Offset.zero;

  Future<void> _pickImage(bool isBackground) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final decoded =
          await decodeImageFromList(await File(image.path).readAsBytes());
      setState(() {
        if (isBackground) {
          _bgPath = image.path;
          _bgActualSize =
              Size(decoded.width.toDouble(), decoded.height.toDouble());
        } else {
          _fgPath = image.path;
          _fgActualSize =
              Size(decoded.width.toDouble(), decoded.height.toDouble());
        }
      });
    }
  }

  Future<void> _saveOverlay(Size displaySize) async {
    if (_bgPath == null ||
        _fgPath == null ||
        _bgActualSize == null ||
        _fgActualSize == null) return;

    // Calculate final rect on original background image
    final scaleX = _bgActualSize!.width / displaySize.width;
    final scaleY = _bgActualSize!.height / displaySize.height;

    final finalWidth = _fgActualSize!.width *
        _fgScale *
        (displaySize.width / _bgActualSize!.width) *
        scaleX;
    final finalHeight = _fgActualSize!.height *
        _fgScale *
        (displaySize.height / _bgActualSize!.height) *
        scaleY;

    final rect = Rect.fromLTWH(
      _fgPos.dx * scaleX,
      _fgPos.dy * scaleY,
      finalWidth,
      finalHeight,
    );

    setState(() => _isEditing = false); // Show loading?

    try {
      final result = await ImageProcessingLogic.overlayImages(
        backgroundPath: _bgPath!,
        foregroundPath: _fgPath!,
        foregroundRect: rect,
      );

      if (result != null) {
        final fileName = 'overlay_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedPath =
            await StorageUtils.saveFileToCustomFolder(result, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(savedPath != null
                    ? 'Saved to MS Smart Tools folder!'
                    : 'Failed to save!')),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Overlay')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _selectCard('1. Background Image', _bgPath,
                  () => _pickImage(true), Icons.image),
              const SizedBox(height: 20),
              _selectCard('2. Foreground Image', _fgPath,
                  () => _pickImage(false), Icons.layers),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: (_bgPath != null && _fgPath != null)
                    ? () => setState(() => _isEditing = true)
                    : null,
                icon: const Icon(Icons.edit),
                label: const Text('Create Overlay'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editing Overlay'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewSize = constraints.biggest;
          final double imgAspect = _bgActualSize!.width / _bgActualSize!.height;
          final double viewAspect = viewSize.width / viewSize.height;

          Size displaySize;
          if (imgAspect > viewAspect) {
            displaySize = Size(viewSize.width, viewSize.width / imgAspect);
          } else {
            displaySize = Size(viewSize.height * imgAspect, viewSize.height);
          }

          final fgWidth = (_fgActualSize!.width *
              _fgScale *
              (displaySize.width / _bgActualSize!.width));
          final fgHeight = (_fgActualSize!.height *
              _fgScale *
              (displaySize.height / _bgActualSize!.height));

          return Stack(
            children: [
              // BG
              Center(
                child: Container(
                  width: displaySize.width,
                  height: displaySize.height,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                          child: Image.file(File(_bgPath!), fit: BoxFit.fill)),
                      // FG
                      Positioned(
                        left: _fgPos.dx,
                        top: _fgPos.dy,
                        child: GestureDetector(
                          onScaleStart: (details) {
                            _basePos = _fgPos;
                            _baseScale = _fgScale;
                            _startFocalPoint = details.focalPoint;
                          },
                          onScaleUpdate: (details) {
                            setState(() {
                              _fgScale = (_baseScale * details.scale)
                                  .clamp(0.01, 20.0);
                              _fgPos = _basePos +
                                  (details.focalPoint - _startFocalPoint);
                            });
                          },
                          child: Container(
                            width: fgWidth,
                            height: fgHeight,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  width: 2),
                            ),
                            child: Image.file(File(_fgPath!), fit: BoxFit.fill),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // UI Controls (Instructions & Scaling Slider)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pinch to Resize • Drag to Move',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100 + MediaQuery.of(context).padding.bottom,
                left: 40,
                right: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, size: 20, color: Colors.teal),
                      Expanded(
                        child: Slider(
                          value: _fgScale.clamp(0.01, 5.0),
                          min: 0.01,
                          max: 5.0,
                          activeColor: Colors.teal,
                          onChanged: (val) {
                            setState(() {
                              _fgScale = val;
                            });
                          },
                        ),
                      ),
                      const Icon(Icons.zoom_in, size: 20, color: Colors.teal),
                    ],
                  ),
                ),
              ),
              // Save Button Overlay
              Positioned(
                bottom: 20 + MediaQuery.of(context).padding.bottom,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () => _saveOverlay(displaySize),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _selectCard(
      String title, String? path, VoidCallback onTap, IconData icon) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: path != null ? Colors.green : Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: path != null ? Colors.green : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    path != null ? 'Selected' : 'Not Selected',
                    style: TextStyle(
                        color: path != null ? Colors.green : Colors.grey,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if (path != null)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
