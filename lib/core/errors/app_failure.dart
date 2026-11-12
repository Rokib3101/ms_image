import 'app_exception.dart';

/// User-facing Failure representations with localized Bengali error messages
sealed class AppFailure {
  final String userMessage;
  final String? technicalDetails;

  const AppFailure({
    required this.userMessage,
    this.technicalDetails,
  });

  factory AppFailure.fromException(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return switch (error) {
        FileException e => FileFailure(
            userMessage: 'ফাইল প্রসেসিং বা সেভ করতে ব্যর্থ হয়েছে: ${e.message}',
            technicalDetails: e.filePath != null ? 'File path: ${e.filePath}' : e.originalError?.toString(),
          ),
        PermissionException e => PermissionFailure(
            permissionName: e.permissionName,
            userMessage: '${e.permissionName} অনুমতি না থাকায় কাজটি সম্পন্ন করা যাচ্ছে না।',
          ),
        ImageProcessingException e => ProcessingFailure(
            userMessage: 'ছবি প্রসেস করার সময় একটি ত্রুটি ঘটেছে: ${e.message}',
            technicalDetails: e.originalError?.toString(),
          ),
        StorageException e => StorageFailure(
            userMessage: 'ডাটাবেজ বা লোকাল স্টোরেজে সংরক্ষণে ব্যর্থ হয়েছে।',
            technicalDetails: e.keyOrBox != null ? 'Box/Key: ${e.keyOrBox}' : e.originalError?.toString(),
          ),
      };
    }

    return UnknownFailure(
      userMessage: 'একটি অপ্রত্যাশিত ত্রুটি ঘটেছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      technicalDetails: error.toString(),
    );
  }
}

class PermissionFailure extends AppFailure {
  final String permissionName;

  const PermissionFailure({
    required this.permissionName,
    required super.userMessage,
    super.technicalDetails,
  });
}

class FileFailure extends AppFailure {
  const FileFailure({
    required super.userMessage,
    super.technicalDetails,
  });
}

class ProcessingFailure extends AppFailure {
  const ProcessingFailure({
    required super.userMessage,
    super.technicalDetails,
  });
}

class StorageFailure extends AppFailure {
  const StorageFailure({
    required super.userMessage,
    super.technicalDetails,
  });
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({
    required super.userMessage,
    super.technicalDetails,
  });
}
