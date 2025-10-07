# Design Document

## Overview

The Receipt Splitter uses a single-page Flutter web app with three main sections that flow vertically. The design prioritizes speed over complexity with smart defaults, gesture shortcuts, and instant feedback. All processing happens client-side using browser APIs for maximum privacy and speed.

## Architecture

### Single Page Layout
```
┌─────────────────────────────┐
│     Upload Section          │ ← Drop zone + quick manual entry
├─────────────────────────────┤
│     Items Section           │ ← Auto-detected + manual items
├─────────────────────────────┤  
│     People Section          │ ← Name input + assignment dots
├─────────────────────────────┤
│     Totals Section          │ ← Live calculations + share
└─────────────────────────────┘
```

### State Management
- **Single StatefulWidget**: `ReceiptSplitterPage` manages all state
- **Simple State Model**: Three main lists (items, people, assignments)
- **Real-time Updates**: setState() triggers immediate UI updates
- **No Persistence**: All data lives in memory only

### Data Flow
1. **Upload** → OCR attempt → Items list
2. **Items** + **People** → Assignment matrix
3. **Assignments** → Real-time total calculations
4. **Totals** → Share-ready text format

## Components and Interfaces

### Core Components

#### 1. UploadSection
```dart
class UploadSection extends StatelessWidget {
  final Function(File) onImageUploaded;
  final VoidCallback onManualEntry;
}
```
- Large drop zone with drag/drop support
- File picker fallback for mobile
- Instant transition to items section
- "Skip OCR" shortcut for manual entry

#### 2. ItemsSection  
```dart
class ItemsSection extends StatelessWidget {
  final List<ReceiptItem> items;
  final Function(ReceiptItem) onItemAdded;
  final Function(int, ReceiptItem) onItemUpdated;
}
```
- Auto-detected items as editable chips
- Smart text input: "$12.50 pizza" → name: "pizza", price: 12.50
- Double-tap to edit, swipe to delete
- "Add item" always visible at bottom

#### 3. PeopleSection
```dart
class PeopleSection extends StatelessWidget {
  final List<Person> people;
  final Function(String) onPersonAdded;
  final List<ReceiptItem> items;
  final Function(int itemIndex, int personIndex) onAssignmentToggled;
}
```
- Smart name input: "john, sarah, mike" creates three people
- Colored avatars for visual recognition
- Assignment dots next to each item
- Gesture shortcuts (long-press, double-tap)

#### 4. TotalsSection
```dart
class TotalsSection extends StatelessWidget {
  final Map<Person, double> totals;
  final Function(double) onTipAdded;
  final VoidCallback onShare;
}
```
- Live-updating totals with person colors
- One-tap tip/tax addition
- Share button copies formatted text
- Clear visual hierarchy

### Data Models

#### ReceiptItem
```dart
class ReceiptItem {
  String name;
  double price;
  Set<int> assignedPeople; // Person indices
  
  double get splitPrice => price / assignedPeople.length;
}
```

#### Person
```dart
class Person {
  String name;
  Color color; // Auto-assigned for visual recognition
  
  static Color generateColor(int index) => 
    Colors.primaries[index % Colors.primaries.length];
}
```

#### Assignment Matrix
```dart
// Simple 2D structure: items × people
List<List<bool>> assignments = [
  [true, false, true],  // Item 0: assigned to person 0 and 2
  [false, true, true],  // Item 1: assigned to person 1 and 2
];
```

## Error Handling

### Graceful Degradation
- **OCR fails**: Show manual entry shortcuts immediately
- **Invalid prices**: Auto-correct common formats ($12.5 → $12.50)
- **No assignments**: Highlight unassigned items in subtle color
- **Network issues**: Everything works offline after initial load

### User-Friendly Shortcuts
- **Empty state**: Show example items to demonstrate functionality
- **Parsing errors**: Smart suggestions ("Did you mean $12.50?")
- **Gesture hints**: Subtle animations show available shortcuts
- **Undo support**: Simple undo for accidental assignments

## Testing Strategy

### Core Functionality Tests
- **Upload flow**: File handling, OCR integration, manual fallback
- **Item parsing**: Text-to-item conversion, price validation
- **Assignment logic**: Toggle mechanics, bulk operations
- **Calculation accuracy**: Split math, tip distribution, rounding

### User Experience Tests
- **Gesture recognition**: Touch targets, long-press timing
- **Performance**: Large receipts (20+ items), many people (10+)
- **Responsive design**: Mobile, tablet, desktop layouts
- **Accessibility**: Screen readers, keyboard navigation

### Browser Compatibility
- **OCR libraries**: Tesseract.js fallback chains
- **File handling**: Drag/drop across browsers
- **Clipboard API**: Share functionality
- **Local storage**: Memory-only operation verification

## Technical Implementation Notes

### OCR Strategy
1. **Primary**: Browser-based Tesseract.js for client-side OCR
2. **Fallback**: Manual entry with smart parsing shortcuts
3. **Performance**: Web Workers to prevent UI blocking
4. **Accuracy**: Focus on price detection over perfect text recognition

### Responsive Design
- **Mobile-first**: Touch-optimized gestures and targets
- **Progressive enhancement**: Desktop gets additional shortcuts
- **Single layout**: Vertical flow works on all screen sizes
- **Adaptive spacing**: Comfortable on phones and tablets

### Performance Optimizations
- **Lazy loading**: OCR library loads only when needed
- **Efficient rendering**: Minimal rebuilds with targeted setState
- **Memory management**: Clear data on page refresh/close
- **Fast startup**: Core UI loads immediately, OCR loads in background

### Privacy Implementation
- **No network calls**: Everything processes locally
- **No persistence**: Data cleared on browser close
- **No analytics**: Zero tracking or data collection
- **Secure by default**: No external dependencies after load