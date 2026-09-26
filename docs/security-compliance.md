# Security and Compliance

PsyFi handles highly sensitive psychological data, requiring a strict approach to security, encryption, and privacy compliance.

## Architectural Security Decisions

### 1. Data Minimization and Local Storage
The most significant security feature of PsyFi is its local-first architecture. 
- All explicit and inferred emotional data (`care_state_history`, `diary`, `patterns`, `profile`) is stored securely on the user's device using Hive.
- By never transmitting this data to a cloud database (like Supabase), the application drastically reduces the attack surface and mitigates the risk of a mass data breach.

### 2. Transient AI Processing
When the user opts to use the AI features, a subset of their context is sent to the `mistral-api` backend.
- The AI backend is designed to run locally on the device (via Ollama on supported hardware) or on a privately controlled server.
- The `mistral-api` does not persist chat histories to a long-term database. It caches context in a transient SQLite instance strictly for the duration of the active WebSocket session, dropping it when the session closes.

## Cryptography and Data in Transit

### 1. Transport Layer Security (TLS)
All external communications—whether to Supabase Auth, Supabase PostgreSQL, or the remote `mistral-api` server—must occur over HTTPS or WSS (WebSocket Secure), ensuring data is encrypted in transit.

### 2. End-to-End Encryption for Human Support
To facilitate the professional support features, messages must be routed through Supabase. To prevent even the database administrators from reading user messages:
- **AES Encryption:** The `MessageCryptoHelper` (`lib/core/components/encrypt.dart`) encrypts the raw text of chat messages locally on the device before transmission.
- **Ciphertext Storage:** The Supabase `messages` table stores only the resulting ciphertext.
- **Client-Side Decryption:** When the peer receives the payload via the Realtime subscription, the Flutter client decrypts it in memory for rendering.

## Compliance and Safety Guardrails

### 1. The High-Risk Override
The `CareStateEngine` continuously monitors for severe risk flags (e.g., a user indicating self-harm).
- If the calculated state hits `CareState.highRisk`, the engine overrides all other logic.
- The UI immediately changes to present crisis support hotlines and restricts access to standard journaling or chat functions until the user acknowledges the safety prompt.
- The `mistral-api` is strictly prompted *never* to offer clinical advice. If the AI detects a crisis, its output JSON schema explicitly flags `needs_professional_help: true`, which triggers the Flutter client's local high-risk override.

### 2. HIPAA and GDPR Considerations
- **HIPAA:** Because the primary emotional data resides exclusively on the user's device, PsyFi avoids acting as a centralized repository of Electronic Health Records (EHR). The encrypted professional chat feature adds a layer of security, though formal HIPAA compliance would require Business Associate Agreements (BAAs) with hosting providers if deployed commercially.
- **GDPR:** The Right to Erasure (Right to be Forgotten) is trivialized for the core emotional engine: a user simply deletes the app to destroy their Hive data. For the Supabase cloud components, a standard account deletion flow removes their Auth record and cascadingly deletes their encrypted chat history.
