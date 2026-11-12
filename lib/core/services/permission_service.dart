import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Request camera permission with built-in dialog and settings redirect if permanently denied.
  Future<bool> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      }
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionSettingsDialog(
          context,
          title: 'Camera Permission Required',
          content: 'Camera access is required to take photos and scan documents. Please enable it in app settings.',
        );
      }
    }

    return false;
  }

  /// Request storage/photos permission based on Android version.
  Future<bool> requestStoragePermission(BuildContext context) async {
    // For Android 13+ READ_MEDIA_IMAGES, or general storage
    Permission permission = Permission.photos;
    if (await Permission.storage.status.isGranted || await Permission.photos.status.isGranted) {
      return true;
    }

    var status = await permission.request();
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionSettingsDialog(
          context,
          title: 'Storage Permission Required',
          content: 'Storage access is required to save and load images. Please enable it in app settings.',
        );
      }
    }

    return false;
  }

  Future<void> _showPermissionSettingsDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
