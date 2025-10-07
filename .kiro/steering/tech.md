# Technology Stack

## Framework & Language
- **Flutter SDK**: Cross-platform UI framework
- **Dart**: Programming language (SDK ^3.9.0)
- **Material Design**: Primary UI design system

## Dependencies
- `cupertino_icons: ^1.0.8` - iOS-style icons
- `flutter_lints: ^5.0.0` - Recommended linting rules

## Development Tools
- Flutter Lints for code quality
- Analysis options configured with `package:flutter_lints/flutter.yaml`

## Responsive Design Principles
- **Fluid Layouts**: Use Slivers and flexible widgets for smooth adaptation
- **Breakpoint-free**: Avoid rigid breakpoints, use continuous scaling
- **Content-first**: Layout adapts to content, not device categories
- **Performance**: Minimize rebuilds with efficient responsive calculations

### Layout Strategy
- **Single Column** (< 600px): Stack all sections vertically
- **Two Column** (600-900px): Items + (People/Totals stacked)
- **Three Column** (> 900px): Items + People + Totals side-by-side
- **Proportional Spacing**: Use percentage-based padding and gaps
- **Constrained Width**: Prevent excessive stretching on ultra-wide screens

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d <device_id>

# Hot reload (during development)
# Press 'r' in terminal or save files in IDE
```

### Testing & Quality
```bash
# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Check for outdated dependencies
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

### Building
```bash
# Build for Android (APK)
flutter build apk

# Build for Android (App Bundle)
flutter build appbundle

# Build for iOS
flutter build ios

# Build for web
flutter build web

# Build for desktop platforms
flutter build macos
flutter build linux
flutter build windows
```

## Code Style
- Uses `flutter_lints` package for consistent code style
- Material Design components preferred
- Hot reload enabled for rapid development
- Prefer Slivers over SingleChildScrollView for complex layouts
- Use LayoutBuilder for responsive calculations
- Minimize widget rebuilds with proper keys and caching