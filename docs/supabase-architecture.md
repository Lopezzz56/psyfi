# Supabase Architecture

While PsyFi's emotional intelligence engine runs entirely locally on the device, the application utilizes Supabase as its cloud backend to handle user identity and facilitate real-time human connection (professional support and community features).

## Supabase Services Utilized

1. **Supabase Auth:** Handles user registration, login, session management, and secure token refresh.
2. **Supabase PostgreSQL:** Stores relational data that must be shared across clients (e.g., user roles, encrypted chat messages).
3. **Supabase Realtime:** Powers the live chat experience between users and professionals.

## Database Schema Overview

The core PostgreSQL database is structured to support basic identity and messaging without storing any sensitive emotional data.

### `profiles` Table
Stores basic metadata about an authenticated user.
- `id` (UUID, Primary Key, References `auth.users`)
- `role` (Text): Typically `user` or `professional`. Used by `GlobalState` to determine which UI to render (e.g., standard app vs. professional dashboard).
- `created_at` (Timestamp)
- `last_active` (Timestamp)

### `messages` Table
Stores the encrypted payload of human-to-human chat interactions.
- `id` (UUID, Primary Key)
- `sender_id` (UUID, References `profiles.id`)
- `receiver_id` (UUID, References `profiles.id`)
- `message` (Text): The AES-encrypted ciphertext of the message.
- `created_at` (Timestamp)
- `is_typing` (Boolean): Used by the Realtime engine to broadcast typing indicators.
- `seen` (Boolean): Read receipt flag.

## Authentication Flow

1. **Initialization:** On launch, `main.dart` initializes the Supabase client.
2. **Routing:** `GoRouter` uses `GlobalState` to check the current session. If `supabase.auth.currentSession` is null, the user is forced to the `/auth` screen.
3. **Login:** The user logs in via email/password.
4. **Role Fetching:** Upon successful auth, `GlobalState` queries the `profiles` table to fetch the user's `role`. If the user is a `professional`, they are routed to the `psyfi-admin-dashboard` or a specialized view. If `user`, they proceed to the daily check-in or home screen.

## Realtime Chat Flow

The human support chat relies heavily on Supabase Realtime to deliver a seamless experience.

1. **Connection:** When a user opens a chat with a professional, the `ChatDetailController` subscribes to a specific channel: `supabase.channel('chat-$currentUserId-$peerId')`.
2. **Sending:** `sendMessage` writes a new row to the `messages` table via standard PostgREST HTTP insert.
3. **Receiving:** The Realtime subscription listens for `PostgresChangeEvent.insert` on the `messages` table. When a new row arrives, the controller checks if the sender/receiver IDs match the current session, decrypts the `message` field, and updates the UI instantly.
4. **Typing Indicators:** A user typing updates the `is_typing` flag on a temporary row or broadcast event, which the peer receives and uses to render a typing indicator for 2 seconds.

## Row Level Security (RLS) Policies

To secure the database, Supabase RLS is configured so that:
- Users can only read rows in the `profiles` table that are necessary for their operations (e.g., their own profile, or the profile of a professional they are matched with).
- Users can only `SELECT` and `INSERT` rows in the `messages` table where their `user_id` matches either the `sender_id` or `receiver_id`. This guarantees that even if the API endpoint is discovered, a user cannot query messages belonging to other people.
