import 'package:flutter/material.dart';

enum DeviceFormFactor {
  mobile,
  tablet,
  desktop,
}

class AdaptiveLayout {
  static DeviceFormFactor getFormFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) {
      return DeviceFormFactor.desktop;
    } else if (width >= 600) {
      return DeviceFormFactor.tablet;
    } else {
      return DeviceFormFactor.mobile;
    }
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final formFactor = getFormFactor(context);
    switch (formFactor) {
      case DeviceFormFactor.mobile:
        return 2;
      case DeviceFormFactor.tablet:
        return 3;
      case DeviceFormFactor.desktop:
        return 4;
    }
  }

  static double getGridChildAspectRatio(BuildContext context) {
    final formFactor = getFormFactor(context);
    switch (formFactor) {
      case DeviceFormFactor.mobile:
        return 1.35;
      case DeviceFormFactor.tablet:
        return 1.45;
      case DeviceFormFactor.desktop:
        return 1.55;
    }
  }
}

/// Adaptive Scaffold wrapper that switches between Bottom Navigation & NavigationRail for tablet/large screens.
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.destinations = const [],
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final formFactor = AdaptiveLayout.getFormFactor(context);

    if (formFactor == DeviceFormFactor.mobile || destinations.isEmpty) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: destinations.isNotEmpty && onDestinationSelected != null
            ? NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: destinations,
              )
            : null,
      );
    }

    // Tablet or Desktop Screen Layout with NavigationRail
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.selected,
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon ?? d.icon,
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Adaptive Two-Column Layout for Image Editors on wide/tablet screens.
class TwoColumnEditorLayout extends StatelessWidget {
  final Widget preview;
  final Widget controls;
  final double controlsWidth;

  const TwoColumnEditorLayout({
    super.key,
    required this.preview,
    required this.controls,
    this.controlsWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = AdaptiveLayout.getFormFactor(context) != DeviceFormFactor.mobile;

    if (!isExpanded) {
      return Column(
        children: [
          Expanded(child: preview),
          controls,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: preview),
        const VerticalDivider(thickness: 1, width: 1),
        SizedBox(
          width: controlsWidth,
          child: controls,
        ),
      ],
    );
  }
}
