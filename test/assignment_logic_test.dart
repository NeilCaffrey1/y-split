import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:split/models/assignment_matrix.dart';
import 'package:split/models/person.dart';
import 'package:split/models/receipt_item.dart';

void main() {
  group('Assignment Matrix Tests', () {
    late AssignmentMatrix matrix;
    late List<Person> testPeople;
    late List<ReceiptItem> testItems;

    setUp(() {
      matrix = AssignmentMatrix();
      testPeople = [
        Person.withAutoColor('John', 0),
        Person.withAutoColor('Sarah', 1),
        Person.withAutoColor('Mike', 2),
      ];
      testItems = [
        ReceiptItem(name: 'Pizza', price: 24.00),
        ReceiptItem(name: 'Drinks', price: 12.00),
        ReceiptItem(name: 'Dessert', price: 8.00),
      ];

      // Add test data to matrix
      for (final person in testPeople) {
        matrix.addPerson(person);
      }
      for (final item in testItems) {
        matrix.addItem(item);
      }
    });

    test('should add and remove items correctly', () {
      final initialCount = matrix.items.length;
      final newItem = ReceiptItem(name: 'Appetizer', price: 6.00);
      
      matrix.addItem(newItem);
      expect(matrix.items.length, initialCount + 1);
      expect(matrix.items.last.name, 'Appetizer');
      
      matrix.removeItem(matrix.items.length - 1);
      expect(matrix.items.length, initialCount);
    });

    test('should add and remove people correctly', () {
      final initialCount = matrix.people.length;
      final newPerson = Person.withAutoColor('Alice', matrix.people.length);
      
      matrix.addPerson(newPerson);
      expect(matrix.people.length, initialCount + 1);
      expect(matrix.people.last.name, 'Alice');
      
      matrix.removePerson(matrix.people.length - 1);
      expect(matrix.people.length, initialCount);
    });

    test('should toggle assignments correctly', () {
      final itemIndex = 0;
      final personIndex = 0;
      final item = matrix.items[itemIndex];
      
      // Initially no assignments
      expect(item.assignedPeople.isEmpty, true);
      
      // Toggle on
      matrix.toggleAssignment(itemIndex, personIndex);
      expect(item.assignedPeople.contains(personIndex), true);
      
      // Toggle off
      matrix.toggleAssignment(itemIndex, personIndex);
      expect(item.assignedPeople.contains(personIndex), false);
    });

    test('should assign item to everyone correctly', () {
      final itemIndex = 0;
      final item = matrix.items[itemIndex];
      
      matrix.assignItemToEveryone(itemIndex);
      
      expect(item.assignedPeople.length, matrix.people.length);
      for (int i = 0; i < matrix.people.length; i++) {
        expect(item.assignedPeople.contains(i), true);
      }
    });

    test('should assign remaining items equally', () {
      // Leave first item unassigned, assign second item to one person
      matrix.toggleAssignment(1, 0);
      
      matrix.assignRemainingItemsEqually();
      
      // First item should now be assigned to everyone
      expect(matrix.items[0].assignedPeople.length, matrix.people.length);
      // Second item should remain assigned to just one person
      expect(matrix.items[1].assignedPeople.length, 1);
      // Third item should be assigned to everyone
      expect(matrix.items[2].assignedPeople.length, matrix.people.length);
    });

    test('should calculate totals correctly', () {
      // Assign pizza to John and Sarah (24.00 / 2 = 12.00 each)
      matrix.toggleAssignment(0, 0); // John
      matrix.toggleAssignment(0, 1); // Sarah
      
      // Assign drinks to all three (12.00 / 3 = 4.00 each)
      matrix.assignItemToEveryone(1);
      
      // Assign dessert to Mike only (8.00)
      matrix.toggleAssignment(2, 2); // Mike
      
      final totals = matrix.calculateTotals();
      
      expect(totals[testPeople[0]], 16.00); // John: 12.00 + 4.00
      expect(totals[testPeople[1]], 16.00); // Sarah: 12.00 + 4.00
      expect(totals[testPeople[2]], 12.00); // Mike: 4.00 + 8.00
    });

    test('should calculate totals with tip correctly', () {
      // Assign all items to everyone
      for (int i = 0; i < matrix.items.length; i++) {
        matrix.assignItemToEveryone(i);
      }
      
      final tipAmount = 8.80; // 20% tip on 44.00 total
      final totalsWithTip = matrix.calculateTotalsWithTip(tipAmount);
      
      // Each person should pay 1/3 of total + tip
      final expectedPerPerson = (44.00 + 8.80) / 3;
      
      for (final person in testPeople) {
        expect(totalsWithTip[person]!, closeTo(expectedPerPerson, 0.01));
      }
    });

    test('should handle person removal and update assignments', () {
      // Assign items to all people
      matrix.assignItemToEveryone(0);
      matrix.toggleAssignment(1, 1); // Sarah only for drinks
      
      // Remove Sarah (index 1)
      matrix.removePerson(1);
      
      expect(matrix.people.length, 2);
      expect(matrix.people[0].name, 'John');
      expect(matrix.people[1].name, 'Mike'); // Mike moved to index 1
      
      // Check that assignments were updated
      expect(matrix.items[0].assignedPeople.contains(0), true); // John still assigned
      expect(matrix.items[0].assignedPeople.contains(1), true); // Mike now at index 1
      expect(matrix.items[1].assignedPeople.isEmpty, true); // Sarah's assignment removed
    });

    test('should identify unassigned items correctly', () {
      // Assign only the first item
      matrix.toggleAssignment(0, 0);
      
      final unassigned = matrix.getUnassignedItemIndices();
      
      expect(unassigned.length, 2);
      expect(unassigned.contains(1), true);
      expect(unassigned.contains(2), true);
      expect(unassigned.contains(0), false);
    });

    test('should clear all assignments', () {
      // Assign some items
      matrix.assignItemToEveryone(0);
      matrix.toggleAssignment(1, 0);
      
      matrix.clearAllAssignments();
      
      for (final item in matrix.items) {
        expect(item.assignedPeople.isEmpty, true);
      }
    });
  });

  group('Person Model Tests', () {
    test('should generate different colors for different indices', () {
      final person1 = Person.withAutoColor('John', 0);
      final person2 = Person.withAutoColor('Sarah', 1);
      final person3 = Person.withAutoColor('Mike', 2);
      
      expect(person1.color, isNot(equals(person2.color)));
      expect(person2.color, isNot(equals(person3.color)));
      expect(person1.color, isNot(equals(person3.color)));
    });

    test('should cycle colors when index exceeds available colors', () {
      final person1 = Person.withAutoColor('Person1', 0);
      final person13 = Person.withAutoColor('Person13', 12); // Should cycle back
      
      expect(person1.color, equals(person13.color));
    });

    test('should handle equality correctly', () {
      final person1 = Person(name: 'John', color: Colors.blue);
      final person2 = Person(name: 'John', color: Colors.red);
      final person3 = Person(name: 'Sarah', color: Colors.blue);
      
      expect(person1, equals(person2)); // Same name
      expect(person1, isNot(equals(person3))); // Different name
    });

    test('should generate consistent colors', () {
      final color1 = Person.generateColor(5);
      final color2 = Person.generateColor(5);
      
      expect(color1, equals(color2));
    });
  });

  group('Receipt Item Tests', () {
    test('should calculate split price correctly', () {
      final item = ReceiptItem(name: 'Pizza', price: 24.00);
      
      // No assignments
      expect(item.splitPrice, 0.0);
      
      // One person
      item.assignedPeople.add(0);
      expect(item.splitPrice, 24.00);
      
      // Two people
      item.assignedPeople.add(1);
      expect(item.splitPrice, 12.00);
      
      // Three people
      item.assignedPeople.add(2);
      expect(item.splitPrice, 8.00);
    });

    test('should handle assignment operations correctly', () {
      final item = ReceiptItem(name: 'Pizza', price: 24.00);
      
      // Toggle assignment
      expect(item.isAssignedTo(0), false);
      item.toggleAssignment(0);
      expect(item.isAssignedTo(0), true);
      item.toggleAssignment(0);
      expect(item.isAssignedTo(0), false);
      
      // Assign to everyone
      item.assignToEveryone([0, 1, 2]);
      expect(item.assignedPeople.length, 3);
      expect(item.isAssignedTo(0), true);
      expect(item.isAssignedTo(1), true);
      expect(item.isAssignedTo(2), true);
      
      // Clear assignments
      item.clearAssignments();
      expect(item.assignedPeople.isEmpty, true);
    });

    test('should handle edge cases in split calculation', () {
      final item = ReceiptItem(name: 'Free Item', price: 0.00);
      
      item.assignedPeople.addAll([0, 1, 2]);
      expect(item.splitPrice, 0.0);
    });
  });

  group('Integration Tests', () {
    test('should handle complex assignment scenario', () {
      final matrix = AssignmentMatrix();
      
      // Add people
      final people = [
        Person.withAutoColor('Alice', 0),
        Person.withAutoColor('Bob', 1),
        Person.withAutoColor('Charlie', 2),
        Person.withAutoColor('Diana', 3),
      ];
      
      for (final person in people) {
        matrix.addPerson(person);
      }
      
      // Add items
      final items = [
        ReceiptItem(name: 'Appetizer', price: 16.00),
        ReceiptItem(name: 'Main Course', price: 80.00),
        ReceiptItem(name: 'Dessert', price: 20.00),
        ReceiptItem(name: 'Drinks', price: 24.00),
      ];
      
      for (final item in items) {
        matrix.addItem(item);
      }
      
      // Complex assignments
      matrix.assignItemToEveryone(0); // Appetizer: everyone (4.00 each)
      matrix.toggleAssignment(1, 0); // Main: Alice only (80.00)
      matrix.toggleAssignment(1, 1); // Main: Alice and Bob (40.00 each)
      matrix.toggleAssignment(2, 2); // Dessert: Charlie only (20.00)
      matrix.toggleAssignment(2, 3); // Dessert: Charlie and Diana (10.00 each)
      matrix.assignItemToEveryone(3); // Drinks: everyone (6.00 each)
      
      final totals = matrix.calculateTotals();
      
      expect(totals[people[0]], 50.00); // Alice: 4 + 40 + 0 + 6
      expect(totals[people[1]], 50.00); // Bob: 4 + 40 + 0 + 6
      expect(totals[people[2]], 20.00); // Charlie: 4 + 0 + 10 + 6
      expect(totals[people[3]], 20.00); // Diana: 4 + 0 + 10 + 6
      
      // Verify total adds up
      final totalSum = totals.values.fold(0.0, (sum, amount) => sum + amount);
      final expectedTotal = items.fold(0.0, (sum, item) => sum + item.price);
      expect(totalSum, expectedTotal);
    });

    test('should handle empty states gracefully', () {
      final matrix = AssignmentMatrix();
      
      expect(matrix.calculateTotals(), isEmpty);
      expect(matrix.getUnassignedItemIndices(), isEmpty);
      
      // Add person but no items
      matrix.addPerson(Person.withAutoColor('John', 0));
      final totals = matrix.calculateTotals();
      expect(totals.length, 1);
      expect(totals.values.first, 0.0);
    });
  });
}