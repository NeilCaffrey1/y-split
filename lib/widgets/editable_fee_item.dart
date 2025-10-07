import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'confirmation_dialog.dart';

/// A tile widget that allows inline editing of fee amounts
class EditableFeeItem extends StatefulWidget {
  final String feeType;
  final double amount;
  final Function(double) onChanged;
  final VoidCallback onDelete;

  const EditableFeeItem({
    super.key,
    required this.feeType,
    required this.amount,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<EditableFeeItem> createState() => _EditableFeeItemState();
}

class _EditableFeeItemState extends State<EditableFeeItem> {
  late TextEditingController _amountController;
  bool _isEditing = false;
  bool _hasError = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              _getFeeIcon(widget.feeType),
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatFeeLabel(widget.feeType)}:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              '\$${widget.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: _startEditing,
              tooltip: 'Edit fee',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: _handleDelete,
              tooltip: 'Remove fee',
            ),
          ],
        ),
      ],
    );
  }

  /// Build the editing view with input field
  Widget _buildEditingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getFeeIcon(widget.feeType),
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatFeeLabel(widget.feeType)}:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Amount field
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '\$',
            errorText: _errorText,
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
          onChanged: (_) => _validateAmount(),
          autofocus: true,
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
              onPressed: _hasError ? null : _saveChanges,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  /// Get icon for fee type
  IconData _getFeeIcon(String feeType) {
    switch (feeType.toLowerCase()) {
      case 'tax':
        return Icons.account_balance;
      case 'service':
        return Icons.room_service;
      case 'delivery':
        return Icons.delivery_dining;
      default:
        return Icons.attach_money;
    }
  }

  /// Format fee label for display
  String _formatFeeLabel(String feeType) {
    switch (feeType.toLowerCase()) {
      case 'tax':
        return 'Tax';
      case 'service':
        return 'Service Fee';
      case 'delivery':
        return 'Delivery Fee';
      default:
        return feeType.toUpperCase();
    }
  }

  /// Start editing mode
  void _startEditing() {
    setState(() {
      _isEditing = true;
      _hasError = false;
      _errorText = null;
    });
  }

  /// Cancel editing and revert changes
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _amountController.text = widget.amount.toStringAsFixed(2);
      _hasError = false;
      _errorText = null;
    });
  }

  /// Save changes and exit editing mode
  void _saveChanges() {
    if (_validateAmount()) {
      final newAmount = double.parse(_amountController.text);
      widget.onChanged(newAmount);
      
      setState(() {
        _isEditing = false;
      });
    }
  }

  /// Validate amount format
  bool _validateAmount() {
    final amountText = _amountController.text.trim();
    
    setState(() {
      if (amountText.isEmpty) {
        _hasError = true;
        _errorText = 'Amount cannot be empty';
      } else {
        final amount = double.tryParse(amountText);
        if (amount == null) {
          _hasError = true;
          _errorText = 'Invalid amount format';
        } else if (amount < 0) {
          _hasError = true;
          _errorText = 'Amount cannot be negative';
        } else if (amount > 9999.99) {
          _hasError = true;
          _errorText = 'Amount cannot exceed \$9999.99';
        } else {
          _hasError = false;
          _errorText = null;
        }
      }
    });
    
    return !_hasError;
  }

  /// Handle fee deletion with confirmation
  Future<void> _handleDelete() async {
    final confirmed = await ConfirmationDialog.showConfirmation(
      context,
      title: 'Remove Fee',
      message: 'Are you sure you want to remove this ${_formatFeeLabel(widget.feeType).toLowerCase()}?',
      confirmText: 'Remove',
      confirmColor: Colors.red,
    );

    if (confirmed) {
      widget.onDelete();
    }
  }
}