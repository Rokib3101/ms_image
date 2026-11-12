import 'package:flutter/material.dart';
import '../../../image_tools/data/services/text_overlay_service.dart';

class TextOverlayEditorSheet extends StatefulWidget {
  final List<TextOverlayData> initialOverlays;
  final ValueChanged<List<TextOverlayData>> onSave;

  const TextOverlayEditorSheet({
    super.key,
    required this.initialOverlays,
    required this.onSave,
  });

  @override
  State<TextOverlayEditorSheet> createState() => _TextOverlayEditorSheetState();
}

class _TextOverlayEditorSheetState extends State<TextOverlayEditorSheet> {
  late List<TextOverlayData> _overlays;
  int _selectedIndex = -1;

  final TextEditingController _textController = TextEditingController();
  Color _selectedTextColor = Colors.white;
  Color? _selectedBgColor = Colors.black87;
  double _fontSize = 28.0;
  double _opacity = 1.0;

  final List<Color> _colors = const [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  final List<Color?> _bgColors = [
    null,
    Colors.black87,
    Colors.white70,
    Colors.red.shade800,
    Colors.blue.shade800,
    Colors.green.shade800,
  ];

  @override
  void initState() {
    super.initState();
    _overlays = widget.initialOverlays.map((e) => e.copyWith()).toList();
    if (_overlays.isNotEmpty) {
      _selectedIndex = 0;
      _loadOverlayData(_overlays[0]);
    } else {
      _addDefaultText();
    }
  }

  void _loadOverlayData(TextOverlayData item) {
    _textController.text = item.text;
    _selectedTextColor = item.textColor;
    _selectedBgColor = item.backgroundColor;
    _fontSize = item.fontSize;
    _opacity = item.opacity;
  }

  void _addDefaultText() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = TextOverlayData(
      id: id,
      text: 'নতুন টেক্সট',
      positionRatio: const Offset(0.2, 0.3),
      textColor: Colors.white,
      backgroundColor: Colors.black87,
      fontSize: 28.0,
      opacity: _opacity,
    );
    setState(() {
      _overlays.add(item);
      _selectedIndex = _overlays.length - 1;
      _loadOverlayData(item);
    });
  }

  void _updateCurrent() {
    if (_selectedIndex < 0 || _selectedIndex >= _overlays.length) return;

    setState(() {
      _overlays[_selectedIndex] = _overlays[_selectedIndex].copyWith(
        text: _textController.text,
        textColor: _selectedTextColor,
        backgroundColor: _selectedBgColor,
        fontSize: _fontSize,
        opacity: _opacity,
      );
    });
  }

  void _deleteCurrent() {
    if (_selectedIndex < 0 || _selectedIndex >= _overlays.length) return;

    setState(() {
      _overlays.removeAt(_selectedIndex);
      if (_overlays.isNotEmpty) {
        _selectedIndex = _overlays.length - 1;
        _loadOverlayData(_overlays[_selectedIndex]);
      } else {
        _selectedIndex = -1;
        _textController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                'ছবিতে টেক্সট যোগ করুন',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('প্রয়োগ করুন'),
                onPressed: () {
                  widget.onSave(_overlays);
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Text Input & Add/Delete Buttons
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'টেক্সট',
                    hintText: 'যে কোন কিছু লিখুন...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _updateCurrent(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                tooltip: 'নতুন টেক্সট',
                onPressed: _addDefaultText,
              ),
              if (_selectedIndex >= 0) ...[
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'মুছুন',
                  onPressed: _deleteCurrent,
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Color Palettes
          Row(
            children: [
              const Text('রং:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _colors.map((color) {
                      final isSelected = _selectedTextColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedTextColor = color);
                          _updateCurrent();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.grey.shade400,
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

          const SizedBox(height: 10),

          // Background Palette
          Row(
            children: [
              const Text('ব্যাকগ্রাউন্ড:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _bgColors.map((bgColor) {
                      final isSelected = _selectedBgColor == bgColor;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedBgColor = bgColor);
                          _updateCurrent();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: bgColor ?? Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected ? Colors.deepPurple : Colors.grey,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: bgColor == null
                              ? const Icon(Icons.block,
                                  size: 14, color: Colors.grey)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Size Slider
          Row(
            children: [
              const Text('সাইজ:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 16.0,
                  max: 64.0,
                  activeColor: Colors.deepPurple,
                  onChanged: (val) {
                    setState(() => _fontSize = val);
                    _updateCurrent();
                  },
                ),
              ),
              Text('${_fontSize.round()}px'),
            ],
          ),

          const SizedBox(height: 8),

          // Opacity Slider
          Row(
            children: [
              const Text('ওপাসিটি:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.deepPurple,
                  onChanged: (val) {
                    setState(() => _opacity = val);
                    _updateCurrent();
                  },
                ),
              ),
              Text('${(_opacity * 100).round()}%'),
            ],
          ),
        ],
      ),
    );
  }
}
