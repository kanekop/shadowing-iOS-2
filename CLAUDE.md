# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShadowingPractice2 is an iOS application for English pronunciation practice, specifically designed for Japanese learners. It uses speech recognition to help users improve their pronunciation through shadowing and reading practice.

## Development Environment

- **IDE**: Xcode 16.3+
- **Swift**: 5.0+
- **Minimum iOS**: 16.0
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

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architectural decisions and data model relationships.

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
   - Examples: `MaterialService`, `SpeechRecognizer`, `AudioRecorder`, `PracticeHistoryService`

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
   - AudioRecorder now uses async/await for recording operations

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
- `Core/Services/PracticeHistoryService.swift`: Practice history persistence and retrieval
- `Features/Practice/PracticeViewModel.swift`: Core practice logic
- `Core/Models/PracticeResult.swift`: Practice result data model with scoring
- `Core/Models/AppError.swift`: Unified error handling model
- `Core/Models/AppError+Usage.swift`: Error handling implementation guidelines
- `Core/Utilities/Logger.swift`: Centralized logging system
- `Core/Utilities/FileManager+Extensions.swift`: File system helpers

## Development Guidelines

- Follow existing code patterns and naming conventions
- Maintain pure SwiftUI implementation (no external dependencies)
- Handle errors with user-friendly messages and recovery options
- Test audio functionality thoroughly (permissions, session conflicts)
- Ensure offline functionality for all core features
- Define enums at file top level for better reusability
- Use weak self in closures and timers to prevent memory leaks
- Prefer @StateObject for ViewModel initialization in Views

## Error Handling Strategy

1. **Service Layer**: Each service defines its own specific error types
2. **ViewModel Layer**: Convert service errors to `AppError` for unified handling
3. **View Layer**: Display errors using SwiftUI alerts with localized messages
4. **Error Usage Pattern**:
   ```swift
   // In ViewModel
   do {
       try await someService.performAction()
   } catch {
       self.error = AppError.from(error)
   }
   ```
5. See `AppError+Usage.swift` for detailed implementation guidelines

## Common Issues and Solutions

1. **0% Recognition Accuracy**: Check AVAudioSession deactivation
2. **File Access Errors**: Verify security-scoped resource handling
3. **UI Not Updating**: Ensure @MainActor for UI updates
4. **Memory Leaks**: Use weak self in closures and timers
5. **Enum Placement**: Define enums at file top level, not inside Views
6. **Async Method Naming**: Use `Async` suffix for async versions of sync methods
7. **Type Inference**: Use explicit type names for enum cases when needed

## Recent Updates

### Model Changes
- **PracticeResult**: Extended with `recordingURL`, `duration`, `practiceType` properties
- **PracticeResult**: Added computed properties: `score`, `accuracy`, `wordErrorRate`, `wordsPerMinute`
- **PracticeMode**: Made `Codable` for persistence support
- **AppError**: Created unified error model with usage guidelines

### Service Updates
- **PracticeHistoryService**: Added for practice result persistence and retrieval
- **SpeechRecognizer**: Fixed default language to en-US for English learning app
- **FileManager Extensions**: Centralized directory creation with error handling

### Best Practices Applied
- All service classes use singleton pattern (`.shared`)
- Logger provides both static and instance methods for flexibility
- FileManager extensions use static properties for app directories
- Enums moved outside of View structs for better accessibility
- Proper async/await usage in AudioRecorder and other services
- Error handling with Result types in completion handlers
- Proper memory management with weak self in closures
- Unified error handling with AppError model

## Learning Documentation

このプロジェクトでは、バグ修正やリファクタリングを通じて得られた知見を **`lesson-learnt-iOSdev.md`** にまとめています。

### 学習ドキュメントの目的
- iOS開発における問題パターンと解決方法の記録
- 同じミスを繰り返さないための参照資料
- プロジェクト固有の設計判断の理由を文書化

### 更新タイミング
- 新しいバグを修正したとき
- APIの使い方で問題が見つかったとき
- アーキテクチャの改善を行ったとき
- ビルド設定やプロジェクト構造の変更時

### 主な内容
1. **プロジェクト設定とビルドエラー**: Xcode特有の問題と解決策
2. **Swift言語仕様とAPI使用方法**: 正しいコードパターン
3. **SwiftUIとMVVMアーキテクチャ**: ベストプラクティス
4. **iOS特有のAPI使用方法**: AVFoundation、UTTypeなど
5. **デバッグとトラブルシューティング**: 効率的な問題解決方法

開発中に遭遇した問題は必ず `lesson-learnt-iOSdev.md` に記録し、チーム全体で知識を共有してください。

## Current Implementation Status

### Completed Features
- ✅ Material management (import, record, delete)
- ✅ Audio recording with AVAudioRecorder
- ✅ Speech recognition with SFSpeechRecognizer
- ✅ Text comparison and diff display
- ✅ Practice result scoring and analysis
- ✅ Basic UI for all main features
- ✅ Practice mode implementation (reading & shadowing)
- ✅ History view with statistics

### Recently Fixed Issues
- ✅ PracticeResult initialization signature mismatch - Fixed by adding explicit UUID
- ✅ AVAudioSession proper deactivation for 0% recognition issue - Added delay for reliable deactivation
- ✅ Memory leak in audio playback callbacks - Fixed with weak references
- ✅ Shared components organization - Created SearchBar and EmptyStateView
- ✅ PracticeView-ViewModel connection - Properly integrated with analyzePracticeRecording
- ✅ Added recordedAt property alias to PracticeResult for compatibility
- ✅ Created unified AppError model for consistent error handling
- ✅ Fixed SpeechRecognizer result.transcription to result.text reference error
- ✅ Implemented PracticeHistoryService for reading practice results from disk

### Pending Features
- ⏳ Material transcription caching
- ⏳ Advanced statistics and progress tracking
- ⏳ Export functionality for practice results (CSV format planned)
- ⏳ iPad support
- ⏳ Offline speech recognition optimization
- ⏳ Practice reminder notifications
- ⏳ Detailed audio waveform display

### Future Considerations (from spec v2.0)
- 🔮 OpenAI Whisper API integration (Phase 2 - 6 months)
- 🔮 Multi-language support (Japanese, Chinese)
- 🔮 Material sharing functionality
- 🔮 Cloud backup
- 🔮 AI pronunciation coaching (Phase 3 - 1 year)
- 🔮 Real-time pronunciation correction
- 🔮 Social features (rankings, etc.)
- 🔮 Material marketplace

## Specification Alignment

This implementation follows the requirements outlined in:
- `complete-shadowing-spec.md` (v2.0) - Main functional specification
- `development-guidelines.md` (v2.0) - Development standards and practices

The current implementation covers all Phase 0 (MVP) features. Future phases including external API integrations (such as OpenAI Whisper) are documented in the spec but not yet implemented.