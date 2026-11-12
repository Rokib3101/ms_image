import 'package:flutter/material.dart';
import '../database/repositories/recent_tools_repository.dart';
import '../errors/error_handler.dart';
import 'tool_registry.dart';
import 'smart_tool_model.dart';

class ToolProvider extends ChangeNotifier {
  final RecentToolsRepository _repository;

  List<String> _recent = [];

  List<SmartTool> get recentTools {
    final list = <SmartTool>[];
    for (final id in _recent) {
      final matches = ToolRegistry.allTools.where((t) => t.id == id);
      if (matches.isNotEmpty) {
        list.add(matches.first);
      }
    }
    return list.take(5).toList();
  }

  ToolProvider({RecentToolsRepository? repository})
      : _repository = repository ?? HiveRecentToolsRepository() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _recent = await _repository.getRecentTools();
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ToolProvider._loadData');
    }
  }

  Future<void> addToRecent(String toolId) async {
    try {
      await _repository.addRecentTool(toolId);
      _recent = await _repository.getRecentTools();
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ToolProvider.addToRecent');
    }
  }

  /// Clears all stored recent tools from repository
  Future<void> clearRecentTools() async {
    try {
      await _repository.clearRecentTools();
      _recent.clear();
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ToolProvider.clearRecentTools');
    }
  }
}
