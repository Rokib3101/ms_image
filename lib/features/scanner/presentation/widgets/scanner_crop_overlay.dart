import 'package:flutter/material.dart';

class ScannerCropOverlay extends CustomPainter {
  final List<Offset>
      corners; // 4 normalized corners [top-left, top-right, bottom-right, bottom-left]
  final Size displaySize;
  final int activeHandleIndex; // 0..3: corners, 4..7: edge midpoints

  ScannerCropOverlay({
    required this.corners,
    required this.displaySize,
    this.activeHandleIndex = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final width = displaySize.width;
    final height = displaySize.height;

    final p0 = Offset(corners[0].dx * width, corners[0].dy * height);
    final p1 = Offset(corners[1].dx * width, corners[1].dy * height);
    final p2 = Offset(corners[2].dx * width, corners[2].dy * height);
    final p3 = Offset(corners[3].dx * width, corners[3].dy * height);

    // Compute edge midpoints
    final m01 = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2); // Top
    final m12 = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2); // Right
    final m23 = Offset((p2.dx + p3.dx) / 2, (p2.dy + p3.dy) / 2); // Bottom
    final m30 = Offset((p3.dx + p0.dx) / 2, (p3.dy + p0.dy) / 2); // Left

    final polyPath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    // 1. Draw dimmed mask outside document polygon
    final fullRectPath = Path()..addRect(Rect.fromLTWH(0, 0, width, height));
    final dimPath =
        Path.combine(PathOperation.difference, fullRectPath, polyPath);

    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dimPath, dimPaint);

    // 2. Draw 3x3 Alignment Grid if handle is active
    if (activeHandleIndex != -1) {
      final gridPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      for (int i = 1; i <= 2; i++) {
        final t = i / 3.0;
        // Horizontal grid lines
        final hStart = Offset.lerp(p0, p3, t)!;
        final hEnd = Offset.lerp(p1, p2, t)!;
        canvas.drawLine(hStart, hEnd, gridPaint);

        // Vertical grid lines
        final vStart = Offset.lerp(p0, p1, t)!;
        final vEnd = Offset.lerp(p3, p2, t)!;
        canvas.drawLine(vStart, vEnd, gridPaint);
      }
    }

    // 3. Draw border line connecting corners
    final linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(polyPath, linePaint);

    // 4. Draw Corner Handles (0..3) & Midpoint Handles (4..7)
    final allHandles = [p0, p1, p2, p3, m01, m12, m23, m30];

    for (int i = 0; i < allHandles.length; i++) {
      final isSelected = (i == activeHandleIndex);
      final isCorner = i < 4;
      final pt = allHandles[i];

      if (isCorner) {
        // Circle for corners
        final innerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, isSelected ? 12.0 : 9.0, innerPaint);

        final ringPaint = Paint()
          ..color = isSelected ? Colors.deepOrange : Colors.cyan
          ..strokeWidth = isSelected ? 3.5 : 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(pt, isSelected ? 12.0 : 9.0, ringPaint);
      } else {
        // Rectangular pill for edge midpoints
        final rectSize = isSelected ? 14.0 : 10.0;
        final rect = Rect.fromCenter(
            center: pt, width: rectSize * 1.6, height: rectSize);

        final bgPaint = Paint()
          ..color = isSelected ? Colors.deepOrange : Colors.cyanAccent
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)), bgPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScannerCropOverlay oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.displaySize != displaySize ||
        oldDelegate.activeHandleIndex != activeHandleIndex;
  }
}
