import '../../../image_tools/data/services/text_overlay_service.dart';

class ScannerPageModel {
  final String id;
  final String originalImagePath;
  int rotationAngle; // 0, 90, 180, 270 degrees
  bool isFlippedHorizontal;
  bool isFlippedVertical;
  List<TextOverlayData> textOverlays;

  ScannerPageModel({
    required this.id,
    required this.originalImagePath,
    this.rotationAngle = 0,
    this.isFlippedHorizontal = false,
    this.isFlippedVertical = false,
    this.textOverlays = const [],
  });

  ScannerPageModel copyWith({
    int? rotationAngle,
    bool? isFlippedHorizontal,
    bool? isFlippedVertical,
    List<TextOverlayData>? textOverlays,
  }) {
    return ScannerPageModel(
      id: id,
      originalImagePath: originalImagePath,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      isFlippedHorizontal: isFlippedHorizontal ?? this.isFlippedHorizontal,
      isFlippedVertical: isFlippedVertical ?? this.isFlippedVertical,
      textOverlays: textOverlays ?? List.from(this.textOverlays),
    );
  }
}
