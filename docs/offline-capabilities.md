# Offline Capabilities

Because mental health support should be available even in unstable network environments, PsyFi is designed with a strong offline-first approach for its core emotional features. 

## Fully Supported Offline Features

The following features function perfectly without any internet connection because they rely entirely on the local `memory` Hive box and the deterministic rules compiled into the Flutter application:

1. **Emotional Check-ins:** Users can complete their daily check-ins. The app will calculate their `CareState` and save the event to the local episodic memory log.
2. **Behavioral Interventions:** The `InterventionLibrary` is statically compiled into the app. Users can access, view, and complete grounding exercises, breathing guides, and other behavioral activation prompts offline.
3. **Journaling:** The private journal saves directly to local storage and does not require cloud synchronization.
4. **Adaptive UI:** The theme and layout changes driven by the `CareStateEngine` (e.g., switching to a simplified UI when overwhelmed) evaluate locally and remain active offline.

## Partially Supported / Degraded Features

1. **Memory Diary Generation:** The fallback deterministic generation (`_composeDiarySummary`) can construct basic summaries from recent journal entries and check-ins offline. However, any advanced semantic extraction intended for the AI backend will not function.
2. **AI Context Building:** The `MemoryService` continues to aggregate context offline, so that when the network is restored, the next AI chat starts with a fully updated semantic profile.

## Features Requiring Connectivity

1. **AI Chat Experience:** The `mistral-api` must be reachable via WebSocket. If the app is offline, the `AIController` will immediately catch the connection error and display an "AI not available" message, gracefully disabling the chat input until the network returns.
2. **Professional Human Support:** Sending and receiving messages to human professionals requires a connection to the Supabase Realtime service. The `ChatDetailController` actively monitors connectivity using the `connectivity_plus` package. If the device goes offline, sending is disabled. When the device reconnects, the controller automatically calls `fetchMessages()` to retrieve any messages missed while disconnected.
3. **Authentication:** Creating an account or performing a fresh login requires connecting to Supabase Auth. (However, an already authenticated session cached on the device usually allows the user past the initial router guards offline).

## Synchronization Strategy

Currently, PsyFi does not implement an eventual-consistency sync queue for its emotional data, because the emotional data is never intended for the cloud. Therefore, no complex conflict resolution logic is required for offline mutations.
