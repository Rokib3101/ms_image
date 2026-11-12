import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ms_image/core/navigation/app_router.dart';

class ImageEditorDashboard extends StatelessWidget {
  const ImageEditorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _EditorCard(
            title: 'Collage',
            subtitle: 'Create Photo Collage',
            icon: Icons.grid_view_rounded,
            color: Colors.purple,
            onTap: () => context.push(AppRoutes.collage),
          ),
          _EditorCard(
            title: 'Overlay',
            subtitle: 'Layers & Background',
            icon: Icons.layers,
            color: Colors.teal,
            onTap: () => context.push(AppRoutes.overlay),
          ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EditorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
