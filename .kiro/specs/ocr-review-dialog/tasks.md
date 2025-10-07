# Implementation Plan

- [x] 1. Create core data models and dialog structure

  - Implement DetectedItem, UnmappedNumber, and DetectedRegion data models
  - Create OCRReviewDialog StatefulWidget with basic modal structure
  - Set up OCRReviewState class for managing dialog state
  - _Requirements: 1.3, 8.3_

- [x] 1.1 Build basic dialog layout and responsive structure

  - Implement responsive layout switching between desktop split-screen and mobile tabs
  - Create placeholder containers for image viewer and results panel
  - Add dialog app bar with title and close button
  - _Requirements: 1.2, 2.4_

- [x] 1.2 Add dialog integration to existing OCR flow

  - Modify existing OCR processing in receipt_splitter_page.dart to show review dialog
  - Create dialog show/hide methods with proper result handling
  - Implement apply/cancel logic that updates main app state
  - _Requirements: 1.1, 1.4, 1.5_

- [x] 2. Implement image viewer component

  - Create ImageViewer widget with InteractiveViewer for zoom/pan functionality
  - Add image loading, error handling, and aspect ratio preservation
  - Implement mobile-optimized touch controls and zoom limits
  - _Requirements: 2.1, 2.2, 2.4_

- [ ]\* 2.1 Write unit tests for image viewer functionality

  - Test zoom/pan behavior and boundary constraints
  - Verify image loading and error states
  - Test responsive behavior across different screen sizes
  - _Requirements: 2.1, 2.2, 2.4_

- [ ] 3. Build results panel with detected items list

  - Create ResultsPanel widget with scrollable sections layout
  - Implement ItemsList component showing detected items
  - Add section headers for Items, Fees, Unmapped Numbers, and Totals
  - _Requirements: 1.3, 4.1_

- [x] 3.1 Implement editable item tiles

  - Create EditableItemTile with inline editing for name and price
  - Add validation for price format and item name requirements
  - Implement save/cancel functionality with proper state updates
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 3.2 Add item deletion with confirmation

  - Implement delete button on each item tile
  - Create confirmation dialog for item removal
  - Update totals calculation when items are removed
  - _Requirements: 5.1, 5.2, 5.4_

- [ ]\* 3.3 Write unit tests for item editing functionality

  - Test inline editing validation and state updates
  - Verify delete confirmation and state cleanup
  - Test edge cases with invalid input formats
  - _Requirements: 4.2, 4.3, 5.1, 5.2_

- [x] 4. Create fees management section

  - Implement FeesList component for tax, service, and delivery fees
  - Add editable fee tiles with category labels and validation
  - Create fee editing interface with proper number formatting
  - _Requirements: 3.1, 3.4, 4.2_

- [x] 4.1 Build unmapped numbers interface

  - Create UnmappedNumberTile component for unclassified numbers
  - Implement category mapping dropdown/bottom sheet
  - Add item name input when mapping number as new item
  - _Requirements: 3.1, 3.2, 3.3, 6.2_

- [ ]\* 4.2 Add number mapping validation and conflict prevention

  - Implement duplicate mapping detection and warnings
  - Create validation for mapping the same number to multiple categories
  - Add visual indicators for successfully mapped vs unmapped numbers
  - _Requirements: 3.5, 7.3_

- [ ]\* 4.3 Write unit tests for fees and mapping functionality

  - Test fee editing and validation logic
  - Verify number mapping and conflict detection
  - Test category selection and item name input
  - _Requirements: 3.1, 3.2, 3.5_

- [x] 5. Implement real-time totals calculation and validation

  - Create TotalsSummary component with calculated vs detected total comparison
  - Add real-time calculation updates when items or fees change
  - Implement visual indicators for matching vs mismatched totals
  - _Requirements: 7.1, 7.2, 7.5_

- [ ]\* 5.1 Add totals mismatch handling and suggestions

  - Create visual highlighting when calculated total differs from detected total
  - Implement suggestions for resolving total discrepancies
  - Add indicators for unmapped numbers that might resolve mismatches
  - _Requirements: 7.2, 7.3, 7.4_

- [ ]\* 5.2 Write unit tests for totals calculation

  - Test real-time calculation accuracy with various item combinations
  - Verify mismatch detection and visual indicator logic
  - Test edge cases with missing or invalid totals
  - _Requirements: 7.1, 7.2, 7.5_

- [ ] 6. Add manual item creation functionality

  - Implement "Add Item" button and input dialog
  - Create new item form with name and price fields
  - Add smart price parsing support ("12.50 pizza" format)
  - _Requirements: 6.1, 6.2, 6.3, 6.5_

- [x] 6.1 Integrate manual items with existing OCR results

  - Merge manually added items with OCR-detected items in results list
  - Update totals calculation to include manual items
  - Ensure manual items are included in final apply operation
  - _Requirements: 6.4, 6.5_

- [ ]\* 6.2 Write unit tests for manual item creation

  - Test item creation form validation and smart parsing
  - Verify integration with existing OCR results
  - Test totals calculation with mixed manual and OCR items
  - _Requirements: 6.1, 6.2, 6.3, 6.5_

- [x] 7. Implement dialog action bar and state management

  - Create action bar with Cancel, Add Item, and Apply Changes buttons
  - Implement proper state cleanup on cancel operation
  - Add confirmation dialog when canceling with unsaved changes
  - _Requirements: 1.4, 1.5, 8.4_

- [x] 7.1 Add data privacy and session management

  - Ensure all dialog state remains local and temporary
  - Implement proper cleanup when dialog closes or page refreshes
  - Verify no external network calls or data persistence
  - _Requirements: 8.1, 8.2, 8.4, 8.5_

- [ ]\* 7.2 Write integration tests for complete dialog workflow

  - Test full flow from dialog open to apply/cancel operations
  - Verify state management and cleanup across dialog lifecycle
  - Test responsive behavior and mobile/desktop differences
  - _Requirements: 1.1, 1.4, 1.5, 8.1_

- [ ]\* 8. Polish UI and add accessibility features

  - Implement smooth animations and transitions for dialog operations
  - Add loading states and progress indicators for async operations
  - Create proper focus management and keyboard navigation
  - _Requirements: 1.2, 4.5, 7.4_

- [ ]\* 8.1 Add accessibility and screen reader support

  - Implement semantic labels and descriptions for all interactive elements
  - Add proper focus order and visual focus indicators
  - Create high contrast support and respect system accessibility settings
  - _Requirements: 1.2, 4.1, 6.1_

- [ ]\* 8.2 Write accessibility and performance tests
  - Test screen reader compatibility and keyboard navigation
  - Verify performance with large receipts and many detected items
  - Test memory usage and cleanup to prevent leaks
  - _Requirements: 1.2, 7.1, 8.1_
