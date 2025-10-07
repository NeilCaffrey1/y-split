import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/receipt_item.dart';

class ItemsSection extends StatefulWidget {
  final List<ReceiptItem> items;
  final Function(ReceiptItem) onItemAdded;
  final Function(int, ReceiptItem) onItemUpdated;
  final Function(int) onItemRemoved;

  const ItemsSection({
    super.key,
    required this.items,
    required this.onItemAdded,
    required this.onItemUpdated,
    required this.onItemRemoved,
  });

  @override
  State<ItemsSection> createState() => _ItemsSectionState();
}

class _ItemsSectionState extends State<ItemsSection> {
  final TextEditingController _itemController = TextEditingController();
  final FocusNode _itemFocusNode = FocusNode();
  String? _validationError;

  @override
  void dispose() {
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item input with smart parsing
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): () =>
                            _addItem(_itemController.text),
                        const SingleActivator(
                          LogicalKeyboardKey.enter,
                          control: true,
                        ): () =>
                            _addItem(_itemController.text),
                      },
                      child: TextField(
                        controller: _itemController,
                        focusNode: _itemFocusNode,
                        decoration: InputDecoration(
                          hintText: '12.50 pizza or pizza 12.50',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          errorText: _validationError,
                          suffixIcon: _itemController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _itemController.clear();
                                    setState(() {
                                      _validationError = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: _addItem,
                        onChanged: _validateInput,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        _itemController.text.trim().isNotEmpty &&
                            _validationError == null
                        ? () => _addItem(_itemController.text)
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    _getSuggestion(_itemController.text),
                    style: TextStyle(color: Colors.blue[600], fontSize: 12),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Items list
          if (widget.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No items yet. Add items above.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            )
          else
            ...widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemTile(index, item);
            }),
        ],
      ),
    );
  }

  Widget _buildItemTile(int index, ReceiptItem item) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.assignedPeople.isNotEmpty 
                          ? Colors.green[400] 
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600], 
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.assignedPeople.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${item.assignedPeople.length} person${item.assignedPeople.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onItemRemoved(index),
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: Colors.grey[500],
                    tooltip: 'Remove item',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _validateInput(String input) {
    setState(() {
      if (input.trim().isEmpty) {
        _validationError = null;
        return;
      }

      final parsed = _parseItemInput(input.trim());
      if (parsed == null) {
        _validationError = 'Invalid format';
      } else {
        _validationError = null;
      }
    });
  }

  String _getSuggestion(String input) {
    if (input.trim().isEmpty) return '';

    // Try to suggest corrections for common mistakes
    final corrected = _autoCorrectInput(input.trim());
    if (corrected != input.trim()) {
      return 'Did you mean: $corrected?';
    }

    return 'Try: "12.50 pizza" or "pizza 12.50"';
  }

  String _autoCorrectInput(String input) {
    // Auto-correct common price formats
    String corrected = input;

    // Fix missing decimal places: $12.5 -> $12.50
    corrected = corrected.replaceAllMapped(
      RegExp(r'(\d+)\.(\d)(?!\d)'),
      (match) => '${match.group(1)}.${match.group(2)}0',
    );

    // Fix missing dollar sign: 12.50 pizza -> $12.50 pizza
    corrected = corrected.replaceAllMapped(
      RegExp(r'^(\d+\.?\d*)\s+(.+)'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Fix missing dollar sign at end: pizza 12.50 -> pizza $12.50
    corrected = corrected.replaceAllMapped(
      RegExp(r'^(.+)\s+(\d+\.?\d*)$'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return corrected;
  }

  void _addItem(String input) {
    if (input.trim().isEmpty) return;

    // Try auto-correction first
    final correctedInput = _autoCorrectInput(input.trim());
    final parsed = _parseItemInput(correctedInput);

    if (parsed != null) {
      widget.onItemAdded(parsed);
      _itemController.clear();
      setState(() {
        _validationError = null;
      });

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added: ${parsed.name} - ${parsed.price.toStringAsFixed(2)}',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Show validation error
      setState(() {
        _validationError = 'Invalid format';
      });
    }
  }

  ReceiptItem? _parseItemInput(String input) {
    if (input.trim().isEmpty) return null;

    // Enhanced parsing for multiple formats
    String cleanInput = input.trim();

    // Remove extra whitespace
    cleanInput = cleanInput.replaceAll(RegExp(r'\s+'), ' ');

    // Try different parsing patterns
    final patterns = [
      // Pattern 1: "$12.50 pizza" or "$12.5 pizza"
      RegExp(r'^(\d+(?:\.\d{1,2})?)\s+(.+)$'),
      // Pattern 2: "pizza $12.50" or "pizza $12.5"
      RegExp(r'^(.+)\s+(\d+(?:\.\d{1,2})?)$'),
      // Pattern 3: "12.50 pizza" (no dollar sign)
      RegExp(r'^(\d+(?:\.\d{1,2})?)\s+(.+)$'),
      // Pattern 4: "pizza 12.50" (no dollar sign)
      RegExp(r'^(.+)\s+(\d+(?:\.\d{1,2})?)$'),
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
              return ReceiptItem(
                name: cleanName,
                price: double.parse(
                  price.toStringAsFixed(2),
                ), // Ensure 2 decimal places
              );
            }
          }
        }
      }
    }

    return null;
  }
}
