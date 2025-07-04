# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShadowingPractice2 is an iOS application for English pronunciation practice, specifically designed for Japanese learners. It uses speech recognition to help users improve their pronunciation through shadowing and reading practice.

## Development Environment

- **IDE**: Xcode 16.3+
- **Swift**: 5.0+
- **Minimum iOS**: 18.4 (though documentation mentions iOS 17.0 compatibility)
- **UI Framework**: Pure SwiftUI (no UIKit except for special cases)
- **Architecture**: MVVM with Services layer
- **Dependencies**: None (pure Swift/SwiftUI implementation)

## Common Commands

### Build and Run
```bash
# Open project in Xcode
open ShadowingPractice2.xcodeproj

# Build from command line
xcodebuild -project ShadowingPractice2.xcodeproj -scheme ShadowingPractice2 -sdk iphonesimulator build

# Clean build folder
xcodebuild -project ShadowingPractice2.xcodeproj -scheme ShadowingPractice2 clean
```

### Testing
```bash
# Run unit tests
xcodebuild test -project ShadowingPractice2.xcodeproj -scheme ShadowingPractice2 -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -project ShadowingPractice2.xcodeproj -scheme ShadowingPractice2 -only-testing:ShadowingPractice2Tests/TextComparisonTests
```

### Code Quality
```bash
# Format Swift code (if swift-format is installed)
swift-format -i -r ShadowingPractice2/

# Analyze for potential issues
xcodebuild analyze -project ShadowingPractice2.xcodeproj -scheme ShadowingPractice2
```

## Architecture Overview

### Directory Structure
```
ShadowingPractice2/
├── App/                    # App entry point and configuration
├── Core/                   # Business logic layer
│   ├── Models/            # Data models (Codable structs)
│   ├── Services/          # Singleton services for business logic
│   └── Utilities/         # Helper functions and extensions
├── Features/              # Feature modules (MVVM pattern)
│   ├── History/           # Practice history feature
│   ├── Materials/         # Audio material management
│   ├── Practice/          # Practice modes (shadowing/reading)
│   └── Settings/          # App settings
└── Shared/                # Shared components and resources
```

### Key Architectural Patterns

1. **MVVM Pattern**:
   - Views: SwiftUI views ending with `View`
   - ViewModels: `ObservableObject` classes ending with `ViewModel`
   - Models: `Codable` structs for persistence

2. **Service Layer**:
   - Singletons accessed via `.shared`
   - Handle business logic and data management
   - Examples: `MaterialService`, `SpeechRecognizer`, `AudioRecorder`

3. **Data Flow**:
   - Local file storage in Documents directory
   - JSON metadata for materials and practice sessions
   - No network dependencies (offline-first)

### Critical Implementation Details

1. **AVAudioSession Management**:
   - Must deactivate after recording to prevent conflicts
   - Critical for avoiding 0% recognition accuracy issue
   ```swift
   // Always deactivate after use
   try? AVAudioSession.sharedInstance().setActive(false)
   ```

2. **File Access Security**:
   - Use security-scoped resources for imported files
   ```swift
   guard url.startAccessingSecurityScopedResource() else { throw error }
   defer { url.stopAccessingSecurityScopedResource() }
   ```

3. **SwiftUI State Management**:
   - Use `@StateObject` for ViewModel initialization
   - Use `@ObservedObject` when passing to child views
   - UI updates must use `@MainActor`

4. **Speech Recognition Settings**:
   ```swift
   request.shouldReportPartialResults = true
   request.taskHint = .dictation
   request.requiresOnDeviceRecognition = false  // Better accuracy
   request.addsPunctuation = true  // iOS 16+
   ```

## Key Features

1. **Material Management**: Import, record, and manage audio materials
2. **Practice Modes**: Shadowing (repeat after audio) and Reading (record original)
3. **Speech Recognition**: Real-time transcription with accuracy analysis
4. **Diff Display**: Visual comparison of original vs recognized text
5. **Practice History**: Track progress over time

## Important Files

- `App/ShadowingPractice2App.swift`: App entry point, permissions, initialization
- `Core/Services/MaterialService.swift`: Material data management
- `Core/Services/SpeechRecognizer.swift`: Speech-to-text functionality
- `Core/Services/AudioRecorder.swift`: Audio recording management
- `Features/Practice/ViewModels/PracticeViewModel.swift`: Core practice logic

## Development Guidelines

- Follow existing code patterns and naming conventions
- Maintain pure SwiftUI implementation (no external dependencies)
- Handle errors with user-friendly messages and recovery options
- Test audio functionality thoroughly (permissions, session conflicts)
- Ensure offline functionality for all core features

## Common Issues and Solutions

1. **0% Recognition Accuracy**: Check AVAudioSession deactivation
2. **File Access Errors**: Verify security-scoped resource handling
3. **UI Not Updating**: Ensure @MainActor for UI updates
4. **Memory Leaks**: Use weak self in closures and timers