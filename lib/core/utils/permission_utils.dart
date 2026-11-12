import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../errors/error_handler.dart';

class PermissionUtils {
  static const String _firstEntryKey = 'first_entry_permission_asked';
  static const String _lastCameraPromptKey = 'last_camera_prompt_date';
  static const String _lastPhotosPromptKey = 'last_photos_prompt_date';

  /// Called on first entry to the app to request camera and photos permissions.
  static Future<void> checkAndRequestInitialPermissions(
      BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAsked = prefs.getBool(_firstEntryKey) ?? false;
      if (alreadyAsked) return;

      await prefs.setBool(_firstEntryKey, true);

      final cameraStatus = await Permission.camera.status;
      final photosStatus = await Permission.photos.status;

      if (cameraStatus.isGranted &&
          (photosStatus.isGranted || photosStatus.isLimited)) {
        return;
      }

      if (!context.mounted) return;

      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('অ্যাপের অনুমতি (Permissions)'),
            ],
          ),
          content: const Text(
            'এই ইমেজ এডিটিং অ্যাপটি সঠিকভাবে কাজ করার জন্য এবং ক্যামেরা ও গ্যালারি থেকে ছবি নিয়ে এডিট করার জন্য ক্যামেরা এবং ফটো অ্যাক্সেস প্রয়োজন। আপনার ছবিগুলো সম্পূর্ণ সুরক্ষিত থাকে এবং ডিভাইসের বাইরে কোথাও পাঠানো হয় না।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('পরে দিন'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white),
              child: const Text('অনুমতি দিন'),
            ),
          ],
        ),
      );

      if (shouldRequest == true && context.mounted) {
        await [Permission.camera, Permission.photos].request();
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'PermissionUtils.checkAndRequestInitialPermissions');
    }
  }

  static Future<bool> requestCameraPermission(BuildContext context,
      {String? customMessage}) async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;

      if (!await _shouldPromptToday(_lastCameraPromptKey)) {
        return status.isGranted;
      }

      if (!context.mounted) return false;

      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('ক্যামেরা অনুমতি (Camera Permission)'),
            ],
          ),
          content: Text(
            customMessage ??
                'ডকুমেন্ট বা ছবি তোলার জন্য ক্যামেরার প্রয়োজন। আপনার ছবি আপনার অনুমতি ছাড়া কোনো সার্ভারে পাঠানো হবে না।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white),
              child: const Text('অনুমতি দিন'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        final result = await Permission.camera.request();
        if (result.isPermanentlyDenied && context.mounted) {
          _showSettingsDialog(context, 'ক্যামেরা');
        }
        return result.isGranted;
      }
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'PermissionUtils.requestCameraPermission');
      return false;
    }
  }

  static Future<bool> requestPhotosPermission(BuildContext context) async {
    try {
      const permission = Permission.photos;
      final status = await permission.status;
      if (status.isGranted || status.isLimited) return true;

      if (!await _shouldPromptToday(_lastPhotosPromptKey)) {
        return status.isGranted || status.isLimited;
      }

      if (!context.mounted) return false;

      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.photo_library, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('গ্যালারি অনুমতি (Photo Access)'),
            ],
          ),
          content: const Text(
            'গ্যালারি থেকে ছবি নির্বাচন করার জন্য ফটো অ্যাক্সেস প্রয়োজন। আপনার ছবিগুলো সম্পূর্ণ সুরক্ষিত থাকে এবং ডিভাইসের বাইরে কোথাও পাঠানো হয় না।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white),
              child: const Text('অনুমতি দিন'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        final result = await permission.request();
        if (result.isPermanentlyDenied && context.mounted) {
          _showSettingsDialog(context, 'গ্যালারি');
        }
        return result.isGranted || result.isLimited;
      }
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'PermissionUtils.requestPhotosPermission');
      return false;
    }
  }

  static Future<bool> _shouldPromptToday(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(key);
      final today = DateTime.now().toIso8601String().substring(0, 10);

      if (lastDate == today) {
        return false;
      }

      await prefs.setString(key, today);
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'PermissionUtils._shouldPromptToday');
      return true;
    }
  }

  static void _showSettingsDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$featureName অনুমতি প্রয়োজন'),
        content: Text(
            'অ্যাপের সেটিংস থেকে অনুগ্রহ করে $featureName অনুমতিটি চালু করুন।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('সেটিংস খুলুন'),
          ),
        ],
      ),
    );
  }

  /// Generic permission helper with standard dialog and settings fallback
  static Future<bool> ensurePermission(
    BuildContext context,
    Permission permission, {
    required String featureName,
    String? explanationText,
  }) async {
    try {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) return true;

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          _showSettingsDialog(context, featureName);
        }
        return false;
      }

      final result = await permission.request();
      if (result.isPermanentlyDenied && context.mounted) {
        _showSettingsDialog(context, featureName);
      }
      return result.isGranted || result.isLimited;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'PermissionUtils.ensurePermission');
      return false;
    }
  }

  /// Displays a user-friendly error SnackBar for any AppException instance
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
