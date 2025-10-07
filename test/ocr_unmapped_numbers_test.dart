import 'package:flutter_test/flutter_test.dart';
import 'package:split/services/ocr_service.dart';

void main() {
  group('OCR Unmapped Numbers Integration Tests', () {
    late OCRService ocrService;

    setUp(() {
      ocrService = OCRService();
    });

    test('OCRService initializes correctly', () async {
      final initialized = await ocrService.initialize();
      expect(initialized, isTrue);
      expect(ocrService.isInitialized, isTrue);
    });

    test('OCRService provides access to unmapped numbers', () {
      // Test that the getter works
      final unmappedNumbers = ocrService.lastUnmappedNumbers;
      expect(unmappedNumbers, isA<List<double>>());
    });

    test('OCRService provides access to extracted fees', () {
      // Test that the getter works
      final fees = ocrService.lastExtractedFees;
      expect(fees, isA<Map<String, double>>());
    });

    test('OCRService extractFeesAndTotals works correctly', () {
      const sampleText = '''
        Item 1 JOD 5.00
        Tax JOD 1.50
        Service Fee JOD 2.00
        Total JOD 8.50
      ''';

      final fees = ocrService.extractFeesAndTotals(sampleText);
      
      expect(fees['tax'], equals(1.50));
      expect(fees['service'], equals(2.00));
      expect(fees['total'], equals(8.50));
    });

    test('OCRService handles empty text gracefully', () {
      final fees = ocrService.extractFeesAndTotals('');
      expect(fees, isEmpty);
      
      final unmappedNumbers = ocrService.lastUnmappedNumbers;
      expect(unmappedNumbers, isA<List<double>>());
    });
  });
}