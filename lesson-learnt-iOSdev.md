# iOS Development Lessons Learned - ShadowingPractice2 Project

## 1. Project Configuration and Build Errors

### 1.1 Info.plist Duplication Issues

**Problem**: 
- Xcode 16.3's new project format uses `PBXFileSystemSynchronizedRootGroup`
- Having both `GENERATE_INFOPLIST_FILE = YES` and a physical Info.plist file causes duplication errors

**Solution**:
```
// Set the following in project.pbxproj
GENERATE_INFOPLIST_FILE = NO;
INFOPLIST_FILE = ShadowingPractice2/Info.plist;
EXCLUDED_SOURCE_FILE_NAMES = Info.plist;

// Add exceptions to file system synchronized groups
PBXFileSystemSynchronizedBuildFileExceptionSet {
    membershipExceptions = (Info.plist);
}
```

**Learnings**:
- When custom Info.plist is needed, disable auto-generation
- Test targets should generate their own Info.plist (`GENERATE_INFOPLIST_FILE = YES`)
- Understanding project file structure is crucial

### 1.2 Understanding Build Phases

**Key Concepts**:
- Copy Bundle Resources: Resources copied to app bundle
- Compile Sources: Source files to be compiled
- Link Binary With Libraries: Frameworks to be linked

**Important Notes**:
- Info.plist should not be included in Copy Bundle Resources (it's processed automatically)

## 2. Swift Language Specifications and API Usage

### 2.1 Singleton Pattern Implementation

**Problem**: ViewModels expected shared instances of service classes that weren't implemented

**Correct Implementation**:
```swift
class MaterialService: ObservableObject {
    // Singleton instance
    static let shared = MaterialService()
    
    // Optionally use private init() to prevent external instantiation
}
```

### 2.2 Logger Design Pattern

**Problem**: Inconsistent calls due to mixing static and instance methods

**Solution**:
```swift
struct Logger {
    static let shared = Logger()
    
    // Instance methods (for shared instance)
    func info(_ message: String) {
        Logger.info(message)  // Delegate to static method
    }
    
    // Static methods (actual implementation)
    static func info(_ message: String) {
        // Implementation
    }
}
```

**Learnings**:
- Importance of providing consistent APIs
- Proper use of static vs instance methods

### 2.3 FileManager Extension Pitfalls

**Problem**: Mixing static properties and instance methods

**Incorrect Usage**:
```swift
FileManager.default.materialsDirectory  // ❌ Not defined as instance property
```

**Correct Usage**:
```swift
FileManager.materialsDirectory  // ✅ Defined as static property
```

**Best Practices**:
```swift
extension FileManager {
    // App-specific directories as static properties
    static var documentsDirectory: URL { ... }
    
    // Generic operations as instance methods
    func createSubdirectoryIfNeeded(named: String) throws { ... }
}
```

### 2.4 Async/Await and Asynchronous Processing

**Problem**: Trying to call synchronous methods as asynchronous

**Pattern 1 - Async Wrapper**:
```swift
// Synchronous method
func updateMaterial(_ material: Material) { ... }

// Async wrapper
func updateMaterialAsync(_ material: Material) async {
    await MainActor.run {
        updateMaterial(material)
    }
}
```

**Pattern 2 - Task Processing**:
```swift
func savePracticeResult(_ result: PracticeResult) {
    Task {
        do {
            try await savePracticeResultToFile(result)  // Different name to prevent recursion
        } catch {
            // Error handling
        }
    }
}
```

### 2.5 Recursive Call Bugs

**Problem**: Methods calling themselves causing stack overflow

**Incorrect Example**:
```swift
func savePracticeResult(_ result: PracticeResult) {
    Task {
        try await savePracticeResult(result)  // ❌ Infinite recursion
    }
}
```

**Correct Example**:
```swift
func savePracticeResult(_ result: PracticeResult) {
    Task {
        try await savePracticeResultToFile(result)  // ✅ Call different method
    }
}
```

### 2.6 Method Visibility and Duplication

**Problem**: Duplicate method declarations in same class

**Common Causes**:
1. Copy-paste errors
2. Merging code from different sources
3. Refactoring remnants

**Best Practices**:
- Use clear access control (`private`, `internal`, `public`)
- Keep public API minimal and well-documented
- Use protocols to define public interfaces
- Regularly search for duplicate declarations

**Example**:
```swift
class Service {
    // Public API
    func reloadData() {
        loadDataFromDisk()
    }
    
    // Private implementation
    private func loadDataFromDisk() {
        // Implementation
    }
}
```

## 3. SwiftUI and MVVM Architecture

### 3.1 Enum Definition Placement

**Problem**: Enums defined inside Views cannot be accessed from ViewModels

**Solution**:
```swift
// Define at file top level
enum PracticeMode: String, CaseIterable {
    case reading = "Reading"
    case shadowing = "Shadowing"
}

// Then define the View
struct PracticeView: View {
    @State private var practiceMode: PracticeMode = .reading
}
```

### 3.2 SwiftUI Binding Patterns

**Problem**: Picker with `.constant()` binding doesn't allow user interaction

**Incorrect Example**:
```swift
struct PracticeView: View {
    @State private var practiceMode: PracticeMode = .reading
    
    var body: some View {
        PracticeContentView(
            practiceMode: practiceMode  // ❌ Passing value, not binding
        )
    }
}

struct PracticeContentView: View {
    let practiceMode: PracticeMode  // ❌ Can't modify this
    
    var body: some View {
        Picker("Mode", selection: .constant(practiceMode)) {  // ❌ Read-only
            // ...
        }
    }
}
```

**Correct Example**:
```swift
struct PracticeView: View {
    @State private var practiceMode: PracticeMode = .reading
    
    var body: some View {
        PracticeContentView(
            practiceMode: $practiceMode  // ✅ Passing binding
        )
    }
}

struct PracticeContentView: View {
    @Binding var practiceMode: PracticeMode  // ✅ Can modify parent's state
    
    var body: some View {
        Picker("Mode", selection: $practiceMode) {  // ✅ Two-way binding
            // ...
        }
    }
}
```

**Key Learning**:
- Use `@Binding` in child views to modify parent's `@State`
- Pass bindings with `$` prefix
- `.constant()` creates read-only bindings for display purposes only

### 3.3 ObservableObject Integration

**Pattern**:
```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    private let service = Service.shared
    
    func loadItems() {
        // Process synchronously
        service.reloadItems()
        items = service.items.sorted { ... }
    }
}
```

## 4. iOS-Specific API Usage

### 4.1 AVFoundation

**Incorrect Example**:
```swift
AVAudioApplication.requestRecordPermission { ... }  // ❌ Non-existent API
```

**Correct Example**:
```swift
AVAudioSession.sharedInstance().requestRecordPermission { ... }  // ✅
```

### 4.2 UniformTypeIdentifiers (UTType)

**Problem**: Not all file formats have predefined UTTypes

**Solution**:
```swift
static let supportedTypes: [UTType] = [
    .mp3,
    .wav,
    .mpeg4Audio,  // Use .mpeg4Audio instead of .m4a
    .aiff,
    UTType(filenameExtension: "caf") ?? .audio,  // Custom extension
    UTType(filenameExtension: "m4a") ?? .audio   // Fallback
]
```

### 4.3 os_log and Format Specifiers

**Problem**: Type conversion errors with os_log format specifiers

**Incorrect Example**:
```swift
os_log("[ERROR] %{public}@ - %{public}@:%{public}d", 
       fileName, function, line)  // ❌ %d expects CInt, not Int
```

**Correct Example**:
```swift
os_log("[ERROR] %{public}@ - %{public}@:%{public}ld", 
       fileName, function, line)  // ✅ %ld for Int values
```

**Format Specifier Reference**:
- `%@` - Objects (String, NSObject subclasses)
- `%d` - 32-bit signed integers (CInt)
- `%ld` - Long integers (Int on 64-bit systems)
- `%f` - Floating point numbers
- `%{public}` - Modifier to make the value visible in Console.app

### 4.4 StaticString vs String

**Problem**: Some APIs require StaticString but we have regular String

**Example Issue**:
```swift
assertionFailure(message, file: file, line: line)  
// ❌ file is String, but assertionFailure expects StaticString
```

**Solution**:
```swift
assertionFailure(message)  
// ✅ Let it use default #file and #line parameters
```

## 5. Debugging and Troubleshooting

### 5.1 Reading Error Messages

1. **Build Phase Errors**: Check which phase failed
2. **Swift Compile Errors**: Check specific code location and reason
3. **Duplicate File Errors**: Review project settings
4. **Type Mismatch Errors**: Verify expected types in error messages

### 5.2 Incremental Fix Approach

1. Fix the most basic errors first (imports, type definitions, etc.)
2. Fix architecture-level issues (singletons, dependencies)
3. Fix detailed API usage

### 5.3 Project-Wide Consistency Check

**Checklist**:
- [ ] Singleton patterns for all service classes
- [ ] Consistent Logger usage
- [ ] FileManager extension usage patterns
- [ ] Async method naming conventions
- [ ] Proper placement of enums and structs

## 6. Best Practices

### 6.1 Naming Conventions

- Add `Async` suffix to async versions of methods
- Use different names for internal implementation methods (prevent recursion)

### 6.2 Error Handling

```swift
do {
    try await someAsyncOperation()
} catch {
    Logger.shared.error("Operation failed: \(error)")
    // Set user-facing error message
}
```

### 6.3 Project Structure

```
Project/
├── App/               # App entry point
├── Core/              # Business logic
│   ├── Models/        # Data models
│   ├── Services/      # Singleton services
│   └── Utilities/     # Helpers, extensions
└── Features/          # Feature-based UI
    └── Feature/
        ├── Views/
        └── ViewModels/
```

## 7. Model Design and Data Flow

### 7.1 Model Initialization Patterns

**Problem**: Complex models with many parameters can have different initializers

**Best Practice**:
- Provide convenience initializers for common use cases
- Use default parameters where appropriate
- Consider builder pattern for very complex objects

**Example**:
```swift
struct PracticeResult {
    // Simple initializer for most cases
    init(recognizedText: String, originalText: String, wordAnalysis: [WordAnalysis]) {
        // Calculate scores internally
    }
    
    // Full initializer for loading from storage
    init(id: UUID, createdAt: Date, recognizedText: String, /* ... */) {
        // Direct assignment
    }
}
```

### 7.2 ViewModels and Service Dependencies

**Problem**: Deciding between singleton instances and dependency injection

**Guidelines**:
- Use singletons for true app-wide services (MaterialService, AudioRecorder)
- Use instances for utilities without state (TextComparisonService)
- Always use `.shared` for consistency when using singletons

**Example**:
```swift
class ViewModel: ObservableObject {
    private let audioRecorder = AudioRecorder.shared  // Singleton
    private let textService = TextComparisonService() // Instance
}
```

### 7.3 Async Method Naming

**Problem**: Methods that are sometimes async and sometimes not

**Solution**: Create separate async wrappers with clear naming

```swift
// Synchronous
func updateMaterial(_ material: Material)

// Asynchronous wrapper
func updateMaterialAsync(_ material: Material) async

// Async-throws version
func deleteMaterialAsync(_ material: Material) async throws
```

## 8. Future Improvements

1. **Dependency Injection**: Consider dependency injection instead of singletons
2. **Protocol-Oriented**: Reduce dependencies on concrete types
3. **Testability**: Design for easier mocking
4. **Error Type Unification**: Consistent error handling across the app
5. **Model Versioning**: Plan for data model evolution

## 9. iOS Version Compatibility

### 9.1 @AppStorage with Custom Types (iOS 18.0+)

**Problem**: iOS 18.0 introduced new @AppStorage initializers that are not available in earlier versions

**Incorrect Example (iOS 18.0+ only)**:
```swift
@AppStorage("selectedEngine") private var selectedEngine: EngineType = .apple
@AppStorage("reminderTime") private var reminderTime = Date()
```

**Correct Example (iOS 16.0+)**:
```swift
// Store raw values instead of custom types
@AppStorage("selectedEngine") private var selectedEngine = EngineType.apple.rawValue
@AppStorage("reminderTime") private var reminderTimeInterval: Double = Date().timeIntervalSince1970

// Create computed properties or Binding for conversion
private var selectedEngineType: Binding<EngineType> {
    Binding(
        get: { EngineType(rawValue: selectedEngine) ?? .apple },
        set: { selectedEngine = $0.rawValue }
    )
}

private var reminderTime: Binding<Date> {
    Binding(
        get: { Date(timeIntervalSince1970: reminderTimeInterval) },
        set: { reminderTimeInterval = $0.timeIntervalSince1970 }
    )
}
```

**Learnings**:
- Always check iOS deployment target when using newer APIs
- Use primitive types with @AppStorage for better compatibility
- Create wrapper Bindings for type conversion when needed

### 9.2 Actor Isolation in SwiftUI

**Problem**: Modifying @State variables inside Task blocks requires proper actor isolation

**Incorrect Example**:
```swift
Task {
    try await someAsyncOperation()
    isPracticing = true  // ❌ Cannot mutate from non-isolated context
}
```

**Correct Example**:
```swift
Task { @MainActor in
    try await someAsyncOperation()
    isPracticing = true  // ✅ Properly isolated to MainActor
}
```

**Alternative Pattern**:
```swift
Task {
    try await someAsyncOperation()
    await MainActor.run {
        isPracticing = true
    }
}
```

## Summary

iOS development requires deep understanding of platform-specific knowledge and Swift language. Particularly:

- Xcode project configuration is complex but powerful when understood
- Leverage Swift's type system and memory management
- Design asynchronous processing carefully
- Consistent architecture improves maintainability
- Always consider iOS version compatibility when using newer APIs

Use these lessons to develop more robust iOS applications.

## 10. SwiftUI Data Model Requirements

### 10.1 Identifiable Protocol Conformance

**Problem**: SwiftUI's `ForEach` and `sheet(item:)` modifiers require data models to conform to `Identifiable`

**Error Message**:
```
Referencing initializer 'init(_:content:)' on 'ForEach' requires that 'PracticeResult' conform to 'Identifiable'
Instance method 'sheet(item:onDismiss:content:)' requires that 'PracticeResult' conform to 'Identifiable'
```

**Solution**:
```swift
// Add Identifiable to struct/class declaration
struct PracticeResult: Codable, Identifiable {
    let id: UUID  // Must have an 'id' property
    // ... other properties
}
```

**Learnings**:
- SwiftUI uses `Identifiable` to track view updates efficiently
- Even if your model has an `id` property, you must explicitly conform to `Identifiable`
- This is a compile-time requirement, not runtime

### 10.2 Xcode Build Errors - Missing Bundle ID

**Problem**: "Simulator device failed to install the application. Missing bundle ID."

**Root Causes**:
1. Info.plist missing required keys
2. Build settings misconfiguration
3. Xcode cache issues

**Solution Steps**:
1. **Check Info.plist**:
   ```xml
   <key>CFBundleIdentifier</key>
   <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
   <key>CFBundleExecutable</key>
   <string>$(EXECUTABLE_NAME)</string>
   ```

2. **Clean build artifacts**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

3. **Xcode clean build**:
   - Product → Clean Build Folder (⇧⌘K)
   - Restart Xcode
   - Simulator → Device → Erase All Content and Settings...

4. **Verify project settings**:
   - Check PRODUCT_BUNDLE_IDENTIFIER in project.pbxproj
   - Ensure Team is selected in Signing & Capabilities

**Learnings**:
- Xcode cache can cause mysterious build failures
- Info.plist may need explicit bundle ID references even with auto-generation
- Always try clean build when encountering strange errors

### 10.3 Build-Time vs Runtime Issues

**Key Insight**: iOS development has two distinct types of issues:

1. **Build-Time Issues** (caught by compiler):
   - Missing protocol conformance
   - Type mismatches
   - Missing imports

2. **Runtime Issues** (only discovered when running):
   - AVAudioSession conflicts
   - Permission denials
   - File access errors

**Best Practice**: Fix all build-time issues first before debugging runtime issues

## 11. Debugging Philosophy

### 11.1 Confidence in Solutions

**Important**: 場当たり的な修正を避ける
- 時間をかけて原因を分析する
- 自信がある時だけ修正を行う
- わからない時は正直に認める

### 11.2 Error Pattern Recognition

**Common Patterns**:
1. **"requires that X conform to Y"** → Add protocol conformance
2. **"Missing X"** → Check Info.plist or project settings
3. **"Failed to install"** → Clean build and caches
4. **"Cannot find X in scope"** → Check imports and access levels

### 11.3 Systematic Approach

1. **Read the full error message** - Often contains the solution
2. **Check recent changes** - What did you modify last?
3. **Verify assumptions** - Is the API really available?
4. **Clean and rebuild** - Solves many cache-related issues
5. **Document the solution** - Add to this lessons learned file

## 12. Project-Specific Gotchas

### 12.1 Auto-Modified Files

**Observation**: Sometimes Xcode or build tools modify files automatically:
- Info.plist may get CFBundleIdentifier added
- Project files may be reformatted
- Swift files may be auto-formatted

**Best Practice**: 
- Accept these changes if they fix issues
- Use version control to track what changed
- Don't fight the tools - they often know better

### 12.2 The Frustration Factor

**Reality Check**: iOS development can be frustrating because:
- Error messages can be cryptic
- Build system is complex
- Many moving parts (Xcode, Swift, iOS SDK, Simulator)

**Coping Strategy**:
- Take breaks when stuck
- Clean builds solve ~30% of weird issues
- Community (Stack Overflow, Apple Forums) has seen it before
- Document solutions for future reference

この悔しさも、将来の開発の糧になります。

## 13. Memory Management in Closures and Tasks

### 13.1 EXC_BAD_ACCESS with Task Blocks

**Problem**: Memory access violation when using `self` in Task blocks

**Error**: `Thread 1: EXC_BAD_ACCESS (code=1, address=0xbeadddff7868)`

**Incorrect Example**:
```swift
Task { @MainActor in
    self.isRecording = false  // ❌ Can cause EXC_BAD_ACCESS
}
```

**Correct Example**:
```swift
Task { @MainActor [weak self] in
    self?.isRecording = false  // ✅ Safe with weak reference
}
```

**Learnings**:
- Always use `[weak self]` in Task blocks to prevent retain cycles
- This is especially important in classes that might be deallocated
- Timer callbacks and async operations should also use weak references

### 13.2 Memory Management Best Practices

**Common Patterns**:
```swift
// In timers
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    Task { @MainActor [weak self] in
        self?.updateUI()
    }
}

// In completion handlers
audioRecorder.stopRecording { [weak self] result in
    self?.handleResult(result)
}

// In notification observers
NotificationCenter.default.addObserver(
    forName: .someNotification,
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.handleNotification()
}
```

## 14. SwiftUI View Integration Issues

### 14.1 Missing View Actions

**Problem**: Button actions left empty during development

**Symptom**: Buttons appear but don't respond to taps

**Example**:
```swift
// Incorrect - Empty action
Button {
    // 教材選択画面を表示
} label: {
    Text("教材を選択")
}

// Correct - Implement the action
Button {
    showingMaterialPicker = true
} label: {
    Text("教材を選択")
}
```

**Learnings**:
- Always implement button actions, even if temporary
- Use TODO comments if implementation is pending
- Test all interactive elements during development

### 14.2 Sheet Presentation Pattern

**Required Elements**:
1. State variable to control presentation
2. Button action to set state
3. Sheet modifier with the view to present

**Complete Pattern**:
```swift
struct SomeView: View {
    @State private var showingPicker = false
    
    var body: some View {
        VStack {
            Button("Show Picker") {
                showingPicker = true  // 2. Set state
            }
        }
        .sheet(isPresented: $showingPicker) {  // 3. Sheet modifier
            PickerView { selection in
                // Handle selection
            }
        }
    }
}
```

## 15. Feature Implementation Patterns

### 15.1 Audio Transcription Implementation

**Problem**: Placeholder implementations that don't actually work

**Example Issue**:
```swift
// Incorrect - Placeholder only
func transcribeMaterial(_ material: Material) async throws {
    Logger.shared.info("Transcription requested for material: \(material.title)")
}
```

**Correct Implementation**:
```swift
func transcribeMaterial(_ material: Material) async throws {
    // Check if already transcribing
    if material.transcription != nil || material.isTranscribing {
        return
    }
    
    // Update status
    var updatedMaterial = material
    updatedMaterial.isTranscribing = true
    updateMaterial(updatedMaterial)
    
    do {
        // Perform actual transcription
        let speechRecognizer = SpeechRecognizer.shared
        let transcription = try await speechRecognizer.transcribeAudioFile(at: material.url)
        
        // Update with results
        updatedMaterial.transcription = transcription
        updatedMaterial.isTranscribing = false
        updatedMaterial.transcriptionError = nil
        updateMaterial(updatedMaterial)
    } catch {
        // Handle errors properly
        updatedMaterial.isTranscribing = false
        updatedMaterial.transcriptionError = error.localizedDescription
        updateMaterial(updatedMaterial)
        throw error
    }
}
```

**Key Points**:
- Replace TODO comments with actual implementations
- Include proper error handling
- Update UI state at each step
- Use existing services (don't reinvent the wheel)

### 15.2 Service Method Extensions

**Pattern**: When adding new functionality to existing services

```swift
extension SpeechRecognizer {
    /// Convenience method for simple transcription
    func transcribeAudioFile(at url: URL) async throws -> String {
        let options = RecognitionOptions()
        let result = try await recognizeFromFile(url: url, options: options)
        return result.transcription
    }
}
```

**Best Practice**:
- Add convenience methods as extensions
- Reuse existing functionality
- Keep method signatures simple for common use cases

## 16. Debugging Workflow

### 16.1 Visual Debugging with Screenshots

**Effective Process**:
1. User provides screenshot of issue
2. Identify the specific view/component
3. Search for relevant text in codebase
4. Trace back to find the implementation
5. Fix and verify

**Example**:
- Screenshot shows "教材を選択" button not working
- Search for "教材を選択" in codebase
- Find MaterialSelectionView
- Discover empty button action
- Implement missing functionality

### 16.2 Common UI Issues and Solutions

**Issue**: Features appear to work but nothing happens
**Common Causes**:
1. Missing button actions
2. State variables not connected
3. Sheet/alert not presented
4. Async operations not awaited

**Debugging Checklist**:
- [ ] Is the button action implemented?
- [ ] Is the state variable declared?
- [ ] Is the sheet/navigation modifier present?
- [ ] Are async operations properly handled?
- [ ] Is the view model properly initialized?

## Summary of Recent Fixes

1. **Memory Management**: Added `[weak self]` to all Task blocks in AudioRecorder
2. **UI Integration**: Connected MaterialSelectionView button to MaterialPickerView
3. **Feature Implementation**: Implemented actual transcription functionality in MaterialService
4. **Service Extensions**: Added transcribeAudioFile method to SpeechRecognizer

These patterns repeat across iOS development - understanding them saves debugging time.