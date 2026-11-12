import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../../core/registry/tool_registry.dart';
import '../../../../core/registry/smart_tool_model.dart';
import '../../../../core/registry/tool_provider.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/ui/app_more_menu.dart';
import '../../../../core/ui/adaptive_layout.dart';
import '../../../../core/utils/permission_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionUtils.checkAndRequestInitialPermissions(context);
    });

    // For sharing images while app is in memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        _navigateToSharedImage(value.first.path);
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing images while app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        _navigateToSharedImage(value.first.path);
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _navigateToSharedImage(String path) {
    debugPrint("Shared image path received: $path");
    if (mounted) {
      context.push(AppRoutes.rotationMirror, extra: path);
    }
  }

  void _openTool(SmartTool tool) async {
    Provider.of<ToolProvider>(context, listen: false).addToRecent(tool.id);
    await context.push(tool.route);
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = AdaptiveLayout.getGridCrossAxisCount(context);
    final childAspectRatio = AdaptiveLayout.getGridChildAspectRatio(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MS Image',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [
          AppMoreMenuButton(),
        ],
      ),
      body: Consumer<ToolProvider>(
        builder: (context, toolProvider, child) {
          final allTools = ToolRegistry.mainMenuTools;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: allTools.length,
                  itemBuilder: (context, index) {
                    return _buildToolCard(allTools[index], toolProvider);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolCard(SmartTool tool, ToolProvider toolProvider) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${tool.titleBn} টুলটি খুলুন',
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: InkWell(
          onTap: () => _openTool(tool),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: double.infinity),
                Icon(tool.icon, color: tool.color, size: 36),
                const SizedBox(height: 10),
                Text(
                  tool.titleBn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
