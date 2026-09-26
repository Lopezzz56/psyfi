# PsyFi Documentation Index

Welcome to the technical documentation for the PsyFi project. This documentation explains the architecture, structure, systems, and data flows of the repository as it is currently implemented.

This guide is intended for developers who need to understand, navigate, maintain, and extend the PsyFi project.

## Recommended Reading Order

For a comprehensive understanding of the project, we recommend reading the documentation in the following order:

1. **[Project Overview](./project-overview.md)**: A high-level introduction to the purpose, modules, and architecture of the PsyFi repository.
2. **[Repository Structure](./repository-structure.md)**: A navigation guide detailing the directory layout and important files.
3. **[System Architecture](./system-architecture.md)**: An explanation of the complete system architecture and its layers.
4. **[User State Lifecycle](./user-state-lifecycle.md)**: How user state is created, maintained, and persisted.
5. **[Emotional Intelligence System](./emotional-intelligence.md)**: How the application processes emotional information and updates the care state.
6. **[Context, Memory, and Tag System](./context-memory-tags.md)**: The contextual intelligence system and how memories/tags are used.
7. **[AI Chat Architecture](./ai-chat.md)**: The lifecycle of an AI chat message from the UI to the AI service and back.
8. **[Behavioral Activation and Interventions](./behavioral-activation.md)**: How the intervention system recommends and tracks activities.
9. **[Diary Generation System](./diary-generation.md)**: How diary entries are generated, including inputs and triggers.
10. **[Storage, Data Flow, and Privacy](./data-flow-and-privacy.md)**: How information moves across the system and where it is stored.
11. **[Supabase Architecture](./supabase-architecture.md)**: The Supabase integration, tables, and real-time features.
12. **[Professional Support and Realtime Chat](./professional-support.md)**: The implementation of the professional support module.
13. **[Analytics and Feedback System](./analytics-and-feedback.md)**: How analytics and feedback are collected and consumed.
14. **[Background Processes](./background-processes.md)**: Active background processes, timers, and streams in the application.
15. **[Local Storage](./local-storage.md)**: Details on local persistence mechanisms (e.g., Hive).
16. **[Emotional Check-in System](./emotional-checkin.md)**: The implementation of the emotional check-in flow and its downstream effects.
17. **[Services and Integrations](./services-and-integrations.md)**: An inventory of external services and integrations.
18. **[End-to-End Flows](./end-to-end-flows.md)**: End-to-end technical flows for major user actions.
19. **[Implementation Notes](./implementation-notes.md)**: A factual overview of the current implementation status (implemented vs. planned).
20. **[Code Reference Guide](./code-reference.md)**: A practical reference for navigating the codebase by feature.

---

> [!NOTE]
> This documentation is purely descriptive of the *existing implementation*. It does not cover planned features or ideal architecture unless explicitly stated as "Planned" or "Partially Implemented."
