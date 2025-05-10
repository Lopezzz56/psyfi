![Cover Image](https://github.com/Lopezzz56/psyfi/blob/main/assets/images/cover.png?raw=true)


# 🧠 PSY FI – Empowering Mental Wellness with AI and Community

## 💡 Problem Statement

Many individuals hesitate to seek help for personal, mental, or health issues due to fear of judgment, lack of trust, or discomfort with exposure. This reluctance prevents them from accessing professional support and solutions.

**PSY FI** is a digital platform that bridges the gap between personal struggles and effective care. By leveraging AI-driven and community-based solutions, we empower users to privately and confidently navigate their wellness journeys.

---

## 🧩 Features

### 1. 🌟 Motivational Posts
- Real-time curated motivational posts from a database.
- Designed to uplift users and encourage daily engagement.

### 2. 👨‍⚕️ Professional Support
- Connects users with certified professionals.
- Offers secure, private, and direct communication channels for personalized guidance.

### 3. 🤖 AI Chatbot Assistance
- Built using the **Mistral 7B** model (customized and hosted via **Ollama**).
- Provides initial emotional support, resources, and encouragement while waiting for professional help.
- Requires a local Mistral server to be running.

### 4. 📊 Personalized Dashboard & Motivations
- Tracks user engagement and progress.
- Provides personalized motivational insights to sustain wellness and growth.

---

## 🛠️ Tech Stack

| Component   | Technology Used             |
|------------|-----------------------------|
| Frontend   | Flutter                     |
| Backend    | Supabase (DB, Auth, API)    |
| AI Engine  | Mistral 7B via Ollama       |
| Security   | AES Encryption for messages |

---

## 🔐 Security & Privacy

- All user interactions and messages are end-to-end encrypted.
- User data is stored securely using Supabase’s authentication and row-level security.
- AI conversations are handled locally to ensure privacy (requires self-hosted Mistral).

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Ollama installed locally with `mistral-7b` model
- Supabase project configured

### Running Locally

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-username/psy-fi.git
   cd psy-fi
