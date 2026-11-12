import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import '../../../../core/utils/storage_utils.dart';

enum CollageLayoutMode { grid, horizontal, vertical }

class CollageToolScreen extends StatefulWidget {
  const CollageToolScreen({super.key});

  @override
  State<CollageToolScreen> createState() => _CollageToolScreenState();
}

class _CollageToolScreenState extends State<CollageToolScreen>
    with SingleTickerProviderStateMixin {
  final List<File> _images = [];
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;
  CollageLayoutMode _layoutMode = CollageLayoutMode.grid;
  int _gridColumns = 2;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveCollage() async {
    if (_images.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final tempDir = Directory.systemTemp;
        final tempFile = File(
            '${tempDir.path}/collage_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(imageBytes);

        final savedPath = await StorageUtils.saveFileToCustomFolder(
          tempFile.path,
          'Collage_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(savedPath != null
                  ? 'Successfully saved to MS Smart Tools folder!'
                  : 'Failed to save collage'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collage & Merge'),
        bottom: _images.isNotEmpty
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.preview), text: 'Preview'),
                  Tab(icon: Icon(Icons.reorder), text: 'Manage & Reorder'),
                ],
              )
            : null,
        actions: [
          if (_images.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: () => setState(() => _images.clear()),
            ),
        ],
      ),
      body: _images.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No images selected for Collage & Merge',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Select Images'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Preview & Layout Controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Layout Mode & Column Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Grid'),
                              selected: _layoutMode == CollageLayoutMode.grid,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() =>
                                      _layoutMode = CollageLayoutMode.grid);
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Horizontal'),
                              selected:
                                  _layoutMode == CollageLayoutMode.horizontal,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _layoutMode =
                                      CollageLayoutMode.horizontal);
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Vertical'),
                              selected:
                                  _layoutMode == CollageLayoutMode.vertical,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() =>
                                      _layoutMode = CollageLayoutMode.vertical);
                              },
                            ),
                            if (_layoutMode == CollageLayoutMode.grid) ...[
                              const SizedBox(width: 16),
                              ActionChip(
                                avatar: const Icon(Icons.grid_view, size: 16),
                                label: Text('Columns: $_gridColumns'),
                                onPressed: () {
                                  setState(() {
                                    _gridColumns = _gridColumns == 2
                                        ? 3
                                        : (_gridColumns == 3 ? 4 : 2);
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Collage Preview & Capture Area
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Screenshot(
                                controller: _screenshotController,
                                child: Container(
                                  color: Colors.transparent,
                                  child: _buildCollageWidget(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add),
                              label: const Text('Add More'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveCollage,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save),
                              label: Text(
                                  _isSaving ? 'Saving...' : 'Save Collage'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab 2: Manage & Reorder Images
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Images: ${_images.length}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Images'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _images.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _images.removeAt(oldIndex);
                            _images.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          return Card(
                            key: ValueKey(
                                _images[index].path + index.toString()),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_images[index],
                                    width: 50, height: 50, fit: BoxFit.cover),
                              ),
                              title: Text('Image ${index + 1}'),
                              subtitle: Text(
                                  _images[index].path.split('/').last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeImage(index),
                                  ),
                                  const Icon(Icons.drag_handle),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildCollageWidget() {
    if (_layoutMode == CollageLayoutMode.grid) {
      return SizedBox(
        width: 400,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridColumns,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
            childAspectRatio: 1.0,
          ),
          itemCount: _images.length,
          itemBuilder: (context, index) {
            return Image.file(_images[index], fit: BoxFit.cover);
          },
        ),
      );
    } else if (_layoutMode == CollageLayoutMode.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _images.map((file) {
          return Image.file(
            file,
            height: 300,
            fit: BoxFit.fitHeight,
          );
        }).toList(),
      );
    } else {
      // Vertical mode
      return SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _images.map((file) {
            return Image.file(
              file,
              width: 400,
              fit: BoxFit.fitWidth,
            );
          }).toList(),
        ),
      );
    }
  }
}
