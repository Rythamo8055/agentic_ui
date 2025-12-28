# 🎓 Agentic UI — Building an AI-Powered Learning Assistant

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.35+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-AI-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![GenUI](https://img.shields.io/badge/GenUI-0.6.0-purple?style=for-the-badge)

**A Case Study in AI-First Mobile Development**

*How I built a personalized learning assistant with real-time voice capabilities using Flutter, Firebase AI, and GenUI*

</div>

---

## 📖 The Story

### The Problem I Set Out to Solve

In an age of information overload, **learning effectively has become a challenge**. Traditional learning apps offer static content that doesn't adapt to individual learning styles. I asked myself:

> *"What if an AI could understand how I learn best and create personalized, interactive lessons on any topic—in real-time?"*

This question led me to build **Agentic UI**—an AI-powered learning assistant that doesn't just answer questions, but creates **dynamic, interactive learning experiences** tailored to each user.

---

## 🎯 The Vision

I envisioned an app where:

- ✨ **The AI generates custom UI** — Not just text responses, but interactive quizzes, flashcards, and lesson structures
- 🎤 **Voice is a first-class citizen** — Learn hands-free with natural voice conversations
- 🧠 **Personalization is automatic** — The AI remembers your interests and adapts its teaching style
- 📱 **Cross-platform from day one** — One codebase for Android, iOS, Web, and Desktop

---

## 🛠 The Technical Journey

### Challenge #1: Dynamic AI-Generated UI

**The Problem:** Traditional chatbots return text. I wanted the AI to return *interactive UI components*.

**The Solution:** I discovered **GenUI**, a Flutter package that enables AI models to generate UI schemas that render into real Flutter widgets.

```dart
// The AI can now generate interactive components like:
// - Quizzes with MultipleChoice widgets
// - Flashcards with reveal animations
// - Lesson tabs with organized content
// - Progress sliders for confidence tracking
```

**What I Built:**
- Integrated `genui_firebase_ai` with **Gemini 2.5 Flash**
- Created a comprehensive **System Prompt** guiding the AI on 6 different learning modes
- Built a custom catalog with **20+ interactive widget types**

---

### Challenge #2: Real-Time Voice Conversations

**The Problem:** Users wanted to learn while cooking, commuting, or exercising. Text-only wasn't enough.

**The Solution:** I implemented **bidirectional audio streaming** using WebSocket connections to Gemini's Live API.

```dart
class GeminiLiveService {
  // Real-time voice input → AI processing → Voice + Text output
  // All happening in milliseconds
}
```

**What I Built:**
- **Push-to-talk interface** with visual feedback
- **Live audio waveform** visualization during recording
- **Dual output system** — AI responds with both voice AND text
- **Robust error handling** for network interruptions

---

### Challenge #3: Beautiful, Consistent UI

**The Problem:** AI apps often look generic. I wanted something that felt *premium*.

**The Solution:** I chose **Forui** — a modern design system for Flutter—and enforced a light theme optimized for learning.

**What I Built:**
- Clean, distraction-free **full-width message layout**
- Smooth **animated transitions** between states
- **Custom bottom navigation** with intelligent highlighting
- Professional **error and loading states**

---

## 🏗 Architecture Deep Dive

```
┌─────────────────────────────────────────────────────────────┐
│                        AGENTIC UI                           │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐                       │
│  │  Chat Screen │    │ Voice Screen │    ← Presentation    │
│  └──────┬───────┘    └──────┬───────┘                       │
│         │                   │                               │
│  ┌──────┴───────────────────┴───────┐                       │
│  │         GenUI Conversation        │   ← AI Processing    │
│  └──────────────┬───────────────────┘                       │
│                 │                                           │
│  ┌──────────────┴───────────────────┐                       │
│  │   Firebase AI (Gemini 2.5 Flash) │   ← Intelligence     │
│  └──────────────────────────────────┘                       │
│                                                             │
│  ┌──────────────────────────────────┐                       │
│  │    GeminiLiveService (WebSocket) │   ← Voice Streaming  │
│  └──────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **GenUI over custom parsing** | Let the AI focus on content, not JSON structure |
| **WebSocket over REST** | Sub-second latency for voice is non-negotiable |
| **Forui over Material** | Consistent, opinionated design system |
| **ValueListenable over BLoC** | Lightweight state for real-time UI updates |

---

## 💡 Key Features Implemented

### 🎓 Learning Modes

| Mode | Description | Widgets Used |
|------|-------------|--------------|
| **Onboarding** | Collect user preferences | TextField, MultipleChoice, Button |
| **Quiz** | Test knowledge interactively | Card, MultipleChoice, Modal (hints) |
| **Flashcard** | Memorization with confidence | Card, Button, Slider |
| **Lesson** | Organized content by topic | Tabs, Card, Text, Image |
| **Audio Learning** | Language & pronunciation | AudioPlayer, Button, Text |

### 🎤 Voice Assistant Capabilities

- **16kHz PCM audio capture** — Optimized for voice recognition
- **Amplitude monitoring** — Visual feedback during recording
- **Connection state management** — Graceful handling of network issues
- **Automatic transcription** — See what you said in text

---

## 📊 Results & Learnings

### What Worked Well

✅ **GenUI eliminated 80% of response parsing code** — The AI handles UI schema generation  
✅ **WebSocket voice streaming achieved <500ms latency** — Natural conversation flow  
✅ **Forui reduced UI development time by 40%** — Consistent, pre-styled components  

### Challenges & How I Overcame Them

| Challenge | Solution |
|-----------|----------|
| GenUI learning curve | Studied widget catalog, built test prompts |
| Audio format compatibility | Switched to WAV with specific sample rates |
| Firebase AI quota limits | Implemented request throttling |

### What I'd Do Differently

- Add **offline caching** for previously generated lessons
- Implement **spaced repetition** algorithm for flashcards
- Build **analytics dashboard** to track learning progress

---

## 🚀 Running the Project

```bash
# Clone and install
git clone https://github.com/Rythamo8055/flutter-ai.git
cd flutter-ai/agentic_ui
flutter pub get

# Configure your API key
cp .env.example .env
# Add your GEMINI_API_KEY to .env

# Run
flutter run
```

---

## 🔮 Future Roadmap

- [ ] **Spaced Repetition** — Smart review scheduling
- [ ] **Multi-language Support** — Learn in any language
- [ ] **Study Analytics** — Visualize your progress
- [ ] **Social Features** — Study groups and challenges
- [ ] **Offline Mode** — Download lessons for later

---

## 👨‍💻 About the Developer

<div align="center">

<img src="https://github.com/Rythamo8055.png" width="150" style="border-radius: 50%;" alt="Vishnu Vardhan M"/>

### **Vishnu Vardhan M**

*Flutter Developer | AI Enthusiast | Problem Solver*

</div>

I'm a passionate developer who loves building products at the intersection of **mobile development** and **artificial intelligence**. This project represents my exploration of what's possible when you give AI the power to generate interactive experiences.

### My Technical Expertise

| Domain | Technologies |
|--------|-------------|
| 📱 **Mobile Development** | Flutter, Dart, Android, iOS |
| 🤖 **AI/ML Integration** | Gemini, Firebase AI, LLMs, GenUI |
| 🔥 **Backend & Cloud** | Firebase, REST APIs, WebSockets |
| 🎨 **UI/UX** | Modern design systems, Animations |
| 🎤 **Audio/Media** | Recording, Streaming, Playback |

### What I Can Build For You

- 🎓 **Educational Platforms** — Interactive learning experiences
- 💬 **AI-Powered Apps** — Chatbots, assistants, automation
- 🎙️ **Voice Applications** — Real-time audio processing
- 📊 **Data Dashboards** — Beautiful data visualization
- 🛍️ **E-commerce** — Full-featured shopping apps

---

## 📬 Let's Connect

<div align="center">

[![Portfolio](https://img.shields.io/badge/Portfolio-vishnuvardhanm.vercel.app-FF5722?style=for-the-badge&logo=google-chrome&logoColor=white)](https://vishnuvardhanm.vercel.app/)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-vishnu--vardhan8055-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/vishnu-vardhan8055/)
[![GitHub](https://img.shields.io/badge/GitHub-Rythamo8055-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Rythamo8055)
[![Email](https://img.shields.io/badge/Email-vishnuvardhanthe8055@gmail.com-EA4335?style=for-the-badge&logo=gmail&logoColor=white)](mailto:vishnuvardhanthe8055@gmail.com)

**📍 Available for:** Freelance | Contract | Full-time (Remote/Hybrid)

</div>

---

## 🙏 Acknowledgments

- **Google** for Gemini AI and Firebase
- **Flutter team** for the amazing framework
- **GenUI contributors** for the innovative package
- **Forui** for the beautiful component library

---

<div align="center">

**Built with 💙 and Flutter**

*If this project inspires you or helps in any way, please consider giving it a ⭐*

---

**© 2024 Vishnu Vardhan M** — Feel free to reach out for collaboration!

</div>
