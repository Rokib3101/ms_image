library core_database;

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalPersistence {
  static late HiveAesCipher financeCipher;
  static bool isInitialized = false;

  static Future<void> init() async {
    if (isInitialized) return;
    await Hive.initFlutter();

    // Secure key generation/retrieval for Finance data encryption
    const secureStorage = FlutterSecureStorage();
    String? keyString =
        await secureStorage.read(key: 'ms_smart_tools_finance_key');

    List<int> key;
    if (keyString == null) {
      key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'ms_smart_tools_finance_key',
        value: base64UrlEncode(key),
      );
    } else {
      key = base64Url.decode(keyString);
    }

    financeCipher = HiveAesCipher(key);
    isInitialized = true;
  }

  static Future<Box<T>> openEncryptedBox<T>(String boxName) async {
    if (!isInitialized) {
      await init();
    }
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName, encryptionCipher: financeCipher);
  }

  /// Closes all open Hive boxes safely to prevent memory leaks
  static Future<void> closeAllBoxes() async {
    await Hive.close();
    isInitialized = false;
  }
}
