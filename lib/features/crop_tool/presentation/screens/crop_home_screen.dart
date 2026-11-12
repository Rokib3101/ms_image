import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/crop_provider.dart';
import 'crop_adjust_screen.dart';
import '../../../../core/utils/permission_utils.dart';

class CropHomeScreen extends StatelessWidget {
  const CropHomeScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasCam = await PermissionUtils.requestCameraPermission(context);
      if (!hasCam) return;
    } else {
      final hasStorage = await PermissionUtils.requestPhotosPermission(context);
      if (!hasStorage) return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    if (!context.mounted) return;

    final provider = Provider.of<CropProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Color(0xFF262C38),
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent),
            SizedBox(width: 20),
            Text('Preparing document...',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    await provider.initSession(picked.path);

    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: CropAdjustScreen(
            imagePath: picked.path,
            initialCorners: provider.corners,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title:
            const Text('Crop', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.crop_rounded,
                  size: 54,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Crop & Dewarp Studio',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Automatically detect document edges, warp perspective, and adjust corners with 8-point precision.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Document (Camera)',
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
                    foregroundColor: Colors.deepPurple.shade700,
                    side: BorderSide(
                        color: Colors.deepPurple.shade700, width: 1.5),
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
