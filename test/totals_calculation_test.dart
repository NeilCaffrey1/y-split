import 'package:flutter_test/flutter_test.dart';
import 'package:split/models/receipt_item.dart';
import 'package:split/models/person.dart';
import 'package:split/models/assignment_matrix.dart';

void main() {
  group('Totals Calculation Integration Tests', () {
    test('Real-time totals calculation with live updates', () {
      final matrix = AssignmentMatrix();
      
      // Add items
      final pizza = ReceiptItem(name: 'Pizza', price: 24.99);
      final drinks = ReceiptItem(name: 'Drinks', price: 8.50);
      final dessert = ReceiptItem(name: 'Dessert', price: 12.00);
      
      matrix.addItem(pizza);
      matrix.addItem(drinks);
      matrix.addItem(dessert);
      
      // Add people
      final alice = Person.withAutoColor('Alice', 0);
      final bob = Person.withAutoColor('Bob', 1);
      final charlie = Person.withAutoColor('Charlie', 2);
      
      matrix.addPerson(alice);
      matrix.addPerson(bob);
      matrix.addPerson(charlie);
      
      // Test 1: No assignments - all totals should be 0
      var totals = matrix.calculateTotals();
      expect(totals[alice], equals(0.0));
      expect(totals[bob], equals(0.0));
      expect(totals[charlie], equals(0.0));
      
      // Test 2: Assign pizza to Alice only
      matrix.toggleAssignment(0, 0); // Alice gets pizza
      totals = matrix.calculateTotals();
      expect(totals[alice], equals(24.99));
      expect(totals[bob], equals(0.0));
      expect(totals[charlie], equals(0.0));
      
      // Test 3: Share drinks between Alice and Bob
      matrix.toggleAssignment(1, 0); // Alice gets drinks
      matrix.toggleAssignment(1, 1); // Bob gets drinks
      totals = matrix.calculateTotals();
      expect(totals[alice], equals(24.99 + 4.25)); // Pizza + half drinks
      expect(totals[bob], equals(4.25)); // Half drinks
      expect(totals[charlie], equals(0.0));
      
      // Test 4: Everyone shares dessert
      matrix.toggleAssignment(2, 0); // Alice gets dessert
      matrix.toggleAssignment(2, 1); // Bob gets dessert
      matrix.toggleAssignment(2, 2); // Charlie gets dessert
      totals = matrix.calculateTotals();
      expect(totals[alice], equals(24.99 + 4.25 + 4.00)); // Pizza + half drinks + third dessert
      expect(totals[bob], equals(4.25 + 4.00)); // Half drinks + third dessert
      expect(totals[charlie], equals(4.00)); // Third dessert
      
      // Verify total sum equals original bill
      final totalBill = totals.values.fold(0.0, (sum, amount) => sum + amount);
      final originalBill = pizza.price + drinks.price + dessert.price;
      expect(totalBill, closeTo(originalBill, 0.01));
    });

    test('Proportional tip distribution accuracy', () {
      final matrix = AssignmentMatrix();
      
      // Add items with different price points
      final expensive = ReceiptItem(name: 'Steak', price: 45.00);
      final moderate = ReceiptItem(name: 'Pasta', price: 18.00);
      final cheap = ReceiptItem(name: 'Salad', price: 12.00);
      
      matrix.addItem(expensive);
      matrix.addItem(moderate);
      matrix.addItem(cheap);
      
      // Add people
      final person1 = Person.withAutoColor('Person1', 0);
      final person2 = Person.withAutoColor('Person2', 1);
      final person3 = Person.withAutoColor('Person3', 2);
      
      matrix.addPerson(person1);
      matrix.addPerson(person2);
      matrix.addPerson(person3);
      
      // Assign items to different people
      matrix.toggleAssignment(0, 0); // Person1 gets expensive item
      matrix.toggleAssignment(1, 1); // Person2 gets moderate item
      matrix.toggleAssignment(2, 2); // Person3 gets cheap item
      
      // Calculate base totals
      final baseTotals = matrix.calculateTotals();
      expect(baseTotals[person1], equals(45.00));
      expect(baseTotals[person2], equals(18.00));
      expect(baseTotals[person3], equals(12.00));
      
      // Add 20% tip ($15 on $75 total)
      final tipAmount = 15.00;
      final totalsWithTip = matrix.calculateTotalsWithTip(tipAmount);
      
      // Verify proportional tip distribution
      // Person1: $45 + ($45/$75 * $15) = $45 + $9 = $54
      // Person2: $18 + ($18/$75 * $15) = $18 + $3.60 = $21.60
      // Person3: $12 + ($12/$75 * $15) = $12 + $2.40 = $14.40
      expect(totalsWithTip[person1], closeTo(54.00, 0.01));
      expect(totalsWithTip[person2], closeTo(21.60, 0.01));
      expect(totalsWithTip[person3], closeTo(14.40, 0.01));
      
      // Verify total with tip equals original + tip
      final totalWithTip = totalsWithTip.values.fold(0.0, (sum, amount) => sum + amount);
      expect(totalWithTip, closeTo(75.00 + 15.00, 0.01));
    });

    test('Complex assignment scenarios', () {
      final matrix = AssignmentMatrix();
      
      // Create a complex scenario with multiple items and people
      final items = [
        ReceiptItem(name: 'Appetizer', price: 16.00),
        ReceiptItem(name: 'Main1', price: 28.00),
        ReceiptItem(name: 'Main2', price: 32.00),
        ReceiptItem(name: 'Shared Side', price: 8.00),
        ReceiptItem(name: 'Dessert', price: 14.00),
      ];
      
      for (final item in items) {
        matrix.addItem(item);
      }
      
      final people = [
        Person.withAutoColor('Alice', 0),
        Person.withAutoColor('Bob', 1),
        Person.withAutoColor('Carol', 2),
        Person.withAutoColor('Dave', 3),
      ];
      
      for (final person in people) {
        matrix.addPerson(person);
      }
      
      // Complex assignment pattern:
      // Appetizer: shared by Alice and Bob
      matrix.toggleAssignment(0, 0); // Alice
      matrix.toggleAssignment(0, 1); // Bob
      
      // Main1: Alice only
      matrix.toggleAssignment(1, 0); // Alice
      
      // Main2: Bob only
      matrix.toggleAssignment(2, 1); // Bob
      
      // Shared Side: everyone
      matrix.toggleAssignment(3, 0); // Alice
      matrix.toggleAssignment(3, 1); // Bob
      matrix.toggleAssignment(3, 2); // Carol
      matrix.toggleAssignment(3, 3); // Dave
      
      // Dessert: Carol and Dave
      matrix.toggleAssignment(4, 2); // Carol
      matrix.toggleAssignment(4, 3); // Dave
      
      // Calculate totals
      final totals = matrix.calculateTotals();
      
      // Expected calculations:
      // Alice: $16/2 + $28 + $8/4 = $8 + $28 + $2 = $38
      // Bob: $16/2 + $32 + $8/4 = $8 + $32 + $2 = $42
      // Carol: $8/4 + $14/2 = $2 + $7 = $9
      // Dave: $8/4 + $14/2 = $2 + $7 = $9
      
      expect(totals[people[0]], closeTo(38.00, 0.01)); // Alice
      expect(totals[people[1]], closeTo(42.00, 0.01)); // Bob
      expect(totals[people[2]], closeTo(9.00, 0.01));  // Carol
      expect(totals[people[3]], closeTo(9.00, 0.01));  // Dave
      
      // Verify total equals sum of all items
      final totalBill = totals.values.fold(0.0, (sum, amount) => sum + amount);
      final originalBill = items.fold(0.0, (sum, item) => sum + item.price);
      expect(totalBill, closeTo(originalBill, 0.01));
    });

    test('Edge cases and error handling', () {
      final matrix = AssignmentMatrix();
      
      // Test with empty matrix
      var totals = matrix.calculateTotals();
      expect(totals.isEmpty, isTrue);
      
      // Test with items but no people
      matrix.addItem(ReceiptItem(name: 'Item', price: 10.00));
      totals = matrix.calculateTotals();
      expect(totals.isEmpty, isTrue);
      
      // Test with people but no items
      matrix.items.clear();
      matrix.addPerson(Person.withAutoColor('Person', 0));
      totals = matrix.calculateTotals();
      expect(totals.length, equals(1));
      expect(totals.values.first, equals(0.0));
      
      // Test with zero-price items
      matrix.addItem(ReceiptItem(name: 'Free Item', price: 0.0));
      matrix.toggleAssignment(0, 0);
      totals = matrix.calculateTotals();
      expect(totals.values.first, equals(0.0));
      
      // Test tip calculation with zero base
      final totalsWithTip = matrix.calculateTotalsWithTip(5.0);
      expect(totalsWithTip.values.first, equals(0.0));
    });

    test('Share text formatting verification', () {
      final matrix = AssignmentMatrix();
      
      // Add items with various price formats
      matrix.addItem(ReceiptItem(name: 'Item1', price: 10.50));
      matrix.addItem(ReceiptItem(name: 'Item2', price: 7.25));
      matrix.addItem(ReceiptItem(name: 'Item3', price: 15.00));
      
      final john = Person.withAutoColor('John', 0);
      final sarah = Person.withAutoColor('Sarah', 1);
      
      matrix.addPerson(john);
      matrix.addPerson(sarah);
      
      // Assign items
      matrix.toggleAssignment(0, 0); // John gets Item1
      matrix.toggleAssignment(1, 1); // Sarah gets Item2
      matrix.toggleAssignment(2, 0); // John gets Item3
      matrix.toggleAssignment(2, 1); // Sarah gets Item3 (shared)
      
      final totals = matrix.calculateTotals();
      
      // John: $10.50 + $15.00/2 = $10.50 + $7.50 = $18.00
      // Sarah: $7.25 + $15.00/2 = $7.25 + $7.50 = $14.75
      expect(totals[john], equals(18.00));
      expect(totals[sarah], equals(14.75));
      
      // Test formatting for share text
      expect(totals[john]!.toStringAsFixed(2), equals('18.00'));
      expect(totals[sarah]!.toStringAsFixed(2), equals('14.75'));
      
      // Test with tip
      final totalsWithTip = matrix.calculateTotalsWithTip(6.55); // 20% tip
      
      // Total base: $32.75, tip: $6.55
      // John proportion: $18.00/$32.75 = 0.5496
      // Sarah proportion: $14.75/$32.75 = 0.4504
      // John with tip: $18.00 + ($6.55 * 0.5496) ≈ $18.00 + $3.60 = $21.60
      // Sarah with tip: $14.75 + ($6.55 * 0.4504) ≈ $14.75 + $2.95 = $17.70
      
      expect(totalsWithTip[john]!.toStringAsFixed(2), equals('21.60'));
      expect(totalsWithTip[sarah]!.toStringAsFixed(2), equals('17.70'));
    });
  });
}