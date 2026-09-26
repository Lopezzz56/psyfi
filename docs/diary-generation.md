# Diary Generation System

PsyFi's Diary Generation System transforms transient interactions (check-ins, journaling, chat) into a structured daily reflection. This helps users track emotional progress and recognize patterns over time.

## Implementation Details

- **Relevant File:** `lib/core/components/memory_service.dart`
- **Method:** `generateMemoryDiary(String date)`
- **Data Stores:** Hive `daily` and `diary` lists.

## Triggers and Tracing

The diary is generally generated lazily. `triggerMemoryDiaryGeneration()` checks if the diary for *yesterday* has been generated yet. If not, it executes the generation process.

### Input Data Sources
The system aggregates all events that occurred on the target date:
1. **Journal Entries:** Raw user journal texts.
2. **Chat Messages:** Up to 8 of the user's most recent chat messages from that day (ignoring the AI's responses).
3. **Episodic Events:** Memory events logged from check-ins and other interactions.
4. **Interventions:** Records of completed activities (e.g., grounding, breathing).

## Data Flow

```mermaid
flowchart TD
    subgraph Data Sources [For Target Date]
        J[Journal Entries]
        C[User Chat Messages]
        E[Check-in Events]
        I[Completed Interventions]
    end
    
    Data Sources --> Agg[MemoryService Aggregation]
    
    Agg --> Stats[Calculate Dominant Emotion, Severity, Triggers]
    Agg --> Compile[Compile All Text Inputs]
    
    Stats --> Gen[Compose Summary]
    Compile --> Gen
    I --> Gen[Inject Recovery Behaviors]
    
    Gen --> Entry[Create Structured Diary Entry]
    Entry --> Hive[(Hive 'diary' collection)]
```

## Generation Logic

While the `mistral-api` backend contains prompts for diary summarization (`DIARY_SYSTEM_PROMPT`), **the current primary implementation in the Flutter application relies on local heuristic generation**. 

The `_composeDiarySummary` method deterministicly creates a diary paragraph based on:
1. The dominant `emotion` of the day.
2. The `CareState` (e.g., Burnout, Isolated).
3. The top two `triggers`.
4. The list of `completedInterventions`.

### Examples of Deterministic Generation
- If the `CareState` is `burnout`, it outputs: *"Today seemed to ask for lower pressure. [Trigger] was present, and pacing mattered more than pushing."*
- If interventions were completed, it appends: *"I also noticed [Intervention] as small recovery behaviors."*
- If the user wrote very short journal entries, it may inject the exact journal text into the summary.

## Storage and Lifecycle

- The generated structured entry is saved in the Hive `diary` array.
- A duplicate is saved in the `daily` array (used as a fallback or broader timeline feature).
- The system prevents regenerating the same date twice unless manually cleared.
- This local generation approach ensures that highly sensitive daily reflections are constructed and stored entirely on the device without necessarily broadcasting a full day's history to an external LLM.

## Implementation Notes & Gaps
- **Partially Implemented AI Integration:** The backend Python code defines an AI summarization pipeline (`DIARY_RESPONSE_SCHEMA`), but the client code (`_composeDiarySummary`) executes a rule-based string template approach instead of calling the API. Therefore, AI-based diary generation is planned/documented but its connection is not fully realized in the current repository execution path.
