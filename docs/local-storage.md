# Local Storage and Data Persistence

To protect user privacy and allow the app to function offline, PsyFi relies heavily on local persistence mechanisms.

## Technologies Used

1. **Hive (NoSQL Local Database):** The primary storage engine for all complex, structured emotional and contextual data.
2. **SharedPreferences:** Used for simple key-value flags (e.g., first-time app launch, whether the daily check-in has been completed today).
3. **Flutter Secure Storage:** (If implemented for Supabase Auth token persistence natively).

## Hive Box Structure

PsyFi uses a single primary Hive box named `memory`. 
Inside this box, data is stored under the key `"data"` as a large JSON-like `Map<String, dynamic>`.

The `data` map contains the following primary keys:

### 1. `profile`
- **Type:** `Map<String, dynamic>`
- **Purpose:** Stores the user's overarching emotional profile and onboarding answers.
- **Fields:** `last_emotion`, `tags` (List), `core_issues` (List), `common_triggers` (List), `support_preference`, `coping_style`, `energy_pattern`, `profile_onboarding_complete`.

### 2. `events`
- **Type:** `List<Map<String, dynamic>>`
- **Purpose:** An episodic memory log of the user's interactions.
- **Fields per entry:** `ts` (Timestamp), `type` ("checkin", "chat", "journal"), `t` (Trigger text), `e` (Emotion), `s` (Severity).

### 3. `patterns`
- **Type:** `Map<String, int>`
- **Purpose:** Tracks the frequency of specific emotional triggers.
- **Example:** `{"work stress": 5, "loneliness": 2}`

### 4. `care_state_history`
- **Type:** `List<Map<String, dynamic>>`
- **Purpose:** A historical log of the user's `CareState` snapshots over time.
- **Fields:** `ts` (Timestamp), `state` (e.g., "anxious", "lowMood"), `confidence` (Score).

### 5. `intervention_history`
- **Type:** `List<Map<String, dynamic>>`
- **Purpose:** Logs which behavioral interventions were shown to the user.
- **Fields:** `id` (Intervention ID), `category`, `action` ("completed", "skipped"), `effectiveness_score` (1-5).

### 6. `support_preferences`
- **Type:** `Map<String, dynamic>`
- **Purpose:** Learns what interventions work best. 
- **Fields:** Sub-maps for `successful_interventions`, `helpful_actions`, `ignored_actions`, counting how many times an intervention was helpful or ignored.

### 7. `diary` and `daily`
- **Type:** `List<Map<String, dynamic>>`
- **Purpose:** Stores the generated daily memory diaries.
- **Fields:** `date`, `title`, `emotion`, `summary`, `triggers`.

## MemoryService API

The `MemoryService` (`lib/core/components/memory_service.dart`) acts as the singleton wrapper around Hive. 

- **Initialization:** `getMemory()` ensures the map structure exists, creating empty lists/maps if they are missing.
- **Mutations:** Functions like `updateMemory`, `saveContextualCheckIn`, and `recordInterventionEvent` mutate the map in memory and then immediately call `_saveMemory(data)` to flush the changes to the disk using `box.put('data', data)`.

## Advantages of this Architecture
- **Speed:** Reading and writing to Hive is virtually instantaneous, allowing the `CareStateEngine` to run synchronously during UI updates without loading spinners.
- **Privacy:** By keeping the `memory` box local, the most sensitive emotional data never touches a cloud database.
