/// Custom Exception hierarchy for MS Image App
sealed class AppException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, [
    this.originalError,
    this.stackTrace,
  ]);

  @override
  String toString() => 'AppException: $message ${originalError != null ? "($originalError)" : ""}';
}

/// Thrown when file IO operations fail
class FileException extends AppException {
  final String? filePath;

  const FileException(
    String message, {
    this.filePath,
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError, stackTrace);
}

/// Thrown when system or feature permissions are denied
class PermissionException extends AppException {
  final String permissionName;

  const PermissionException(
    String message, {
    required this.permissionName,
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError, stackTrace);
}

/// Thrown during image decoding, cropping, filtering, or encoding failure
class ImageProcessingException extends AppException {
  const ImageProcessingException(
    super.message, [
    super.originalError,
    super.stackTrace,
  ]);
}

/// Thrown when Hive or Local Storage read/write fails
class StorageException extends AppException {
  final String? keyOrBox;

  const StorageException(
    String message, {
    this.keyOrBox,
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError, stackTrace);
}
