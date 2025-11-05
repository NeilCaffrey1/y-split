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
          args: {
            "preserve_interword_spaces": "1",
            "psm": "6", // Assume a single uniform block of text
            "oem": "1", // LSTM only
            // Improve numeric fidelity and avoid stray symbols
            "tessedit_char_whitelist":
                "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz./:-+()\$% "
          },
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
            args: {
              "preserve_interword_spaces": "1",
              "psm": "6",
              "oem": "1",
              "tessedit_char_whitelist":
                  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz./:-+()\$% "
            },
          );
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }

      // Normalize OCR text for better parsing reliability
      final normalizedText = normalizeOcrText(ocrText);

      debugPrint('OCR extracted (raw): $ocrText');
      debugPrint('OCR extracted (normalized): $normalizedText');

      // Store the extracted fees for later use
      _lastExtractedFees = extractFeesAndTotals(normalizedText);
      debugPrint('OCR extracted fees: $_lastExtractedFees');

      final parsedItems = _parseReceiptText(normalizedText);
      debugPrint(
        'OCR parsed ${parsedItems.length} items: ${parsedItems.map((i) => '${i.name}: ${i.price}').join(', ')}',
      );

      // Extract unmapped numbers after parsing items and fees
      _lastUnmappedNumbers = _extractUnmappedNumbers(normalizedText, parsedItems, _lastExtractedFees);
      debugPrint('OCR extracted unmapped numbers: $_lastUnmappedNumbers');

      return parsedItems;
    } catch (e) {
      debugPrint('OCR error: $e');
      return [];
    }
  }

  /// Normalize OCR text to improve downstream parsing accuracy
  String normalizeOcrText(String text) {
    final lines = text.split('\n');
    final normalizedLines = <String>[];

    for (var line in lines) {
      var s = line;

      // Normalize currency tokens: J0D/Jd/JD -> JOD
      s = s.replaceAll(RegExp(r'\bJ[O0][D]\b', caseSensitive: false), 'JOD');
      s = s.replaceAll(RegExp(r'\bJD\b', caseSensitive: false), 'JOD');

      // Ensure a single space after JOD when directly attached to numbers
      s = s.replaceAll(RegExp(r'\bJOD\s*'), 'JOD ');

      // Fix decimal comma (12,50 -> 12.50)
      s = s.replaceAllMapped(
        RegExp(r'(\d+),(\d{2})(?!\d)'),
        (m) => '${m.group(1)}.${m.group(2)}',
      );

      // Remove thousands commas: 1,234 -> 1234
      s = s.replaceAll(RegExp(r',(\d{3})(\b)'), r'$1');

      // Fix letter O inside numeric contexts (e.g., 1O.50 -> 10.50)
      s = s.replaceAll(RegExp(r'(?<=\d)[Oo](?=\d)'), '0');

      // Collapse multiple spaces
      s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

      normalizedLines.add(s);
    }

    return normalizedLines.join('\n');
  }

  /// Get the last extracted fees and totals
  Map<String, double> get lastExtractedFees => Map.from(_lastExtractedFees);

  /// Get the last extracted unmapped numbers
  List<double> get lastUnmappedNumbers => List.from(_lastUnmappedNumbers);

  /// Parse a price token that may be missing a decimal point.
  double? _parsePriceToken(String token) {
    if (token.isEmpty) return null;
    final cleaned = token.replaceAll(RegExp(r'[^0-9\.]'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.contains('.')) {
      final v = double.tryParse(cleaned);
      return v == null ? null : double.parse(v.toStringAsFixed(2));
    }
    if (cleaned.length >= 3) {
      final withDot = cleaned.substring(0, cleaned.length - 2) + '.' + cleaned.substring(cleaned.length - 2);
      final v = double.tryParse(withDot);
      return v == null ? null : double.parse(v.toStringAsFixed(2));
    }
    return null;
  }

  List<ReceiptItem> _parseReceiptText(String text) {
    final items = <ReceiptItem>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check for quantity + item patterns (e.g., "1 x Zinger", "3 x Orange Beetroot")
      // Allow for long text, numbers, dashes, and special characters in item names
      final quantityMatch = RegExp(r'^(\d+)\s*x\s*([^J]+?)(?:\s+JOD\s*(\d+(?:\.\d{2})|\d{3,}))?$').firstMatch(line);
      if (quantityMatch != null) {
        final quantity = quantityMatch.group(1);
        final itemName = quantityMatch.group(2)?.trim();
        final priceStr = quantityMatch.group(3);

        if (itemName != null && quantity != null && itemName.isNotEmpty) {
          String currentGroupItem = '$quantity x $itemName';
          double currentGroupPrice = 0.0;
          if (priceStr != null) {
            final parsed = _parsePriceToken(priceStr);
            currentGroupPrice = parsed ?? 0.0;
          }

          // Look ahead for sub-items (lines starting with +)
          final subItems = <String>[];
          for (int j = i + 1; j < lines.length; j++) {
            final nextLine = lines[j].trim();
            if (nextLine.startsWith('+')) {
              final subItemMatch = RegExp(r'^\+\s*([^J]+?)(?:\s+JOD\s*(\d+(?:\.\d{2})|\d{3,}))?$').firstMatch(nextLine);
              if (subItemMatch != null) {
                final subItemName = subItemMatch.group(1)?.trim();
                final subItemPrice = subItemMatch.group(2);
                if (subItemName != null && subItemName.isNotEmpty) {
                  subItems.add(subItemName);
                  if (subItemPrice != null) {
                    final parsed = _parsePriceToken(subItemPrice);
                    if (parsed != null) currentGroupPrice += parsed;
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
      final regularMatch = RegExp(r'^([^J]+?)\s+JOD\s*(\d+(?:\.\d{2})|\d{3,})\s*$').firstMatch(line);
      if (regularMatch != null) {
        final name = regularMatch.group(1)?.trim();
        final priceStr = regularMatch.group(2);

        if (name != null && priceStr != null && !name.startsWith('+') && name.isNotEmpty) {
          final price = _parsePriceToken(priceStr);
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

      final match = RegExp(r'^([^J]+?)\s+JOD\s*(\d+(?:\.\d{2})|\d{3,})\s*$').firstMatch(trimmed);
      if (match != null) {
        final name = match.group(1)?.trim().toLowerCase();
        final priceStr = match.group(2);

        if (name != null && priceStr != null && name.isNotEmpty) {
          final price = _parsePriceToken(priceStr);
          if (price != null) {
            if (name.contains('service')) {
              fees['service'] = price;
            } else if (name.contains('tax')) {
              fees['tax'] = price;
            } else if (name.contains('delivery')) {
              fees['delivery'] = price;
            } else if (name.contains('discount')) {
              fees['discount'] = price;
            } else if (name.contains('subtotal')) {
              fees['subtotal'] = price;
            } else if (name.contains('total')) {
              fees['total'] = price;
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
      
      // Look for numbers optionally preceded by currency, allowing missing decimals
      final numberMatches = RegExp(r'(?:JOD\s*)?(\d+(?:\.\d{2})|\d{3,})').allMatches(trimmed);
      
      for (final match in numberMatches) {
        final numberStr = match.group(1);
        if (numberStr != null) {
          final number = _parsePriceToken(numberStr);
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
      
      // Also look for standalone numbers without currency (accepting missing decimals)
      final standaloneMatches = RegExp(r'\b(\d+(?:\.\d{2})|\d{3,})\b').allMatches(trimmed);
      for (final match in standaloneMatches) {
        final numberStr = match.group(1);
        if (numberStr != null) {
          final number = _parsePriceToken(numberStr);
          if (number != null && number > 0) {
            // If there was no explicit decimal, be conservative unless context suggests price
            final hadDot = numberStr.contains('.');
            final seemsPriceContext = trimmed.contains('JOD') || match.end == trimmed.length;
            if (!hadDot && !seemsPriceContext) {
              continue;
            }
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

  /// Clear cached OCR data for privacy compliance
  void clearCache() {
    _lastExtractedFees.clear();
    _lastUnmappedNumbers.clear();
    debugPrint('OCR Service: Cache cleared for privacy compliance');
  }

  /// Reset service state (for privacy compliance)
  void reset() {
    clearCache();
    _isInitialized = false;
    debugPrint('OCR Service: Service reset for privacy compliance');
  }

  bool get isAvailable => true;
  bool get isInitialized => _isInitialized;
}
