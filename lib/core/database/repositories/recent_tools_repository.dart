import 'package:hive_flutter/hive_flutter.dart';
import '../../errors/app_exception.dart';

abstract class RecentToolsRepository {
  Future<List<String>> getRecentTools();
  Future<void> addRecentTool(String toolId);
  Future<void> clearRecentTools();
}

class HiveRecentToolsRepository implements RecentToolsRepository {
  static const String _boxName = 'recent_tools';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box<String>(_boxName);
      } else {
        _box = await Hive.openBox<String>(_boxName);
      }
      return _box!;
    } catch (e, stackTrace) {
      throw StorageException(
        'Failed to open recent_tools box',
        keyOrBox: _boxName,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<String>> getRecentTools() async {
    try {
      final box = await _getBox();
      return box.values.toList();
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to read recent tools from Hive',
        keyOrBox: _boxName,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> addRecentTool(String toolId) async {
    try {
      final box = await _getBox();
      final items = box.values.toList();

      items.remove(toolId);
      items.insert(0, toolId);

      final trimmed = items.length > 10 ? items.sublist(0, 10) : items;

      await box.clear();
      await box.addAll(trimmed);
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to add recent tool to Hive',
        keyOrBox: _boxName,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> clearRecentTools() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to clear recent tools from Hive',
        keyOrBox: _boxName,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
