# Product Overview

**Split** is a Flutter-based receipt splitting application that helps users quickly divide bills among multiple people. The app focuses on simplicity and speed, allowing users to go from receipt upload to split totals in under 30 seconds.

## Core Features

### Receipt Processing
- **OCR Integration**: Automatic receipt scanning using Tesseract OCR to extract items and prices
- **Manual Entry Fallback**: Quick manual item entry when OCR fails or for manual receipts
- **Smart Price Parsing**: Automatic detection of prices when typing items like "$12.50 pizza"

### Bill Splitting Logic
- **Assignment Matrix**: Visual assignment system where users tap colored dots to assign items to people
- **Real-time Calculations**: Live total updates as assignments change
- **Fee Distribution**: Proportional splitting of taxes, service fees, and delivery charges
- **Bulk Actions**: Quick assignment of items to everyone or equal distribution of remaining items

### User Experience
- **Responsive Design**: Adaptive layout that works across mobile, tablet, and desktop
- **Privacy-First**: All data processing happens locally, no external servers or accounts required
- **Clean Interface**: Minimal design with three main sections: Upload, Items/People, and Totals
- **Performance Optimized**: Cached calculations and smooth animations for fluid interactions

## Current State
- **Fully Functional**: Complete receipt splitter with OCR, manual entry, and sharing capabilities
- **Multi-platform**: Configured for iOS, Android, Web, macOS, Linux, and Windows
- **Production Ready**: Comprehensive error handling, loading states, and user feedback
- **Privacy Compliant**: Local-only processing with automatic data clearing
- **Version 1.0.0+1**: Stable release with comprehensive test coverage

## Technical Stack
- **Flutter SDK**: Cross-platform UI framework with Material Design
- **Dart**: Primary programming language (SDK ^3.9.0)
- **OCR**: flutter_tesseract_ocr for receipt text extraction
- **File Handling**: file_picker and image processing capabilities
- **HTTP Client**: For any future web-based features

## Target Platforms
- **Primary**: Web (instant access, no installation required)
- **Secondary**: iOS and Android (mobile-optimized experience)
- **Tertiary**: Desktop platforms (macOS, Linux, Windows) for larger screens

## Privacy & Data Handling
- **Local Processing**: All OCR and calculations happen on-device
- **No Data Persistence**: Automatic data clearing on app close/refresh
- **No External Dependencies**: Works offline after initial load
- **No User Accounts**: Zero registration or login requirements