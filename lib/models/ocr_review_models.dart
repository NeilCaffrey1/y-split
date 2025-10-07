import 'dart:ui';
import 'receipt_item.dart';

/// Represents a detected item from OCR with additional metadata
class DetectedItem {
  String name;
  double price;
  final String originalText; // For reference to original OCR text
  final Rect? boundingBox; // For image highlighting (optional)
  
  DetectedItem({
    required this.name,
    required this.price,
    required this.originalText,
    this.boundingBox,
  });

  /// Convert to ReceiptItem for main app integration
  ReceiptItem toReceiptItem() => ReceiptItem(name: name, price: price);

  /// Create from existing ReceiptItem (for editing existing items)
  factory DetectedItem.fromReceiptItem(ReceiptItem item, {String? originalText}) {
    return DetectedItem(
      name: item.name,
      price: item.price,
      originalText: originalText ?? item.name,
    );
  }

  @override
  String toString() {
    return 'DetectedItem(name: $name, price: ${price.toStringAsFixed(2)}, original: $originalText)';
  }
}

/// Represents an unmapped number detected by OCR that needs classification
class UnmappedNumber {
  final double value;
  final String originalText;
  final Rect? boundingBox; // For image highlighting (optional)
  String? mappedCategory; // 'item', 'tax', 'service', 'delivery', 'total', 'ignore'
  String? itemName; // If mapped as item, this holds the name

  UnmappedNumber({
    required this.value,
    required this.originalText,
    this.boundingBox,
    this.mappedCategory,
    this.itemName,
  });

  /// Check if this number has been mapped to a category
  bool get isMapped => mappedCategory != null && mappedCategory != 'ignore';

  /// Check if this number is mapped as an item
  bool get isMappedAsItem => mappedCategory == 'item';

  /// Check if this number is mapped as a fee
  bool get isMappedAsFee => 
      mappedCategory == 'tax' || 
      mappedCategory == 'service' || 
      mappedCategory == 'delivery';

  /// Convert to DetectedItem if mapped as item
  DetectedItem? toDetectedItem() {
    if (mappedCategory == 'item' && itemName != null && itemName!.isNotEmpty) {
      return DetectedItem(
        name: itemName!,
        price: value,
        originalText: originalText,
        boundingBox: boundingBox,
      );
    }
    return null;
  }

  @override
  String toString() {
    return 'UnmappedNumber(value: ${value.toStringAsFixed(2)}, category: $mappedCategory, itemName: $itemName)';
  }
}

/// Represents a detected region on the receipt image (for highlighting)
class DetectedRegion {
  final Rect boundingBox;
  final String text;
  final String category; // 'item', 'price', 'fee', 'unmapped'
  final Color highlightColor;

  DetectedRegion({
    required this.boundingBox,
    required this.text,
    required this.category,
    required this.highlightColor,
  });

  /// Create region for detected item
  factory DetectedRegion.forItem(Rect boundingBox, String text) {
    return DetectedRegion(
      boundingBox: boundingBox,
      text: text,
      category: 'item',
      highlightColor: const Color(0xFF4CAF50), // Green for items
    );
  }

  /// Create region for detected price
  factory DetectedRegion.forPrice(Rect boundingBox, String text) {
    return DetectedRegion(
      boundingBox: boundingBox,
      text: text,
      category: 'price',
      highlightColor: const Color(0xFF2196F3), // Blue for prices
    );
  }

  /// Create region for detected fee
  factory DetectedRegion.forFee(Rect boundingBox, String text) {
    return DetectedRegion(
      boundingBox: boundingBox,
      text: text,
      category: 'fee',
      highlightColor: const Color(0xFFFF9800), // Orange for fees
    );
  }

  /// Create region for unmapped number
  factory DetectedRegion.forUnmapped(Rect boundingBox, String text) {
    return DetectedRegion(
      boundingBox: boundingBox,
      text: text,
      category: 'unmapped',
      highlightColor: const Color(0xFF9C27B0), // Purple for unmapped
    );
  }

  @override
  String toString() {
    return 'DetectedRegion(category: $category, text: $text, bounds: $boundingBox)';
  }
}