import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../providers/scanner_provider.dart';
import '../../data/services/scanner_storage_service.dart';
import '../widgets/scanner_page_navigation.dart';

class ScannerEditorScreen extends StatefulWidget {
  const ScannerEditorScreen({super.key});

  @override
  State<ScannerEditorScreen> createState() => _ScannerEditorScreenState();
}

class _ScannerEditorScreenState extends State<ScannerEditorScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ScannerProvider>(
      builder: (context, provider, child) {
        final page = provider.currentPage;
        final previewPath = provider.currentPreviewPath;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          appBar: AppBar(
            title: Text(
              provider.totalPages > 1
                  ? 'Rotation & Mirror (${provider.currentIndex + 1}/${provider.totalPages})'
                  : 'Rotation & Mirror',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save'),
                  onPressed: page == null || provider.isLoading
                      ? null
                      : () => _showSaveDialog(context, provider),
                ),
              ),
            ],
          ),
          body: provider.isLoading && page == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.deepPurple),
                      const SizedBox(height: 16),
                      Text(
                        provider.loadingMessage ?? 'Processing...',
                        style:
                            const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : page == null
                  ? const Center(child: Text('No image selected'))
                  : Column(
                      children: [
                        // Document Preview Area
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black12,
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
                                        File(page.originalImagePath),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                if (provider.isLoading)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Controls Section with SafeArea to avoid system navigation bar overlap
                        SafeArea(
                          bottom: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Action Bar: Rotate & Mirror
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                color: Colors.white,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.rotate_left),
                                        tooltip: 'Rotate Left',
                                        onPressed: provider.isLoading
                                            ? null
                                            : () => provider
                                                .rotateCurrentPageLeft(),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.flip),
                                        tooltip: 'Mirror Horizontal',
                                        onPressed: provider.isLoading
                                            ? null
                                            : () => provider
                                                .flipHorizontalCurrentPage(),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.swap_vert),
                                        tooltip: 'Mirror Vertical',
                                        onPressed: provider.isLoading
                                            ? null
                                            : () => provider
                                                .flipVerticalCurrentPage(),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.rotate_right),
                                        tooltip: 'Rotate Right',
                                        onPressed: provider.isLoading
                                            ? null
                                            : () => provider
                                                .rotateCurrentPageRight(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Page Navigation Indicator
                              ScannerPageNavigation(
                                currentIndex: provider.currentIndex,
                                totalPages: provider.totalPages,
                                onPrevious: () => provider.previousPage(),
                                onNext: () => provider.nextPage(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  void _showSaveDialog(BuildContext context, ScannerProvider provider) {
    final page = provider.currentPage;
    if (page == null) return;

    final originalName = p.basenameWithoutExtension(page.originalImagePath);
    final nameController = TextEditingController(text: originalName);
    OutputFormat selectedFormat = OutputFormat.jpg;
    double compressionQuality = 85;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      'Save Edited Image',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Image Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('File Format:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<OutputFormat>(
                            title: const Text('JPG'),
                            subtitle: const Text('Smaller file size'),
                            value: OutputFormat.jpg,
                            groupValue: selectedFormat,
                            onChanged: (val) {
                              if (val != null)
                                setModalState(() => selectedFormat = val);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<OutputFormat>(
                            title: const Text('PNG'),
                            subtitle: const Text('Lossless quality'),
                            value: OutputFormat.png,
                            groupValue: selectedFormat,
                            onChanged: (val) {
                              if (val != null)
                                setModalState(() => selectedFormat = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (selectedFormat == OutputFormat.jpg) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Compression / Quality:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${compressionQuality.round()}%',
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: compressionQuality,
                        min: 20,
                        max: 100,
                        divisions: 16,
                        activeColor: Colors.deepPurple,
                        label: '${compressionQuality.round()}%',
                        onChanged: (val) {
                          setModalState(() => compressionQuality = val);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Smaller Size (20%)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          Text('Best Quality (100%)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                        ],
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
    ScannerProvider provider,
    String baseName,
    OutputFormat format,
    int quality,
  ) async {
    int currentStep = 1;
    int totalSteps = provider.totalPages;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text('Saving image $currentStep of $totalSteps...'),
                ],
              ),
            );
          },
        );
      },
    );

    final savedPaths = await provider.saveSession(
      baseName: baseName,
      format: format,
      quality: quality,
      onProgress: (cur, tot) {
        currentStep = cur;
        totalSteps = tot;
      },
    );

    if (context.mounted) {
      Navigator.pop(context); // Dismiss progress dialog

      if (savedPaths.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Saved successfully to MS Smart Tools! (${savedPaths.length} file(s))'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
