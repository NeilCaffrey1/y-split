import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/ocr_review_models.dart';
import '../models/receipt_item.dart';
import 'image_viewer.dart';
import 'results_panel.dart';

/// State class for managing OCR review dialog data
class OCRReviewState {
  final Uint8List imageBytes;
  final List<DetectedItem> items;
  final Map<String, double> fees;
  final List<UnmappedNumber> unmappedNumbers;
  final double? detectedTotal;

  OCRReviewState({
    required this.imageBytes,
    required this.items,
    required this.fees,
    required this.unmappedNumbers,
    this.detectedTotal,
  });

  /// Calculate total from current items and fees
  double get calculatedTotal => 
      items.fold(0.0, (sum, item) => sum + item.price) + 
      fees.values.fold(0.0, (sum, fee) => sum + fee);

  /// Check if calculated total matches detected total (within 1 cent)
  bool get totalsMatch => 
      detectedTotal != null && 
      (calculatedTotal - detectedTotal!).abs() < 0.01;

  /// Get total discrepancy amount
  double get totalDiscrepancy => 
      detectedTotal != null ? calculatedTotal - detectedTotal! : 0.0;

  /// Create a copy with updated values
  OCRReviewState copyWith({
    Uint8List? imageBytes,
    List<DetectedItem>? items,
    Map<String, double>? fees,
    List<UnmappedNumber>? unmappedNumbers,
    double? detectedTotal,
  }) {
    return OCRReviewState(
      imageBytes: imageBytes ?? this.imageBytes,
      items: items ?? List.from(this.items),
      fees: fees ?? Map.from(this.fees),
      unmappedNumbers: unmappedNumbers ?? List.from(this.unmappedNumbers),
      detectedTotal: detectedTotal ?? this.detectedTotal,
    );
  }
}

/// Full-screen modal dialog for reviewing and correcting OCR results
class OCRReviewDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final List<ReceiptItem> detectedItems;
  final Map<String, double> detectedFees;
  final List<double> unmappedNumbers;
  final double? detectedTotal;
  final Function(List<ReceiptItem>, Map<String, double>) onApply;

  const OCRReviewDialog({
    super.key,
    required this.imageBytes,
    required this.detectedItems,
    required this.detectedFees,
    required this.unmappedNumbers,
    this.detectedTotal,
    required this.onApply,
  });

  /// Show the OCR review dialog
  static Future<bool?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    required List<ReceiptItem> detectedItems,
    required Map<String, double> detectedFees,
    required List<double> unmappedNumbers,
    double? detectedTotal,
    required Function(List<ReceiptItem>, Map<String, double>) onApply,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (context) => OCRReviewDialog(
        imageBytes: imageBytes,
        detectedItems: detectedItems,
        detectedFees: detectedFees,
        unmappedNumbers: unmappedNumbers,
        detectedTotal: detectedTotal,
        onApply: onApply,
      ),
    );
  }

  @override
  State<OCRReviewDialog> createState() => _OCRReviewDialogState();
}

class _OCRReviewDialogState extends State<OCRReviewDialog>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late OCRReviewState _state;
  late OCRReviewState _originalState;
  late TabController _tabController;
  bool _hasUnsavedChanges = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Initialize the dialog state from provided data
  void _initializeState() {
    // Convert ReceiptItems to DetectedItems
    final detectedItems = widget.detectedItems
        .map((item) => DetectedItem.fromReceiptItem(item))
        .toList();

    // Convert unmapped numbers to UnmappedNumber objects
    final unmappedNumbers = widget.unmappedNumbers
        .map((value) => UnmappedNumber(
              value: value,
              originalText: value.toStringAsFixed(2),
            ))
        .toList();

    _state = OCRReviewState(
      imageBytes: widget.imageBytes,
      items: detectedItems,
      fees: Map.from(widget.detectedFees),
      unmappedNumbers: unmappedNumbers,
      detectedTotal: widget.detectedTotal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: _buildAppBar(),
        body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        bottomNavigationBar: _buildActionBar(),
      ),
    );
  }

  /// Build the app bar with title and close button
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Review OCR Results',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black87),
        onPressed: _handleCancel,
        tooltip: 'Cancel',
      ),
      actions: [
        if (_state.totalsMatch)
          const Icon(
            Icons.check_circle,
            color: Colors.green,
          )
        else if (_state.detectedTotal != null)
          Icon(
            Icons.warning,
            color: Colors.orange[600],
          ),
        const SizedBox(width: 16),
      ],
    );
  }

  /// Build mobile layout with tabs
  Widget _buildMobileLayout() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.image),
              text: 'Image',
            ),
            Tab(
              icon: Icon(Icons.list),
              text: 'Results',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildImageViewer(),
              _buildResultsPanel(),
            ],
          ),
        ),
      ],
    );
  }

  /// Build desktop layout with split screen
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Image viewer (60% width)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: _buildImageViewer(),
          ),
        ),
        // Results panel (40% width)
        Expanded(
          flex: 2,
          child: _buildResultsPanel(),
        ),
      ],
    );
  }

  /// Build image viewer with zoom/pan functionality
  Widget _buildImageViewer() {
    return ImageViewer(
      imageBytes: _state.imageBytes,
      highlightedRegions: _getHighlightedRegions(),
      onImageTap: () {
        // Optional: Handle image tap events
      },
    );
  }

  /// Get highlighted regions for detected items and numbers
  List<DetectedRegion>? _getHighlightedRegions() {
    final List<DetectedRegion> regions = [];

    // Add regions for detected items
    for (final item in _state.items) {
      if (item.boundingBox != null) {
        regions.add(DetectedRegion.forItem(item.boundingBox!, item.name));
      }
    }

    // Add regions for unmapped numbers
    for (final number in _state.unmappedNumbers) {
      if (number.boundingBox != null) {
        regions.add(DetectedRegion.forUnmapped(
          number.boundingBox!, 
          number.originalText,
        ));
      }
    }

    return regions.isEmpty ? null : regions;
  }

  /// Build results panel with detected items
  Widget _buildResultsPanel() {
    return ResultsPanel(
      state: _state,
      onItemChanged: _handleItemChanged,
      onItemDeleted: _handleItemDeleted,
      onFeeChanged: _handleFeeChanged,
      onFeeDeleted: _handleFeeDeleted,
      onNumberMapped: _handleNumberMapped,
      onAddItem: _handleAddItem,
    );
  }

  /// Build action bar with buttons
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _handleAddItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Changes'),
            ),
          ),
        ],
      ),
    );
  }

  // Event Handlers

  /// Handle item changes from editing
  void _handleItemChanged(int index, DetectedItem updatedItem) {
    setState(() {
      _state = _state.copyWith(
        items: List.from(_state.items)..[index] = updatedItem,
      );
    });
    _markAsChanged();
  }

  /// Handle item deletion
  void _handleItemDeleted(int index) {
    setState(() {
      final updatedItems = List<DetectedItem>.from(_state.items);
      updatedItems.removeAt(index);
      _state = _state.copyWith(items: updatedItems);
    });
    _markAsChanged();
  }

  /// Handle fee changes
  void _handleFeeChanged(String feeType, double amount) {
    setState(() {
      final updatedFees = Map<String, double>.from(_state.fees);
      updatedFees[feeType] = amount;
      _state = _state.copyWith(fees: updatedFees);
    });
    _markAsChanged();
  }

  /// Handle fee deletion
  void _handleFeeDeleted(String feeType) {
    setState(() {
      final updatedFees = Map<String, double>.from(_state.fees);
      updatedFees.remove(feeType);
      _state = _state.copyWith(fees: updatedFees);
    });
    _markAsChanged();
  }

  /// Handle number mapping
  void _handleNumberMapped(int index, String category) {
    final number = _state.unmappedNumbers[index];
    
    setState(() {
      final updatedUnmapped = List<UnmappedNumber>.from(_state.unmappedNumbers);
      
      if (category.startsWith('item:')) {
        // Extract item name from category string
        final itemName = category.substring(5);
        
        // Add as new item
        final newItem = DetectedItem(
          name: itemName,
          price: number.value,
          originalText: number.originalText,
          boundingBox: number.boundingBox,
        );
        
        final updatedItems = List<DetectedItem>.from(_state.items);
        updatedItems.add(newItem);
        updatedUnmapped.removeAt(index);
        
        _state = _state.copyWith(
          items: updatedItems,
          unmappedNumbers: updatedUnmapped,
        );
        _markAsChanged();
      } else if (category == 'tax' || category == 'service' || category == 'delivery') {
        // Add as fee
        final updatedFees = Map<String, double>.from(_state.fees);
        updatedFees[category] = (updatedFees[category] ?? 0) + number.value;
        updatedUnmapped.removeAt(index);
        
        _state = _state.copyWith(
          fees: updatedFees,
          unmappedNumbers: updatedUnmapped,
        );
        _markAsChanged();
      } else if (category == 'total') {
        // Set as detected total
        updatedUnmapped.removeAt(index);
        _state = _state.copyWith(
          detectedTotal: number.value,
          unmappedNumbers: updatedUnmapped,
        );
        _markAsChanged();
      } else if (category == 'ignore') {
        // Remove from unmapped
        updatedUnmapped.removeAt(index);
        _state = _state.copyWith(unmappedNumbers: updatedUnmapped);
        _markAsChanged();
      }
    });
  }

  /// Show dialog to add a new item manually
  Future<void> _showAddItemDialog() async {
    final controller = TextEditingController();
    String? validationError;
    
    final result = await showDialog<DetectedItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter item name and price:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '12.50 pizza or pizza 12.50',
                  border: const OutlineInputBorder(),
                  errorText: validationError,
                  helperText: 'Examples: "12.50 pizza", "coffee 4.25"',
                  helperMaxLines: 2,
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                onChanged: (value) {
                  setDialogState(() {
                    if (value.trim().isEmpty) {
                      validationError = null;
                    } else {
                      final parsed = _parseItemInput(value.trim());
                      validationError = parsed == null ? 'Invalid format' : null;
                    }
                  });
                },
                onSubmitted: (value) {
                  final parsed = _parseItemInput(value.trim());
                  if (parsed != null) {
                    Navigator.of(context).pop(parsed);
                  }
                },
              ),
              if (validationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _getInputSuggestion(controller.text),
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: validationError == null && controller.text.trim().isNotEmpty
                  ? () {
                      final parsed = _parseItemInput(controller.text.trim());
                      if (parsed != null) {
                        Navigator.of(context).pop(parsed);
                      }
                    }
                  : null,
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final updatedItems = List<DetectedItem>.from(_state.items);
        updatedItems.add(result);
        _state = _state.copyWith(items: updatedItems);
      });
      _markAsChanged();

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added: ${result.name} - \$${result.price.toStringAsFixed(2)}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[600],
          ),
        );
      }
    }
  }

  /// Parse item input with smart price parsing (similar to ItemsSection)
  DetectedItem? _parseItemInput(String input) {
    if (input.trim().isEmpty) return null;

    // Enhanced parsing for multiple formats
    String cleanInput = input.trim();

    // Remove extra whitespace
    cleanInput = cleanInput.replaceAll(RegExp(r'\s+'), ' ');

    // Try different parsing patterns
    final patterns = [
      // Pattern 1: "12.50 pizza" or "12.5 pizza"
      RegExp(r'^(\d+(?:\.\d{1,2})?)\s+(.+)$'),
      // Pattern 2: "pizza 12.50" or "pizza 12.5"
      RegExp(r'^(.+)\s+(\d+(?:\.\d{1,2})?)$'),
      // Pattern 3: "$12.50 pizza" or "$12.5 pizza"
      RegExp(r'^\$(\d+(?:\.\d{1,2})?)\s+(.+)$'),
      // Pattern 4: "pizza $12.50" or "pizza $12.5"
      RegExp(r'^(.+)\s+\$(\d+(?:\.\d{1,2})?)$'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(cleanInput);
      if (match != null) {
        String? priceStr;
        String? name;

        if (i == 0 || i == 2) {
          // Price first format
          priceStr = match.group(1);
          name = match.group(2);
        } else {
          // Name first format
          name = match.group(1);
          priceStr = match.group(2);
        }

        if (priceStr != null && name != null) {
          final price = double.tryParse(priceStr);
          if (price != null && price > 0 && price <= 9999.99) {
            // Validate name is not just numbers or symbols
            final cleanName = name.trim();
            if (cleanName.isNotEmpty &&
                cleanName.length >= 2 &&
                RegExp(r'[a-zA-Z]').hasMatch(cleanName)) {
              return DetectedItem(
                name: cleanName,
                price: double.parse(price.toStringAsFixed(2)), // Ensure 2 decimal places
                originalText: 'Manual: $cleanName \$${price.toStringAsFixed(2)}',
              );
            }
          }
        }
      }
    }

    return null;
  }

  /// Get input suggestion for invalid formats
  String _getInputSuggestion(String input) {
    if (input.trim().isEmpty) return '';

    // Try to suggest corrections for common mistakes
    final corrected = _autoCorrectInput(input.trim());
    if (corrected != input.trim()) {
      return 'Did you mean: $corrected?';
    }

    return 'Try: "12.50 pizza" or "pizza 12.50"';
  }

  /// Auto-correct common input mistakes
  String _autoCorrectInput(String input) {
    String corrected = input;

    // Fix missing decimal places: 12.5 -> 12.50
    corrected = corrected.replaceAllMapped(
      RegExp(r'(\d+)\.(\d)(?!\d)'),
      (match) => '${match.group(1)}.${match.group(2)}0',
    );

    // Remove extra dollar signs in the middle: pizza $12.50 -> pizza 12.50
    corrected = corrected.replaceAllMapped(
      RegExp(r'^(.+)\s+\$(\d+\.?\d*)$'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return corrected;
  }



  void _handleAddItem() {
    _showAddItemDialog();
  }

  void _handleCancel() {
    if (_hasUnsavedChanges) {
      _showCancelConfirmation();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  void _handleApply() {
    // Convert DetectedItems back to ReceiptItems (includes both OCR and manual items)
    final receiptItems = _state.items
        .map((item) => item.toReceiptItem())
        .toList();

    // Apply changes through callback
    widget.onApply(receiptItems, _state.fees);

    // Close dialog with success result
    Navigator.of(context).pop(true);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation
              Navigator.of(context).pop(false); // Close dialog
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}