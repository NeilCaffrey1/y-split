# Design Document

## Overview

The OCR Review Dialog is a full-screen modal interface that allows users to review and correct OCR results before applying them to the main receipt splitter. The design uses a split-screen layout with the receipt image on one side and editable detection results on the other. The interface prioritizes visual clarity, touch-friendly interactions, and seamless integration with the existing app's Material Design system.

## Architecture

### Dialog Structure
```
┌─────────────────────────────────────────────────────────────┐
│  OCR Review Dialog                                    [X]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐  ┌─────────────────────────────┐   │
│  │                     │  │   Detected Results          │   │
│  │   Receipt Image     │  │                             │   │
│  │   (Zoomable)        │  │  Items:                     │   │
│  │                     │  │  □ Pizza - $12.50 [Edit]   │   │
│  │                     │  │  □ Soda - $3.25  [Edit]    │   │
│  │                     │  │                             │   │
│  │                     │  │  Fees:                      │   │
│  │                     │  │  Tax: $2.15                 │   │
│  │                     │  │  Service: $1.50             │   │
│  │                     │  │                             │   │
│  │                     │  │  Unmapped Numbers:          │   │
│  │                     │  │  15.75 [Map as...]          │   │
│  │                     │  │                             │   │
│  │                     │  │  Total: $19.40              │   │
│  └─────────────────────┘  └─────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│              [Cancel]  [Add Item]  [Apply Changes]          │
└─────────────────────────────────────────────────────────────┘
```

### Component Hierarchy
- **OCRReviewDialog** (StatefulWidget)
  - **ImageViewer** (Zoomable receipt display)
  - **ResultsPanel** (Scrollable list of detections)
    - **ItemsList** (Editable detected items)
    - **FeesList** (Tax, service, delivery fees)
    - **UnmappedNumbersList** (Numbers needing classification)
    - **TotalsSummary** (Calculated vs detected totals)
  - **ActionBar** (Cancel, Add Item, Apply buttons)

### State Management
```dart
class OCRReviewState {
  final Uint8List imageBytes;
  final List<DetectedItem> items;
  final Map<String, double> fees;
  final List<UnmappedNumber> unmappedNumbers;
  final double? detectedTotal;
  
  // Calculated properties
  double get calculatedTotal => items.fold(0, (sum, item) => sum + item.price) + 
                               fees.values.fold(0, (sum, fee) => sum + fee);
  bool get totalsMatch => (calculatedTotal - (detectedTotal ?? 0)).abs() < 0.01;
}
```

## Components and Interfaces

### Core Components

#### 1. OCRReviewDialog
```dart
class OCRReviewDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final List<ReceiptItem> detectedItems;
  final Map<String, double> detectedFees;
  final List<double> unmappedNumbers;
  final double? detectedTotal;
  final Function(List<ReceiptItem>, Map<String, double>) onApply;
  
  static Future<bool?> show(BuildContext context, {...}) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OCRReviewDialog(...),
    );
  }
}
```

#### 2. ImageViewer
```dart
class ImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final List<DetectedRegion>? highlightedRegions;
  
  // Features:
  // - InteractiveViewer for zoom/pan
  // - Aspect ratio preservation
  // - Optional overlay highlighting of detected regions
  // - Mobile-optimized touch controls
}
```

#### 3. ResultsPanel
```dart
class ResultsPanel extends StatelessWidget {
  final OCRReviewState state;
  final Function(DetectedItem) onItemEdit;
  final Function(String, double) onFeeEdit;
  final Function(UnmappedNumber, String) onNumberMap;
  final VoidCallback onAddItem;
  
  // Sections:
  // - Detected Items (editable list)
  // - Fees (tax, service, delivery)
  // - Unmapped Numbers (with mapping options)
  // - Totals Summary (calculated vs detected)
}
```

#### 4. EditableItemTile
```dart
class EditableItemTile extends StatefulWidget {
  final DetectedItem item;
  final Function(DetectedItem) onChanged;
  final VoidCallback onDelete;
  
  // Features:
  // - Inline editing for name and price
  // - Validation with error states
  // - Delete confirmation
  // - Material Design styling
}
```

#### 5. UnmappedNumberTile
```dart
class UnmappedNumberTile extends StatelessWidget {
  final UnmappedNumber number;
  final Function(String category) onMap;
  
  // Features:
  // - Shows detected number prominently
  // - Dropdown/bottom sheet for category selection
  // - Options: Item, Tax, Service Fee, Delivery Fee, Total, Ignore
  // - When mapped as Item, shows name input field
}
```

### Data Models

#### DetectedItem
```dart
class DetectedItem {
  String name;
  double price;
  final String originalText; // For reference
  final Rect? boundingBox; // For image highlighting
  
  DetectedItem({
    required this.name,
    required this.price,
    required this.originalText,
    this.boundingBox,
  });
  
  // Convert to ReceiptItem for main app
  ReceiptItem toReceiptItem() => ReceiptItem(name: name, price: price);
}
```

#### UnmappedNumber
```dart
class UnmappedNumber {
  final double value;
  final String originalText;
  final Rect? boundingBox;
  String? mappedCategory; // 'item', 'tax', 'service', 'delivery', 'total', 'ignore'
  String? itemName; // If mapped as item
  
  UnmappedNumber({
    required this.value,
    required this.originalText,
    this.boundingBox,
  });
}
```

#### DetectedRegion
```dart
class DetectedRegion {
  final Rect boundingBox;
  final String text;
  final String category; // 'item', 'price', 'fee', 'unmapped'
  final Color highlightColor;
  
  // For optional image overlay highlighting
}
```

## User Interface Design

### Layout Strategy

#### Desktop/Tablet (> 600px width)
- **Split Screen**: Image (60%) | Results Panel (40%)
- **Fixed Dialog Size**: 80% of screen width, 90% of screen height
- **Scrollable Results**: Panel scrolls independently of image
- **Keyboard Shortcuts**: Enter to save edits, Escape to cancel

#### Mobile (< 600px width)
- **Tabbed Interface**: "Image" tab | "Results" tab
- **Full Screen**: Dialog takes full screen real estate
- **Swipe Navigation**: Swipe between image and results
- **Touch Optimized**: Larger touch targets, bottom sheet for selections

### Visual Design

#### Color Scheme
```dart
// Extends existing app theme
class OCRReviewTheme {
  static const Color correctItem = Colors.green;
  static const Color incorrectItem = Colors.orange;
  static const Color unmappedNumber = Colors.blue;
  static const Color errorState = Colors.red;
  static const Color matchingTotal = Colors.green;
  static const Color mismatchedTotal = Colors.orange;
}
```

#### Typography
- **Item Names**: Body1, editable with underline when focused
- **Prices**: Body1, monospace font for alignment
- **Categories**: Caption, uppercase, colored by type
- **Totals**: Headline6, bold, colored by match status

#### Interactive Elements
- **Edit Buttons**: Material icon buttons with tooltips
- **Delete Actions**: Require confirmation dialog
- **Mapping Dropdowns**: Material dropdown or bottom sheet on mobile
- **Add Item FAB**: Floating action button for quick access

### Responsive Behavior

#### Image Viewer
- **Auto-fit**: Image scales to fit available space
- **Zoom Controls**: Pinch-to-zoom on mobile, mouse wheel on desktop
- **Pan Limits**: Prevent panning beyond image boundaries
- **Reset Button**: Quick return to fit-to-screen view

#### Results Panel
- **Adaptive Scrolling**: Smooth scrolling with momentum
- **Section Headers**: Sticky headers for Items, Fees, Unmapped
- **Empty States**: Helpful messages when sections are empty
- **Loading States**: Skeleton loading during processing

## Error Handling

### Validation Rules
- **Price Format**: Must be valid decimal number > 0
- **Item Names**: Cannot be empty, max 100 characters
- **Duplicate Detection**: Warn when mapping same number twice
- **Total Mismatch**: Highlight but don't block when totals don't match

### User Feedback
- **Inline Errors**: Show validation errors directly on form fields
- **Toast Messages**: Success/error messages for actions
- **Confirmation Dialogs**: For destructive actions (delete, cancel with changes)
- **Progress Indicators**: For any async operations

### Graceful Degradation
- **Image Load Failure**: Show placeholder with retry option
- **Large Images**: Automatic compression/resizing for performance
- **Memory Constraints**: Lazy loading and cleanup of unused resources
- **Touch Precision**: Larger touch targets on mobile devices

## Testing Strategy

### Component Testing
- **Image Viewer**: Zoom/pan functionality, aspect ratio preservation
- **Editable Items**: Inline editing, validation, save/cancel flows
- **Number Mapping**: Category selection, duplicate prevention
- **Totals Calculation**: Real-time updates, accuracy verification

### Integration Testing
- **Dialog Flow**: Open → Edit → Apply/Cancel workflows
- **Data Persistence**: State management during editing session
- **Responsive Layout**: Behavior across different screen sizes
- **Performance**: Large receipts with many detected items

### User Experience Testing
- **Touch Interactions**: Gesture recognition, button sizing
- **Keyboard Navigation**: Tab order, enter/escape handling
- **Accessibility**: Screen reader support, color contrast
- **Error Recovery**: Handling of invalid inputs and edge cases

## Technical Implementation Notes

### Performance Optimizations
- **Image Caching**: Cache processed image for smooth zooming
- **Lazy Rendering**: Only render visible items in scrollable lists
- **Debounced Input**: Delay validation during rapid typing
- **Memory Management**: Dispose of image resources when dialog closes

### Integration Points
- **OCR Service**: Extend existing service to provide bounding box data
- **Main App State**: Clean integration with existing ReceiptSplitterPage
- **Theme System**: Inherit from existing Material theme
- **Navigation**: Proper dialog lifecycle management

### Accessibility Features
- **Screen Reader**: Semantic labels for all interactive elements
- **High Contrast**: Support for system accessibility settings
- **Font Scaling**: Respect user's preferred text size
- **Focus Management**: Proper focus order and visual indicators

### Browser Compatibility
- **Image Rendering**: Efficient handling across different browsers
- **Touch Events**: Consistent gesture recognition
- **Dialog Positioning**: Proper centering and overflow handling
- **Memory Usage**: Efficient cleanup to prevent memory leaks