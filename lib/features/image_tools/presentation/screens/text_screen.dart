import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/text_overlay_service.dart';
import '../../../../core/utils/storage_utils.dart';
import '../../../../core/utils/permission_utils.dart';

class TextScreen extends StatefulWidget {
  final String? initialImagePath;

  const TextScreen({super.key, this.initialImagePath});

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  String? _imagePath;
  Size? _imagePixelSize;

  // List of text items
  final List<TextOverlayData> _overlays = [];
  int _selectedOverlayIndex = -1;

  final TextEditingController _textController = TextEditingController();
  Color _selectedTextColor = Colors.white;
  Color? _selectedBgColor = Colors.transparent;
  double _fontSize = 28.0;
  bool _hasShadow = true;
  double _rotation = 0.0;
  double _opacity = 1.0;
  double _baseRotation = 0.0;
  double _baseFontSize = 28.0;

  bool _isSaving = false;

  final List<Color> _colorPalette = const [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  final List<Color?> _bgPalette = [
    Colors.transparent, // Transparent
    Colors.black54,
    Colors.black,
    Colors.white70,
    Colors.white,
    Colors.red.shade700,
    Colors.blue.shade700,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _loadImage(widget.initialImagePath!);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadImage(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    final decoded = await decodeImageFromList(await file.readAsBytes());
    setState(() {
      _imagePath = path;
      _imagePixelSize =
          Size(decoded.width.toDouble(), decoded.height.toDouble());
      _overlays.clear();
      _selectedOverlayIndex = -1;
    });

    // Add initial default text item
    _addNewText('টেক্সট লিখুন');
  }

  Future<void> _pickImage() async {
    final hasPermission =
        await PermissionUtils.requestPhotosPermission(context);
    if (!hasPermission) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _loadImage(image.path);
    }
  }

  void _addNewText([String text = 'নতুন টেক্সট']) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newOverlay = TextOverlayData(
      id: id,
      text: text,
      positionRatio: const Offset(0.3, 0.4),
      textColor: _selectedTextColor,
      backgroundColor: _selectedBgColor,
      fontSize: _fontSize,
      hasShadow: _hasShadow,
      rotation: 0.0,
      opacity: _opacity,
    );

    setState(() {
      _overlays.add(newOverlay);
      _selectedOverlayIndex = _overlays.length - 1;
      _textController.text = text;
      _rotation = 0.0;
    });
  }

  void _updateSelectedOverlay() {
    if (_selectedOverlayIndex < 0 || _selectedOverlayIndex >= _overlays.length)
      return;

    final current = _overlays[_selectedOverlayIndex];
    final updated = current.copyWith(
      text: _textController.text,
      textColor: _selectedTextColor,
      backgroundColor: _selectedBgColor,
      fontSize: _fontSize,
      hasShadow: _hasShadow,
      rotation: _rotation,
      opacity: _opacity,
    );

    setState(() {
      _overlays[_selectedOverlayIndex] = updated;
    });
  }

  void _deleteSelectedOverlay() {
    if (_selectedOverlayIndex < 0 || _selectedOverlayIndex >= _overlays.length)
      return;

    setState(() {
      _overlays.removeAt(_selectedOverlayIndex);
      if (_overlays.isNotEmpty) {
        _selectedOverlayIndex = _overlays.length - 1;
        _textController.text = _overlays[_selectedOverlayIndex].text;
        _rotation = _overlays[_selectedOverlayIndex].rotation;
        _opacity = _overlays[_selectedOverlayIndex].opacity;
      } else {
        _selectedOverlayIndex = -1;
        _textController.clear();
        _rotation = 0.0;
        _opacity = 1.0;
      }
    });
  }

  Future<void> _saveResult() async {
    if (_imagePath == null || _overlays.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final bakedPath = await TextOverlayService.renderTextOverlay(
        imagePath: _imagePath!,
        overlays: _overlays,
      );

      if (bakedPath != null) {
        final fileName =
            'edited_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedPath =
            await StorageUtils.saveFileToCustomFolder(bakedPath, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(savedPath != null
                  ? 'গ্যালারিতে সংরক্ষিত হয়েছে! (MS Smart Tools)'
                  : 'সংরক্ষণ ব্যর্থ হয়েছে!'),
              backgroundColor: savedPath != null ? Colors.green : Colors.red,
            ),
          );
        }
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
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3D),
        foregroundColor: Colors.white,
        title: const Text('Add Text to Image',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_imagePath != null)
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: 'নতুন ছবি',
              onPressed: _pickImage,
            ),
          if (_imagePath != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save'),
                onPressed: _isSaving ? null : _saveResult,
              ),
            ),
        ],
      ),
      body: _imagePath == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.text_fields,
                        size: 50, color: Colors.deepPurpleAccent),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ছবিতে টেক্সট যুক্ত করুন',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'গ্যালারি থেকে ছবি সিলেক্ট করুন এবং কাস্টম টেক্সট বসান',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('গ্যালারি থেকে ছবি বেছে নিন',
                        style: TextStyle(fontSize: 16)),
                    onPressed: _pickImage,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Interactive Canvas Area
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewSize = constraints.biggest;
                      final imgAspect =
                          _imagePixelSize!.width / _imagePixelSize!.height;
                      final viewAspect = viewSize.width / viewSize.height;

                      Size displaySize;
                      if (imgAspect > viewAspect) {
                        displaySize =
                            Size(viewSize.width, viewSize.width / imgAspect);
                      } else {
                        displaySize =
                            Size(viewSize.height * imgAspect, viewSize.height);
                      }

                      return Center(
                        child: Container(
                          width: displaySize.width,
                          height: displaySize.height,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Stack(
                            children: [
                              // Background Image
                              Positioned.fill(
                                child: Image.file(File(_imagePath!),
                                    fit: BoxFit.fill),
                              ),

                              // Text Overlays
                              ...List.generate(_overlays.length, (index) {
                                final overlay = _overlays[index];
                                final isSelected =
                                    index == _selectedOverlayIndex;

                                final x = overlay.positionRatio.dx *
                                    displaySize.width;
                                final y = overlay.positionRatio.dy *
                                    displaySize.height;

                                final hasBg = overlay.backgroundColor != null &&
                                    overlay.backgroundColor !=
                                        Colors.transparent;

                                return Positioned(
                                  left: x,
                                  top: y,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedOverlayIndex = index;
                                        _textController.text = overlay.text;
                                        _selectedTextColor = overlay.textColor;
                                        _selectedBgColor =
                                            overlay.backgroundColor;
                                        _fontSize = overlay.fontSize;
                                        _hasShadow = overlay.hasShadow;
                                        _rotation = overlay.rotation;
                                        _opacity = overlay.opacity;
                                      });
                                    },
                                    onScaleStart: (details) {
                                      setState(() {
                                        _selectedOverlayIndex = index;
                                        _textController.text = overlay.text;
                                        _selectedTextColor = overlay.textColor;
                                        _selectedBgColor =
                                            overlay.backgroundColor;
                                        _fontSize = overlay.fontSize;
                                        _hasShadow = overlay.hasShadow;
                                        _rotation = overlay.rotation;
                                        _opacity = overlay.opacity;
                                      });
                                      _baseRotation = overlay.rotation;
                                      _baseFontSize = overlay.fontSize;
                                    },
                                    onScaleUpdate: (details) {
                                      if (_selectedOverlayIndex != index)
                                        return;

                                      double newRotation = overlay.rotation;
                                      double newFontSize = overlay.fontSize;

                                      if (details.pointerCount >= 2) {
                                        newRotation =
                                            _baseRotation + details.rotation;
                                        if (details.scale != 1.0) {
                                          newFontSize =
                                              (_baseFontSize * details.scale)
                                                  .clamp(14.0, 80.0);
                                        }
                                      }

                                      final newX = (x +
                                              details.focalPointDelta.dx)
                                          .clamp(0.0, displaySize.width - 40);
                                      final newY = (y +
                                              details.focalPointDelta.dy)
                                          .clamp(0.0, displaySize.height - 30);

                                      final updated = overlay.copyWith(
                                        positionRatio: Offset(
                                          newX / displaySize.width,
                                          newY / displaySize.height,
                                        ),
                                        rotation: newRotation,
                                        fontSize: newFontSize,
                                      );

                                      setState(() {
                                        _overlays[index] = updated;
                                        _rotation = newRotation;
                                        _fontSize = newFontSize;
                                      });
                                    },
                                    child: Opacity(
                                      opacity: overlay.opacity.clamp(0.0, 1.0),
                                      child: Transform.rotate(
                                        angle: overlay.rotation,
                                        child: Container(
                                          padding: hasBg
                                              ? const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4)
                                              : const EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: hasBg
                                                ? overlay.backgroundColor
                                                : Colors.transparent,
                                            borderRadius: hasBg
                                                ? BorderRadius.circular(6)
                                                : null,
                                            border: isSelected
                                                ? Border.all(
                                                    color: Colors.yellowAccent,
                                                    width: 1.5)
                                                : null,
                                          ),
                                          child: Text(
                                            overlay.text.isEmpty
                                                ? 'টেক্সট...'
                                                : overlay.text,
                                            style: TextStyle(
                                              color: overlay.textColor,
                                              fontSize: overlay.fontSize *
                                                  (displaySize.height / 600.0)
                                                      .clamp(0.5, 2.5),
                                              fontWeight: FontWeight.bold,
                                              shadows: overlay.hasShadow
                                                  ? const [
                                                      Shadow(
                                                        offset: Offset(2, 2),
                                                        blurRadius: 4,
                                                        color: Colors.black87,
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              if (_isSaving)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Text Control Panel
                Container(
                  color: const Color(0xFF2A2A3D),
                  padding: const EdgeInsets.all(12),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Input field & Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'টেক্সট টাইপ করুন...',
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFF1E1E2C),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (_) => _updateSelectedOverlay(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent),
                              icon: const Icon(Icons.add, color: Colors.white),
                              tooltip: 'নতুন টেক্সট যোগ করুন',
                              onPressed: () => _addNewText('নতুন টেক্সট'),
                            ),
                            if (_selectedOverlayIndex >= 0) ...[
                              const SizedBox(width: 4),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                    backgroundColor: Colors.redAccent.shade200),
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.white),
                                tooltip: 'টেক্সট মুছুন',
                                onPressed: _deleteSelectedOverlay,
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Text Color Selection
                        Row(
                          children: [
                            const Text('রং:',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _colorPalette.map((color) {
                                    final isSelected =
                                        _selectedTextColor == color;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(
                                            () => _selectedTextColor = color);
                                        _updateSelectedOverlay();
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.yellowAccent
                                                : Colors.grey.shade600,
                                            width: isSelected ? 3 : 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Background Color Selection & Font Size Slider
                        Row(
                          children: [
                            const Text('ব্যাকগ্রাউন্ড:',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _bgPalette.map((bgColor) {
                                    final isTransparent = bgColor == null ||
                                        bgColor == Colors.transparent;
                                    final isSelected = (isTransparent &&
                                            (_selectedBgColor == null ||
                                                _selectedBgColor ==
                                                    Colors.transparent)) ||
                                        (!isTransparent &&
                                            _selectedBgColor == bgColor);

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => _selectedBgColor =
                                            isTransparent
                                                ? Colors.transparent
                                                : bgColor);
                                        _updateSelectedOverlay();
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: isTransparent
                                              ? Colors.transparent
                                              : bgColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.yellowAccent
                                                : Colors.grey,
                                            width: isSelected ? 2.5 : 1,
                                          ),
                                        ),
                                        child: isTransparent
                                            ? const Icon(Icons.block,
                                                size: 14, color: Colors.white70)
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Size Slider
                        Row(
                          children: [
                            const Text('সাইজ:',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: _fontSize,
                                min: 14.0,
                                max: 64.0,
                                activeColor: Colors.deepPurpleAccent,
                                inactiveColor: Colors.white24,
                                onChanged: (val) {
                                  setState(() => _fontSize = val);
                                  _updateSelectedOverlay();
                                },
                              ),
                            ),
                            Text('${_fontSize.round()}px',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Opacity Slider
                        Row(
                          children: [
                            const Text('ওপাসিটি:',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: _opacity,
                                min: 0.0,
                                max: 1.0,
                                activeColor: Colors.deepPurpleAccent,
                                inactiveColor: Colors.white24,
                                onChanged: (val) {
                                  setState(() => _opacity = val);
                                  _updateSelectedOverlay();
                                },
                              ),
                            ),
                            Text(
                              '${(_opacity * 100).round()}%',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Rotation Slider
                        Row(
                          children: [
                            const Text('ঘুরান:',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: _rotation,
                                min: -3.14159,
                                max: 3.14159,
                                activeColor: Colors.deepPurpleAccent,
                                inactiveColor: Colors.white24,
                                onChanged: (val) {
                                  setState(() => _rotation = val);
                                  _updateSelectedOverlay();
                                },
                              ),
                            ),
                            Text(
                              '${(_rotation * 180 / 3.14159).round()}°',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            if (_rotation != 0.0)
                              IconButton(
                                icon: const Icon(Icons.rotate_left,
                                    color: Colors.yellowAccent, size: 20),
                                tooltip: 'রোটেশন রিসেট (0°)',
                                onPressed: () {
                                  setState(() => _rotation = 0.0);
                                  _updateSelectedOverlay();
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
