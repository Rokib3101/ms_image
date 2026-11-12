import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/utils/storage_utils.dart';
import '../../../../core/utils/permission_utils.dart';

class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawnLine({
    required this.path,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });
}

class DrawScreen extends StatefulWidget {
  final String? initialImagePath;

  const DrawScreen({super.key, this.initialImagePath});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  ui.Image? _loadedUiImage;
  Size? _imageAspectSize;

  final List<DrawnLine> _lines = [];
  final List<DrawnLine> _redoStack = [];
  DrawnLine? _currentLine;

  Color _selectedColor = Colors.red;
  double _strokeWidth = 6.0;
  bool _isEraser = false;
  bool _isSaving = false;
  Color _canvasBackgroundColor = Colors.white;
  bool _isBlankCanvas = false;

  final List<Color> _presetColors = const [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _loadImage(widget.initialImagePath!);
    }
  }

  Future<void> _loadImage(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final uiImg = frameInfo.image;

      setState(() {
        _loadedUiImage = uiImg;
        _imageAspectSize =
            Size(uiImg.width.toDouble(), uiImg.height.toDouble());
        _lines.clear();
        _redoStack.clear();
        _isBlankCanvas = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ছবি লোড করতে ব্যর্থ হয়েছে: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final hasPermission =
        await PermissionUtils.requestPhotosPermission(context);
    if (!hasPermission) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      _loadImage(image.path);
    }
  }

  void _createBlankCanvas([Color color = Colors.white]) {
    setState(() {
      _loadedUiImage = null;
      _imageAspectSize = const Size(1080, 1080);
      _canvasBackgroundColor = color;
      _lines.clear();
      _redoStack.clear();
      _isBlankCanvas = true;
    });
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _redoStack.add(_lines.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _lines.add(_redoStack.removeLast());
      });
    }
  }

  void _clearCanvas() {
    if (_lines.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ক্যানভাস পরিষ্কার করুন'),
        content: const Text('আপনি কি আপনার আঁকা সমস্ত লাইন মুছে ফেলতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _lines.clear();
                _redoStack.clear();
              });
            },
            child:
                const Text('মুছে ফেলুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomColorPicker() async {
    Color tempColor = _selectedColor;
    double red = tempColor.r * 255.0;
    double green = tempColor.g * 255.0;
    double blue = tempColor.b * 255.0;
    double opacity = tempColor.a;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2A3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentColor = Color.fromRGBO(
              red.round(),
              green.round(),
              blue.round(),
              opacity,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'কাস্টম কালার পিক করুন (Color Picker)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: currentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Palette grid of popular colors
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetColors.map((color) {
                      final isSelected = currentColor.value == color.value;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            red = color.r * 255.0;
                            green = color.g * 255.0;
                            blue = color.b * 255.0;
                            opacity = color.a;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const Divider(color: Colors.white24, height: 28),

                  // Red Slider
                  Row(
                    children: [
                      const SizedBox(
                          width: 50,
                          child: Text('Red',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                        child: Slider(
                          value: red,
                          min: 0,
                          max: 255,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            setModalState(() => red = val);
                          },
                        ),
                      ),
                      Text(red.round().toString(),
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),

                  // Green Slider
                  Row(
                    children: [
                      const SizedBox(
                          width: 50,
                          child: Text('Green',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                        child: Slider(
                          value: green,
                          min: 0,
                          max: 255,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            setModalState(() => green = val);
                          },
                        ),
                      ),
                      Text(green.round().toString(),
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),

                  // Blue Slider
                  Row(
                    children: [
                      const SizedBox(
                          width: 50,
                          child: Text('Blue',
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                        child: Slider(
                          value: blue,
                          min: 0,
                          max: 255,
                          activeColor: Colors.blue,
                          onChanged: (val) {
                            setModalState(() => blue = val);
                          },
                        ),
                      ),
                      Text(blue.round().toString(),
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),

                  // Opacity Slider
                  Row(
                    children: [
                      const SizedBox(
                          width: 50,
                          child: Text('Opacity',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                        child: Slider(
                          value: opacity,
                          min: 0.1,
                          max: 1.0,
                          activeColor: Colors.purpleAccent,
                          onChanged: (val) {
                            setModalState(() => opacity = val);
                          },
                        ),
                      ),
                      Text('${(opacity * 100).round()}%',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedColor = currentColor;
                          _isEraser = false;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('কালার সিলেক্ট করুন',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveDrawing(Size containerSize) async {
    if (_lines.isEmpty && _loadedUiImage == null && !_isBlankCanvas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('সংরক্ষণের জন্য কোনো ছবি বা ড্রয়িং নেই!'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double exportWidth =
          _loadedUiImage != null ? _loadedUiImage!.width.toDouble() : 1080.0;
      final double exportHeight =
          _loadedUiImage != null ? _loadedUiImage!.height.toDouble() : 1080.0;

      final recorder = ui.PictureRecorder();
      final canvas =
          Canvas(recorder, Rect.fromLTWH(0, 0, exportWidth, exportHeight));

      // Draw background
      if (_loadedUiImage != null) {
        final src = Rect.fromLTWH(0, 0, _loadedUiImage!.width.toDouble(),
            _loadedUiImage!.height.toDouble());
        final dst = Rect.fromLTWH(0, 0, exportWidth, exportHeight);
        canvas.drawImageRect(_loadedUiImage!, src, dst, Paint());
      } else {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, exportWidth, exportHeight),
          Paint()..color = _canvasBackgroundColor,
        );
      }

      // Calculate scale from container coordinates to export image coordinates
      final scaleX = exportWidth / containerSize.width;
      final scaleY = exportHeight / containerSize.height;
      final avgScale = (scaleX + scaleY) / 2;

      // Save layer for erasing support
      canvas.saveLayer(Rect.fromLTWH(0, 0, exportWidth, exportHeight), Paint());

      for (final line in _lines) {
        if (line.path.isEmpty) continue;

        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth * avgScale
          ..style = PaintingStyle.stroke;

        if (line.isEraser) {
          paint.blendMode =
              _loadedUiImage != null ? BlendMode.clear : BlendMode.srcOver;
          paint.color = _loadedUiImage != null
              ? Colors.transparent
              : _canvasBackgroundColor;
        } else {
          paint.color = line.color;
        }

        if (line.path.length == 1) {
          paint.style = PaintingStyle.fill;
          final p =
              Offset(line.path.first.dx * scaleX, line.path.first.dy * scaleY);
          canvas.drawCircle(p, (line.strokeWidth * avgScale) / 2, paint);
        } else {
          final path = Path();
          path.moveTo(line.path.first.dx * scaleX, line.path.first.dy * scaleY);
          for (int i = 1; i < line.path.length; i++) {
            path.lineTo(line.path[i].dx * scaleX, line.path[i].dy * scaleY);
          }
          canvas.drawPath(path, paint);
        }
      }

      canvas.restore();

      final picture = recorder.endRecording();
      final image =
          await picture.toImage(exportWidth.toInt(), exportHeight.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('ছবি তৈরি করা সম্ভব হয়নি');
      }

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'drawn_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(buffer);

      final savedPath =
          await StorageUtils.saveFileToCustomFolder(tempFile.path, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedPath != null
                  ? 'ছবি গ্যালারিতে সংরক্ষিত হয়েছে! (MS Smart Tools)'
                  : 'সংরক্ষণ ব্যর্থ হয়েছে!',
            ),
            backgroundColor: savedPath != null ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _loadedUiImage != null || _isBlankCanvas;

    return Scaffold(
      backgroundColor: const Color(0xFF181824),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242434),
        foregroundColor: Colors.white,
        title: const Text(
          'Draw on Image',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'ছবি আনুন',
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'আনডু',
            onPressed: _lines.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'রিডু',
            onPressed: _redoStack.isNotEmpty ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'মুছে ফেলুন',
            onPressed: _lines.isNotEmpty ? _clearCanvas : null,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final containerSize =
              Size(constraints.maxWidth, constraints.maxHeight);

          if (!hasContent) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Drawing Canvas Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: _imageAspectSize != null
                              ? _imageAspectSize!.width /
                                  _imageAspectSize!.height
                              : 1.0,
                          child: LayoutBuilder(
                            builder: (context, canvasConstraints) {
                              final canvasSize = Size(
                                canvasConstraints.maxWidth,
                                canvasConstraints.maxHeight,
                              );

                              return GestureDetector(
                                onPanStart: (details) {
                                  setState(() {
                                    _redoStack.clear();
                                    _currentLine = DrawnLine(
                                      path: [details.localPosition],
                                      color: _selectedColor,
                                      strokeWidth: _strokeWidth,
                                      isEraser: _isEraser,
                                    );
                                  });
                                },
                                onPanUpdate: (details) {
                                  if (_currentLine != null) {
                                    setState(() {
                                      final newPath =
                                          List<Offset>.from(_currentLine!.path)
                                            ..add(details.localPosition);
                                      _currentLine = DrawnLine(
                                        path: newPath,
                                        color: _selectedColor,
                                        strokeWidth: _strokeWidth,
                                        isEraser: _isEraser,
                                      );
                                    });
                                  }
                                },
                                onPanEnd: (details) {
                                  if (_currentLine != null) {
                                    setState(() {
                                      _lines.add(_currentLine!);
                                      _currentLine = null;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  size: canvasSize,
                                  painter: _DrawingPainter(
                                    lines: _lines,
                                    currentLine: _currentLine,
                                    bgImage: _loadedUiImage,
                                    backgroundColor: _canvasBackgroundColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Control Bar
              _buildBottomControls(containerSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.brush_rounded,
                size: 72,
                color: Colors.purpleAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Draw (আঁকুন)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ছবি নির্বাচন করুন অথবা খালি ক্যানভাসে আঁকা শুরু করুন',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Pick Image Button
            SizedBox(
              width: 260,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: const Text(
                  'গ্যালারি থেকে ছবি নিন',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Camera Button
            SizedBox(
              width: 260,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.purpleAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, color: Colors.purpleAccent),
                label: const Text(
                  'ক্যামেরা দিয়ে ছবি তুলুন',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Blank Canvas Button
            SizedBox(
              width: 260,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _createBlankCanvas(Colors.white),
                icon: const Icon(Icons.crop_square, color: Colors.grey),
                label: const Text(
                  'খালি সাদা ক্যানভাস শুরু করুন',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(Size containerSize) {
    return Container(
      color: const Color(0xFF242434),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pen vs Eraser toggle & Pen Thickness Slider
          Row(
            children: [
              // Pen Mode Button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor:
                      !_isEraser ? Colors.purpleAccent : Colors.transparent,
                  side: BorderSide(
                      color: !_isEraser ? Colors.purpleAccent : Colors.white24),
                ),
                icon: Icon(Icons.create,
                    color: !_isEraser ? Colors.white : Colors.grey),
                tooltip: 'Pen Tool',
                onPressed: () => setState(() => _isEraser = false),
              ),
              const SizedBox(width: 8),

              // Eraser Mode Button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor:
                      _isEraser ? Colors.purpleAccent : Colors.transparent,
                  side: BorderSide(
                      color: _isEraser ? Colors.purpleAccent : Colors.white24),
                ),
                icon: Icon(Icons.auto_fix_normal,
                    color: _isEraser ? Colors.white : Colors.grey),
                tooltip: 'Eraser Tool',
                onPressed: () => setState(() => _isEraser = true),
              ),
              const SizedBox(width: 12),

              // Pen Thickness Slider label & Indicator
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Container(
                  width: (_strokeWidth).clamp(2.0, 22.0),
                  height: (_strokeWidth).clamp(2.0, 22.0),
                  decoration: BoxDecoration(
                    color: _isEraser ? Colors.white : _selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Slider for Stroke Width (চিকন / মোটা)
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _strokeWidth,
                    min: 1.0,
                    max: 40.0,
                    activeColor: Colors.purpleAccent,
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() => _strokeWidth = val);
                    },
                  ),
                ),
              ),

              Text(
                '${_strokeWidth.round()} px',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Color Palette Swatches & Custom Picker
          Row(
            children: [
              // Custom Color Picker Button
              GestureDetector(
                onTap: _showCustomColorPicker,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purpleAccent, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.palette, color: Colors.purpleAccent, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'পিকার',
                        style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Preset Colors horizontal list
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetColors.length,
                    itemBuilder: (context, index) {
                      final color = _presetColors[index];
                      final isSelected =
                          !_isEraser && _selectedColor.value == color.value;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                            _isEraser = false;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Save Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : () => _saveDrawing(containerSize),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_alt, color: Colors.white, size: 18),
                label: Text(
                  _isSaving ? 'সংরক্ষণ...' : 'সেভ',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final DrawnLine? currentLine;
  final ui.Image? bgImage;
  final Color backgroundColor;

  _DrawingPainter({
    required this.lines,
    required this.currentLine,
    this.bgImage,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background (Image or Solid Color)
    if (bgImage != null) {
      final src = Rect.fromLTWH(
          0, 0, bgImage!.width.toDouble(), bgImage!.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(bgImage!, src, dst, Paint());
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );
    }

    // 2. Save Layer for Eraser BlendMode support
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    final allLines = [...lines];
    if (currentLine != null) {
      allLines.add(currentLine!);
    }

    for (final line in allLines) {
      if (line.path.isEmpty) continue;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.strokeWidth
        ..style = PaintingStyle.stroke;

      if (line.isEraser) {
        paint.blendMode = bgImage != null ? BlendMode.clear : BlendMode.srcOver;
        paint.color = bgImage != null ? Colors.transparent : backgroundColor;
      } else {
        paint.color = line.color;
      }

      if (line.path.length == 1) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(line.path.first, line.strokeWidth / 2, paint);
      } else {
        final path = Path();
        path.moveTo(line.path.first.dx, line.path.first.dy);
        for (int i = 1; i < line.path.length; i++) {
          path.lineTo(line.path[i].dx, line.path[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
