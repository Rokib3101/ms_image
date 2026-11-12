import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Dashboard & Core
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/privacy_policy_screen.dart';
import '../../features/dashboard/presentation/screens/about_screen.dart';
import '../../features/dashboard/presentation/screens/social_media_screen.dart';
import '../../features/dashboard/presentation/screens/settings_screen.dart';

// Utilities & Image Tools
import '../../features/qr_tools/presentation/screens/qr_generator_screen.dart';
import '../../features/qr_tools/presentation/screens/qr_scanner_screen.dart';
import '../../features/scanner/presentation/screens/scanner_home_screen.dart';
import '../../features/filters/presentation/screens/filters_home_screen.dart';
import '../../features/crop_tool/presentation/screens/crop_home_screen.dart';
import '../../features/image_tools/presentation/screens/overlay_screen.dart';
import '../../features/image_tools/presentation/screens/text_screen.dart';
import '../../features/image_tools/presentation/screens/draw_screen.dart';

// Advanced Phase 4 Features
import '../../features/toolbox/presentation/screens/collage_tool_screen.dart';


abstract class AppRoutes {
  static const String dashboard = '/';
  static const String privacyPolicy = '/privacy-policy';
  static const String about = '/about';
  static const String socialMedia = '/social-media';
  static const String settings = '/settings';

  static const String qrScanner = '/qr-scanner';
  static const String qrGenerator = '/qr-generator';
  static const String rotationMirror = '/rotation-mirror';
  static const String filters = '/filters';
  static const String crop = '/crop';
  static const String text = '/text';
  static const String draw = '/draw';
  static const String overlay = '/overlay';

  static const String collage = '/collage';
  static const String privacyMetadata = '/privacy-metadata';
  static const String exif = '/toolbox/exif';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.socialMedia,
        builder: (context, state) => const SocialMediaScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Utilities & Image Tools
      GoRoute(
        path: AppRoutes.qrScanner,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrGenerator,
        builder: (context, state) => const QrGeneratorScreen(),
      ),
      GoRoute(
        path: AppRoutes.rotationMirror,
        builder: (context, state) => const ScannerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.filters,
        builder: (context, state) => const FiltersHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.crop,
        builder: (context, state) => const CropHomeScreen(),
      ),
      GoRoute(
        path: '/doc-scanner',
        redirect: (context, state) => AppRoutes.rotationMirror,
      ),
      GoRoute(
        path: '/cam-tools',
        redirect: (context, state) => AppRoutes.filters,
      ),
      GoRoute(
        path: '/crop-tool',
        redirect: (context, state) => AppRoutes.crop,
      ),
      GoRoute(
        path: AppRoutes.text,
        builder: (context, state) => const TextScreen(),
      ),
      GoRoute(
        path: AppRoutes.draw,
        builder: (context, state) => const DrawScreen(),
      ),
      GoRoute(
        path: AppRoutes.overlay,
        builder: (context, state) => const OverlayScreen(),
      ),

      // Advanced Phase 4 Features
      GoRoute(
        path: AppRoutes.collage,
        builder: (context, state) => const CollageToolScreen(),
      ),

      GoRoute(
        path: '/toolbox',
        redirect: (context, state) => AppRoutes.collage,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}
