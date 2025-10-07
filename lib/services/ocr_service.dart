import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import '../models/receipt_item.dart';

class OCRService {
  bool _isInitialized = false;
  Map<String, double> _lastExtractedFees = {};
  List<double> _lastUnmappedNumbers = [];

  /// Initialize OCR service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = true;
      debugPrint('OCR Service: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('OCR Service: Error initializing: $e');
      return false;
    }
  }

  /// Process image and extract receipt items
  Future<List<ReceiptItem>> processReceiptImage(Uint8List imageBytes) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Failed to initialize OCR service');
        }
      }

      String ocrText;

      if (kIsWeb) {
        // For web, use base64 approach
        final base64Image =
            'data:image/jpeg;base64,${base64Encode(imageBytes)}';
        ocrText = await FlutterTesseractOcr.extractText(
          base64Image,
          language: 'eng',
          args: {"preserve_interword_spaces": "1", "psm": "6"},
        );
      } else {
        // For mobile, create temporary file
        final tempFile = File(
          'temp_receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(imageBytes);

        try {
          ocrText = await FlutterTesseractOcr.extractText(
            tempFile.path,
            language: 'eng',
            args: {"preserve_interword_spaces": "1", "psm": "6"},
          );
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }

      debugPrint('OCR extracted: $ocrText');

      // Store the extracted fees for later use
      _lastExtractedFees = extractFeesAndTotals(ocrText);
      debugPrint('OCR extracted fees: $_lastExtractedFees');

      final parsedItems = _parseReceiptText(ocrText);
      debugPrint(
        'OCR parsed ${parsedItems.length} items: ${parsedItems.map((i) => '${i.name}: ${i.price}').join(', ')}',
      );

      // Extract unmapped numbers after parsing items and fees
      _lastUnmappedNumbers = _extractUnmappedNumbers(ocrText, parsedItems, _lastExtractedFees);
      debugPrint('OCR extracted unmapped numbers: $_lastUnmappedNumbers');

      return parsedItems;
    } catch (e) {
      debugPrint('OCR error: $e');
      return [];
    }
  }

  /// Get the last extracted fees and totals
  Map<String, double> get lastExtractedFees => Map.from(_lastExtractedFees);

  /// Get the last extracted unmapped numbers
  List<double> get lastUnmappedNumbers => List.from(_lastUnmappedNumbers);

  List<ReceiptItem> _parseReceiptText(String text) {
    final items = <ReceiptItem>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check for quantity + item patterns (e.g., "1 x Zinger", "3 x Orange Beetroot")
      // Allow for long text, numbers, dashes, and special characters in item names
      final quantityMatch = RegExp(r'^(\d+)\s*x\s*([^J]+?)(?:\s+JOD\s*(\d+\.\d{2}))?$').firstMatch(line);
      if (quantityMatch != null) {
        final quantity = quantityMatch.group(1);
        final itemName = quantityMatch.group(2)?.trim();
        final priceStr = quantityMatch.group(3);

        if (itemName != null && quantity != null && itemName.isNotEmpty) {
          String currentGroupItem = '$quantity x $itemName';
          double currentGroupPrice = priceStr != null ? (double.tryParse(priceStr) ?? 0.0) : 0.0;

          // Look ahead for sub-items (lines starting with +)
          final subItems = <String>[];
          for (int j = i + 1; j < lines.length; j++) {
            final nextLine = lines[j].trim();
            if (nextLine.startsWith('+')) {
              final subItemMatch = RegExp(r'^\+\s*([^J]+?)(?:\s+JOD\s*(\d+\.\d{2}))?$').firstMatch(nextLine);
              if (subItemMatch != null) {
                final subItemName = subItemMatch.group(1)?.trim();
                final subItemPrice = subItemMatch.group(2);
                if (subItemName != null && subItemName.isNotEmpty) {
                  subItems.add(subItemName);
                  if (subItemPrice != null) {
                    currentGroupPrice += double.tryParse(subItemPrice) ?? 0.0;
                  }
                }
              }
              i = j; // Skip processed sub-items
            } else {
              break;
            }
          }

          // Create combined item name
          String finalName = currentGroupItem;
          if (subItems.isNotEmpty) {
            finalName += ' (${subItems.join(', ')})';
          }

          if (currentGroupPrice > 0) {
            items.add(ReceiptItem(name: finalName, price: currentGroupPrice));
          }
          continue;
        }
      }

      // Check for regular item + price patterns
      // Use [^J]+ to match everything except 'J' (to stop before 'JOD')
      final regularMatch = RegExp(r'^([^J]+?)\s+JOD\s*(\d+\.\d{2})\s*$').firstMatch(line);
      if (regularMatch != null) {
        final name = regularMatch.group(1)?.trim();
        final priceStr = regularMatch.group(2);

        if (name != null && priceStr != null && !name.startsWith('+') && name.isNotEmpty) {
          final price = double.tryParse(priceStr);
          if (price != null && price > 0 && name.length > 1) {
            // Skip if it looks like a total/tax/delivery line
            if (!_isSpecialLine(name)) {
              items.add(ReceiptItem(name: name, price: price));
            }
          }
        }
      }
    }

    return items;
  }

  /// Check if a line represents totals, taxes, or delivery fees
  bool _isSpecialLine(String name) {
    final lowerName = name.toLowerCase();
    return lowerName.contains('total') ||
        lowerName.contains('tax') ||
        lowerName.contains('delivery') ||
        lowerName.contains('service') ||
        lowerName.contains('subtotal') ||
        lowerName.contains('discount') ||
        lowerName.contains('fee');
  }

  /// Extract special fees and totals from receipt text
  Map<String, double> extractFeesAndTotals(String text) {
    final fees = <String, double>{};
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = RegExp(r'^([^J]+?)\s+JOD\s*(\d+\.\d{2})\s*$').firstMatch(trimmed);
      if (match != null) {
        final name = match.group(1)?.trim().toLowerCase();
        final priceStr = match.group(2);

        if (name != null && priceStr != null && name.isNotEmpty) {
          final price = double.tryParse(priceStr);
          if (price != null) {
            if (name.contains('service') || name.contains('fee')) {
              fees['service'] = price;
            } else if (name.contains('tax')) {
              fees['tax'] = price;
            } else if (name.contains('delivery')) {
              fees['delivery'] = price;
            } else if (name.contains('total')) {
              fees['total'] = price;
            } else if (name.contains('subtotal')) {
              fees['subtotal'] = price;
            }
          }
        }
      }
    }

    return fees;
  }

  /// Extract numbers from OCR text that couldn't be classified as items or fees
  List<double> _extractUnmappedNumbers(
    String text,
    List<ReceiptItem> parsedItems,
    Map<String, double> extractedFees,
  ) {
    final unmappedNumbers = <double>[];
    final lines = text.split('\n');
    
    // Collect all numbers that were already classified
    final classifiedNumbers = <double>{};
    
    // Add item prices
    for (final item in parsedItems) {
      classifiedNumbers.add(item.price);
    }
    
    // Add fee amounts
    for (final fee in extractedFees.values) {
      classifiedNumbers.add(fee);
    }
    
    // Find all numbers in the text
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Look for standalone numbers or numbers with currency
      final numberMatches = RegExp(r'(?:JOD\s*)?(\d+\.\d{2})').allMatches(trimmed);
      
      for (final match in numberMatches) {
        final numberStr = match.group(1);
        if (numberStr != null) {
          final number = double.tryParse(numberStr);
          if (number != null && number > 0) {
            // Check if this number is already classified
            bool isClassified = false;
            for (final classified in classifiedNumbers) {
              if ((number - classified).abs() < 0.01) { // Allow for small floating point differences
                isClassified = true;
                break;
              }
            }
            
            // If not classified and not already in unmapped list, add it
            if (!isClassified && !unmappedNumbers.any((n) => (n - number).abs() < 0.01)) {
              // Additional filtering: skip very common numbers that are likely not prices
              if (number >= 0.10 && number <= 1000.00) { // Reasonable price range
                unmappedNumbers.add(number);
              }
            }
          }
        }
      }
      
      // Also look for standalone decimal numbers without currency
      final standaloneMatches = RegExp(r'\b(\d+\.\d{2})\b').allMatches(trimmed);
      for (final match in standaloneMatches) {
        final numberStr = match.group(1);
        if (numberStr != null) {
          final number = double.tryParse(numberStr);
          if (number != null && number > 0) {
            // Check if this number is already classified
            bool isClassified = false;
            for (final classified in classifiedNumbers) {
              if ((number - classified).abs() < 0.01) {
                isClassified = true;
                break;
              }
            }
            
            // If not classified and not already in unmapped list, add it
            if (!isClassified && !unmappedNumbers.any((n) => (n - number).abs() < 0.01)) {
              if (number >= 0.10 && number <= 1000.00) {
                unmappedNumbers.add(number);
              }
            }
          }
        }
      }
    }
    
    // Sort unmapped numbers for consistent ordering
    unmappedNumbers.sort();
    
    return unmappedNumbers;
  }

  bool get isAvailable => true;
  bool get isInitialized => _isInitialized;
}
