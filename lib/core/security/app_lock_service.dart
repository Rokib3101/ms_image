import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../database/repositories/security_repository.dart';
import '../errors/error_handler.dart';

class AppLockService extends ChangeNotifier {
  final SecurityRepository _securityRepository;
  final LocalAuthentication _auth;

  bool _isLocked = false;
  bool get isLocked => _isLocked;

  bool _isPinSet = false;
  bool get isPinSet => _isPinSet;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  AppLockService({
    SecurityRepository? securityRepository,
    LocalAuthentication? auth,
  })  : _securityRepository = securityRepository ?? SecureStorageSecurityRepository(),
        _auth = auth ?? LocalAuthentication() {
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final pin = await _securityRepository.getPin();
      _biometricEnabled = await _securityRepository.isBiometricEnabled();
      _isPinSet = pin != null && pin.isNotEmpty;
      if (_isPinSet) {
        _isLocked = true;
      }
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'AppLockService._loadSecuritySettings');
    }
  }

  Future<bool> isBiometricSupported() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'AppLockService.isBiometricSupported');
      return false;
    }
  }

  Future<bool> setPin(String pin) async {
    try {
      await _securityRepository.savePin(pin);
      _isPinSet = true;
      _isLocked = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'AppLockService.setPin');
      return false;
    }
  }

  Future<bool> verifyPin(String enteredPin) async {
    try {
      final storedPin = await _securityRepository.getPin();
      if (storedPin == enteredPin) {
        _isLocked = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'AppLockService.verifyPin');
      return false;
    }
  }

  Future<void> removePin() async {
    try {
      await _securityRepository.deletePin();
      _isPinSet = false;
      _biometricEnabled = false;
      _isLocked = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'AppLockService.removePin');
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      _biometricEnabled = enabled;
      await _securityRepository.setBiometricEnabled(enabled);
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'AppLockService.setBiometricEnabled');
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!_biometricEnabled) return false;
    try {
      final bool isSupported = await isBiometricSupported();
      if (!isSupported) return false;

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'MS Image আনলক করতে আপনার পরিচয় নিশ্চিত করুন',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (didAuthenticate) {
        _isLocked = false;
        notifyListeners();
      }
      return didAuthenticate;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'AppLockService.authenticateWithBiometrics');
      return false;
    }
  }

  void lockApp() {
    if (_isPinSet) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isLocked = false;
    notifyListeners();
  }
}
