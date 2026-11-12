import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/filters_provider.dart';
import 'filters_editor_screen.dart';
import '../../../../core/utils/permission_utils.dart';

class FiltersHomeScreen extends StatelessWidget {
  const FiltersHomeScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasCam = await PermissionUtils.requestCameraPermission(context);
      if (!hasCam) return;
    } else {
      final hasStorage = await PermissionUtils.requestPhotosPermission(context);
      if (!hasStorage) return;
    }

    final picker = ImagePicker();
    String? imagePath;

    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      imagePath = picked.path;
    }

    if (imagePath == null || imagePath.isEmpty) return;
    if (!context.mounted) return;

    final provider = Provider.of<FiltersProvider>(context, listen: false);
    await provider.initImage(imagePath);

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const FiltersEditorScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Image Filters',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 58,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Professional Image Filters',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Apply magic color, grayscale, b&w, shadow removal and other professional filters instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo (Camera)',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: () => _pickImage(context, ImageSource.camera),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade700,
                    side: BorderSide(color: Colors.teal.shade700, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select from Gallery',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: () => _pickImage(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
