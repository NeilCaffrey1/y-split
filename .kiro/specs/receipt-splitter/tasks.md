# Implementation Plan

- [x] 1. Set up project structure and core data models

  - Replace default Flutter app with Receipt Splitter structure
  - Create data models for ReceiptItem, Person, and assignment logic
  - Set up main app theme with neutral color palette
  - _Requirements: 6.1, 6.3_

- [x] 1.1 Create core data models and state management

  - Implement ReceiptItem class with name, price, and assigned people
  - Create Person class with name and auto-generated colors
  - Build assignment matrix logic for tracking item-person relationships
  - _Requirements: 4.1, 4.2, 5.1_

- [x] 1.2 Set up main page structure and basic layout

  - Create ReceiptSplitterPage as single StatefulWidget
  - Implement vertical section layout (Upload, Items, People, Totals)
  - Add responsive design with mobile-first approach
  - _Requirements: 6.1, 6.2_

- [ ] 2. Implement upload section with file handling

  - Create drag-and-drop upload zone with visual feedback
  - Add file picker fallback for mobile devices
  - Implement image preview and basic validation
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2.1 Build manual item entry with smart parsing

  - Create text input that parses "$12.50 pizza" format
  - Implement price validation and auto-correction
  - Add "Add item" button with keyboard shortcuts
  - _Requirements: 2.3, 2.4, 4.1_

- [x] 2.2 Add OCR integration with Tesseract.js

  - Integrate Tesseract.js for client-side OCR processing
  - Implement Web Worker to prevent UI blocking
  - Create fallback chain when OCR fails or is unavailable
  - _Requirements: 2.1, 2.2, 7.1_

- [x] 2.3 Write unit tests for item parsing and OCR

  - Test smart text parsing with various input formats
  - Verify OCR integration and fallback mechanisms
  - Test file upload validation and error handling
  - _Requirements: 2.3, 2.4_

- [x] 3. Create people management with smart input

  - Build people input that handles comma-separated names
  - Implement auto-generated color assignment for visual recognition
  - Add person editing and removal functionality
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3.1 Implement assignment interface with gesture shortcuts

  - Create colored dots for person assignment next to each item
  - Add tap-to-toggle functionality for individual assignments
  - Implement long-press to assign item to everyone
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 3.2 Add bulk assignment shortcuts

  - Create double-tap "everyone" to split all remaining items
  - Implement visual feedback for assignment changes
  - Add undo functionality for accidental assignments
  - _Requirements: 4.3, 4.4, 6.2_

- [x] 3.3 Write unit tests for assignment logic

  - Test assignment matrix operations and calculations
  - Verify gesture recognition and bulk operations
  - Test person management and color generation
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 4. Build real-time totals calculation and display

  - Implement live calculation engine for per-person totals
  - Create totals display with person colors and clear formatting
  - Add proportional tip/tax splitting functionality
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 4.1 Add sharing functionality with formatted output

  - Implement clipboard API for one-tap sharing
  - Create clean text format: "John: $12.50, Sarah: $8.25"
  - Add share button with visual feedback
  - _Requirements: 5.3, 5.4_

- [x] 4.2 Implement privacy and data management

  - Ensure all processing stays client-side in browser
  - Add automatic data clearing on page refresh/close
  - Verify no external network calls after initial load
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 4.3 Write integration tests for complete user flows

  - Test full flow from upload to sharing
  - Verify calculation accuracy with various scenarios
  - Test responsive design across different screen sizes
  - _Requirements: 5.1, 5.2, 6.1, 6.2_

- [x] 5. Polish UI and add final optimizations
  - Implement smooth animations and transitions
  - Add loading states and progress indicators
  - Optimize performance for large receipts and many people
  - _Requirements: 6.2, 6.3_
