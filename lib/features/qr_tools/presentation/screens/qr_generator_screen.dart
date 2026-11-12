import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/storage_utils.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _controller = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  String _qrData = '';
  bool _isSaving = false;

  Future<void> _saveQrImage() async {
    setState(() => _isSaving = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
        final imagePath = '${directory.path}/$fileName';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);

        final savedPath =
            await StorageUtils.saveFileToCustomFolder(imagePath, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(savedPath != null
                    ? 'QR code saved to MS Smart Tools folder!'
                    : 'Failed to save!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter Link or Text',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => setState(() => _qrData = _controller.text),
                ),
              ),
              onSubmitted: (val) => setState(() => _qrData = val),
            ),
            const SizedBox(height: 40),
            if (_qrData.isNotEmpty)
              Column(
                children: [
                  Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        gapless: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveQrImage,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: Text(_isSaving ? 'Saving...' : 'Save to Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Scan this code to view information',
                      style: TextStyle(color: Colors.black54)),
                ],
              )
            else
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
                    Text('Type text and tap generate button',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
