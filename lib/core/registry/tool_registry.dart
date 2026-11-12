import 'package:flutter/material.dart';
import 'smart_tool_model.dart';

import '../../features/qr_tools/presentation/screens/qr_generator_screen.dart';
import '../../features/qr_tools/presentation/screens/qr_scanner_screen.dart';
import '../../features/image_tools/presentation/screens/overlay_screen.dart';
import '../../features/scanner/presentation/screens/scanner_home_screen.dart';
import '../../features/filters/presentation/screens/filters_home_screen.dart';
import '../../features/crop_tool/presentation/screens/crop_home_screen.dart';
import '../../features/image_tools/presentation/screens/text_screen.dart';
import '../../features/image_tools/presentation/screens/draw_screen.dart';
import '../../features/toolbox/presentation/screens/collage_tool_screen.dart';


class ToolRegistry {
  static final List<SmartTool> allTools = [
    const SmartTool(
      id: 'qr_scanner',
      titleBn: 'QR Scanner',
      titleEn: 'QR Scanner',
      category: ToolCategory.utility,
      icon: Icons.qr_code_scanner,
      color: Colors.teal,
      keywords: ['scan', 'code', 'qr', 'barcode', 'gallery', 'স্ক্যান'],
      screen: QrScannerScreen(),
      route: '/qr-scanner',
      accepts: {PayloadKind.qrCode, PayloadKind.image},
      requiresCamera: true,
      analyticsEventName: 'tool_open_qr_scanner',
    ),
    const SmartTool(
      id: 'qr_generator',
      titleBn: 'QR Generator',
      titleEn: 'QR Generator',
      category: ToolCategory.utility,
      icon: Icons.qr_code,
      color: Colors.indigo,
      keywords: ['create', 'code', 'qr', 'make', 'wifi', 'বানানো'],
      screen: QrGeneratorScreen(),
      route: '/qr-generator',
      accepts: {PayloadKind.text},
      requiresStorage: true,
      analyticsEventName: 'tool_open_qr_generator',
    ),
    const SmartTool(
      id: 'crop',
      titleBn: 'Crop',
      titleEn: 'Crop',
      category: ToolCategory.utility,
      icon: Icons.crop_rounded,
      color: Colors.deepPurple,
      keywords: [
        'crop',
        'dewarp',
        'perspective',
        'scanner',
        'doc',
        'document',
        'gallery',
        'ক্রপ',
        'কাট',
        'কাটা'
      ],
      screen: CropHomeScreen(),
      route: '/crop',
      accepts: {PayloadKind.image},
      requiresCamera: true,
      requiresStorage: true,
      analyticsEventName: 'tool_open_crop',
    ),
    const SmartTool(
      id: 'rotation_mirror',
      titleBn: 'Rotation & Mirror',
      titleEn: 'Rotation & Mirror',
      category: ToolCategory.utility,
      icon: Icons.crop_rotate,
      color: Colors.indigo,
      keywords: ['rotate', 'mirror', 'flip', 'rotation', 'image', 'editor', 'ঘুরানো'],
      screen: ScannerHomeScreen(),
      route: '/rotation-mirror',
      accepts: {PayloadKind.image},
      requiresCamera: true,
      requiresStorage: true,
      analyticsEventName: 'tool_open_rotation_mirror',
    ),
    const SmartTool(
      id: 'filters',
      titleBn: 'Filters',
      titleEn: 'Filters',
      category: ToolCategory.utility,
      icon: Icons.auto_awesome_mosaic,
      color: Colors.teal,
      keywords: [
        'filters',
        'magic',
        'filter',
        'crop',
        'enhance',
        'scanner',
        'doc',
        'ফিল্টার',
        'grayscale',
        'color',
        'shadow',
        'image',
        'photo'
      ],
      screen: FiltersHomeScreen(),
      route: '/filters',
      accepts: {PayloadKind.image},
      requiresCamera: true,
      requiresStorage: true,
      analyticsEventName: 'tool_open_filters',
    ),
    const SmartTool(
      id: 'text',
      titleBn: 'Text',
      titleEn: 'Text',
      category: ToolCategory.utility,
      icon: Icons.title,
      color: Colors.deepOrange,
      keywords: ['text', 'image', 'photo', 'font', 'overlay', 'editor', 'লেখা'],
      screen: TextScreen(),
      route: '/text',
      accepts: {PayloadKind.image, PayloadKind.text},
      requiresStorage: true,
      analyticsEventName: 'tool_open_text',
    ),
    const SmartTool(
      id: 'draw',
      titleBn: 'Draw',
      titleEn: 'Draw',
      category: ToolCategory.utility,
      icon: Icons.brush_rounded,
      color: Colors.purple,
      keywords: [
        'draw',
        'pen',
        'brush',
        'paint',
        'image',
        'color',
        'sketch',
        'markup',
        'আঁকা'
      ],
      screen: DrawScreen(),
      route: '/draw',
      accepts: {PayloadKind.image},
      requiresStorage: true,
      analyticsEventName: 'tool_open_draw',
    ),
    const SmartTool(
      id: 'collage',
      titleBn: 'Collage & Merge',
      titleEn: 'Collage & Merge',
      category: ToolCategory.utility,
      icon: Icons.grid_view_rounded,
      color: Colors.purple,
      keywords: [
        'collage',
        'grid',
        'photo',
        'merge',
        'picture',
        'কোলাজ',
        'combine',
        'join'
      ],
      screen: CollageToolScreen(),
      route: '/collage',
      accepts: {PayloadKind.images},
      requiresStorage: true,
      analyticsEventName: 'tool_open_collage',
    ),
    const SmartTool(
      id: 'overlay',
      titleBn: 'Overlay',
      titleEn: 'Overlay',
      category: ToolCategory.utility,
      icon: Icons.layers,
      color: Colors.teal,
      keywords: ['image', 'overlay', 'layers'],
      screen: OverlayScreen(),
      route: '/overlay',
      accepts: {PayloadKind.image, PayloadKind.images},
      requiresStorage: true,
      analyticsEventName: 'tool_open_overlay',
    ),


  ];

  static List<SmartTool> get mainMenuTools => allTools;

  static SmartTool? getById(String id) {
    try {
      return allTools.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<SmartTool> forPayload(PayloadKind payload) {
    return allTools.where((t) => t.accepts.contains(payload)).toList();
  }

  static List<SmartTool> getByCategory(ToolCategory category) {
    return allTools.where((t) => t.category == category).toList();
  }

  static List<SmartTool> getToolsRequiringCamera() {
    return allTools.where((t) => t.requiresCamera).toList();
  }

  static List<SmartTool> getToolsRequiringStorage() {
    return allTools.where((t) => t.requiresStorage).toList();
  }

  static List<SmartTool> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return allTools.where((t) {
      return t.titleBn.toLowerCase().contains(q) ||
          t.titleEn.toLowerCase().contains(q) ||
          t.keywords.any((k) => k.contains(q));
    }).toList();
  }
}
