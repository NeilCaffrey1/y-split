import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split/models/person.dart';
import 'package:split/models/receipt_item.dart';
import 'package:split/widgets/people_section.dart';

void main() {
  group('PeopleSection Widget Tests', () {
    late List<Person> testPeople;
    late List<ReceiptItem> testItems;

    setUp(() {
      testPeople = [
        Person.withAutoColor('John', 0),
        Person.withAutoColor('Sarah', 1),
      ];
      testItems = [
        ReceiptItem(name: 'Pizza', price: 24.00),
        ReceiptItem(name: 'Drinks', price: 12.00),
      ];
    });

    Widget createTestWidget({
      List<Person>? people,
      List<ReceiptItem>? items,
      Function(String)? onPersonAdded,
      Function(int)? onPersonRemoved,
      Function(int, int)? onAssignmentToggled,
      Function(int)? onAssignToEveryone,
      VoidCallback? onAssignRemainingEqually,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PeopleSection(
            people: people ?? testPeople,
            items: items ?? testItems,
            onPersonAdded: onPersonAdded ?? (name) {},
            onPersonRemoved: onPersonRemoved ?? (index) {},
            onAssignmentToggled: onAssignmentToggled ?? (itemIndex, personIndex) {},
            onAssignToEveryone: onAssignToEveryone ?? (itemIndex) {},
            onAssignRemainingEqually: onAssignRemainingEqually ?? () {},
          ),
        ),
      );
    }

    testWidgets('should display people input field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('john, sarah, mike'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('should display people list when people exist', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('People:'), findsOneWidget);
      expect(find.text('John'), findsOneWidget);
      expect(find.text('Sarah'), findsOneWidget);
    });

    testWidgets('should display empty state when no people', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(people: []));

      expect(find.text('Add people to start assigning items.'), findsOneWidget);
    });

    testWidgets('should call onPersonAdded when add button is pressed', (WidgetTester tester) async {
      String? addedName;
      
      await tester.pumpWidget(createTestWidget(
        onPersonAdded: (name) => addedName = name,
      ));

      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(addedName, 'Alice');
    });

    testWidgets('should parse comma-separated names correctly', (WidgetTester tester) async {
      final addedNames = <String>[];
      
      await tester.pumpWidget(createTestWidget(
        onPersonAdded: (name) => addedNames.add(name),
      ));

      await tester.enterText(find.byType(TextField), 'Alice, Bob, Charlie');
      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(addedNames, ['Alice', 'Bob', 'Charlie']);
    });

    testWidgets('should display assignment interface when people and items exist', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Pizza (24.00)'), findsOneWidget);
      expect(find.text('Drinks (12.00)'), findsOneWidget);
      expect(find.text('everyone'), findsNWidgets(2)); // One for each item
    });

    testWidgets('should display colored dots for person assignment', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should find assignment dots (circles) for each person for each item
      expect(find.byType(AnimatedContainer), findsNWidgets(4)); // 2 people × 2 items
    });

    testWidgets('should call onAssignmentToggled when assignment dot is tapped', (WidgetTester tester) async {
      int? toggledItemIndex;
      int? toggledPersonIndex;
      
      await tester.pumpWidget(createTestWidget(
        onAssignmentToggled: (itemIndex, personIndex) {
          toggledItemIndex = itemIndex;
          toggledPersonIndex = personIndex;
        },
      ));

      // Find and tap the first assignment dot
      final assignmentDots = find.byType(AnimatedContainer);
      await tester.tap(assignmentDots.first);
      await tester.pump();

      expect(toggledItemIndex, isNotNull);
      expect(toggledPersonIndex, isNotNull);
    });

    testWidgets('should display bulk actions when items exist', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Split remaining equally'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsWidgets);
    });

    testWidgets('should call onAssignRemainingEqually when bulk action is pressed', (WidgetTester tester) async {
      bool bulkActionCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onAssignRemainingEqually: () => bulkActionCalled = true,
      ));

      await tester.tap(find.text('Split remaining equally'));
      await tester.pump();

      expect(bulkActionCalled, true);
    });

    testWidgets('should display gesture hints', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('Long-press "everyone"'), findsOneWidget);
      expect(find.textContaining('Double-tap "everyone"'), findsOneWidget);
    });

    testWidgets('should show unassigned items warning', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('not assigned'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('should handle person removal', (WidgetTester tester) async {
      int? removedPersonIndex;
      
      await tester.pumpWidget(createTestWidget(
        onPersonRemoved: (index) => removedPersonIndex = index,
      ));

      // Find and tap the close icon for the first person
      final closeIcons = find.byIcon(Icons.close);
      await tester.tap(closeIcons.first);
      await tester.pump();

      expect(removedPersonIndex, 0);
    });

    testWidgets('should display assignment status for items', (WidgetTester tester) async {
      // Create items with some assignments
      final itemsWithAssignments = [
        ReceiptItem(name: 'Pizza', price: 24.00)..assignedPeople.add(0),
        ReceiptItem(name: 'Drinks', price: 12.00),
      ];
      
      await tester.pumpWidget(createTestWidget(items: itemsWithAssignments));

      // Should show assigned person names for pizza
      expect(find.text('John'), findsWidgets); // In people list and assignment status
    });

    testWidgets('should handle empty text input gracefully', (WidgetTester tester) async {
      String? addedName;
      
      await tester.pumpWidget(createTestWidget(
        onPersonAdded: (name) => addedName = name,
      ));

      await tester.enterText(find.byType(TextField), '   '); // Just spaces
      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(addedName, isNull); // Should not call onPersonAdded for empty input
    });

    testWidgets('should handle various name separators', (WidgetTester tester) async {
      final addedNames = <String>[];
      
      await tester.pumpWidget(createTestWidget(
        onPersonAdded: (name) => addedNames.add(name),
      ));

      await tester.enterText(find.byType(TextField), 'Alice Bob,Charlie   Dave');
      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(addedNames, ['Alice', 'Bob', 'Charlie', 'Dave']);
    });
  });

  group('PeopleSection Gesture Tests', () {
    testWidgets('should handle long press on everyone button', (WidgetTester tester) async {
      int? assignedItemIndex;
      
      final widget = MaterialApp(
        home: Scaffold(
          body: PeopleSection(
            people: [Person.withAutoColor('John', 0)],
            items: [ReceiptItem(name: 'Pizza', price: 24.00)],
            onPersonAdded: (name) {},
            onPersonRemoved: (index) {},
            onAssignmentToggled: (itemIndex, personIndex) {},
            onAssignToEveryone: (itemIndex) => assignedItemIndex = itemIndex,
            onAssignRemainingEqually: () {},
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // Find the "everyone" button and long press it
      final everyoneButton = find.text('everyone');
      await tester.longPress(everyoneButton.first);
      await tester.pump();

      expect(assignedItemIndex, 0);
    });

    testWidgets('should handle double tap on everyone button', (WidgetTester tester) async {
      bool assignRemainingCalled = false;
      
      final widget = MaterialApp(
        home: Scaffold(
          body: PeopleSection(
            people: [Person.withAutoColor('John', 0)],
            items: [ReceiptItem(name: 'Pizza', price: 24.00)],
            onPersonAdded: (name) {},
            onPersonRemoved: (index) {},
            onAssignmentToggled: (itemIndex, personIndex) {},
            onAssignToEveryone: (itemIndex) {},
            onAssignRemainingEqually: () => assignRemainingCalled = true,
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // Find the "everyone" button and double tap it
      final everyoneButton = find.text('everyone');
      await tester.tap(everyoneButton.first);
      await tester.tap(everyoneButton.first);
      await tester.pump();

      expect(assignRemainingCalled, true);
    });
  });
}