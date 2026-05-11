# PsyFi — Emotionally Adaptive Mental Wellness Companion

<p align="center">
  <img src="assets/images/psyfyimg.png" alt="PsyFi Logo" width="120"/>
</p>

<p align="center">
  <strong>
    A privacy-focused emotional wellness companion designed to support reflection,
    emotional awareness, journaling, grounding, and personalized self-care.
  </strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Hive-Local%20Storage-F6AE2D" alt="Hive"/>
</p>

---

# PsyFi

PsyFi is an evolving mental wellness application focused on emotionally adaptive support rather than generic wellness interactions.

The goal is simple:

> create a digital space that feels reflective, emotionally aware, calm, and personal.

Instead of treating users like data points or conversations like disposable chat history, PsyFi attempts to understand emotional patterns over time while prioritizing privacy and long-term emotional awareness.

The app combines journaling, grounding, calming exercises, adaptive AI support, emotional memory systems, and reflective insights into one evolving experience.

---

# Why PsyFi Exists

Most wellness apps today feel:
- repetitive
- generic
- overly clinical
- emotionally disconnected
- engagement-driven rather than reflection-driven

PsyFi is being designed differently.

The experience adapts gradually through:
- emotional check-ins
- journaling
- conversational interactions
- recurring emotional patterns
- coping preferences
- daily reflections

The vision is not to replace professionals or therapy.

The vision is to help users:
- understand themselves better
- regulate emotions
- reflect consistently
- identify patterns
- build healthier habits
- feel emotionally supported

---

# Core Experience

## Emotional Check-ins

Users begin by selecting how they feel:
- anxious
- overwhelmed
- low
- neutral
- good

The app adapts recommendations and support flows based on the user's current emotional state.

Examples:
- anxiety → grounding + breathing
- overwhelm → calming flows + simplified support
- low mood → journaling + behavioral prompts
- good mood → reflection + consistency encouragement

---

## AI Chat Companion

PsyFi includes a conversational AI companion focused on:
- reflective support
- emotional organization
- contextual conversations
- journaling assistance
- gentle follow-up questions

The AI gradually adapts to:
- writing tone
- recurring themes
- emotional patterns
- support preferences

The goal is to create interactions that feel:
- calm
- contextual
- emotionally intelligent
- non-judgmental

rather than robotic or overly motivational.

---

## Memory Diary

PsyFi includes a long-term reflective system called the **Memory Diary**.

The Memory Diary transforms:
- journal entries
- emotional check-ins
- grounding reflections
- conversational moments

into structured daily reflections over time.

This creates:
- emotional timelines
- pattern awareness
- recurring trigger identification
- progress tracking
- long-term emotional context

The intention is to help users understand:
> not just how they feel now, but how patterns evolve over time.

---

## Journaling

The journaling system allows users to:
- freely express thoughts
- document emotions
- reflect on difficult moments
- track emotional progress
- revisit previous entries

PsyFi focuses heavily on making journaling feel:
- safe
- calming
- personal
- low-pressure

rather than structured like productivity software.

---

## Grounding & Regulation Tools

The app currently includes:
- guided grounding exercises
- breathing exercises
- calming audio experiences
- reflective prompts
- emotional support suggestions

These tools are dynamically surfaced based on emotional context and recent patterns.

---

## Emotionally Adaptive Homepage

The homepage changes based on:
- emotional state
- recent activity
- patterns
- memory signals
- wellness consistency

Users may see:
- grounding prompts
- calming suggestions
- reflective questions
- poetry or excerpts
- motivation
- journaling reminders
- breathing recommendations

The system is intentionally designed to feel subtle rather than overwhelming.

---

# Privacy First

Privacy is a core part of PsyFi’s direction.

PsyFi is being designed around:
- minimal unnecessary cloud dependency
- local-first emotional understanding
- user-controlled reflection
- respectful personalization

The focus is on building emotionally intelligent experiences without making users feel surveilled.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Flutter App (Client)                        │
│                                                                     │
│  ┌──────────────┐  ┌───────────────────┐  ┌─────────────────────┐  │
│  │  UI Layer    │  │  Service Layer     │  │  Memory Layer       │  │
│  │  (Screens,   │  │  (MemoryService,   │  │  (Hive Box: data)   │  │
│  │   Widgets)   │  │   SuggestionEngine,│  │  - profile          │  │
│  │              │  │   PromotionEngine) │  │  - events           │  │
│  └──────┬───────┘  └────────┬──────────┘  │  - journal          │  │
│         │                   │             │  - diary            │  │
│         │         ┌─────────▼──────────┐  │  - patterns        │  │
│         │         │  GoRouter (Shell)   │  └─────────────────────┘  │
│         │         │  ShellRoute +       │                           │
│         │         │  MainScreen         │                           │
│         │         └────────────────────┘                           │
└─────────┼────────────────────────────────────────────────────────── ┘
          │
     ┌────┴────────────────────────────────────────┐
     │              External Services              │
     │                                             │
     │  ┌─────────────┐      ┌──────────────────┐  │
     │  │  Supabase   │      │  Mistral FastAPI  │  │
     │  │  (Auth,     │      │  (WebSocket AI   │  │
     │  │  Promotions,│      │   Chat Backend)  │  │
     │  │  Community) │      │                  │  │
     │  └─────────────┘      └──────────────────┘  │
     └─────────────────────────────────────────────┘
```

### State & Navigation

- **State Management** — `Provider` is used for global user state (`GlobalState`). Screen-local state is managed with `StatefulWidget`.
- **Navigation** — `GoRouter` with a `ShellRoute` wrapping all authenticated screens inside `MainScreen` (which hosts the bottom navigation bar as a `Positioned` overlay).
- **Auth Guard** — A `redirect` in the router redirects unauthenticated users to `/login` and authenticated users away from `/login`.

---

## Technical Stack

| Layer | Technology |
|---|---|
| Mobile Framework | Flutter 3.x / Dart 3.x |
| UI State | StatefulWidget + Provider |
| Navigation | GoRouter (ShellRoute) |
| Local Storage | Hive |
| Cloud Backend | Supabase (Auth, Database, Realtime) |
| AI Backend | Mistral via FastAPI (locally hosted) |
| HTTP | `http` package |
| WebSocket | Dart `web_socket_channel` |
| Fonts | Google Fonts (Inter / Actor) |

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0
- Android SDK ≥ 36 (compileSdk)
- Kotlin Gradle Plugin ≥ 2.1.0
- A running Supabase project
- A locally running Mistral inference server (see `/mistral-api/`)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Lopezzz56/psyfi
cd psyfi/psy_fi

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure environment (see below)

# 4. Run the app
flutter run
```

### Running the AI Backend

```bash
cd mistral-api/app
uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## Environment Configuration

The app connects to Supabase and the AI backend. Update the following values before running:

**`lib/main.dart`** — Supabase credentials:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

**`lib/core/components/memory_service.dart`** — AI backend URL:
```dart
Uri.parse("http://YOUR_LOCAL_IP:8000/chat")
```

> **Note:** Replace `192.168.1.x` with your development machine's local IP address when testing on a physical device.

---

## Project Structure

```
lib/
├── aichat/                    # AI chat interface (WebSocket streaming)
├── auth/                      # Login & signup screens
├── bottomnav/                 # MainScreen shell with bottom navigation
├── breathing/                 # Breathing exercise screens
├── calming_audio/             # Calming audio info & player screens
├── chat/                      # Community peer chat screens
├── Community/                 # Community feed
├── core/
│   ├── components/
│   │   ├── memory_service.dart    # Central memory & inference engine
│   │   ├── custom_button.dart
│   │   └── ...
│   ├── routes/routes.dart         # GoRouter configuration
│   └── theme/                     # Colours, spacing, typography tokens
├── features/
│   └── dashboard/                 # Insights dashboard screen
├── grounding/                 # Grounding form, info, feedback screens
├── home/
│   ├── controllers/           # HomeController (promotions)
│   ├── models/                # Promotion, GuidanceSuggestion models
│   ├── screens/
│   │   ├── home_screen.dart       # Main home screen
│   │   ├── daily_checkin_screen.dart
│   │   ├── memory_debug_screen.dart
│   │   └── promotion_debug_screen.dart
│   ├── services/
│   │   └── suggestion_engine.dart # Contextual suggestion logic
│   └── widgets/
│       └── promotion_renderer.dart # Promotion card/banner/full-screen widgets
├── journal/                   # Journal list & add/edit screens
├── Motivations/               # Motivation feed & post cards
└── profile/                   # User profile screen
```
---

# Current Features

- Emotional onboarding
- Daily emotional check-ins
- AI-assisted chat
- Journaling system
- Memory Diary
- Grounding exercises
- Breathing exercises
- Calming audio
- Emotion-aware suggestions
- Promotions & wellness cards
- Feedback collection system
- Insights dashboard
- Emotional trend tracking
- Pattern recognition
- Context-aware recommendations

---

# Prototype Status

PsyFi is currently in active prototyping and experimentation.

The project is evolving rapidly with:
- UX refinements
- emotional intelligence improvements
- personalization systems
- adaptive support mechanisms
- wellness analytics
- reflection systems

New ideas and improvements are continuously being tested and iterated.

The current focus is:
- emotional UX
- personalization
- memory systems
- adaptive interventions
- privacy-focused intelligence
- meaningful long-term support

---

# Planned Direction

Upcoming systems being explored include:
- adaptive behavioral activation
- improved emotional analytics
- deeper reflection systems
- smarter intervention routing
- emotionally adaptive AI behavior
- memory-aware support systems
- long-term wellness pattern visualization
- privacy-preserving intelligence systems

---

## Licence

This project is proprietary. All rights reserved.

---

<p align="center">
  Built with care for mental wellness · PsyFi © 2025
</p>