import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../providers/filters_provider.dart';
import '../../data/models/filters_type.dart';
import '../../../scanner/data/services/scanner_storage_service.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../core/utils/gpu_color_filter_utils.dart';

class FiltersEditorScreen extends StatefulWidget {
  const FiltersEditorScreen({super.key});

  @override
  State<FiltersEditorScreen> createState() => _FiltersEditorScreenState();
}

class _FiltersEditorScreenState extends State<FiltersEditorScreen> {
  void _showSaveDialog(BuildContext context, FiltersProvider provider) {
    final originalPath = provider.originalImagePath;
    if (originalPath == null) return;

    final originalName = p.basenameWithoutExtension(originalPath);
    final nameController =
        TextEditingController(text: '${originalName}_filtered');
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
                      'Save Filtered Image',
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
                        prefixIcon: Icon(Icons.image, color: Colors.tealAccent),
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
                            activeColor: Colors.tealAccent,
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
                            activeColor: Colors.tealAccent,
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
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: compressionQuality,
                        min: 30,
                        max: 100,
                        divisions: 14,
                        activeColor: Colors.tealAccent,
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
                          backgroundColor: Colors.teal,
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
    FiltersProvider provider,
    String baseName,
    OutputFormat format,
    int quality,
  ) async {
    final hasPermission =
        await PermissionUtils.requestPhotosPermission(context);
    if (!hasPermission && Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Storage permission is required to save image.')),
        );
      }
      return;
    }

    final savedPath =
        await provider.saveFilteredImage(baseName, format, quality);

    if (!mounted) return;
    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Successfully saved filtered image to MS Smart Tools & Gallery!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to save image.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FiltersProvider>(
      builder: (context, provider, child) {
        final originalPath = provider.originalImagePath;
        final previewPath = provider.previewPath;

        return Scaffold(
          backgroundColor: const Color(0xFF1E222B),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E222B),
            foregroundColor: Colors.white,
            title: const Text(
              'Filter Editor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save'),
                  onPressed: originalPath == null || provider.isLoading
                      ? null
                      : () => _showSaveDialog(context, provider),
                ),
              ),
            ],
          ),
          body: provider.isLoading &&
                  previewPath == null &&
                  originalPath == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent))
              : originalPath == null
                  ? const Center(
                      child: Text('No image selected',
                          style: TextStyle(color: Colors.white70)))
                  : Column(
                      children: [
                        // Preview Area
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                if (previewPath != null &&
                                    File(previewPath).existsSync())
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: ColorFiltered(
                                        colorFilter: GpuColorFilterUtils.getFilter(provider.selectedFilter),
                                        child: Image.file(
                                          File(previewPath),
                                          key: ValueKey(previewPath),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: ColorFiltered(
                                        colorFilter: GpuColorFilterUtils.getFilter(provider.selectedFilter),
                                        child: Image.file(
                                          File(originalPath),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (provider.isLoading)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                              color: Colors.tealAccent),
                                          if (provider.loadingMessage !=
                                              null) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              provider.loadingMessage!,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Filter Selector Panel
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: const Color(0xFF262C38),
                          child: _buildFilterSelector(provider),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildFilterSelector(FiltersProvider provider) {
    final currentFilter = provider.selectedFilter;

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: FiltersType.values.map((type) {
          final isSelected = currentFilter == type;
          return GestureDetector(
            onTap: () => provider.setFilter(type),
            child: Container(
              width: 76,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.teal.shade700 : const Color(0xFF1E222B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.tealAccent : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.auto_awesome,
                    color: isSelected ? Colors.tealAccent : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type.labelEn,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
