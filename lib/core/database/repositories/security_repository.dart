import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../errors/app_exception.dart';

abstract class SecurityRepository {
  Future<String?> getPin();
  Future<void> savePin(String pin);
  Future<void> deletePin();

  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
}

class SecureStorageSecurityRepository implements SecurityRepository {
  final FlutterSecureStorage _storage;

  static const String _pinKey = 'app_lock_pin';
  static const String _biometricKey = 'app_lock_biometric';

  SecureStorageSecurityRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> getPin() async {
    try {
      return await _storage.read(key: _pinKey);
    } catch (e, stackTrace) {
      throw StorageException(
        'Failed to read PIN from Secure Storage',
        keyOrBox: _pinKey,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> savePin(String pin) async {
    try {
      await _storage.write(key: _pinKey, value: pin);
    } catch (e, stackTrace) {
      throw StorageException(
        'Failed to save PIN to Secure Storage',
        keyOrBox: _pinKey,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deletePin() async {
    try {
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _biometricKey);
    } catch (e, stackTrace) {
      throw StorageException(
        'Failed to delete Security data from Secure Storage',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricKey);
      return value == 'true';
    } catch (e, stackTrace) {
      throw StorageException(
        'Failed to read Biometric setting from Secure Storage',
        keyOrBox: _biometricKey,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _biometricKey, value: enabled.toString());
    } catch (e, stackTrace) {
      throw StorageException(
        'Failed to save Biometric setting to Secure Storage',
        keyOrBox: _biometricKey,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
