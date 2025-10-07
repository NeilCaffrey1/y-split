class ReceiptItem {
  String name;
  double price;
  Set<int> assignedPeople; // Person indices

  ReceiptItem({
    required this.name,
    required this.price,
    Set<int>? assignedPeople,
  }) : assignedPeople = assignedPeople ?? <int>{};

  /// Calculate the split price per person for this item
  double get splitPrice => assignedPeople.isEmpty ? 0.0 : price / assignedPeople.length;

  /// Check if this item is assigned to a specific person
  bool isAssignedTo(int personIndex) => assignedPeople.contains(personIndex);

  /// Toggle assignment for a specific person
  void toggleAssignment(int personIndex) {
    if (assignedPeople.contains(personIndex)) {
      assignedPeople.remove(personIndex);
    } else {
      assignedPeople.add(personIndex);
    }
  }

  /// Assign this item to everyone in the provided list
  void assignToEveryone(List<int> peopleIndices) {
    assignedPeople.clear();
    assignedPeople.addAll(peopleIndices);
  }

  /// Clear all assignments for this item
  void clearAssignments() {
    assignedPeople.clear();
  }

  @override
  String toString() {
    return 'ReceiptItem(name: $name, price: ${price.toStringAsFixed(2)}, assignedTo: $assignedPeople)';
  }
}