import 'package:flutter/material.dart';

enum ToolCategory {
  finance('Finance', Icons.account_balance_wallet, Colors.indigo),
  calculator('Calculator', Icons.calculate, Colors.orange),
  converter('Converter', Icons.compare_arrows, Colors.blue),
  utility('Utility', Icons.build, Colors.teal),
  system('System', Icons.settings, Colors.blueGrey);

  final String title;
  final IconData icon;
  final Color color;
  const ToolCategory(this.title, this.icon, this.color);
}

enum PayloadKind {
  image,
  images,
  text,
  pdf,
  qrCode,
}

class SmartTool {
  final String id;
  final String titleBn;
  final String titleEn;
  final ToolCategory category;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final Widget screen;
  final String route;
  final Set<PayloadKind> accepts;

  // Metadata for permissions & analytics
  final bool requiresCamera;
  final bool requiresStorage;
  final String analyticsEventName;
  final String? badge;

  const SmartTool({
    required this.id,
    required this.titleBn,
    required this.titleEn,
    required this.category,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.screen,
    required this.route,
    this.accepts = const {},
    this.requiresCamera = false,
    this.requiresStorage = false,
    this.badge,
    String? analyticsEventName,
  }) : analyticsEventName = analyticsEventName ?? 'tool_open_$id';
}
