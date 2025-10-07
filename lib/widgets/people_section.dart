import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/receipt_item.dart';

class PeopleSection extends StatefulWidget {
  final List<Person> people;
  final List<ReceiptItem> items;
  final Function(String) onPersonAdded;
  final Function(int) onPersonRemoved;
  final Function(int, int) onAssignmentToggled;
  final Function(int) onAssignToEveryone;
  final VoidCallback onAssignRemainingEqually;

  const PeopleSection({
    super.key,
    required this.people,
    required this.items,
    required this.onPersonAdded,
    required this.onPersonRemoved,
    required this.onAssignmentToggled,
    required this.onAssignToEveryone,
    required this.onAssignRemainingEqually,
  });

  @override
  State<PeopleSection> createState() => _PeopleSectionState();
}

class _PeopleSectionState extends State<PeopleSection> {
  final TextEditingController _peopleController = TextEditingController();

  // Undo functionality
  Map<String, dynamic>? _lastAction;

  @override
  void dispose() {
    _peopleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // People input with smart parsing
          _buildPeopleInput(),

          const SizedBox(height: 16),

          // People list with editing capabilities
          if (widget.people.isNotEmpty) ...[
            _buildPeopleList(),
            const SizedBox(height: 16),
          ],

          // Assignment interface
          if (widget.people.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Add people to start assigning items.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            )
          else ...[
            // Bulk actions
            if (widget.items.isNotEmpty) ...[
              _buildBulkActions(),
              const SizedBox(height: 16),
            ],

            // Gesture hints
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Long-press "everyone" to assign item • Double-tap "everyone" to split all remaining',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Assignment matrix
            ...widget.items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;
              return _buildAssignmentRow(itemIndex, item);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPeopleInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _peopleController,
            decoration: InputDecoration(
              hintText: 'john, sarah, mike',
              helperText: 'Separate names with commas or spaces',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              prefixIcon: const Icon(Icons.person_add),
            ),
            onSubmitted: _addPeople,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _addPeople(_peopleController.text),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildPeopleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'People:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: widget.people.asMap().entries.map((entry) {
            final personIndex = entry.key;
            final person = entry.value;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: person.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: person.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: person.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    person.name,
                    style: TextStyle(
                      color: person.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => widget.onPersonRemoved(personIndex),
                    child: Icon(Icons.close, size: 14, color: person.color),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBulkActions() {
    final unassignedCount = widget.items
        .where((item) => item.assignedPeople.isEmpty)
        .length;

    return Column(
      children: [
        if (unassignedCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '$unassignedCount item${unassignedCount == 1 ? '' : 's'} not assigned',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _saveUndoState('assign_remaining');
                  _showAssignmentFeedback('Split all remaining items equally!');
                  widget.onAssignRemainingEqually();
                },
                icon: const Icon(Icons.group),
                label: Text(
                  unassignedCount > 0
                      ? 'Split $unassignedCount remaining equally'
                      : 'Split remaining equally',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentRow(int itemIndex, ReceiptItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.name} (${item.price.toStringAsFixed(2)})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onLongPress: () {
                  _saveUndoState('assign_everyone', itemIndex);
                  _showAssignmentFeedback('Assigned to everyone!');
                  widget.onAssignToEveryone(itemIndex);
                },
                onDoubleTap: () {
                  _saveUndoState('assign_remaining');
                  _showAssignmentFeedback('Split all remaining items equally!');
                  widget.onAssignRemainingEqually();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'everyone',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Assign to:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.people.asMap().entries.map((entry) {
                    final personIndex = entry.key;
                    final person = entry.value;
                    final isAssigned = item.isAssignedTo(personIndex);

                    return GestureDetector(
                      onTap: () {
                        _saveUndoState(
                          'toggle_assignment',
                          itemIndex,
                          personIndex,
                        );
                        widget.onAssignmentToggled(itemIndex, personIndex);
                        _showAssignmentFeedback(
                          isAssigned
                              ? 'Removed ${person.name}'
                              : 'Added ${person.name}',
                        );
                      },
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 250),
                        tween: Tween(begin: 0.0, end: isAssigned ? 1.0 : 0.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (0.1 * value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  Colors.grey[200]!,
                                  person.color,
                                  value,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color.lerp(
                                    Colors.grey[400]!,
                                    person.color,
                                    value,
                                  )!,
                                  width: 2,
                                ),
                                boxShadow: value > 0.5 ? [
                                  BoxShadow(
                                    color: person.color.withValues(alpha: 0.3 * value),
                                    blurRadius: 6 * value,
                                    offset: Offset(0, 2 * value),
                                  ),
                                ] : null,
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: isAssigned
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                          key: ValueKey('check_$personIndex'),
                                        )
                                      : Text(
                                          person.name.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          key: ValueKey('initial_$personIndex'),
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          if (widget.people.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: widget.people.asMap().entries.map((entry) {
                final personIndex = entry.key;
                final person = entry.value;
                final isAssigned = item.isAssignedTo(personIndex);

                if (!isAssigned) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: person.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    person.name,
                    style: TextStyle(
                      color: person.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignmentFeedback(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (_lastAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _undoLastAction,
                child: const Text(
                  'UNDO',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  void _saveUndoState(String actionType, [int? itemIndex, int? personIndex]) {
    // Save current state for undo functionality
    final actionData = <String, dynamic>{
      'type': actionType,
      'itemIndex': itemIndex,
      'personIndex': personIndex,
      'timestamp': DateTime.now(),
    };

    // Save current assignments state
    if (actionType == 'toggle_assignment' && itemIndex != null) {
      final item = widget.items[itemIndex];
      actionData['previousAssignments'] = Set<int>.from(item.assignedPeople);
    } else if (actionType == 'assign_everyone' && itemIndex != null) {
      final item = widget.items[itemIndex];
      actionData['previousAssignments'] = Set<int>.from(item.assignedPeople);
    } else if (actionType == 'assign_remaining') {
      // Save all current assignments
      actionData['allPreviousAssignments'] = widget.items
          .map((item) => Set<int>.from(item.assignedPeople))
          .toList();
    }

    _lastAction = actionData;
  }

  void _undoLastAction() {
    if (_lastAction == null) return;

    final action = _lastAction!;
    final actionType = action['type'] as String;

    try {
      if (actionType == 'toggle_assignment') {
        final itemIndex = action['itemIndex'] as int;
        final personIndex = action['personIndex'] as int;
        // Toggle back
        widget.onAssignmentToggled(itemIndex, personIndex);
      } else if (actionType == 'assign_everyone') {
        final itemIndex = action['itemIndex'] as int;
        final previousAssignments = action['previousAssignments'] as Set<int>;
        final item = widget.items[itemIndex];

        // Restore previous assignments
        item.assignedPeople.clear();
        item.assignedPeople.addAll(previousAssignments);
      } else if (actionType == 'assign_remaining') {
        final allPreviousAssignments =
            action['allPreviousAssignments'] as List<Set<int>>;

        // Restore all previous assignments
        for (
          int i = 0;
          i < widget.items.length && i < allPreviousAssignments.length;
          i++
        ) {
          widget.items[i].assignedPeople.clear();
          widget.items[i].assignedPeople.addAll(allPreviousAssignments[i]);
        }
      }

      // Clear undo state and refresh UI
      _lastAction = null;
      setState(() {});

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.undo, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Action undone'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.orange[600],
        ),
      );
    } catch (e) {
      // Handle undo errors gracefully
      _lastAction = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not undo action'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addPeople(String input) {
    if (input.trim().isEmpty) return;

    final names = input
        .split(RegExp(r'[,\s]+'))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    for (final name in names) {
      widget.onPersonAdded(name);
    }

    _peopleController.clear();
  }
}
