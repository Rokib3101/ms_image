import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../providers/crop_provider.dart';
import '../../../scanner/presentation/widgets/scanner_crop_overlay.dart';
import '../../../scanner/data/services/scanner_storage_service.dart';
import '../../../../core/utils/permission_utils.dart';

class CropAdjustScreen extends StatefulWidget {
  final String imagePath;
  final List<Offset> initialCorners;

  const CropAdjustScreen({
    super.key,
    required this.imagePath,
    required this.initialCorners,
  });

  @override
  State<CropAdjustScreen> createState() => _CropAdjustScreenState();
}

class _CropAdjustScreenState extends State<CropAdjustScreen> {
  late List<Offset> _corners;
  img.Image? _loadedImage;
  bool _isLoading = true;
  int _activeHandleIndex = -1; // 0..3 corners, 4..7 midpoints
  Offset? _lastDragPos;
  String _selectedOption = 'Full Page';
  bool _isSymmetrical = false;

  @override
  void initState() {
    super.initState();
    _corners = widget.initialCorners.isNotEmpty
        ? List.from(widget.initialCorners)
        : [
            const Offset(0.0, 0.0),
            const Offset(1.0, 0.0),
            const Offset(1.0, 1.0),
            const Offset(0.0, 1.0),
          ];
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = await compute(_decodeAndBake, bytes);
      if (mounted) {
        setState(() {
          _loadedImage = decoded;
          _isLoading = false;
        });
        final provider = Provider.of<CropProvider>(context, listen: false);
        if (provider.originalImagePath == null) {
          await provider.initSession(widget.imagePath);
        } else {
          provider.updateCorners(_corners);
        }
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
    });
    _updateProviderCorners();
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

    setState(() {
      _corners = [
        Offset(minX, minY),
        Offset(maxX, minY),
        Offset(maxX, maxY),
        Offset(minX, maxY),
      ];
    });
    _updateProviderCorners();
  }

  void _updateProviderCorners() {
    final provider = Provider.of<CropProvider>(context, listen: false);
    provider.updateCorners(_corners);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Crop Studio',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save'),
                  onPressed: provider.isLoading
                      ? null
                      : () => _showSaveDialog(context, provider),
                ),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent))
              : Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final maxHeight = constraints.maxHeight;

                          if (_loadedImage == null) {
                            return const Center(
                                child: Text('Failed to load image',
                                    style: TextStyle(color: Colors.white)));
                          }

                          final imgW = _loadedImage!.width.toDouble();
                          final imgH = _loadedImage!.height.toDouble();

                          final scale = min(maxWidth / imgW, maxHeight / imgH);
                          final displayW = imgW * scale;
                          final displayH = imgH * scale;

                          Offset? activePos;
                          if (_activeHandleIndex != -1) {
                            if (_activeHandleIndex < 4) {
                              activePos = _corners[_activeHandleIndex];
                            } else {
                              final p1 = _corners[_activeHandleIndex - 4];
                              final p2 = _corners[(_activeHandleIndex - 3) % 4];
                              activePos = Offset(
                                  (p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
                            }
                          }

                          return Center(
                            child: SizedBox(
                              width: displayW,
                              height: displayH,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(
                                      File(widget.imagePath),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onPanStart: (details) {
                                        final localPos = details.localPosition;
                                        final normX = (localPos.dx / displayW)
                                            .clamp(0.0, 1.0);
                                        final normY = (localPos.dy / displayH)
                                            .clamp(0.0, 1.0);
                                        final touch = Offset(normX, normY);

                                        int bestIdx = -1;
                                        double minDist = 0.12;

                                        for (int i = 0; i < 4; i++) {
                                          final dist =
                                              (_corners[i] - touch).distance;
                                          if (dist < minDist) {
                                            minDist = dist;
                                            bestIdx = i;
                                          }
                                        }

                                        if (bestIdx == -1) {
                                          minDist = 0.10;
                                          for (int i = 0; i < 4; i++) {
                                            final p1 = _corners[i];
                                            final p2 = _corners[(i + 1) % 4];
                                            final mid = Offset(
                                                (p1.dx + p2.dx) / 2,
                                                (p1.dy + p2.dy) / 2);
                                            final dist = (mid - touch).distance;
                                            if (dist < minDist) {
                                              minDist = dist;
                                              bestIdx = i + 4;
                                            }
                                          }
                                        }

                                        setState(() {
                                          _activeHandleIndex = bestIdx;
                                          _lastDragPos = touch;
                                        });
                                      },
                                      onPanUpdate: (details) {
                                        if (_activeHandleIndex == -1 ||
                                            _lastDragPos == null) return;
                                        final localPos = details.localPosition;
                                        final normX = (localPos.dx / displayW)
                                            .clamp(0.0, 1.0);
                                        final normY = (localPos.dy / displayH)
                                            .clamp(0.0, 1.0);
                                        final currentPos = Offset(normX, normY);

                                        final dx =
                                            currentPos.dx - _lastDragPos!.dx;
                                        final dy =
                                            currentPos.dy - _lastDragPos!.dy;

                                        setState(() {
                                          if (_activeHandleIndex < 4) {
                                            final p =
                                                _corners[_activeHandleIndex];
                                            final newX =
                                                (p.dx + dx).clamp(0.0, 1.0);
                                            final newY =
                                                (p.dy + dy).clamp(0.0, 1.0);

                                            _corners[_activeHandleIndex] =
                                                Offset(newX, newY);

                                            if (_isSymmetrical) {
                                              switch (_activeHandleIndex) {
                                                case 0: // Top-Left
                                                  _corners[1] = Offset(
                                                      _corners[1].dx, newY);
                                                  _corners[3] = Offset(
                                                      newX, _corners[3].dy);
                                                  break;
                                                case 1: // Top-Right
                                                  _corners[0] = Offset(
                                                      _corners[0].dx, newY);
                                                  _corners[2] = Offset(
                                                      newX, _corners[2].dy);
                                                  break;
                                                case 2: // Bottom-Right
                                                  _corners[1] = Offset(
                                                      newX, _corners[1].dy);
                                                  _corners[3] = Offset(
                                                      _corners[3].dx, newY);
                                                  break;
                                                case 3: // Bottom-Left
                                                  _corners[0] = Offset(
                                                      newX, _corners[0].dy);
                                                  _corners[2] = Offset(
                                                      _corners[2].dx, newY);
                                                  break;
                                              }
                                            }
                                          } else {
                                            final edgeIdx =
                                                _activeHandleIndex - 4;
                                            final i1 = edgeIdx;
                                            final i2 = (edgeIdx + 1) % 4;

                                            _corners[i1] = Offset(
                                              (_corners[i1].dx + dx)
                                                  .clamp(0.0, 1.0),
                                              (_corners[i1].dy + dy)
                                                  .clamp(0.0, 1.0),
                                            );
                                            _corners[i2] = Offset(
                                              (_corners[i2].dx + dx)
                                                  .clamp(0.0, 1.0),
                                              (_corners[i2].dy + dy)
                                                  .clamp(0.0, 1.0),
                                            );
                                          }
                                          _lastDragPos = currentPos;
                                        });
                                      },
                                      onPanEnd: (_) {
                                        setState(() {
                                          _activeHandleIndex = -1;
                                          _lastDragPos = null;
                                        });
                                        _updateProviderCorners();
                                      },
                                      child: CustomPaint(
                                        painter: ScannerCropOverlay(
                                          corners: _corners,
                                          displaySize: Size(displayW, displayH),
                                          activeHandleIndex: _activeHandleIndex,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (activePos != null)
                                    Positioned(
                                      left: activePos.dx * displayW - 35,
                                      top: activePos.dy * displayH - 65,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.cyanAccent,
                                              width: 1),
                                        ),
                                        child: Text(
                                          '${(activePos.dx * 100).toInt()}%, ${(activePos.dy * 100).toInt()}%',
                                          style: const TextStyle(
                                              color: Colors.cyanAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.9),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOptionChip('Full Page', () {
                                setState(() {
                                  _selectedOption = 'Full Page';
                                  _isSymmetrical = false;
                                  _selectAll();
                                });
                              }),
                              _buildOptionChip('Symmetrical', () {
                                setState(() {
                                  _selectedOption = 'Symmetrical';
                                  _isSymmetrical = true;
                                  _alignCornersSymmetrically();
                                });
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildOptionChip(String name, VoidCallback onTap) {
    final isSelected = _selectedOption == name;
    return ChoiceChip(
      label: Text(name),
      selected: isSelected,
      selectedColor: Colors.cyanAccent,
      backgroundColor: Colors.grey.shade900,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      onSelected: (_) => onTap(),
    );
  }

  void _showSaveDialog(BuildContext context, CropProvider provider) {
    final originalPath = widget.imagePath;
    final originalName = p.basenameWithoutExtension(originalPath);
    final nameController =
        TextEditingController(text: '${originalName}_cropped');
    OutputFormat selectedFormat = OutputFormat.jpg;
    double compressionQuality = 90;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF262C38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Save Cropped Image',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'File Name',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image, color: Colors.cyanAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Format:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white70)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<OutputFormat>(
                            title: const Text('JPG',
                                style: TextStyle(color: Colors.white)),
                            value: OutputFormat.jpg,
                            groupValue: selectedFormat,
                            activeColor: Colors.cyanAccent,
                            onChanged: (val) {
                              if (val != null)
                                setModalState(() => selectedFormat = val);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<OutputFormat>(
                            title: const Text('PNG',
                                style: TextStyle(color: Colors.white)),
                            value: OutputFormat.png,
                            groupValue: selectedFormat,
                            activeColor: Colors.cyanAccent,
                            onChanged: (val) {
                              if (val != null)
                                setModalState(() => selectedFormat = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (selectedFormat == OutputFormat.jpg) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quality:',
                              style: TextStyle(color: Colors.white70)),
                          Text('${compressionQuality.round()}%',
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: compressionQuality,
                        min: 30,
                        max: 100,
                        divisions: 14,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) =>
                            setModalState(() => compressionQuality = val),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _performSave(
                            context,
                            provider,
                            nameController.text,
                            selectedFormat,
                            compressionQuality.round(),
                          );
                        },
                        child: const Text('Save to MS Smart Tools',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performSave(
    BuildContext context,
    CropProvider provider,
    String baseName,
    OutputFormat format,
    int quality,
  ) async {
    final hasPermission =
        await PermissionUtils.requestPhotosPermission(context);
    if (!hasPermission) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(width: 20),
            Text('Saving cropped document...'),
          ],
        ),
      ),
    );

    final savedPaths = await provider.saveSession(
      baseName: baseName,
      format: format,
      quality: quality,
    );

    if (context.mounted) {
      Navigator.pop(context); // Dismiss dialog
      if (savedPaths.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully saved image to MS Smart Tools!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save document.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

img.Image? _decodeAndBake(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  return decoded != null ? img.bakeOrientation(decoded) : null;
}
