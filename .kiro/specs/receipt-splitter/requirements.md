# Requirements Document

## Introduction

The Receipt Splitter is an ultra-simple Flutter web app that gets you from receipt to split totals in under 30 seconds. One page, three sections, zero complexity. Upload receipt → tap to assign items → see totals. No accounts, no history, no bloat - just fast bill splitting with smart shortcuts.

## Requirements

### Requirement 1

**User Story:** As a user, I want to instantly upload a receipt, so that I can start splitting immediately.

#### Acceptance Criteria

1. WHEN the app loads THEN the system SHALL show a large drop zone saying "Drop receipt here"
2. WHEN a user drops any image THEN the system SHALL accept it instantly without validation dialogs
3. WHEN upload completes THEN the system SHALL auto-advance to item detection
4. WHEN no OCR is available THEN the system SHALL show manual entry shortcuts

### Requirement 2

**User Story:** As a user, I want items auto-detected with quick manual backup, so that I never get stuck.

#### Acceptance Criteria

1. WHEN receipt uploads THEN the system SHALL try OCR but never block the user
2. WHEN items are detected THEN the system SHALL show them as editable chips
3. WHEN OCR fails THEN the system SHALL show "Add item" shortcut with price parsing
4. WHEN typing "$12.50 pizza" THEN the system SHALL auto-split into name and price
5. WHEN double-tapping any item THEN the system SHALL enable quick edit mode

### Requirement 3

**User Story:** As a user, I want to add people with zero friction, so that I can focus on splitting.

#### Acceptance Criteria

1. WHEN starting THEN the system SHALL show "Add people" with smart defaults (Me, +)
2. WHEN typing names THEN the system SHALL add on Enter, comma, or space
3. WHEN typing "john, sarah, mike" THEN the system SHALL create all three people
4. WHEN people exist THEN the system SHALL show colored avatars for quick recognition

### Requirement 4

**User Story:** As a user, I want to assign items with single taps, so that splitting feels effortless.

#### Acceptance Criteria

1. WHEN items exist THEN the system SHALL show people as colored dots next to each item
2. WHEN tapping a person's dot THEN the system SHALL toggle them on/off for that item
3. WHEN long-pressing an item THEN the system SHALL assign it to everyone instantly
4. WHEN double-tapping "everyone" THEN the system SHALL split all remaining items equally
5. WHEN assignments change THEN the system SHALL update totals in real-time

### Requirement 5

**User Story:** As a user, I want to see totals instantly and share them fast, so that everyone knows what they owe.

#### Acceptance Criteria

1. WHEN assignments happen THEN the system SHALL show live totals with person colors
2. WHEN adding tip/tax THEN the system SHALL split proportionally with one tap
3. WHEN totals are ready THEN the system SHALL show "Share" button that copies clean text
4. WHEN sharing THEN the system SHALL format as "John: $12.50, Sarah: $8.25" for easy texting

### Requirement 6

**User Story:** As a user, I want the simplest possible interface, so that I never feel confused or overwhelmed.

#### Acceptance Criteria

1. WHEN the app loads THEN the system SHALL show three sections: Upload, Items, People, Totals
2. WHEN interacting THEN the system SHALL use large touch targets and instant feedback
3. WHEN displaying THEN the system SHALL use minimal colors and maximum contrast
4. WHEN errors occur THEN the system SHALL show helpful shortcuts, not error messages

### Requirement 7

**User Story:** As a privacy-focused user, I want everything local and temporary, so that my data never leaves my device.

#### Acceptance Criteria

1. WHEN processing THEN the system SHALL keep everything in browser memory only
2. WHEN closing THEN the system SHALL automatically clear all data
3. WHEN refreshing THEN the system SHALL start completely fresh
4. WHEN using THEN the system SHALL never require accounts or internet after loading