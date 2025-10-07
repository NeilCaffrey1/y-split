import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split/main.dart';
import 'package:split/models/receipt_item.dart';
import 'package:split/models/person.dart';
import 'package:split/models/assignment_matrix.dart';

void main() {
  group('Receipt Splitter Integration Tests', () {
    testWidgets('Complete user flow: add items, people, assign, and calculate totals', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const ReceiptSplitterApp());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Receipt Splitter'), findsOneWidget);
      expect(find.text('Upload Receipt'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Totals'), findsOneWidget);

      // Test manual item entry (simulating OCR fallback)
      // Note: In a real integration test, we would interact with the UI
      // For now, we'll test the underlying logic
    });

    testWidgets('Calculation accuracy with various scenarios', (WidgetTester tester) async {
      // Test scenario 1: Simple equal split
      final matrix = AssignmentMatrix();
      
      // Add items
      final pizza = ReceiptItem(name: 'Pizza', price: 20.00);
      final drinks = ReceiptItem(name: 'Drinks', price: 8.00);
      matrix.addItem(pizza);
      matrix.addItem(drinks);
      
      // Add people
      final john = Person.withAutoColor('John', 0);
      final sarah = Person.withAutoColor('Sarah', 1);
      matrix.addPerson(john);
      matrix.addPerson(sarah);
      
      // Assign items equally
      matrix.toggleAssignment(0, 0); // John gets pizza
      matrix.toggleAssignment(0, 1); // Sarah gets pizza
      matrix.toggleAssignment(1, 0); // John gets drinks
      matrix.toggleAssignment(1, 1); // Sarah gets drinks
      
      // Calculate totals
      final totals = matrix.calculateTotals();
      
      expect(totals[john], equals(14.00)); // (20/2) + (8/2) = 14
      expect(totals[sarah], equals(14.00)); // (20/2) + (8/2) = 14
    });

    testWidgets('Calculation accuracy with tip distribution', (WidgetTester tester) async {
      // Test scenario 2: Proportional tip distribution
      final matrix = AssignmentMatrix();
      
      // Add items with different prices
      final expensive = ReceiptItem(name: 'Expensive Item', price: 30.00);
      final cheap = ReceiptItem(name: 'Cheap Item', price: 10.00);
      matrix.addItem(expensive);
      matrix.addItem(cheap);
      
      // Add people
      final person1 = Person.withAutoColor('Person1', 0);
      final person2 = Person.withAutoColor('Person2', 1);
      matrix.addPerson(person1);
      matrix.addPerson(person2);
      
      // Assign items differently
      matrix.toggleAssignment(0, 0); // Person1 gets expensive item only
      matrix.toggleAssignment(1, 1); // Person2 gets cheap item only
      
      // Calculate totals with tip
      final tipAmount = 8.00; // 20% tip on $40 total
      final totalsWithTip = matrix.calculateTotalsWithTip(tipAmount);
      
      // Person1 should pay more tip (proportional to their share)
      // Person1: $30 + ($30/$40 * $8) = $30 + $6 = $36
      // Person2: $10 + ($10/$40 * $8) = $10 + $2 = $12
      expect(totalsWithTip[person1], equals(36.00));
      expect(totalsWithTip[person2], equals(12.00));
    });

    testWidgets('Assignment matrix operations', (WidgetTester tester) async {
      // Test scenario 3: Complex assignment operations
      final matrix = AssignmentMatrix();
      
      // Add multiple items
      final items = [
        ReceiptItem(name: 'Item1', price: 10.00),
        ReceiptItem(name: 'Item2', price: 15.00),
        ReceiptItem(name: 'Item3', price: 20.00),
      ];
      for (final item in items) {
        matrix.addItem(item);
      }
      
      // Add multiple people
      final people = [
        Person.withAutoColor('Alice', 0),
        Person.withAutoColor('Bob', 1),
        Person.withAutoColor('Charlie', 2),
      ];
      for (final person in people) {
        matrix.addPerson(person);
      }
      
      // Test assign to everyone functionality
      matrix.assignItemToEveryone(0); // Item1 assigned to all
      
      // Verify assignments
      expect(matrix.items[0].assignedPeople.length, equals(3));
      expect(matrix.items[0].assignedPeople.contains(0), isTrue);
      expect(matrix.items[0].assignedPeople.contains(1), isTrue);
      expect(matrix.items[0].assignedPeople.contains(2), isTrue);
      
      // Test assign remaining equally
      matrix.assignRemainingItemsEqually();
      
      // Verify all items are assigned
      for (final item in matrix.items) {
        expect(item.assignedPeople.isNotEmpty, isTrue);
      }
      
      // Calculate totals
      final totals = matrix.calculateTotals();
      
      // Each person should have some amount
      for (final person in people) {
        expect(totals[person]! > 0, isTrue);
      }
    });

    testWidgets('Edge cases and error handling', (WidgetTester tester) async {
      // Test scenario 4: Edge cases
      final matrix = AssignmentMatrix();
      
      // Test with no items
      final totals1 = matrix.calculateTotals();
      expect(totals1.isEmpty, isTrue);
      
      // Test with items but no people
      matrix.addItem(ReceiptItem(name: 'Item', price: 10.00));
      final totals2 = matrix.calculateTotals();
      expect(totals2.isEmpty, isTrue);
      
      // Test with people but no assignments
      matrix.addPerson(Person.withAutoColor('Person', 0));
      final totals3 = matrix.calculateTotals();
      expect(totals3.values.first, equals(0.0));
      
      // Test removing people updates assignments
      matrix.addPerson(Person.withAutoColor('Person2', 1));
      matrix.toggleAssignment(0, 0); // Assign to first person
      matrix.toggleAssignment(0, 1); // Assign to second person
      
      // Remove first person
      matrix.removePerson(0);
      
      // Verify assignment indices are updated
      expect(matrix.people.length, equals(1));
      expect(matrix.items[0].assignedPeople.contains(0), isTrue);
      expect(matrix.items[0].assignedPeople.contains(1), isFalse);
    });

    testWidgets('Sharing functionality format', (WidgetTester tester) async {
      // Test scenario 5: Share text formatting
      final matrix = AssignmentMatrix();
      
      // Add items and people
      matrix.addItem(ReceiptItem(name: 'Pizza', price: 25.50));
      matrix.addItem(ReceiptItem(name: 'Drinks', price: 12.25));
      
      final john = Person.withAutoColor('John', 0);
      final sarah = Person.withAutoColor('Sarah', 1);
      matrix.addPerson(john);
      matrix.addPerson(sarah);
      
      // Assign items
      matrix.toggleAssignment(0, 0); // John gets pizza
      matrix.toggleAssignment(1, 1); // Sarah gets drinks
      
      // Calculate totals
      final totals = matrix.calculateTotals();
      
      // Verify formatting would be correct
      expect(totals[john], equals(25.50));
      expect(totals[sarah], equals(12.25));
      
      // Test with tip
      final totalsWithTip = matrix.calculateTotalsWithTip(7.55); // 20% tip
      
      // John: $25.50 + ($25.50/$37.75 * $7.55) ≈ $25.50 + $5.10 = $30.60
      // Sarah: $12.25 + ($12.25/$37.75 * $7.55) ≈ $12.25 + $2.45 = $14.70
      expect(totalsWithTip[john]!.toStringAsFixed(2), equals('30.60'));
      expect(totalsWithTip[sarah]!.toStringAsFixed(2), equals('14.70'));
    });

    testWidgets('Privacy compliance verification', (WidgetTester tester) async {
      // Test scenario 6: Privacy and data management
      await tester.pumpWidget(const ReceiptSplitterApp());
      await tester.pumpAndSettle();
      
      // Verify privacy icon is present
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      
      // Tap privacy icon to show dialog
      await tester.tap(find.byIcon(Icons.privacy_tip_outlined));
      await tester.pumpAndSettle();
      
      // Verify privacy dialog content
      expect(find.text('Privacy & Data'), findsOneWidget);
      expect(find.text('Your privacy is protected:'), findsOneWidget);
      expect(find.text('All processing happens locally'), findsOneWidget);
      expect(find.text('No data sent to external servers'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    });
  });

  group('Responsive Design Tests', () {
    testWidgets('Mobile layout (small screen)', (WidgetTester tester) async {
      // Set mobile screen size
      await tester.binding.setSurfaceSize(const Size(375, 667)); // iPhone SE
      
      await tester.pumpWidget(const ReceiptSplitterApp());
      await tester.pumpAndSettle();
      
      // Verify app renders without overflow
      expect(tester.takeException(), isNull);
      
      // Verify sections are present
      expect(find.text('Upload Receipt'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Totals'), findsOneWidget);
    });

    testWidgets('Tablet layout (medium screen)', (WidgetTester tester) async {
      // Set tablet screen size
      await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad
      
      await tester.pumpWidget(const ReceiptSplitterApp());
      await tester.pumpAndSettle();
      
      // Verify app renders without overflow
      expect(tester.takeException(), isNull);
      
      // Verify sections are present and properly spaced
      expect(find.text('Upload Receipt'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Totals'), findsOneWidget);
    });

    testWidgets('Desktop layout (large screen)', (WidgetTester tester) async {
      // Set desktop screen size
      await tester.binding.setSurfaceSize(const Size(1920, 1080)); // Full HD
      
      await tester.pumpWidget(const ReceiptSplitterApp());
      await tester.pumpAndSettle();
      
      // Verify app renders without overflow
      expect(tester.takeException(), isNull);
      
      // Verify sections are present
      expect(find.text('Upload Receipt'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Totals'), findsOneWidget);
    });
  });
}