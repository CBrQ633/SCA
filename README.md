# 🚀 SCA - Smart Call Assistant

**SCA (Smart Call Assistant)** is a high-performance productivity tool designed for sales professionals and call organizers. It streamlines the process of managing call lists, tracking outcomes, and boosting conversion rates through smart integrations.

---

## ✨ Key Features

- 📸 **AI-Powered OCR:** Extract phone numbers directly from images using Google ML Kit.
- 📊 **Excel Integration:** Seamlessly import call lists from `.xlsx` and `.xls` files.
- 💬 **One-Click WhatsApp:** Start chats with customers instantly without saving their numbers.
- 📈 **Performance Insights:** Real-time dashboards with success rate tracking and detailed reports.
- 🔔 **Smart Notifications:** Foreground and background push notifications via Firebase (FCM).
- ☁️ **Cloud Backend:** Powered by **Supabase** for real-time data sync and secure authentication.
- 🎨 **Psychology-Based UI:** Professional theme (Deep Navy & Emerald) optimized for focus and achievement.

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart)
- **Backend:** [Supabase](https://supabase.com) (Database, Auth, Storage)
- **Push Notifications:** [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- **Local Storage:** Shared Preferences
- **Navigation:** GoRouter
- **State Management:** Provider
- **Charts:** FL Chart
- **OCR:** Google ML Kit Text Recognition

---

## 🎨 Design Philosophy

The application uses a custom-built theme designed based on **Color Psychology**:
- **Deep Navy:** For professional trust and deep focus.
- **Emerald Green:** For a sense of achievement and growth.
- **Soft UI:** Rounded corners and subtle shadows to reduce eye strain during long working hours.

---

## 🚀 Getting Started

1. **Clone the Repo:**
   ```bash
   git clone https://github.com/your-username/SCA.git
   ```
2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure Supabase & Firebase:**
   - Add your `google-services.json` and `GoogleService-Info.plist`.
   - Setup Supabase keys in `lib/core/config/supabase_config.dart`.
4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📄 License
This project is for internal use. All rights reserved.

---
Developed with ❤️ to empower sales teams.
