# Repository Structure

The PsyFi repository is divided into three primary modules: the Flutter mobile application (`psy_fi`), the Next.js admin dashboard (`psyfi-admin-dashboard`), and the Python AI backend (`mistral-api`).

Below is the structured overview of the existing directories and important files as they exist in the repository.

## 1. `psy_fi/` (Flutter Mobile Application)

This directory contains the main user-facing application built with Flutter.

| Directory / File | Purpose |
| --- | --- |
| `lib/` | Contains the entire Dart source code for the mobile application. |
| `lib/main.dart` | Application entry point. Initializes Supabase, Hive, and starts the root widget. |
| `lib/aichat/` | Screens and controllers for the WebSocket-based AI chat companion. |
| `lib/auth/` | Authentication flow screens (login, signup, OTP). |
| `lib/bottomnav/` | Hosts the `MainScreen` shell that implements bottom navigation wrapping `GoRouter`. |
| `lib/breathing/` | Implementation of guided breathing exercises. |
| `lib/calming_audio/` | Calming audio player and informational screens. |
| `lib/chat/` | Interfaces for professional and community peer chat (Supabase Realtime). |
| `lib/Community/` | Community feed and post card widgets. |
| `lib/core/` | Global components, theming, routing, services, and the adaptive care state engine. |
| `lib/features/dashboard/` | Screens and widgets for the insights and emotional trend tracking dashboard. |
| `lib/grounding/` | Implementation of grounding exercises, forms, and feedback mechanisms. |
| `lib/home/` | Main emotionally adaptive home screen, check-ins, and contextual suggestion widgets. |
| `lib/journal/` | Memory timeline and journaling interface for reflective entries. |
| `lib/Motivations/` | Motivation feed containing uplifting posts. |
| `lib/profile/` | User profile management and settings. |

### Important Core Files

| File | Purpose | Important Components |
| --- | --- | --- |
| `lib/core/components/memory_service.dart` | Central memory & inference communication | Triggers AI backend for memory summarization and context. |
| `lib/core/adaptive/care_state_engine.dart` | Adaptive routing and logic | Calculates the current care state based on emotional inputs. |
| `lib/core/routes/routes.dart` | Global navigation structure | Configures `GoRouter` paths and auth guards. |
| `lib/core/components/global_state.dart` | Application-wide state | Stores top-level user data, preferences, and transient session context. |

---

## 2. `mistral-api/` (AI Backend)

This directory contains the FastAPI backend that interfaces with the local Ollama mistral model.

| Directory / File | Purpose |
| --- | --- |
| `app/` | Main application folder containing the Python service. |
| `app/main.py` | FastAPI application entry point. Contains WebSocket endpoints for `/chat` and REST endpoints for inference and diary generation. |
| `app/psyfi_local.db` | Local SQLite database acting as a transient context cache and local memory store for AI sessions. |
| `requirements.txt` | Python dependencies (FastAPI, uvicorn, httpx, etc.). |

---

## 3. `psyfi-admin-dashboard/` (Next.js Dashboard)

This directory contains the analytics and administrative interface for monitoring system health and aggregated anonymized wellness data.

| Directory / File | Purpose |
| --- | --- |
| `app/` | Next.js App Router directory containing pages and layouts. |
| `package.json` | Project configuration and Node.js dependencies (Next.js, Supabase JS, Recharts, TailwindCSS). |
| `tailwind.config.ts` | Tailwind CSS theme tokens and layout settings. |
| `next.config.mjs` | Next.js build configuration. |

---

## 4. Repository Root Files

| File | Purpose |
| --- | --- |
| `README.md` | The core project explanation, vision, and setup instructions. |
| `.gitignore` | Defines standard exclusions for Git version control. |
