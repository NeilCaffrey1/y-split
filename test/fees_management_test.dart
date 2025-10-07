import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split/widgets/fees_list.dart';
import 'package:split/widgets/unmapped_number_tile.dart';
import 'package:split/models/ocr_review_models.dart';

void main() {
  group('Fees Management Tests', () {
    test('FeesList can be created with fees', () {
      final fees = {
        'tax': 5.50,
        'service': 2.25,
        'delivery': 3.00,
      };

      expect(() => FeesList(
        fees: fees,
        onFeeChanged: (type, amount) {},
        onFeeDeleted: (type) {},
      ), returnsNormally);
    });

    test('FeesList can be created with empty fees', () {
      expect(() => FeesList(
        fees: {},
        onFeeChanged: (type, amount) {},
        onFeeDeleted: (type) {},
      ), returnsNormally);
    });
  });

  group('Unmapped Numbers Tests', () {
    test('UnmappedNumberTile can be created', () {
      final number = UnmappedNumber(
        value: 12.50,
        originalText: '12.50',
      );

      expect(() => UnmappedNumberTile(
        number: number,
        index: 0,
        onMap: (category) {},
      ), returnsNormally);
    });

    test('UnmappedNumber model works correctly', () {
      final number = UnmappedNumber(
        value: 15.75,
        originalText: '15.75',
      );

      expect(number.value, equals(15.75));
      expect(number.originalText, equals('15.75'));
      expect(number.isMapped, isFalse);
      expect(number.isMappedAsItem, isFalse);
      expect(number.isMappedAsFee, isFalse);

      // Test mapping as item
      number.mappedCategory = 'item';
      number.itemName = 'Pizza';
      expect(number.isMapped, isTrue);
      expect(number.isMappedAsItem, isTrue);

      final detectedItem = number.toDetectedItem();
      expect(detectedItem, isNotNull);
      expect(detectedItem!.name, equals('Pizza'));
      expect(detectedItem.price, equals(15.75));
    });
  });
}