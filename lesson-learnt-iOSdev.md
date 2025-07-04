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

### 3.2 ObservableObject Integration

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