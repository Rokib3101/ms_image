import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:ms_image/core/errors/error_handler.dart';
import 'package:ms_image/core/theme/theme_provider.dart';
import 'package:ms_image/core/navigation/app_router.dart';
import 'package:ms_image/core/registry/tool_provider.dart';
import 'package:ms_image/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:ms_image/features/filters/presentation/providers/filters_provider.dart';
import 'package:ms_image/features/crop_tool/presentation/providers/crop_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Image Cache limits (max 50 images, max 80MB) to prevent OOM
  PaintingBinding.instance.imageCache
    ..maximumSize = 50
    ..maximumSizeBytes = 80 << 20;

  // Global Error Handling Setup
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorHandler.logError(details.exception, details.stack, 'FlutterError.onError');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler.logError(error, stack, 'PlatformDispatcher.onError');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'দুঃখিত, অ্যাপে একটি অপ্রত্যাশিত সমস্যা দেখা দিয়েছে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${details.exception}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  try {
    await Hive.initFlutter();
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace, 'Hive.initFlutter');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ToolProvider()),
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
        ChangeNotifierProvider(create: (_) => FiltersProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MSImageApp(),
    ),
  );
}

class MSImageApp extends StatelessWidget {
  const MSImageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'MS Image',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.getLightTheme(lightDynamic),
          darkTheme: ThemeProvider.getDarkTheme(darkDynamic),
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
