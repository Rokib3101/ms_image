import 'package:flutter_test/flutter_test.dart';
import 'package:ms_image/core/errors/app_exception.dart';
import 'package:ms_image/core/errors/app_failure.dart';

void main() {
  group('AppFailure & AppException Unit Tests', () {
    test('FileException converts to FileFailure with custom message', () {
      const exception = FileException('File not found', filePath: '/path/to/img.png');
      final failure = AppFailure.fromException(exception);

      expect(failure, isA<FileFailure>());
      expect(failure.userMessage, contains('ফাইল প্রসেসিং বা সেভ করতে ব্যর্থ হয়েছে'));
      expect(failure.technicalDetails, contains('/path/to/img.png'));
    });

    test('PermissionException converts to PermissionFailure', () {
      const exception = PermissionException('Camera denied', permissionName: 'ক্যামেরা');
      final failure = AppFailure.fromException(exception);

      expect(failure, isA<PermissionFailure>());
      expect(failure.userMessage, contains('ক্যামেরা অনুমতি না থাকায়'));
    });

    test('Unknown exception converts to UnknownFailure', () {
      final exception = Exception('Something unexpected');
      final failure = AppFailure.fromException(exception);

      expect(failure, isA<UnknownFailure>());
      expect(failure.userMessage, contains('একটি অপ্রত্যাশিত ত্রুটি ঘটেছে'));
    });
  });
}
