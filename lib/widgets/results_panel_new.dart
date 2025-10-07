import 'package:flutter/material.dart';
import '../models/ocr_review_models.dart';
import 'editable_item_tile.dart';
import 'editable_fee_item.dart';
import 'confirmation_dialog.dart';
import 'ocr_review_dialog.dart';

/// Panel showing detected results with editable sections
class ResultsPanel extends StatelessWidget {
  final OCRReviewState state;
  final Function(int, DetectedItem) onItemChanged;
  final Function(int) onItemDeleted;
  final Function(String, double) onFeeChanged;
  final Function(int, String) onNumberMapped;
  final VoidCallback onAddItem;

  const ResultsPanel({
    super.key,
    required this.state,
    required this.onItemChanged,
    required this.onItemDeleted,
    required this.onFeeChanged,
    required this.onNumberMapped,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Results',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemsSection(context),
                  const SizedBox(height: 24),
                  _buildFeesSection(context),
                  const SizedBox(height: 24),
                  _buildUnmappedSection(context),
                  const SizedBox(height: 24),
                  _buildTotalsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build items section with editable tiles
  Widget _buildItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items (${state.items.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.items.isEmpty)
          _buildEmptyItemsState()
        else
          ItemsList(
            items: state.items,
            onItemChanged: onItemChanged,
            onItemDeleted: onItemDeleted,
          ),
      ],
    );
  }

  /// Build empty state for items
  Widget _buildEmptyItemsState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          const Text(
            'No items detected',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use "Add Item" to add manually.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build fees section with editable tiles
  Widget _buildFeesSection(BuildContext context) {
    // Filter out fees with 0 amount
    final activeFees = Map<String, double>.from(state.fees)
      ..removeWhere((key, value) => value <= 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fees',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (activeFees.isEmpty)
          _buildEmptyFeesState()
        else
          ...activeFees.entries.map((entry) => _buildFeeItem(entry)),
      ],
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

  /// Build individual fee item with editing capability
  Widget _buildFeeItem(MapEntry<String, double> entry) {
    return EditableFeeItem(
      feeType: entry.key,
      amount: entry.value,
      onChanged: (newAmount) => onFeeChanged(entry.key, newAmount),
      onDelete: () => _handleFeeDelete(entry.key),
    );
  }

  /// Handle fee deletion by setting amount to 0
  void _handleFeeDelete(String feeType) {
    onFeeChanged(feeType, 0.0);
  }

  /// Build unmapped numbers section
  Widget _buildUnmappedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unmapped Numbers (${state.unmappedNumbers.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (state.unmappedNumbers.isEmpty)
          _buildEmptyUnmappedState()
        else
          ...List.generate(state.unmappedNumbers.length, (index) {
            final number = state.unmappedNumbers[index];
            return _buildUnmappedNumberItem(context, number, index);
          }),
      ],
    );
  }

  /// Build empty state for unmapped numbers
  Widget _buildEmptyUnmappedState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
          ),
          const SizedBox(width: 12),
          const Text(
            'All numbers have been mapped.',
            style: TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }

  /// Build individual unmapped number item
  Widget _buildUnmappedNumberItem(BuildContext context, UnmappedNumber number, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '\$${number.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _showMappingOptions(context, index),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Map as...'),
          ),
        ],
      ),
    );
  }

  /// Show mapping options for unmapped number
  void _showMappingOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map \$${state.unmappedNumbers[index].value.toStringAsFixed(2)} as:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Item'),
              subtitle: const Text('Add as a new item with custom name'),
              onTap: () {
                Navigator.pop(context);
                onNumberMapped(index, 'item');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Tax'),
              subtitle: const Text('Add to tax fees'),
              onTap: () {
                Navigator.pop(context);
                onNumberMapped(index, 'tax');
              },
            ),
            ListTile(
              leading: const Icon(Icons.room_service),
              title: const Text('Service Fee'),
              subtitle: const Text('Add to service fees'),
              onTap: () {
                Navigator.pop(context);
                onNumberMapped(index, 'service');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining),
              title: const Text('Delivery Fee'),
              subtitle: const Text('Add to delivery fees'),
              onTap: () {
                Navigator.pop(context);
                onNumberMapped(index, 'delivery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Total'),
              subtitle: const Text('Set as receipt total'),
              onTap: () {
                Navigator.pop(context);
                onNumberMapped(index, 'total');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Ignore'),
              subtitle: const Text('Remove from consideration'),
              onTap: () {
                Navigator.pop(context);
                onNumberMapped(index, 'ignore');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build totals section
  Widget _buildTotalsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: state.totalsMatch ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.totalsMatch ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.totalsMatch ? Icons.check_circle : Icons.warning,
                color: state.totalsMatch ? Colors.green : Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Totals Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: state.totalsMatch ? Colors.green[800] : Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTotalRow('Calculated Total:', state.calculatedTotal),
          if (state.detectedTotal != null) ...[
            const SizedBox(height: 4),
            _buildTotalRow('Detected Total:', state.detectedTotal!),
            if (!state.totalsMatch) ...[
              const SizedBox(height: 4),
              _buildTotalRow(
                'Difference:',
                state.totalDiscrepancy,
                isError: true,
              ),
            ],
          ],
          if (!state.totalsMatch && state.unmappedNumbers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tip: Check unmapped numbers above to resolve discrepancies.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build individual total row
  Widget _buildTotalRow(String label, double amount, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isError ? Colors.orange[800] : null,
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying list of items with editable tiles
class ItemsList extends StatelessWidget {
  final List<DetectedItem> items;
  final Function(int, DetectedItem) onItemChanged;
  final Function(int) onItemDeleted;

  const ItemsList({
    super.key,
    required this.items,
    required this.onItemChanged,
    required this.onItemDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        return EditableItemTile(
          key: ValueKey('item_$index'),
          item: items[index],
          index: index,
          onChanged: (updatedItem) => onItemChanged(index, updatedItem),
          onDelete: () => _handleDelete(context, index),
        );
      }),
    );
  }

  /// Handle item deletion with confirmation
  Future<void> _handleDelete(BuildContext context, int index) async {
    final item = items[index];
    final confirmed = await ConfirmationDialog.showDeleteConfirmation(
      context,
      itemName: item.name,
    );

    if (confirmed) {
      onItemDeleted(index);
    }
  }
}