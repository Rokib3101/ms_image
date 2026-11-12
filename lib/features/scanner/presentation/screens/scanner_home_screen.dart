import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/scanner_provider.dart';
import 'scanner_editor_screen.dart';
import '../../../../core/utils/permission_utils.dart';

class ScannerHomeScreen extends StatelessWidget {
  const ScannerHomeScreen({super.key});

  Future<void> _pickFromGallery(BuildContext context) async {
    final hasPermission =
        await PermissionUtils.requestPhotosPermission(context);
    if (!hasPermission) return;

    final picker = ImagePicker();
    List<XFile> selectedFiles = [];

    try {
      selectedFiles = await picker.pickMultiImage();
    } catch (_) {
      final single = await picker.pickImage(source: ImageSource.gallery);
      if (single != null) {
        selectedFiles = [single];
      }
    }

    if (selectedFiles.isEmpty) return;

    if (!context.mounted) return;

    final imagePaths = selectedFiles.map((f) => f.path).toList();
    final provider = Provider.of<ScannerProvider>(context, listen: false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerEditorScreen()),
    );

    // Initialize processing session in provider
    provider.initSession(imagePaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Rotation & Mirror',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Hero Graphic & Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rotate_right,
                  size: 54,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Rotation & Mirror',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Select images from Gallery to rotate and mirror.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // Main Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.photo_library, size: 22),
                  label: const Text(
                    'Open Gallery',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _pickFromGallery(context),
                ),
              ),

              const SizedBox(height: 32),

              // Feature Highlights
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Key Features',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800),
                ),
              ),
              const SizedBox(height: 12),

              _buildFeatureTile(
                icon: Icons.rotate_right,
                title: 'Rotation & Mirror',
                description:
                    'Rotate left/right and flip image horizontally or vertically.',
              ),
              _buildFeatureTile(
                icon: Icons.sd_card_outlined,
                title: 'Save to Gallery',
                description:
                    'Saves individual edited images directly as JPG or PNG to MS Smart Tools folder.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.deepPurple, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
