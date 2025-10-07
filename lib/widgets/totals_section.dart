import 'dart:async';
import 'package:flutter/material.dart';
import '../models/person.dart';

class TotalsSection extends StatefulWidget {
  final Map<Person, double> totals;
  final double taxAmount;
  final double serviceAmount;
  final double deliveryAmount;
  final Function(double, double, double) onFeesChanged;
  final VoidCallback onShare;

  const TotalsSection({
    super.key,
    required this.totals,
    required this.taxAmount,
    required this.serviceAmount,
    required this.deliveryAmount,
    required this.onFeesChanged,
    required this.onShare,
  });

  @override
  State<TotalsSection> createState() => _TotalsSectionState();
}

class _TotalsSectionState extends State<TotalsSection> {
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();
  Timer? _debounceTimer;

  getTotal(totals) {
    double totalValue = 0.0;
    totals.forEach((person, number) {
      totalValue += number;
    });
    return totalValue.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _taxController.text = widget.taxAmount.toStringAsFixed(2);
    _serviceController.text = widget.serviceAmount.toStringAsFixed(2);
    _deliveryController.text = widget.deliveryAmount.toStringAsFixed(2);
  }

  @override
  void didUpdateWidget(TotalsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text fields when amounts change externally
    if (widget.taxAmount != oldWidget.taxAmount) {
      _taxController.text = widget.taxAmount.toStringAsFixed(2);
    }
    if (widget.serviceAmount != oldWidget.serviceAmount) {
      _serviceController.text = widget.serviceAmount.toStringAsFixed(2);
    }
    if (widget.deliveryAmount != oldWidget.deliveryAmount) {
      _deliveryController.text = widget.deliveryAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _taxController.dispose();
    _serviceController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.totals.values.any((amount) => amount > 0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fee inputs
          Row(
            children: [
              Expanded(
                child: _buildFeeField('Tax:', _taxController, _updateFees),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeeField(
                  'Service:',
                  _serviceController,
                  _updateFees,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeeField(
                  'Delivery:',
                  _deliveryController,
                  _updateFees,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Totals display
          if (!hasItems)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Assign items to see totals.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            )
          else ...[
            ...widget.totals.entries.toList().asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final person = entry.key;
              final amount = entry.value;

              if (amount <= 0) return const SizedBox.shrink();

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(30 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: person.color.withValues(alpha: 0.08),
                          border: Border.all(
                            color: person.color.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: person.color.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: person.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: person.color.withValues(alpha: 0.3),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                person.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: person.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                amount.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: person.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            const SizedBox(height: 16),

            // Share button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Total: ${getTotal(widget.totals)}"),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('Share totals'),
                    style: ElevatedButton.styleFrom(
                      // padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeField(
    String label,
    TextEditingController controller,
    VoidCallback onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }

  void _updateFees() {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Start a new timer with 1 second delay
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      final tax = double.tryParse(_taxController.text) ?? 0.0;
      final service = double.tryParse(_serviceController.text) ?? 0.0;
      final delivery = double.tryParse(_deliveryController.text) ?? 0.0;
      widget.onFeesChanged(tax, service, delivery);
    });
  }
}
