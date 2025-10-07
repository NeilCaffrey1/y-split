import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for displaying and editing fees (tax, service, delivery)
class FeesList extends StatelessWidget {
  final Map<String, double> fees;
  final Function(String, double) onFeeChanged;
  final Function(String) onFeeDeleted;

  const FeesList({
    super.key,
    required this.fees,
    required this.onFeeChanged,
    required this.onFeeDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (fees.isEmpty) {
      return _buildEmptyFeesState();
    }

    return Column(
      children: fees.entries.map((entry) {
        return EditableFeeItem(
          key: ValueKey('fee_${entry.key}'),
          feeType: entry.key,
          amount: entry.value,
          onChanged: (newAmount) => onFeeChanged(entry.key, newAmount),
          onDeleted: () => onFeeDeleted(entry.key),
        );
      }).toList(),
    );
  }

  /// Build empty state for fees
  Widget _buildEmptyFeesState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 12),
          const Text(
            'No fees detected.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Individual editable fee item widget
class EditableFeeItem extends StatefulWidget {
  final String feeType;
  final double amount;
  final Function(double) onChanged;
  final VoidCallback onDeleted;

  const EditableFeeItem({
    super.key,
    required this.feeType,
    required this.amount,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  State<EditableFeeItem> createState() => _EditableFeeItemState();
}

class _EditableFeeItemState extends State<EditableFeeItem> {
  late TextEditingController _controller;
  bool _isEditing = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
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
      child: Row(
        children: [
          // Fee icon and label
          Expanded(
            flex: 2,
            child: Row(
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
          ),
          // Amount input/display
          Expanded(
            flex: 1,
            child: _isEditing ? _buildEditingField() : _buildDisplayField(),
          ),
          // Action buttons
          const SizedBox(width: 8),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Build the editing field for amount
  Widget _buildEditingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            prefixText: '\$',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            errorText: _errorText,
            isDense: true,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textAlign: TextAlign.right,
          autofocus: true,
          onSubmitted: (_) => _saveChanges(),
          onChanged: _validateInput,
        ),
      ],
    );
  }

  /// Build the display field for amount
  Widget _buildDisplayField() {
    return Text(
      widget.amount.toStringAsFixed(2),
      style: TextStyle(
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.right,
    );
  }

  /// Build action buttons (edit/save/cancel/delete)
  Widget _buildActionButtons() {
    if (_isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _errorText == null ? _saveChanges : null,
            tooltip: 'Save',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _cancelEditing,
            tooltip: 'Cancel',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: _startEditing,
            tooltip: 'Edit',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: _confirmDelete,
            tooltip: 'Delete',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      );
    }
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
      _errorText = null;
      _controller.text = widget.amount.toStringAsFixed(2);
    });
  }

  /// Cancel editing and revert changes
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _errorText = null;
      _controller.text = widget.amount.toStringAsFixed(2);
    });
  }

  /// Save changes and exit editing mode
  void _saveChanges() {
    final text = _controller.text.trim();
    final amount = double.tryParse(text);
    
    if (amount != null && amount >= 0) {
      widget.onChanged(amount);
      setState(() {
        _isEditing = false;
        _errorText = null;
      });
    }
  }

  /// Validate input and show errors
  void _validateInput(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = 'Amount required';
      } else {
        final amount = double.tryParse(value);
        if (amount == null) {
          _errorText = 'Invalid number';
        } else if (amount < 0) {
          _errorText = 'Must be positive';
        } else {
          _errorText = null;
        }
      }
    });
  }

  /// Show confirmation dialog for deletion
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fee'),
        content: Text(
          'Are you sure you want to delete the ${_formatFeeLabel(widget.feeType).toLowerCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDeleted();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}