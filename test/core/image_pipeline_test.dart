import 'package:flutter_test/flutter_test.dart';
import 'package:ms_image/core/services/image_pipeline_service.dart';

void main() {
  group('ImagePipelineService & Cancellation Token Unit Tests', () {
    test('Token is marked cancelled when new token is created for same taskTag', () {
      final pipeline = ImagePipelineService.instance;
      final token1 = pipeline.createToken('test_tag');
      expect(token1.isCancelled, false);

      final token2 = pipeline.createToken('test_tag');
      expect(token1.isCancelled, true);
      expect(token2.isCancelled, false);
    });
  });
}
