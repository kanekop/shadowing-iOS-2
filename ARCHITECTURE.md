# ShadowingPractice2 Architecture

## Data Model Design

### PracticeSession vs PracticeResult

The application uses two related but distinct models for practice data:

#### PracticeResult
- **Purpose**: Stores the evaluation result of a completed practice session
- **Lifecycle**: Created after speech recognition and text comparison are complete
- **Storage**: Persisted to disk as individual JSON files
- **Key Properties**:
  - `materialId`: Links to the Material used
  - `recognizedText`: What the speech recognizer detected
  - `originalText`: The reference text
  - `wordAnalysis`: Detailed word-by-word comparison
  - `scores`: Various evaluation metrics

#### PracticeSession
- **Purpose**: Originally designed to track the entire practice session lifecycle
- **Current Status**: Not actively used in the current implementation
- **Original Intent**: 
  - Track session from start to completion
  - Store recording metadata before analysis
  - Link to PracticeResult after evaluation

### Current Architecture Decision

The current implementation directly creates `PracticeResult` objects without using `PracticeSession`. This simplified approach works because:

1. **Immediate Processing**: Practice recordings are analyzed immediately after recording stops
2. **No Session State**: No need to track incomplete sessions
3. **Simpler Data Flow**: Direct Material → Recording → PracticeResult pipeline

### Future Considerations

If the following features are needed, `PracticeSession` should be reconsidered:
- Saving incomplete practice sessions
- Resuming interrupted practices
- Tracking multiple attempts before finalizing
- Session-level metadata (e.g., environment conditions, user notes)

### Recommended Action

For now, `PracticeSession` can be considered deprecated. If no future requirements emerge for session tracking, it should be removed to simplify the codebase.

## Data Relationships

```
Material (1) ← → (N) PracticeResult
    ↑                     ↑
    └─── materialId ──────┘
```

Each `PracticeResult` is linked to exactly one `Material` via `materialId`, allowing:
- Filtering practice history by material
- Calculating material-specific statistics
- Tracking progress per material