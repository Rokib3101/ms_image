import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../providers/crop_provider.dart';
import 'crop_adjust_screen.dart';
import '../../../scanner/data/services/scanner_storage_service.dart';
import '../../../../core/utils/permission_utils.dart';

class CropEditorScreen extends StatefulWidget {
  const CropEditorScreen({super.key});

  @override
  State<CropEditorScreen> createState() => _CropEditorScreenState();
}

class _CropEditorScreenState extends State<CropEditorScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CropProvider>(
      builder: (context, provider, child) {
        final originalPath = provider.originalImagePath;
        final previewPath = provider.currentPreviewPath;

        return Scaffold(
          backgroundColor: const Color(0xFF1E222B),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E222B),
            foregroundColor: Colors.white,
            title: const Text(
              'Crop Studio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
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
                  child: CircularProgressIndicator(color: Colors.cyanAccent))
              : originalPath == null
                  ? const Center(
                      child: Text('No image selected',
                          style: TextStyle(color: Colors.white70)))
                  : Column(
                      children: [
                        // Preview Area
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(12),
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
                                      child: Image.file(
                                        File(previewPath),
                                        key: ValueKey(previewPath),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                else
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(originalPath),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                if (provider.isLoading)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.cyanAccent),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Tools Toolbar (Adjust Corners only)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          color: const Color(0xFF161922),
                          child: SafeArea(
                            top: false,
                            child: Center(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: originalPath == null
                                    ? null
                                    : () async {
                                        final newCorners =
                                            await Navigator.push<List<Offset>>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CropAdjustScreen(
                                              imagePath: originalPath,
                                              initialCorners: provider.corners,
                                            ),
                                          ),
                                        );
                                        if (newCorners != null) {
                                          provider.updateCorners(newCorners);
                                        }
                                      },
                                icon: const Icon(Icons.crop,
                                    color: Colors.cyanAccent, size: 22),
                                label: const Text('Adjust Corners',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
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

  void _showSaveDialog(BuildContext context, CropProvider provider) {
    final originalPath = provider.originalImagePath;
    if (originalPath == null) return;

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
          SnackBar(
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
