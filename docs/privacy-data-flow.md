# Storage, Data Flow, and Privacy

PsyFi is designed with strict data isolation boundaries to ensure user privacy, particularly because the application handles sensitive emotional and psychological data. 

## The Data Boundary Principle

The core rule of PsyFi's architecture is: **Emotional intelligence stays on the device; only transient relational data touches the cloud.**

```mermaid
flowchart TD
    subgraph Device (Private)
        UI[Flutter UI]
        MemSvc[MemoryService]
        Hive[(Hive Local Storage)]
        Crypto[MessageCryptoHelper]
        
        UI <--> MemSvc
        MemSvc <--> Hive
    end

    subgraph Local AI Backend (Private / Transient)
        FastAPI[mistral-api]
        Ollama[Ollama Local LLM]
        
        UI -- WebSocket Chat --> FastAPI
        FastAPI <--> Ollama
    end
    
    subgraph Supabase Cloud (Public / Relational)
        Auth[Supabase Auth]
        Postgres[(PostgreSQL)]
        
        UI -- Email/Pass --> Auth
        Crypto -- Encrypted Messages --> Postgres
    end
```

## Data Location Breakdown

### 1. What Stays on Device (Hive)
- The user's emotional profile, triggers, and core issues.
- The history of every check-in and emotional state (`CareStateHistory`).
- The user's private memory diaries and journal entries.
- AI Chat logs (stored via `ChatStorage`).
- Behavioral intervention history.
*None of this data is synced to Supabase.*

### 2. What Goes to the AI Backend
- When chatting with the AI, the `MemoryService` constructs a semantic context payload (containing triggers and last known emotion).
- This is sent via WebSocket to the `mistral-api`.
- *Privacy Protection:* The `mistral-api` is designed to run locally (using Ollama) or on a private server. It only holds conversation state in a transient SQLite DB during the active session.

### 3. What Goes to the Cloud (Supabase)
- **Authentication Credentials:** Email and encrypted passwords via Supabase Auth.
- **User Roles:** A basic profile row in PostgreSQL mapping a `user_id` to a `role` (e.g., `user` vs `professional`).
- **Community/Professional Chat:** Real-time messages sent between a user and a human professional.

## Encryption in Transit and at Rest

### Chat Encryption
When a user chats with a human professional, the messages are routed through Supabase. To protect this data:
- **`MessageCryptoHelper`** (`lib/core/components/encrypt.dart`): Implements AES encryption for chat messages.
- Before a message is sent to Supabase via `ChatDetailController.sendMessage`, the raw text is encrypted.
- The PostgreSQL database only stores the encrypted ciphertext.
- When the peer receives the message via the Supabase Realtime subscription, it decrypts the text locally before rendering it in the UI.

### Device Security
- The primary emotional data relies on the mobile operating system's native sandboxing to protect the Hive files (`memory.hive`) from other applications.

## Implications for Features
Because emotional data is entirely local:
1. **No Cross-Device Sync:** A user cannot currently log into a new phone and see their past emotional diaries or `CareState`. They would start fresh.
2. **Account Deletion:** Deleting an account in Supabase removes their login access and human chat history, but the emotional data must be wiped locally by deleting the app or clearing app data.
