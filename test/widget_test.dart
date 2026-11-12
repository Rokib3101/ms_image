import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ms_image/main.dart';
import 'package:ms_image/core/registry/tool_provider.dart';
import 'package:ms_image/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:ms_image/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  testWidgets('MS Image app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ToolProvider()),
          ChangeNotifierProvider(create: (_) => ScannerProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MSImageApp(),
      ),
    );

    expect(find.text('MS Image'), findsOneWidget);
  });
}
