import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ocr_review_models.dart';

/// A tile widget that allows inline editing of detected items
class EditableItemTile extends StatefulWidget {
  final DetectedItem item;
  final Function(DetectedItem) onChanged;
  final VoidCallback onDelete;
  final int index;

  const EditableItemTile({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
    required this.index,
  });

  @override
  State<EditableItemTile> createState() => _EditableItemTileState();
}

class _EditableItemTileState extends State<EditableItemTile> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  bool _isEditing = false;
  bool _hasNameError = false;
  bool _hasPriceError = false;
  String? _nameErrorText;
  String? _priceErrorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(text: widget.item.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isEditing ? Colors.blue[300]! : Colors.grey[200]!,
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: _isEditing ? _buildEditingView() : _buildDisplayView(),
    );
  }

  /// Build the display view (non-editing state)
  Widget _buildDisplayView() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${widget.item.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: _startEditing,
          tooltip: 'Edit item',
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          onPressed: widget.onDelete,
          tooltip: 'Delete item',
        ),
      ],
    );
  }

  /// Build the editing view with input fields
  Widget _buildEditingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item name field
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Item Name',
            errorText: _nameErrorText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _validateName(),
        ),
        const SizedBox(height: 12),
        
        // Price field
        TextField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'Price',
            prefixText: '\$',
            errorText: _priceErrorText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => _validatePrice(),
        ),
        const SizedBox(height: 12),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _hasNameError || _hasPriceError ? null : _saveChanges,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  /// Start editing mode
  void _startEditing() {
    setState(() {
      _isEditing = true;
      _hasNameError = false;
      _hasPriceError = false;
      _nameErrorText = null;
      _priceErrorText = null;
    });
    
    // Focus on name field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  /// Cancel editing and revert changes
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.text = widget.item.name;
      _priceController.text = widget.item.price.toStringAsFixed(2);
      _hasNameError = false;
      _hasPriceError = false;
      _nameErrorText = null;
      _priceErrorText = null;
    });
  }

  /// Save changes and exit editing mode
  void _saveChanges() {
    if (_validateAll()) {
      final updatedItem = DetectedItem(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        originalText: widget.item.originalText,
        boundingBox: widget.item.boundingBox,
      );

      widget.onChanged(updatedItem);
      
      setState(() {
        _isEditing = false;
      });
    }
  }

  /// Validate item name
  bool _validateName() {
    final name = _nameController.text.trim();
    
    setState(() {
      if (name.isEmpty) {
        _hasNameError = true;
        _nameErrorText = 'Item name cannot be empty';
      } else if (name.length > 100) {
        _hasNameError = true;
        _nameErrorText = 'Item name cannot exceed 100 characters';
      } else {
        _hasNameError = false;
        _nameErrorText = null;
      }
    });
    
    return !_hasNameError;
  }

  /// Validate price format
  bool _validatePrice() {
    final priceText = _priceController.text.trim();
    
    setState(() {
      if (priceText.isEmpty) {
        _hasPriceError = true;
        _priceErrorText = 'Price cannot be empty';
      } else {
        final price = double.tryParse(priceText);
        if (price == null) {
          _hasPriceError = true;
          _priceErrorText = 'Invalid price format';
        } else if (price <= 0) {
          _hasPriceError = true;
          _priceErrorText = 'Price must be greater than 0';
        } else if (price > 9999.99) {
          _hasPriceError = true;
          _priceErrorText = 'Price cannot exceed \$9999.99';
        } else {
          _hasPriceError = false;
          _priceErrorText = null;
        }
      }
    });
    
    return !_hasPriceError;
  }

  /// Validate all fields
  bool _validateAll() {
    final nameValid = _validateName();
    final priceValid = _validatePrice();
    return nameValid && priceValid;
  }
}