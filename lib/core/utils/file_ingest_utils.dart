import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../errors/app_failure.dart';

sealed class IngestOutcome<T> {
  const IngestOutcome();
}

final class IngestSuccess<T> extends IngestOutcome<T> {
  final T file;
  const IngestSuccess(this.file);
}

final class IngestFailure<T> extends IngestOutcome<T> {
  final AppFailure failure;
  const IngestFailure(this.failure);
}

class FileIngestUtils {
  static const int maxFileSizeBytes = 60 * 1024 * 1024; // 60 MB
  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.pdf',
  };

  /// Validates and securely copies shared/external files to private app storage.
  /// Prevents path traversal and content URI invalidation.
  static Future<IngestOutcome<File>> ingestSharedFile(String srcPath) async {
    try {
      final src = File(srcPath);
      if (!await src.exists()) {
        return const IngestFailure(
          FileFailure(userMessage: 'ফাইলটি পাওয়া যায়নি।'),
        );
      }

      final len = await src.length();
      if (len == 0) {
        return const IngestFailure(
          FileFailure(userMessage: 'ফাইলটি খালি (0 Bytes)।'),
        );
      }

      if (len > maxFileSizeBytes) {
        return const IngestFailure(
          FileFailure(
            userMessage: 'ফাইলটি অত্যন্ত বড় (সর্বোচ্চ ৬০ MB সমর্থিত)।',
          ),
        );
      }

      final ext = p.extension(srcPath).toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        return IngestFailure(
          FileFailure(userMessage: 'অসমর্থিত ফাইল ফরম্যাট ($ext)।'),
        );
      }

      final appDir = await getApplicationSupportDirectory();
      final inboxDir = Directory(p.join(appDir.path, 'inbox'));
      if (!await inboxDir.exists()) {
        await inboxDir.create(recursive: true);
      }

      final safeName = '${const Uuid().v4()}$ext';
      final targetPath = p.join(inboxDir.path, safeName);
      final dst = await src.copy(targetPath);

      return IngestSuccess(dst);
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 28) {
        return const IngestFailure(
          StorageFailure(userMessage: 'ডিভাইসে যথেষ্ট স্টোরেজ খালি নেই।'),
        );
      }
      return IngestFailure(
        FileFailure(
          userMessage: 'ফাইল কপি করতে ব্যর্থ হয়েছে।',
          technicalDetails: e.message,
        ),
      );
    } catch (e) {
      return IngestFailure(
        FileFailure(
          userMessage: 'একটি অপ্রত্যাশিত ফাইল ত্রুটি ঘটেছে।',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Cleans up old inbox files older than 24 hours.
  static Future<void> cleanupOldInboxFiles() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final inboxDir = Directory(p.join(appDir.path, 'inbox'));
      if (!await inboxDir.exists()) return;

      final now = DateTime.now();
      await for (final entity in inboxDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (now.difference(stat.modified).inHours >= 24) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }
}
