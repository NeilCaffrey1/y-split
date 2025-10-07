# Requirements Document

## Introduction

The OCR Review Dialog is an enhancement to the Receipt Splitter that allows users to review and correct OCR results before they are applied to the bill splitting interface. Users can view the uploaded receipt image alongside all detected numbers and text, then manually map, edit, or remove items to ensure accurate bill splitting. This feature bridges the gap between automatic OCR detection and manual entry, giving users full control over the parsing process.

## Requirements

### Requirement 1

**User Story:** As a user, I want to review the OCR results in a dialog after upload, so that I can verify and correct the detected items before they appear in the main interface.

#### Acceptance Criteria

1. WHEN OCR processing completes THEN the system SHALL show an optional "Review Results" button or automatically open the review dialog
2. WHEN the review dialog opens THEN the system SHALL display the uploaded receipt image alongside the detected items
3. WHEN viewing the dialog THEN the system SHALL show all detected numbers, text, and their current mappings (item, price, tax, service fee, etc.)
4. WHEN the user is satisfied with the results THEN the system SHALL allow them to apply the changes to the main interface
5. WHEN the user cancels the dialog THEN the system SHALL revert to the original OCR results

### Requirement 2

**User Story:** As a user, I want to see the receipt image while reviewing OCR results, so that I can visually verify what was detected against the actual receipt.

#### Acceptance Criteria

1. WHEN the dialog opens THEN the system SHALL display the uploaded receipt image in a zoomable/pannable view
2. WHEN viewing the image THEN the system SHALL maintain aspect ratio and allow users to zoom in for better readability
3. WHEN numbers are detected THEN the system SHALL optionally highlight or overlay detected regions on the image
4. WHEN the image is too large THEN the system SHALL provide scroll/pan controls for navigation
5. WHEN on mobile devices THEN the system SHALL optimize the image display for smaller screens

### Requirement 3

**User Story:** As a user, I want to manually map detected numbers to different categories, so that I can correct misclassified items and fees.

#### Acceptance Criteria

1. WHEN viewing detected numbers THEN the system SHALL show each number with its current mapping (item, tax, service fee, delivery fee, total, or unmapped)
2. WHEN tapping a detected number THEN the system SHALL allow me to change its category via dropdown or selection interface
3. WHEN mapping a number as an item THEN the system SHALL allow me to add or edit the item name
4. WHEN mapping a number as a fee THEN the system SHALL categorize it as tax, service fee, or delivery fee
5. WHEN a number is already used THEN the system SHALL prevent duplicate mappings or warn about conflicts

### Requirement 4

**User Story:** As a user, I want to edit item names and prices from the OCR results, so that I can fix recognition errors and improve accuracy.

#### Acceptance Criteria

1. WHEN viewing detected items THEN the system SHALL show each item with editable name and price fields
2. WHEN editing an item name THEN the system SHALL provide a text input with the current detected text as default
3. WHEN editing a price THEN the system SHALL validate the input and show formatting errors
4. WHEN an item name is unclear THEN the system SHALL allow me to type a completely new name
5. WHEN saving edits THEN the system SHALL update the item in the review list immediately

### Requirement 5

**User Story:** As a user, I want to remove incorrectly detected numbers or items, so that they don't appear in my final bill splitting.

#### Acceptance Criteria

1. WHEN viewing the detected results THEN the system SHALL provide a delete/remove option for each detected item or number
2. WHEN removing an item THEN the system SHALL ask for confirmation to prevent accidental deletion
3. WHEN removing a number THEN the system SHALL remove it from all category mappings
4. WHEN an item is removed THEN the system SHALL update the total calculations in real-time
5. WHEN all items are removed THEN the system SHALL show an empty state with option to add manual items

### Requirement 6

**User Story:** As a user, I want to add missing items that OCR didn't detect, so that I can have a complete bill without switching to manual entry mode.

#### Acceptance Criteria

1. WHEN reviewing results THEN the system SHALL provide an "Add Item" button to manually add missing items
2. WHEN adding an item THEN the system SHALL provide name and price input fields
3. WHEN typing prices THEN the system SHALL support the same smart parsing as the main interface ("$12.50" format)
4. WHEN adding items THEN the system SHALL include them in the final results alongside OCR-detected items
5. WHEN saving new items THEN the system SHALL validate the input and show any errors

### Requirement 7

**User Story:** As a user, I want to see real-time totals and validation in the review dialog, so that I can verify the numbers match the receipt total.

#### Acceptance Criteria

1. WHEN items and fees are mapped THEN the system SHALL calculate and display the total in real-time
2. WHEN the calculated total differs from detected receipt total THEN the system SHALL highlight the discrepancy
3. WHEN there are unmapped numbers THEN the system SHALL show them as potential missing items or fees
4. WHEN validation errors exist THEN the system SHALL show clear indicators and suggestions for resolution
5. WHEN totals match THEN the system SHALL show a positive confirmation indicator

### Requirement 8

**User Story:** As a user, I want the review dialog to work seamlessly with the existing privacy model, so that my data remains secure and local.

#### Acceptance Criteria

1. WHEN using the review dialog THEN the system SHALL keep all data processing local to the browser
2. WHEN the dialog is closed THEN the system SHALL not persist any review state beyond the current session
3. WHEN applying changes THEN the system SHALL only update the main interface state without external storage
4. WHEN canceling the dialog THEN the system SHALL clear any temporary review data
5. WHEN the page refreshes THEN the system SHALL not retain any review dialog history or state