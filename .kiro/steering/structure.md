# Project Structure

## Root Directory
- `pubspec.yaml` - Project configuration and dependencies
- `analysis_options.yaml` - Dart analyzer and linting configuration
- `README.md` - Project documentation

## Core Application
- `lib/` - Main Dart source code
  - `main.dart` - Application entry point and main widget tree

## Platform-Specific Code
- `android/` - Android-specific configuration and native code
- `ios/` - iOS-specific configuration and native code
- `web/` - Web platform assets and configuration
- `macos/` - macOS desktop application configuration
- `linux/` - Linux desktop application configuration
- `windows/` - Windows desktop application configuration

## Testing
- `test/` - Unit and widget tests
  - `widget_test.dart` - Default widget tests

## Build Artifacts
- `.dart_tool/` - Dart tooling cache and generated files
- `pubspec.lock` - Locked dependency versions

## Development Configuration
- `.idea/` - IntelliJ/Android Studio configuration
- `.vscode/` - VS Code configuration
- `.kiro/` - Kiro AI assistant configuration and steering rules

## Conventions

### File Organization
- Keep main application logic in `lib/`
- Use descriptive file names with snake_case
- Group related functionality in subdirectories under `lib/`

### Widget Structure
- StatelessWidget for static UI components
- StatefulWidget for components with mutable state
- Use `const` constructors where possible for performance
- Prefer Slivers for scrollable layouts over SingleChildScrollView
- Use LayoutBuilder for responsive calculations within widgets

### Responsive Layout Guidelines
- **Avoid rigid breakpoints**: Use continuous scaling instead of device categories
- **Use Slivers**: CustomScrollView with SliverPadding, SliverToBoxAdapter, SliverList
- **Flexible spacing**: Calculate padding/margins as percentages of screen width
- **Content-driven**: Let content determine layout, not screen size assumptions
- **Performance**: Cache expensive calculations, use proper widget keys

### Import Organization
- Flutter framework imports first
- Third-party package imports second
- Local project imports last
- Use relative imports for local files

### Code Style
- Follow `flutter_lints` recommendations
- Use trailing commas for better formatting
- Prefer `final` over `var` where possible
- Use meaningful variable and function names
- Keep methods focused and under 50 lines when possible
- Extract complex layouts into separate methods for readability