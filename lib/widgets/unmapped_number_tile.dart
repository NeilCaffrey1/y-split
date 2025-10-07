import 'package:flutter/material.dart';
import '../models/ocr_review_models.dart';

/// Widget for displaying and mapping unmapped numbers to categories
class UnmappedNumberTile extends StatelessWidget {
  final UnmappedNumber number;
  final int index;
  final Function(String category) onMap;

  const UnmappedNumberTile({
    super.key,
    required this.number,
    required this.index,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number.value.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    if (number.originalText != number.value.toStringAsFixed(2))
                      Text(
                        'Original: ${number.originalText}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showMappingOptions(context),
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
  void _showMappingOptions(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      _showMobileBottomSheet(context);
    } else {
      _showDesktopDropdown(context);
    }
  }

  /// Show mobile bottom sheet with mapping options
  void _showMobileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Map ${number.value.toStringAsFixed(2)} as:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ..._buildMappingOptions(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Show desktop dropdown menu
  void _showDesktopDropdown(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'item',
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, size: 20),
              const SizedBox(width: 8),
              const Text('Item'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'tax',
          child: Row(
            children: [
              const Icon(Icons.account_balance, size: 20),
              const SizedBox(width: 8),
              const Text('Tax'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'service',
          child: Row(
            children: [
              const Icon(Icons.room_service, size: 20),
              const SizedBox(width: 8),
              const Text('Service Fee'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delivery',
          child: Row(
            children: [
              const Icon(Icons.delivery_dining, size: 20),
              const SizedBox(width: 8),
              const Text('Delivery Fee'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'total',
          child: Row(
            children: [
              const Icon(Icons.receipt_long, size: 20),
              const SizedBox(width: 8),
              const Text('Total'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ignore',
          child: Row(
            children: [
              const Icon(Icons.block, size: 20),
              const SizedBox(width: 8),
              const Text('Ignore'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null && context.mounted) {
        _handleMapping(context, value);
      }
    });
  }

  /// Build list of mapping option tiles
  List<Widget> _buildMappingOptions(BuildContext context) {
    return [
      _buildMappingOption(
        context,
        icon: Icons.shopping_cart,
        title: 'Item',
        subtitle: 'Add as a new item with custom name',
        category: 'item',
      ),
      _buildMappingOption(
        context,
        icon: Icons.account_balance,
        title: 'Tax',
        subtitle: 'Add to tax fees',
        category: 'tax',
      ),
      _buildMappingOption(
        context,
        icon: Icons.room_service,
        title: 'Service Fee',
        subtitle: 'Add to service fees',
        category: 'service',
      ),
      _buildMappingOption(
        context,
        icon: Icons.delivery_dining,
        title: 'Delivery Fee',
        subtitle: 'Add to delivery fees',
        category: 'delivery',
      ),
      _buildMappingOption(
        context,
        icon: Icons.receipt_long,
        title: 'Total',
        subtitle: 'Set as receipt total',
        category: 'total',
      ),
      _buildMappingOption(
        context,
        icon: Icons.block,
        title: 'Ignore',
        subtitle: 'Remove from consideration',
        category: 'ignore',
      ),
    ];
  }

  /// Build individual mapping option tile
  Widget _buildMappingOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String category,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[600]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        _handleMapping(context, category);
      },
    );
  }

  /// Handle mapping selection
  void _handleMapping(BuildContext context, String category) {
    if (category == 'item') {
      _showItemNameDialog(context);
    } else {
      onMap(category);
    }
  }

  /// Show dialog to get item name when mapping as item
  void _showItemNameDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter name for item with price ${number.value.toStringAsFixed(2)}:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Pizza, Burger, Drink',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              onSubmitted: (value) {
                final name = value.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop();
                  onMap('item:$name');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop();
                onMap('item:$name');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
