# Calorie Tracker

An offline-first personal Android calorie deficit, weight, nutrition, and fitness tracking application built with Flutter. Designed with a modern Glassmorphism UI, Discord-inspired gradient themes, and 100% local on-device storage.

## Key Features

- **Scientific Calorie & Macro Engine:** Calculates BMR via the **Mifflin-St Jeor equation**, determines TDEE using customizable activity levels, and sets daily calorie targets based on your chosen deficit pace. Includes an optional protein tracker (`1.6g–2.2g/kg` of body weight).
- **Dynamic Weight Check-Ins:** Logs weigh-ins over time, tracks total weight progress, and automatically recalculates daily calorie and protein targets as your weight changes while preserving historical accuracy.
- **Hybrid Online/Offline Food Logging:** Searches the **Open Food Facts API** when online (normalizing `kcal`/`kJ` and serving weights) and caches items locally. Supports manual food entry and saved/recent foods when offline via real-time `connectivity_plus` detection.
- **Toggleable Fitness Modules:**
  - **Cardio / Strava-Style Logger:** Track runs, rides, walks, duration, distance, and calories burned.
  - **Strength / Lyfta-Style Logger:** Pre-seeded offline exercise library organized by muscle group with set, rep, and weight tracking plus MET-based calorie burn estimates.
  - **Flexible Net Calorie Math:** Toggle whether burned calories add back to your daily food allowance.
- **Complete History & Local Reminders:** Calendar-based daily logs with edit/delete support, paired with offline meal and weigh-in reminders via `flutter_local_notifications`.
- **AI Daily Coach Summary:** Optional integration with free-tier AI APIs (Google Gemini / Groq) to generate daily progress summaries cached locally for offline viewing.
- **Glassmorphism UI & Theme Customizer:** Frosted glass cards (`BackdropFilter`), curated Discord-inspired dark/light multi-stop gradient themes, and custom typography controls.

## Tech Stack & Local Architecture

- **Framework:** Flutter (Stable SDK) & Dart
- **Local Relational Database:** `sqflite` (SQLite) for `weight_logs`, `food_logs`, `saved_foods`, `cardio_logs`, and `workout_logs`
- **Preferences & Security:** `shared_preferences` for user profile/theme settings and `flutter_secure_storage` for on-device API key encryption
- **Backup & Restore:** Built-in JSON export/import to back up and restore your SQLite database locally
- **APIs & Networking:** Open Food Facts API, Google Gemini / Groq API (optional), `connectivity_plus`

