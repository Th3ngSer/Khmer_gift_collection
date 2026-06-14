# Khmer Gift Collection - Project Summary 🇰🇭✨

This document provides a comprehensive overview of the project's current state, architecture, and implemented features to help you understand the codebase and answer academic questions.

## 🌟 Project Overview
**Khmer Gift Collection** is a premium lifestyle and e-commerce mobile application designed to showcase and preserve traditional Khmer artisan crafts. The app connects users with local makers through immersive storytelling and a modern, "Airy" user experience.

---

## 🛠 Tech Stack & Libraries
The project uses modern Flutter development standards:

| Category | Technology | Purpose |
|----------|------------|---------|
| **Backend** | **Supabase (PostgreSQL)** | Handles Authentication, Database (Real-time), and BaaS functionality. |
| **State Management** | **Flutter Riverpod (Modern Notifiers)** | Manages app state (Theme, Locale, Chat, etc.) in a type-safe, reactive way. |
| **Navigation** | **GoRouter** | Declarative routing system with support for sub-routes and deep linking. |
| **Internationalization** | **Custom Dictionary** | Localized strings for **English, Khmer, and Chinese**. |
| **Video Playback** | **video_player** | Powers the immersive Workshop Reels (live artisan views). |
| **UI Enhancements** | **shimmer** | Provides elegant "skeleton" loading states for a premium feel. |

---

## 📂 Architecture (Clean Feature-Based)
The project follows a **Feature-Based Folder Structure**, making it scalable and easy to maintain:

-   `lib/core/`: Centralized logic (Themes, App Router, Global Providers, Translations).
-   `lib/data/`: Data layer (Models, Repositories for Supabase and Mock data).
-   `lib/features/`: Modular components separated by business logic:
    -   `home/`: Feed, Collections, and Workshop Reels.
    -   `profile/`: User settings, Stats, Language/Theme pickers, and Promotions.
    -   `chat_reviews/`: Message list, Real-time chat, and Product reviews.
    -   `product/`: Detail screens and discovery logic.

---

## 🚀 Key Features Implemented

### 1. Advanced Profile & Customization
-   **Dynamic Themes**: Support for **Light Mode** and a custom **Khmer Dark Mode** (Deep Earthy Brown aesthetic).
-   **Multi-Language**: Instant switching between **English (🇺🇸), Khmer (🇰🇭), and Chinese (🇨🇳)**.
-   **Notification Management**: Ability to mute/unmute messages with a premium UI toggle.
-   **Security**: Professional "Beauty" Sign Out flow with a custom confirmation dialog.
-   **UX Redirects**: Smart logic that guides users to the Home page if they have no active orders.

### 2. Immersive Chat System
-   **Modern UI**: High-end bubble design with color coding (Gold for user, Card-brown for artisan).
-   **Functional Search**: Real-time filtering in the chat list to find artisans or specific messages.
-   **Mock Interaction**: In-memory message storage with **Auto-Reply logic** for realistic testing.
-   **Scalable Core**: Ready to be switched to full Supabase Realtime changes.

### 3. Verified Reviews & Social Proof
-   **Verified Badge**: Visual indicator (Blue checkmark) for reviews linked to actual purchases.
-   **Interactive Writing**: Animated star rating system and smooth submission flow.
-   **Photo Support**: Ability to display product photos within customer reviews.
-   **User Control**: Logic for users to **Delete** their own reviews with confirmation.

### 4. Workshop Reels (The "Wow" Factor)
-   **Storytelling**: Vertical scrolling video experience (TikTok-style) showing artisans at work.
-   **Integration**: Seamless entry point from the Home screen with a glowing "Workshop Live" banner.

---

## 🎓 Potential Teacher Questions & Answers

**Q: Why use Riverpod Notifier instead of StateProvider?**
*A: Notifier is the modern standard for Riverpod. It allows for more complex logic inside the state management class and is better for future-proofing the app.*

**Q: How do you handle multi-language without external packages?**
*A: We use a centralized `Translations` class with a Map structure. A `localeProvider` watches the current language code, and a helper function `t(key)` fetches the correct string based on that state.*

**Q: Why use PostgreSQL (Supabase) for Chat?**
*A: PostgreSQL is robust and allows for complex relations (like linking a review to a product). Supabase adds a Realtime layer on top of Postgres, allowing us to build chat features without writing a custom socket server.*

**Q: What makes the UI "Premium Khmer"?**
*A: We use a specific color palette (Gold `#D4AF37`, Deep Earth `#2A1508`) combined with high-end serif typography and "Airy" spacing (32px+ corner radiuses) to reflect a luxury cultural brand.*

---
*Summary generated on: ${DateTime.now().toLocal()}*
