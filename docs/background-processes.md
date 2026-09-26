# Timers, Streams, and Background Processes

PsyFi manages real-time updates and asynchronous tasks using Dart's native Streams, Timers, and WebSocket subscriptions.

## Real-time Streams and Subscriptions

| Process | File | Purpose | Trigger | Data Impact |
| --- | --- | --- | --- | --- |
| **Connectivity Listener** | `lib/chat/controllers/chatdetail_controller.dart` | Monitors network changes to auto-retry fetching messages. | Setup in `_initConnectivity()` using `Connectivity().onConnectivityChanged`. | Toggles `isConnected` flag. If reconnected, calls `fetchMessages()`. |
| **Supabase Realtime Chat** | `lib/chat/controllers/chatdetail_controller.dart` | Listens for new messages or typing status from peers. | Setup in `listenToMessages()`. Connects to `supabase.channel('chat-$currentUserId-$peerId')`. | Decrypts and prepends new Postgres `insert` events to the local `messages` list. Updates `isTyping`. |
| **WebSocket AI Chat** | `lib/core/components/ai_service.dart` | Maintains a live duplex connection to the `mistral-api` for fast token streaming. | Instantiated upon entering the AI chat view. | Passes JSON strings or partial tokens to the `AIController` via a `BroadcastStream`. |

## Timers

### Chat Typing Indicator Timeout
- **File:** `lib/chat/controllers/chatdetail_controller.dart`
- **Purpose:** When a real-time event marks `is_typing == true`, the UI shows a typing indicator. To prevent the indicator from getting stuck if the peer drops connection, a `Future.delayed(const Duration(seconds: 2))` automatically resets `isTyping` to `false`.

### Background Memory Summarization
- **File:** `lib/core/components/memory_service.dart`
- **Purpose:** `triggerMemoryDiaryGeneration()` is called dynamically during application usage. It checks if the diary for the previous day has been generated. While not a strict `Timer.periodic`, it acts as a passive background check executed on state changes or app launches to generate missing summaries asynchronously.

## Cancellation and Cleanup

Proper resource management is crucial for mobile performance.
- Subscriptions to Supabase channels (`_channel?.unsubscribe()`) and connectivity streams (`_connectivitySub?.cancel()`) are properly cleaned up in the `dispose()` method of their respective controllers (e.g., `ChatDetailController`).
- The AI WebSocket disconnects natively when the user leaves the chat or the application is paused, managed by the `AppConnectionManager` and `AIService`.
