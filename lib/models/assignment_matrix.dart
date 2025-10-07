import 'receipt_item.dart';
import 'person.dart';

class AssignmentMatrix {
  List<ReceiptItem> items;
  List<Person> people;

  AssignmentMatrix({
    List<ReceiptItem>? items,
    List<Person>? people,
  })  : items = items ?? [],
        people = people ?? [];

  /// Add a new item to the matrix
  void addItem(ReceiptItem item) {
    items.add(item);
  }

  /// Remove an item from the matrix
  void removeItem(int itemIndex) {
    if (itemIndex >= 0 && itemIndex < items.length) {
      items.removeAt(itemIndex);
    }
  }

  /// Add a new person to the matrix
  void addPerson(Person person) {
    people.add(person);
  }

  /// Remove a person from the matrix and update all item assignments
  void removePerson(int personIndex) {
    if (personIndex >= 0 && personIndex < people.length) {
      people.removeAt(personIndex);
      
      // Update all item assignments to remove this person and adjust indices
      for (final item in items) {
        item.assignedPeople.remove(personIndex);
        
        // Adjust indices for people that come after the removed person
        final updatedAssignments = <int>{};
        for (final assignedIndex in item.assignedPeople) {
          if (assignedIndex > personIndex) {
            updatedAssignments.add(assignedIndex - 1);
          } else {
            updatedAssignments.add(assignedIndex);
          }
        }
        item.assignedPeople = updatedAssignments;
      }
    }
  }

  /// Toggle assignment for a specific item and person
  void toggleAssignment(int itemIndex, int personIndex) {
    if (itemIndex >= 0 && itemIndex < items.length && 
        personIndex >= 0 && personIndex < people.length) {
      items[itemIndex].toggleAssignment(personIndex);
    }
  }

  /// Assign an item to all people
  void assignItemToEveryone(int itemIndex) {
    if (itemIndex >= 0 && itemIndex < items.length) {
      final allPeopleIndices = List.generate(people.length, (index) => index);
      items[itemIndex].assignToEveryone(allPeopleIndices);
    }
  }

  /// Assign all unassigned items equally among all people
  void assignRemainingItemsEqually() {
    if (people.isEmpty) return;
    
    final allPeopleIndices = List.generate(people.length, (index) => index);
    
    for (final item in items) {
      if (item.assignedPeople.isEmpty) {
        item.assignToEveryone(allPeopleIndices);
      }
    }
  }

  /// Calculate total amount owed by each person
  Map<Person, double> calculateTotals() {
    final totals = <Person, double>{};
    
    // Initialize totals for all people
    for (final person in people) {
      totals[person] = 0.0;
    }
    
    // Calculate totals based on assignments
    for (final item in items) {
      if (item.assignedPeople.isNotEmpty) {
        final splitAmount = item.splitPrice;
        for (final personIndex in item.assignedPeople) {
          if (personIndex < people.length) {
            totals[people[personIndex]] = 
                (totals[people[personIndex]] ?? 0.0) + splitAmount;
          }
        }
      }
    }
    
    return totals;
  }

  /// Add tip/tax and distribute proportionally
  Map<Person, double> calculateTotalsWithTip(double tipAmount) {
    final baseTotals = calculateTotals();
    final totalBase = baseTotals.values.fold(0.0, (sum, amount) => sum + amount);
    
    if (totalBase == 0.0) return baseTotals;
    
    final totalsWithTip = <Person, double>{};
    for (final entry in baseTotals.entries) {
      final proportion = entry.value / totalBase;
      totalsWithTip[entry.key] = entry.value + (tipAmount * proportion);
    }
    
    return totalsWithTip;
  }

  /// Get unassigned items
  List<int> getUnassignedItemIndices() {
    final unassigned = <int>[];
    for (int i = 0; i < items.length; i++) {
      if (items[i].assignedPeople.isEmpty) {
        unassigned.add(i);
      }
    }
    return unassigned;
  }

  /// Clear all assignments
  void clearAllAssignments() {
    for (final item in items) {
      item.clearAssignments();
    }
  }
}